require 'spec_helper'

module Cloudkeeper
  module Aws
    describe 'Cloudkeeper GRPC API' do
      let(:s3) { ::Aws::S3::Resource.new(stub_responses: true) }
      let(:ec2) { ::Aws::EC2::Client.new(stub_responses: true) }
      let(:cloud) { Cloudkeeper::Aws::Cloud.new(s3service: s3, ec2service: ec2) }
      let(:core_connector) { Cloudkeeper::Aws::CoreConnector.new(cloud) }
      let(:stub_data) { 'image data' }

      describe 'add_appliance' do
        before do
          # Stub for obj.exists?
          s3.client.stub_responses(:head_object, status_code: 404, headers: {}, body: '')
          # Stub for obj.upload_stream
          s3.client.stub_responses(:upload_part,
                                   lambda do |context|
                                     @body = context.params[:body].string
                                     { etag: '123' }
                                   end)
          # Stub for polling import task
          ec2.stub_responses(:describe_import_image_tasks,
                             import_image_tasks: [{ status: 'completed',
                                                    image_id: '123456' }])
          # Stubs for downloading images
          stub_request(:get, /testserver.com/).to_return(body: stub_data)
          stub_request(:get, /wrongserver.com/).to_return(status: 404)
        end

        let(:image) { CloudkeeperGrpc::Image.new(uri: image_uri) }
        let(:appliance) { CloudkeeperGrpc::Appliance.new(image: image) }

        context 'with valid appliance' do
          let(:image_uri) { 'https://testserver.com/test.img' }

          before do
            count = 0
            s3.client.stub_responses(:head_object, lambda do |_|
              case count
              when 0
                count += 1
                { status_code: 404, headers: {}, body: '' }
              when 1
                { status_code: 200, headers: {}, body: '' }
              end
            end)
          end

          it 'uploads image' do
            core_connector.add_appliance(appliance, nil)
            expect(@body).to eq(stub_data)
          end
        end

        context 'with invalid image uri' do
          let(:image_uri) { 'https://wrongserver.com/test.img' }

          it 'does not upload image' do
            expect { core_connector.add_appliance(appliance, nil) }.to \
              raise_error(Cloudkeeper::Aws::Errors::ImageDownloadError)
          end
        end

        context 'with already uploaded image' do
          let(:image_uri) { 'https://testserver.com/test.img' }

          before do
            s3.client.stub_responses(:head_object,
                                     status_code: 200,
                                     headers: {},
                                     body: stub_data)
          end

          it 'does not upload image' do
            expect { core_connector.add_appliance(appliance, nil) }.to \
              raise_error(Cloudkeeper::Aws::Errors::Backend::BackendError)
          end
        end
      end

      describe 'remove_appliance' do
        let(:appliance_identifier) { 'a1a111' }
        let(:ami_id) { '123456' }
        let(:image) { CloudkeeperGrpc::Image.new }
        let(:appliance) { CloudkeeperGrpc::Appliance.new(identifier: appliance_identifier, image: image) }

        context 'with existing images' do
          before do
            ec2.stub_responses(:describe_tags, tags: [{ key: 'cloudkeeper_appliance_identifier',
                                                        resource_id: ami_id,
                                                        resource_type: 'image',
                                                        value: appliance_identifier }])
            ec2.stub_responses(:deregister_image, lambda do |context|
                                                    @removed_ami_id = context.params[:image_id]
                                                    {}
                                                  end)
          end

          it 'removes correct image' do
            core_connector.remove_appliance(appliance, nil)
            expect(@removed_ami_id).to eq(ami_id)
          end
        end

        context 'with not existing images' do
          before do
            ec2.stub_responses(:describe_tags, tags: [])
          end

          it 'wont remove image' do
            expect { core_connector.remove_appliance(appliance, nil) }.to \
              raise_error(GRPC::BadStatus)
          end
        end
      end

      describe 'remove_image_list' do
        let(:image_list_identifier) { 'i89-dq' }

        context 'with multiple images in one image list' do
          before do
            ec2.stub_responses(:describe_tags, tags: [{ key: 'cloudkeeper_appliance_image_list_identifier',
                                                        resource_id: '0',
                                                        resource_type: 'image',
                                                        value: image_list_identifier },
                                                      { key: 'cloudkeeper_appliance_image_list_identifier',
                                                        resource_id: '1',
                                                        resource_type: 'image',
                                                        value: image_list_identifier }])
            @removed_amis = []
            ec2.stub_responses(:deregister_image, lambda do |context|
                                                    @removed_amis << context.params[:image_id]
                                                    {}
                                                  end)
          end

          it 'removes all appliances in image list' do
            core_connector.remove_image_list(image_list_identifier, nil)
            expect(@removed_amis).to contain_exactly('0', '1')
          end
        end

        context 'with no images' do
          before do
            ec2.stub_responses(:describe_tags, tags: [])
            @removed_amis = []
            ec2.stub_responses(:deregister_image, lambda do |context|
                                                    @removed_amis << context.params[:image_id]
                                                    {}
                                                  end)
          end

          it 'wont remove any amis' do
            core_connector.remove_image_list(image_list_identifier, nil)
            expect(@removed_amis).to be_empty
          end
        end
      end

      describe 'image_lists' do
        context 'with multiple image lists' do
          before do
            ec2.stub_responses(:describe_tags, tags: [{ key: 'cloudkeeper_appliance_image_list_identifier',
                                                        resource_id: '0',
                                                        resource_type: 'image',
                                                        value: '0' },
                                                      { key: 'cloudkeeper_appliance_image_list_identifier',
                                                        resource_id: '1',
                                                        resource_type: 'image',
                                                        value: '0' },
                                                      { key: 'cloudkeeper_appliance_image_list_identifier',
                                                        resource_id: '2',
                                                        resource_type: 'image',
                                                        value: '1' }])
          end

          it 'returns all image list identifiers' do
            expect(core_connector.image_lists(nil, nil)).to contain_exactly('0', '1')
          end
        end
      end

      describe 'appliances' do
        let(:image) { CloudkeeperGrpc::Image.new }
        let(:image_tags) do
          %w[mode location
             format uri
             checksum size
             username password
             digest].map do |v|
               { key: "cloudkeeper_image_#{v}",
                 resource_id: '0',
                 resource_type: 'image',
                 value: image.send(v) }
             end
        end

        let(:appliance) { CloudkeeperGrpc::Appliance.new(image: image) }
        let(:appliance_tags) do
          { tags: %w[identifier title
                     description mpuri
                     group ram
                     core version
                     architecture operating_system
                     vo expiration_date
                     image_list_identifier base_mpuri
                     appid digest].map do |v|
                       { key: "cloudkeeper_appliance_#{v}",
                         resource_id: '0',
                         resource_type: 'image',
                         value: appliance.send(v) }
                     end + image_tags }
        end

        let(:tag_describer) do
          lambda do |context|
            filter = context.params[:filters].first
            if filter[:name] == 'cloudkeeper_appliance_image_list_identifier'
              { tags: [{ key: 'cloudkeeper_appliance_image_list_identifier',
                         resource_id: '0',
                         resource_type: 'image',
                         value: '123456' }] }
            elsif filter[:name] == 'resource-id'
              appliance_tags
            end
          end
        end

        let(:image_list_identifier) { '123456' }

        before do
          ec2.stub_responses(:describe_tags, tag_describer)
        end

        context 'with one appliance in image list' do
          using Cloudkeeper::Aws::ProtoHelper
          it 'returns 1 appliance' do
            expect(core_connector.appliances(image_list_identifier, nil)).to \
              contain_exactly(appliance)
          end
        end
      end
    end
  end
end
