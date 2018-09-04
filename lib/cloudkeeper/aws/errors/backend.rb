module Cloudkeeper
  module Aws
    module Errors
      # Module used for errors raised by AWS backend
      module Backend
        autoload :BackendError, 'cloudkeeper/aws/errors/backend/backend_error'
        autoload :TimeoutError, 'cloudkeeper/aws/errors/backend/timeout_error'
        autoload :ImageImportError, 'cloudkeeper/aws/errors/backend/image_import_error'
        autoload :ApplianceNotFoundError, 'cloudkeeper/aws/errors/backend/appliance_not_found_error'
        autoload :MultipleAppliancesFoundError, 'cloudkeeper/aws/errors/backend/multiple_appliances_found_error'
        autoload :NoBucketPermissionError, 'cloudkeeper/aws/errors/backend/no_bucket_permission_error'
      end
    end
  end
end
