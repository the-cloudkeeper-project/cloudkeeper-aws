require 'spec_helper'

module Cloudkeeper
  module Aws
    describe ProtoHelper do
      let(:image) { CloudkeeperGrpc::Image.new }
      let(:image_tags) do
        [{ key: 'cloudkeeper_image_mode', value: 'LOCAL' },
         { key: 'cloudkeeper_image_location', value: 'http://localhost' },
         { key: 'cloudkeeper_image_format', value: 'OVA' },
         { key: 'cloudkeeper_image_uri', value: 'http://remotehost' },
         { key: 'cloudkeeper_image_checksum', value: 'a09q589' },
         { key: 'cloudkeeper_image_size', value: '581816320' },
         { key: 'cloudkeeper_image_username', value: 'root' },
         { key: 'cloudkeeper_image_password', value: 'password' },
         { key: 'cloudkeeper_image_digest', value: 'b08q987' }]
      end

      let(:appliance) { CloudkeeperGrpc::Appliance.new(image: image) }
      let(:appliance_tags) do
        [{ key: 'cloudkeeper_appliance_identifier', value: 'abc-123' },
         { key: 'cloudkeeper_appliance_title', value: 'StubImage 0.1' },
         { key: 'cloudkeeper_appliance_description', value: 'Uber image for nothing' },
         { key: 'cloudkeeper_appliance_mpuri', value: 'http://remotehost/mpuri' },
         { key: 'cloudkeeper_appliance_group', value: 'General group' },
         { key: 'cloudkeeper_appliance_ram', value: '9000000' },
         { key: 'cloudkeeper_appliance_core', value: '16' },
         { key: 'cloudkeeper_appliance_version', value: '0.1' },
         { key: 'cloudkeeper_appliance_architecture', value: 'x86_64' },
         { key: 'cloudkeeper_appliance_operating_system', value: 'MSDOS' },
         { key: 'cloudkeeper_appliance_vo', value: 'test.eu' },
         { key: 'cloudkeeper_appliance_expiration_date', value: '69' },
         { key: 'cloudkeeper_appliance_image_list_identifier', value: 'bac-321' },
         { key: 'cloudkeeper_appliance_base_mpuri', value: 'http://remotehost/base_mpuri' },
         { key: 'cloudkeeper_appliance_appid', value: '15' },
         { key: 'cloudkeeper_appliance_digest', value: 'c87q420' },
         { key: 'cloudkeeper_identifier', value: 'cloudkeeper-aws' }] + image_tags
      end

      describe '#appliance_to_tags' do
        it 'creates correct tags' do
          expect(described_class.appliance_to_tags(appliance)).to match_array(appliance_tags)
        end
      end

      describe '#appliance_from_tags' do
        it 'creates correct image from tags' do
          expect(described_class.appliance_from_tags(appliance_tags)).to eq(appliance)
        end
      end

      describe '#image_to_tags' do
        it 'creates correct tags' do
          expect(described_class.image_to_tags(image)).to match_array(image_tags)
        end
      end

      describe '#image_from_tags' do
        it 'creates correct image from tags' do
          expect(described_class.image_from_tags(image_tags)).to eq(image)
        end
      end
    end
  end
end
