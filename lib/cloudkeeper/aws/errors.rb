module Cloudkeeper
  module Aws
    # Module containing error classes for Cloudkeeper-aws
    module Errors
      autoload :StandardError, 'cloudkeeper/aws/errors/standard_error'
      autoload :ImageDownloadError, 'cloudkeeper/aws/errors/image_download_error'
      autoload :InvalidConfigurationError, 'cloudkeeper/aws/errors/invalid_configuration_error'
      autoload :Backend, 'cloudkeeper/aws/errors/backend'
    end
  end
end
