module Cloudkeeper
  module Aws
    # Module containing error classes for Cloudkeeper-aws
    module Errors
      autoload :StandardError, 'cloudkeeper/aws/errors/standard_error'
      autoload :BackendError, 'cloudkeeper/aws/errors/backend_error'
    end
  end
end
