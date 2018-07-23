require 'settingslogic'

module Cloudkeeper
  module Aws
    class Settings < Settingslogic
      CONFIGURATION = 'cloudkeeper-aws.yml'

      source "#{File.dirname(__FILE__)}/../../../config/#{CONFIGURATION}"
    end
  end
end
