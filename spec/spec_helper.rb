require 'cloudkeeper/aws'
require 'webmock/rspec'
require 'vcr'
require 'cloudkeeper_grpc'
require 'yell'
require 'simplecov'
require 'codecov'
require 'aws-sdk-s3'

SimpleCov.start
SimpleCov.formatter = SimpleCov::Formatter::Codecov

RSpec.configure do |c|
  c.color = true
  c.tty = true
  c.order = 'random'
  c.formatter = 'documentation'
end

VCR.configure do |config|
  config.cassette_library_dir = 'spec/cassettes'
  config.hook_into :webmock
  config.configure_rspec_metadata!
  config.after_http_request { |req, _| req.headers['Authorization'] = '' }
end

Yell.new :file, '/dev/null', name: Object, level: 'error', format: Yell::DefaultFormat
Object.send :include, Yell::Loggable

::Aws.config.update(credentials: Aws::Credentials.new('access', 'secret'))
