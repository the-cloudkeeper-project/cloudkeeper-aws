require 'aws-sdk-s3'
require 'aws-sdk-ec2'

module Cloudkeeper
  module Aws
    class Cloud
      attr_reader :s3, :bucket, :ec2

      SUCCESSFUL_STATUS = ['completed'].freeze
      UNSUCCESSFUL_STATUS = ['failed', 'deleted'].freeze

      def initialize
        region = Cloudkeeper::Aws::Settings.aws.region
        @s3 = ::Aws::S3::Resource.new(region: region)
        @ec2 = ::Aws::EC2::Client.new(region: region)
        @bucket = s3.bucket(Cloudkeeper::Aws::Settings.bucket_name)
        bucket.create unless bucket.exists?
      end

      def upload_data(file_name, &block)
        obj = bucket.object(file_name)
        raise "File #{file_name} in AWS bucket already exists" if obj.exists?
        obj.upload_stream(&block)
      end

      def start_import_image(appliance)
        ec2.import_image({
          description: appliance.description,
          disk_containers: [
            {
              description: appliance.description,
              format: appliance.image.format,
              user_bucket: {
                s3_bucket: @bucket.name,
                s3_key: appliance.title
              }
            }
          ]
        }).import_task_id
      end

      def poll_import_task(import_id)
        sleep_time = Cloudkeeper::Aws::Settings.polling_interval
        loop do
          import_task = ec2.describe_import_image_tasks({
            import_task_ids: [import_id]
          }).import_image_tasks.first

          return true if SUCCESSFUL_STATUS.include?(import_task.status)
          return false if UNSUCCESSFUL_STATUS.include?(import_task.status)

          sleep sleep_time
        end
      end

      def deregister_image(image_id)
        ec2.deregister_image({
          image_id: image_id
        })
      end
      
      def set_tags(tags, image_id)
        ec2.create_tags({
          resources: [image_id],
          tags: tags
        })
      end

      def search_tags(tags_filter)
        ec2.describe_tags({
          filters: tags_filter
        }).tags.keep_if { |resource| resource.resource_type: 'image' }
      end
    end
  end
end
