module Cloudkeeper
  # Module for aws related cloudkeeper functionality
  module Aws
    autoload :Cli, 'cloudkeeper/aws/cli'
    autoload :Cloud, 'cloudkeeper/aws/cloud'
    autoload :Settings, 'cloudkeeper/aws/settings'
    autoload :Errors, 'cloudkeeper/aws/errors'
    autoload :ImageDownloader, 'cloudkeeper/aws/image_downloader'
  end
end

require 'cloudkeeper/aws/version'
