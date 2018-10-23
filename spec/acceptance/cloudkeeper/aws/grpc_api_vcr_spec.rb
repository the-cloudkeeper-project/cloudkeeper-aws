require 'spec_helper'

module Cloudkeeper
  module Aws
    describe 'Cloudkeeper GRPC API using VCR' do
      let(:cloud) { Cloudkeeper::Aws::Cloud.new }
      let(:core_connector) { Cloudkeeper::Aws::CoreConnector.new(cloud) }
      let(:image_list) { '403c189b-66b4-5084-81cf-f2a9d602d29e' }
      let(:grpc_image_list) { CloudkeeperGrpc::ImageListIdentifier.new(image_list_identifier: image_list) }

      describe 'remove_expired_appliances' do
        context 'with no expired AMIs', :vcr do
          it 'will not remove appliances' do
            appliances_before = core_connector.fetch_appliances(grpc_image_list)
            core_connector.remove_expired_appliances(Google::Protobuf::Empty.new, nil)
            appliances_after = core_connector.fetch_appliances(grpc_image_list)
            expect(appliances_after).to match_array(appliances_before)
          end
        end

        context 'with one expired AMI', :vcr do
          it 'will remove appliance' do
            appliances_before = core_connector.fetch_appliances(grpc_image_list)
            core_connector.remove_expired_appliances(Google::Protobuf::Empty.new, nil)
            appliances_after = core_connector.fetch_appliances(grpc_image_list)
            expect(appliances_after.length).to eq(appliances_before.length - 1)
          end
        end
      end
    end
  end
end
