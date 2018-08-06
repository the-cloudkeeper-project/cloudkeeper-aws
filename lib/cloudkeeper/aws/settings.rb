require 'settingslogic'

module Cloudkeeper
  module Aws
    # Class handling settings logic of Cloudkeeper-aws
    class Settings < Settingslogic
      CONFIGURATION = 'cloudkeeper-aws.yml'.freeze

      source "#{ENV['HOME']}/.cloudkeeper-aws/#{CONFIGURATION}" \
      if File.exist?("#{ENV['HOME']}/.cloudkeeper-aws/#{CONFIGURATION}")

      source "/etc/cloudkeeper-aws/#{CONFIGURATION}" \
      if File.exist?("/etc/cloudkeeper-aws/#{CONFIGURATION}")

      source "#{File.dirname(__FILE__)}/../../../config/#{CONFIGURATION}"
    end
  end
end
