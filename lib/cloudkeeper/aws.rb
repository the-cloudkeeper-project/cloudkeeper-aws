module Cloudkeeper
  # Module for aws related cloudkeeper functionality
  module Aws
    autoload :Cli, 'cloudkeeper/aws/cli'
    autoload :Cloud, 'cloudkeeper/aws/cloud'
    autoload :Settings, 'cloudkeeper/aws/settings'
    autoload :Errors, 'cloudkeeper/aws/errors'
  end
end

require 'cloudkeeper/aws/version'
