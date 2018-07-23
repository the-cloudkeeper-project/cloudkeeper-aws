require 'aws-sdk-s3'
require 'aws-sdk-ec2'

module Cloudkeeper
  module Aws
    # Class for AWS Cloud related operations
    class Cloud
      attr_reader :s3, :bucket, :ec2

      SUCCESSFUL_STATUS = %w[completed].freeze
      UNSUCCESSFUL_STATUS = %w[failed deleted].freeze

      # Constructs Cloud object that can communicate with AWS cloud.
      #
      # @note This method can be billed by AWS
      def initialize
        region = Cloudkeeper::Aws::Settings.aws.region
        @s3 = ::Aws::S3::Resource.new(region: region)
        @ec2 = ::Aws::EC2::Client.new(region: region)
        @bucket = s3.bucket(Cloudkeeper::Aws::Settings.bucket_name)
        bucket.create unless bucket.exists?
      end

      # Uploads data in block AWS file with given name
      #
      # @note This method can be billed by AWS
      # @param file_name [String] key of object in bucket
      # @yield [data] data to send
      # @raise [Cloudkeeper::Aws::Errors::BackendError] if file already exists
      def upload_data(file_name, &block)
        obj = bucket.object(file_name)
        if obj.exists?
          raise Cloudkeeper::Aws::Errors::BackendError,
                "File #{file_name} in AWS bucket already exists"
        end
        obj.upload_stream(&block)
      end

      # Creates import image task on AWS cloud. This task needs to be
      # polled for. See {#poll_import_task}.
      #
      # @note This method can be billed by AWS
      # @params appliance [Appliance] data about image
      def start_import_image(appliance)
        ec2.import_image(
          description: appliance.description,
          disk_containers: [disk_container(appliance)]
        ).import_task_id
      end

      # Method used for generating dick container for import image task
      #
      # @params appliance [Appliance] data about image
      # @return [Hash] disk container hash
      def disk_container(appliance)
        {
          description: appliance.description,
          format: appliance.image.format,
          user_bucket: {
            s3_bucket: @bucket.name,
            s3_key: appliance.title
          }
        }
      end

      # Polls for import image task result. This method is blocking, so
      # after image import task is completed, successfully or not, it will
      # return true or false.
      #
      # @note This method can be billed by AWS
      # @params import_id [String] id of import image task
      def poll_import_task(import_id)
        sleep_time = Cloudkeeper::Aws::Settings.polling_interval
        loop do
          import_task = ec2.describe_import_image_tasks(
            import_task_ids: [import_id]
          ).import_image_tasks.first

          return true if SUCCESSFUL_STATUS.include?(import_task.status)
          return false if UNSUCCESSFUL_STATUS.include?(import_task.status)

          sleep sleep_time
        end
      end

      # Deregisters specific image.
      #
      # @note This method can be billed by AWS
      # @param image_id [String] id of specific AMI
      def deregister_image(image_id)
        ec2.deregister_image(
          image_id: image_id
        )
      end

      # Sets tags to specific AMI.
      #
      # @note This method can be billed by AWS
      # @param tags [Array<Hash{Symbol => String}>] array of tags to set
      #   to specific AMI. Tag consists of key and value symbols
      # @param image_id [String] id of specific AMI
      def set_tags(tags, image_id)
        ec2.create_tags(
          resources: [image_id],
          tags: tags
        )
      end

      # Searches in AWS for images with specific tags. Returns only
      # image resources.
      #
      # @note This method can be billed by AWS
      # @param tags_filter [Array<Hash{Symbol => String, Array<String>}>] how to
      #   filter resources. Contains `:name` and `:values`.
      # @return [Array<Types::TagDescriptor>] contains `:key`, `:value`
      #   and `:resource_id`
      def search_tags(tags_filter)
        ec2.describe_tags(
          filters: tags_filter
        ).tags.keep_if { |resource| resource.resource_type == 'image' }
      end
    end
  end
end
