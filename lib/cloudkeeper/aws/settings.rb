require 'settingslogic'

module Cloudkeeper
  module Aws
    # Class handling settings logic of Cloudkeeper-aws
    class Settings < Settingslogic
      CONFIGURATION = 'cloudkeeper-aws.yml'.freeze

      source "#{File.dirname(__FILE__)}/../../../config/#{CONFIGURATION}"
    end
  end
end
