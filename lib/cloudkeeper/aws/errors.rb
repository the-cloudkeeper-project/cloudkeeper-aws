module Cloudkeeper
  module Aws
    module Errors
      autoload :StandardError, 'lib/cloudkeeper/aws/errors/standard_error'
      autoload :BackendError, 'lib/cloudkeeper/aws/errors/backend_error'
    end
  end
end
