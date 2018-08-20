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
          tag_descriptors = cloud.search_tags(FilterHelper.appliance(appliance.identifier))
          cloud.set_tags(ProtoHelper.appliance_to_tags(appliance), tag_descriptors.first.resource_id)
        end
      end

      def remove_appliance(appliance, _call)
        handle_aws do
          tag_descriptors = cloud.search_tags(FilterHelper.appliance(appliance.identifier))
          unless tag_descriptors.size == 1
            raise GRPC::BadStatus.new(CloudkeeperGrpc::Constants::STATUS_CODE_INVALID_RESOURCE_STATE,
                                      'Wrong number of appliances fetched')
          end
          cloud.deregister_image(tag_descriptors.first.resource_id)
        end
      end

      def remove_image_list(image_list_identifier, _call)
        handle_aws do
          tag_descriptors = cloud.search_tags(FilterHelper.image_list(image_list_identifier))
          tag_descriptors.each { |td| cloud.deregister_image(td.resource_id) }
        end
      end

      def image_lists(_empty, _call)
        handle_aws do
          tag_descriptors = cloud.search_tags(FilterHelper.all_image_lists)
          tag_descriptors.map(&:value).uniq
        end
      end

      def appliances(image_list_identifier, _call)
        handle_aws do
          tag_descriptors = cloud.search_tags(FilterHelper.image_list(image_list_identifier))
          tag_descriptors.map \
            { |td| ProtoHelper.appliance_from_tags(cloud.search_tags(FilterHelper.all_tags_for(td.resource_id))) }
        end
      end
    end
  end
end
