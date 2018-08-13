module Cloudkeeper
  module Aws
    # Class implementing GRPC procedures
    class CoreConnector < CloudkeeperGrpc::Communicator::Service
      using Cloudkeeper::Aws::ProtoHelper

      attr_accessor :cloud

      def initialize(cloud)
        @cloud = cloud
        super()
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

        image_id = cloud.poll_import_task(cloud.start_import_image(appliance))
        cloud.set_tags(appliance.to_tags, image_id)
      end

      def update_appliance(appliance, _call)
        if appliance.image.nil?
          tag_descriptors = cloud.search_tags(FilterHelper.only(
                                                FilterHelper.by_value('cloudkeeper_appliance_identifier',
                                                                      appliance.identifier)
                                              ))
          cloud.set_tags(appliance.to_tags, tag_descriptors.first.resource_id)
        else
          remove_appliance(appliance, nil)
          add_appliance(appliance, nil)
        end
      end

      def remove_appliance(appliance, _call)
        handle_aws do
          tag_descriptors = cloud.search_tags(FilterHelper.appliance(appliance.identifier))
          unless tag_descriptors.size == 1
            raise GRPC::BadStatus.new(CloudkeeperGrpc::Constants::STATUS_CODE_INVALID_RESOURCE_STATE,
                                      'Appliance duplication or not found')
          end
          cloud.deregister_image(tag_descriptors.first.resource_id)
        end
      end

      def remove_image_list(image_list_identifier, _call)
        tag_descriptors = cloud.search_tags(FilterHelper.only(
                                              FilterHelper.by_value('cloudkeeper_appliance_image_list_identifier',
                                                                    image_list_identifier)
                                            ))
        tag_descriptors.each { |td| cloud.deregister_image(td.resource_id) }
      end

      def image_lists(_empty, _call)
        tag_descriptors = cloud.search_tags(FilterHelper.only(
                                              FilterHelper.by_name('cloudkeeper_appliance_image_list_identifier')
                                            ))
        tag_descriptors.map(&:value).uniq
      end

      def appliances(image_list_identifier, _call)
        tag_descriptors = cloud.search_tags(FilterHelper.only(
                                              FilterHelper.by_value('cloudkeeper_appliance_image_list_identifier',
                                                                    image_list_identifier)
                                            ))
        tag_descriptors.map \
          { |td| Appliance.from_tags(cloud.search_tags(FilterHelper.only(FilterHelper.all_tags_for(td.resource_id)))) }
      end
    end
  end
end
