module Cloudkeeper
  module Aws
    # Module handling complex operations on cloud backend
    module BackendExecutor
      def upload_local_appliance(appliance)
        cloud.upload_file(appliance.identifier, appliance.image.location)
      end

      def upload_remote_appliance(appliance)
        cloud.upload_data(appliance.identifier) do |write_stream|
          ImageDownloader.download(appliance.image.location,
                                   appliance.image.username,
                                   appliance.image.password) do |image_segment|
                                     write_stream << image_segment
                                   end
        end
      end

      def upload_appliance(appliance)
        upload_remote_appliance(appliance) if appliance.image.mode == :REMOTE
        upload_local_appliance(appliance) if appliance.image.mode == :LOCAL
      end

      def register_appliance(appliance)
        upload_appliance(appliance)
        image_id = cloud.poll_import_task(cloud.start_import_image(appliance))
        cloud.set_tags(ProtoHelper.appliance_to_tags(appliance), image_id)
      ensure
        cloud.delete_data(appliance.identifier)
      end

      def deregister_image(appliance)
        logger.debug { "Deregistering appliance #{appliance.identifier}" }
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

      def deregister_expired_appliances
        images = cloud.search_images(FilterHelper.cloudkeeper_instance)
        appliances = images.map { |image| ProtoHelper.appliance_from_tags(image.tags) }
        appliances.keep_if { |appliance| appliance.expiration_date <= Time.now.to_i }

        logger.debug { "Expired appliances #{appliances.map(&:identifier).inspect}" }
        appliances.each { |expired| deregister_image(expired) }
      end
    end
  end
end
