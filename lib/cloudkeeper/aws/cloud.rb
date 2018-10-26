require 'aws-sdk-s3'
require 'aws-sdk-ec2'
require 'timeout'

module Cloudkeeper
  module Aws
    # Class for AWS Cloud related operations
    class Cloud
      attr_reader :s3, :bucket, :ec2

      SUCCESSFUL_STATUS = %w[completed].freeze
      UNSUCCESSFUL_STATUS = %w[deleted].freeze

      # Constructs Cloud object that can communicate with AWS cloud.
      #
      # @note This method can be billed by AWS
      def initialize(s3service: nil, ec2service: nil)
        ::Aws.config.update(Cloudkeeper::Aws::Settings['aws'].deep_symbolize_keys)
        @s3 = s3service || ::Aws::S3::Resource.new
        @ec2 = ec2service || ::Aws::EC2::Client.new
        @bucket = s3.bucket(Cloudkeeper::Aws::Settings['bucket-name'])
        bucket.create unless bucket.exists?
      end

      # Uploads data in block AWS file with given name
      #
      # @note This method can be billed by AWS
      # @param file_name [String] key of object in bucket
      # @yield [write_stream] output stream
      # @raise [Cloudkeeper::Aws::Errors::BackendError] if file already exists
      def upload_data(file_name, &block)
        logger.debug { "Block uploading to entry (#{file_name}) in bucket(#{Cloudkeeper::Aws::Settings['bucket-name']})" }
        obj = bucket.object(file_name)
        if obj.exists?
          raise Cloudkeeper::Aws::Errors::Backend::BackendError,
                "File #{file_name} in AWS bucket already exists"
        end
        obj.upload_stream(&block)
      end

      # Uploads file to AWS bucket
      #
      # @note This method can be billed by AWS
      # @param file_name [String] name of file in AWS bucket
      # @param file_path [String] name of file on local machine
      # @raise [Cloudkeeper::Aws::Errors::BackendError] if file already exists
      def upload_file(file_name, file_path)
        logger.debug { "Local file uploading to entry (#{file_name}) in bucket(#{Cloudkeeper::Aws::Settings['bucket-name']})" }
        obj = bucket.object(file_name)
        if obj.exists?
          raise Cloudkeeper::Aws::Errors::Backend::BackendError,
                "File #{file_name} in AWS bucket already exists"
        end
        obj.upload_file(file_path)
      end

      def delete_data(file_name)
        logger.debug { "Deleting file: #{file_name} from bucket: #{Cloudkeeper::Aws::Settings['bucket-name']}" }
        obj = bucket.object(file_name)
        obj.exists? ? obj.delete : logger.info("File does not exist: #{file_name}")
      end

      # Creates import image task on AWS cloud. This task needs to be
      # polled for. See {#poll_import_task}.
      #
      # @note This method can be billed by AWS
      # @param appliance [Appliance] data about image
      # @return [Number] import task id
      def start_import_image(appliance)
        logger.debug { "Starting import image task for #{appliance.identifier}" }
        ec2.import_image(
          description: appliance.description,
          disk_containers: [disk_container(appliance)]
        ).import_task_id
      end

      # Method used for generating disk container for import image task
      #
      # @param appliance [Appliance] data about image
      # @return [Hash] disk container hash
      def disk_container(appliance)
        {
          description: appliance.description,
          format: appliance.image.format,
          user_bucket: {
            s3_bucket: @bucket.name,
            s3_key: appliance.identifier
          }
        }
      end

      # Polls for import image task result. This method is blocking, so
      # after image import task is completed, successfully or not, it will
      # return true or false.
      #
      # @note This method can be billed by AWS
      # @param import_id [String] id of import image task
      # @raise [Cloudkeeper::Aws::Errors::BackendError] if polling timed out
      def poll_import_task(import_id)
        logger.debug { "Polling for import task #{import_id}" }
        timeout do
          sleep_loop do
            import_task = ec2.describe_import_image_tasks(import_task_ids: [import_id]).import_image_tasks.first
            print_progress(import_task)
            if UNSUCCESSFUL_STATUS.include?(import_task.status)
              raise Cloudkeeper::Aws::Errors::Backend::ImageImportError,
                    "Import failed with status #{import_task.status} and message: #{import_task.status_message}"
            end
            return import_task.image_id if SUCCESSFUL_STATUS.include?(import_task.status)
          end
        end
      end

      def print_progress(import_task)
        logger.info "Import ##{import_task.import_task_id} [#{import_task.status}] with progress #{import_task.progress}%" \
          if Cloudkeeper::Aws::Settings['progress']
      end

      # Simple method used for calling block in intervals
      def sleep_loop
        loop do
          sleep Cloudkeeper::Aws::Settings['polling-interval']
          yield
        end
      end

      # Simple method used for handling timeout
      def timeout
        Timeout.timeout(Cloudkeeper::Aws::Settings['polling-timeout'],
                        Cloudkeeper::Aws::Errors::Backend::TimeoutError) do
          yield
        end
      end

      # Deregisters specific image.
      #
      # @note This method can be billed by AWS
      # @param image_id [String] id of specific AMI
      def deregister_image(image_id)
        logger.debug { "Deregistering AMI #{image_id}" }
        ec2.deregister_image(image_id: image_id)
      end

      # Sets tags to specific AMI.
      #
      # @note This method can be billed by AWS
      # @param tags [Array<Hash{Symbol => String}>] array of tags to set
      #   to specific AMI. Tag consists of key and value symbols
      # @param image_id [String] id of specific AMI
      def set_tags(tags, image_id)
        logger.debug { "Setting tags for AMI #{image_id}: #{tags}" }
        ec2.create_tags(resources: [image_id], tags: tags)
      end

      def search_images(filters)
        logger.debug { "Searching for AMI with filters: #{filters}" }
        ec2.describe_images(filters: filters).images
      end

      def find_appliance(identifier)
        logger.debug { "Fetching appliance with identifier: #{identifier}" }
        images = ec2.describe_images(filters: FilterHelper.appliance(identifier)).images
        raise Cloudkeeper::Aws::Errors::Backend::ApplianceNotFoundError, 'Appliance not found' if images.empty?

        if images.size > 1
          raise Cloudkeeper::Aws::Errors::Backend::MultipleAppliancesFoundError,
                'Multiple appliances with same identifier exist in AWS'
        end
        images.first
      end
    end
  end
end
