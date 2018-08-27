module Cloudkeeper
  module Aws
    # Class implementing GRPC procedures
    class CoreConnector < CloudkeeperGrpc::Communicator::Service
      attr_accessor :cloud

      def initialize(cloud)
        @cloud = cloud
        super()
      end

      def handle_aws
        yield
      rescue ::Aws::Errors::ServiceError => e
        raise GRPC::BadStatus.new(CloudkeeperGrpc::Constants::STATUS_CODE_UNKNOWN, e.message)
      end

      def upload_appliance(appliance)
        cloud.upload_data(appliance.identifier) do |write_stream|
          ImageDownloader.download(appliance.image.uri) do |image_segment|
            write_stream << image_segment
          end
        end
      end

      def pre_action(_empty, _call); end

      def post_action(_empty, _call); end

      def add_appliance(appliance, _call)
        handle_aws do
          begin
            upload_appliance(appliance)

            image_id = cloud.poll_import_task(cloud.start_import_image(appliance))
            cloud.set_tags(ProtoHelper.appliance_to_tags(appliance), image_id)
            cloud.delete_data(appliance.identifier)
          rescue Cloudkeeper::Aws::Errors::Backend::BackendError => e
            raise GRPC::BadStatus.new(CloudkeeperGrpc::Constants::STATUS_CODE_FAILED_APPLIANCE_TRANSFER, e.message)
          end
        end
      end

      def update_appliance(appliance, _call)
        handle_aws do
          remove_appliance(appliance, nil)
          add_appliance(appliance, nil)
        end
      end

      def update_appliance_metadata(appliance, _call)
        handle_aws do
          image = cloud.find_appliance(appliance.identifier)
          cloud.set_tags(ProtoHelper.appliance_to_tags(appliance), image.image_id)
        end
      end

      def remove_appliance(appliance, _call)
        handle_aws do
          image = cloud.find_appliance(appliance.identifier)
          cloud.deregister_image(image.image_id)
        end
      end

      def remove_image_list(image_list_identifier, _call)
        handle_aws do
          images = cloud.search_images(FilterHelper.image_list(image_list_identifier))
          images.each { |image| cloud.deregister_image(image.image_id) }
        end
      end

      def image_lists(_empty, _call)
        handle_aws do
          images = cloud.search_images(FilterHelper.all_image_lists)
          images.map do |image|
            image.tags.find { |tag| tag['key'] == FilterHelper::TAG_APPLIANCE_IMAGE_LIST_IDENTIFIER }['value']
          end.uniq
        end
      end

      def appliances(image_list_identifier, _call)
        handle_aws do
          images = cloud.search_images(FilterHelper.image_list(image_list_identifier))
          images.map { |image| ProtoHelper.appliance_from_tags(image.tags) }
        end
      end
    end
  end
end
