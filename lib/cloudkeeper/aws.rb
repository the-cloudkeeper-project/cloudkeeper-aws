module Cloudkeeper
  # Module for aws related cloudkeeper functionality
  module Aws
    autoload :CLI, 'cloudkeeper/aws/cli'
    autoload :Cloud, 'cloudkeeper/aws/cloud'
    autoload :Settings, 'cloudkeeper/aws/settings'
    autoload :Errors, 'cloudkeeper/aws/errors'
    autoload :ImageDownloader, 'cloudkeeper/aws/image_downloader'
    autoload :CoreConnector, 'cloudkeeper/aws/core_connector'
    autoload :FilterHelper, 'cloudkeeper/aws/filter_helper'
    autoload :ProtoHelper, 'cloudkeeper/aws/proto_helper'
  end
end

require 'cloudkeeper/aws/version'
