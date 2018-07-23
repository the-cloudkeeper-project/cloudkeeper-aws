module Cloudkeeper
  # Module for aws related cloudkeeper functionality
  module Aws
    autoload :Cloud, 'cloudkeeper/aws/cloud'
    autoload :Settings, 'cloudkeeper/aws/settings'
  end
end

require 'cloudkeeper/aws/version'
