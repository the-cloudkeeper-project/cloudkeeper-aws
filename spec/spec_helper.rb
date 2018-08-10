require 'cloudkeeper/aws'
require 'webmock/rspec'

RSpec.configure do |c|
  c.color = true
  c.tty = true
  c.order = 'random'
  c.formatter = 'documentation'
end

WebMock.disable_net_connect!(allow_localhost: true)
