module Cloudkeeper
  module Aws
    # Class implementing GRPC procedures
    class CoreConnector < CloudkeeperGrpc::Communicator::Service
      attr_accessor :cloud

      include Cloudkeeper::Aws::BackendExecutor

      ERRORS = {
        Cloudkeeper::Aws::Errors::Backend::ApplianceNotFoundError => \
          CloudkeeperGrpc::Constants::STATUS_CODE_APPLIANCE_NOT_FOUND,
        Cloudkeeper::Aws::Errors::Backend::MultipleAppliancesFoundError => \
          CloudkeeperGrpc::Constants::STATUS_CODE_INVALID_RESOURCE_STATE,
        Cloudkeeper::Aws::Errors::Backend::ImageImportError => \
          CloudkeeperGrpc::Constants::STATUS_CODE_FAILED_APPLIANCE_TRANSFER,
        Cloudkeeper::Aws::Errors::Backend::TimeoutError => \
          CloudkeeperGrpc::Constants::STATUS_CODE_FAILED_APPLIANCE_TRANSFER,
        Cloudkeeper::Aws::Errors::Backend::BackendError => \
          CloudkeeperGrpc::Constants::STATUS_CODE_UNKNOWN,
        Cloudkeeper::Aws::Errors::ImageDownloadError => \
          CloudkeeperGrpc::Constants::STATUS_CODE_UNKNOWN
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
      rescue ::StandardError => e
        logger.error { "Standard error #{e.class} with message #{e.message}" }
        raise GRPC::BadStatus.new(CloudkeeperGrpc::Constants::STATUS_CODE_UNKNOWN, e.message)
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
        logger.debug { "GRPC add appliance #{appliance.identifier}" }
        handle_error do
          register_appliance(appliance)
          Google::Protobuf::Empty.new
        end
      end

      def update_appliance(appliance, _call)
        logger.debug { "GRPC update appliance #{appliance.identifier}" }
        handle_error do
          modify_appliance(appliance)
          Google::Protobuf::Empty.new
        end
      end

      def update_appliance_metadata(appliance, _call)
        logger.debug { "GRPC update appliance metadata #{appliance.identifier}" }
        handle_error do
          change_tags(appliance)
          Google::Protobuf::Empty.new
        end
      end

      def remove_appliance(appliance, _call)
        logger.debug { "GRPC remove appliance #{appliance.identifier}" }
        handle_error do
          deregister_image(appliance)
          Google::Protobuf::Empty.new
        end
      end

      def remove_image_list(image_list_identifier, _call)
        logger.debug { "GRPC remove image list with id: #{image_list_identifier.image_list_identifier}" }
        handle_error do
          deregister_image_list(image_list_identifier)
          Google::Protobuf::Empty.new
        end
      end

      def image_lists(_empty, _call)
        logger.debug { 'GRPC image lists' }
        handle_error { list_image_lists.each }
      end

      def appliances(image_list_identifier, _call)
        logger.debug { "GRPC appliances for: #{image_list_identifier.image_list_identifier}" }
        handle_error { fetch_appliances(image_list_identifier).each }
      end

      def remove_expired_appliances(_empty, _call)
        logger.debug { 'GRPC remove expired appliances' }
        handle_error do
          deregister_expired_appliances
          Google::Protobuf::Empty.new
        end
      end
    end
  end
end
