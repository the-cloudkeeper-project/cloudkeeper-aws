module Cloudkeeper
  module Aws
    # Module handling complex operations on cloud backend
    module BackendExecutor
      def upload_appliance(appliance)
        cloud.upload_data(appliance.identifier) do |write_stream|
          ImageDownloader.download(appliance.image.location, appliance.image.username, appliance.image.password) do |image_segment|
            write_stream << image_segment
          end
        end
      end

      def register_appliance(appliance)
        upload_appliance(appliance)
        image_id = cloud.poll_import_task(cloud.start_import_image(appliance))
        cloud.set_tags(ProtoHelper.appliance_to_tags(appliance), image_id)
      ensure
        cloud.delete_data(appliance.identifier)
      end

      def deregister_image(appliance)
        image = cloud.find_appliance(appliance.identifier)
        cloud.deregister_image(image.image_id)
      end

      def modify_appliance(appliance)
        deregister_image(appliance)
        register_appliance(appliance)
      end

      def change_tags(appliance)
        image = cloud.find_appliance(appliance.identifier)
        cloud.set_tags(ProtoHelper.appliance_to_tags(appliance), image.image_id)
      end

      def deregister_image_list(image_list_identifier)
        images = cloud.search_images(FilterHelper.image_list(image_list_identifier.image_list_identifier))
        images.each { |image| cloud.deregister_image(image.image_id) }
      end

      def list_image_lists
        images = cloud.search_images(FilterHelper.all_image_lists)
        image_list_identifiers = images.map do |image|
          image.tags.find { |tag| tag['key'] == FilterHelper::TAG_APPLIANCE_IMAGE_LIST_IDENTIFIER }['value']
        end
        image_list_identifiers.uniq.map { |ili| CloudkeeperGrpc::ImageListIdentifier.new(image_list_identifier: ili) }
      end

      def fetch_appliances(image_list_identifier)
        images = cloud.search_images(FilterHelper.image_list(image_list_identifier.image_list_identifier))
        images.map { |image| ProtoHelper.appliance_from_tags(image.tags) }
      end
    end
  end
end
