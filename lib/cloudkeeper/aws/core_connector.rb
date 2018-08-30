module Cloudkeeper
  module Aws
    # Class implementing GRPC procedures
    class CoreConnector < CloudkeeperGrpc::Communicator::Service
      attr_accessor :cloud

      ERRORS = {
        Cloudkeeper::Aws::Errors::Backend::ApplianceNotFoundError \
          => CloudkeeperGrpc::Constants::STATUS_CODE_APPLIANCE_NOT_FOUND,
        Cloudkeeper::Aws::Errors::Backend::MultipleAppliancesFoundError \
          => CloudkeeperGrpc::Constants::STATUS_CODE_INVALID_RESOURCE_STATE,
        Cloudkeeper::Aws::Errors::Backend::ImageImportError \
          => CloudkeeperGrpc::Constants::STATUS_CODE_FAILED_APPLIANCE_TRANSFER,
        Cloudkeeper::Aws::Errors::Backend::TimeoutError \
          => CloudkeeperGrpc::Constants::STATUS_CODE_FAILED_APPLIANCE_TRANSFER,
        Cloudkeeper::Aws::Errors::Backend::BackendError \
          => CloudkeeperGrpc::Constants::STATUS_CODE_UNKNOWN,
        Cloudkeeper::Aws::Errors::ImageDownloadError \
          => CloudkeeperGrpc::Constants::STATUS_CODE_UNKNOWN
      }.freeze

      def initialize(cloud)
        @cloud = cloud
        super()
      end

      def handle_error
        yield
      rescue Cloudkeeper::Aws::Errors::StandardError => e
        logger.error { "Error #{e.class} with message #{e.message}" }
        raise GRPC::BadStatus.new(ERRORS[e.class], e.message)
      rescue ::Aws::Errors::ServiceError => e
        logger.error { "AWS error with message #{e.message}" }
        raise GRPC::BadStatus.new(CloudkeeperGrpc::Constants::STATUS_CODE_UNKNOWN, e.message)
      end

      def upload_appliance(appliance)
        logger.debug { "GRPC upload appliance ##{appliance.identifier}" }
        cloud.upload_data(appliance.identifier) do |write_stream|
          ImageDownloader.download(appliance.image.location, appliance.image.username, appliance.image.password) do |image_segment|
            write_stream << image_segment
          end
        end
      end

      def pre_action(_empty, _call)
        logger.debug { 'GRPC pre action' }
        Google::Protobuf::Empty.new
      end

      def post_action(_empty, _call)
        logger.debug { 'GRPC post action' }
        Google::Protobuf::Empty.new
      end

      def add_appliance(appliance, _call)
        logger.debug { "GRPC add appliance ##{appliance.identifier}" }
        handle_error do
          begin
            upload_appliance(appliance)

            image_id = cloud.poll_import_task(cloud.start_import_image(appliance))
            logger.debug { "Image created: #{image_id}, using tags: #{ProtoHelper.appliance_to_tags(appliance)}" }
            cloud.set_tags(ProtoHelper.appliance_to_tags(appliance), image_id)
          ensure
            cloud.delete_data(appliance.identifier)
          end
          Google::Protobuf::Empty.new
        end
      end

      def update_appliance(appliance, _call)
        logger.debug { "GRPC update appliance ##{appliance.identifier}" }
        handle_error do
          remove_appliance(appliance, nil)
          add_appliance(appliance, nil)
          Google::Protobuf::Empty.new
        end
      end

      def update_appliance_metadata(appliance, _call)
        logger.debug { "GRPC update appliance metadata ##{appliance.identifier}" }
        handle_error do
          image = cloud.find_appliance(appliance.identifier)
          cloud.set_tags(ProtoHelper.appliance_to_tags(appliance), image.image_id)
          Google::Protobuf::Empty.new
        end
      end

      def remove_appliance(appliance, _call)
        logger.debug { "GRPC remove appliance ##{appliance.identifier}" }
        handle_error do
          image = cloud.find_appliance(appliance.identifier)
          cloud.deregister_image(image.image_id)
          Google::Protobuf::Empty.new
        end
      end

      def remove_image_list(image_list_identifier, _call)
        logger.debug { "GRPC remove image list with id: #{image_list_identifier.image_list_identifier}" }
        handle_error do
          images = cloud.search_images(FilterHelper.image_list(image_list_identifier))
          images.each { |image| cloud.deregister_image(image.image_id) }
          Google::Protobuf::Empty.new
        end
      end

      def image_lists(_empty, _call)
        logger.debug { 'GRPC image lists' }
        handle_error do
          images = cloud.search_images(FilterHelper.all_image_lists)
          image_list_identifiers = images.map do |image|
            image.tags.find { |tag| tag['key'] == FilterHelper::TAG_APPLIANCE_IMAGE_LIST_IDENTIFIER }['value']
          end
          image_list_identifiers.uniq.map { |ili| CloudkeeperGrpc::ImageListIdentifier.new(image_list_identifier: ili) }.each
        end
      end

      def appliances(image_list_identifier, _call)
        logger.debug { "GRPC appliances for: #{image_list_identifier.image_list_identifier}" }
        handle_error do
          images = cloud.search_images(FilterHelper.image_list(image_list_identifier))
          images.map { |image| ProtoHelper.appliance_from_tags(image.tags) }.each
        end
      end
    end
  end
end
