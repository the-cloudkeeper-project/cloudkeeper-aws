require 'cloudkeeper/aws'
require 'webmock/rspec'
require 'cloudkeeper_grpc'

RSpec.configure do |c|
  c.color = true
  c.tty = true
  c.order = 'random'
  c.formatter = 'documentation'
end

WebMock.disable_net_connect!(allow_localhost: true)

CloudkeeperGrpc::Image = Struct.new(:mode,
                                    :location,
                                    :format,
                                    :uri,
                                    :checksum,
                                    :size,
                                    :username,
                                    :password,
                                    :digest) do
  def initialize(mode: 'local',
                 location: 'http://localhost',
                 format: 'ova',
                 uri: 'http://remotehost',
                 checksum: 'a09q589',
                 size: '581816320',
                 username: 'root',
                 password: 'password',
                 digest: 'b08q987'); super(mode,
                                           location,
                                           format,
                                           uri,
                                           checksum,
                                           size,
                                           username,
                                           password,
                                           digest)
  end
end

CloudkeeperGrpc::Appliance = Struct.new(:identifier,
                                        :title,
                                        :description,
                                        :mpuri,
                                        :group,
                                        :ram,
                                        :core,
                                        :version,
                                        :architecture,
                                        :operating_system,
                                        :vo,
                                        :expiration_date,
                                        :image_list_identifier,
                                        :base_mpuri,
                                        :appid,
                                        :digest,
                                        :image) do
  def initialize(identifier: 'abc-123',
                 title: 'StubImage 0.1',
                 description: 'Uber image for nothing',
                 mpuri: 'http://remotehost/mpuri',
                 group: 'General group',
                 ram: '9000000',
                 core: '16',
                 version: '0.1',
                 architecture: 'x86_64',
                 operating_system: 'MSDOS',
                 vo: 'test.eu',
                 expiration_date: '2499-12-31T22:00:00Z',
                 image_list_identifier: 'bac-321',
                 base_mpuri: 'http://remotehost/base_mpuri',
                 appid: '15',
                 digest: 'c87q420',
                 image: nil); super(identifier,
                                    title,
                                    description,
                                    mpuri,
                                    group,
                                    ram,
                                    core,
                                    version,
                                    architecture,
                                    operating_system,
                                    vo,
                                    expiration_date,
                                    image_list_identifier,
                                    base_mpuri,
                                    appid,
                                    digest,
                                    image)
  end
end
