require 'spec_helper'
require 'mock_helper'

module Cloudkeeper
  module Aws
    describe 'Cloudkeeper GRPC API using WebMock' do
      let(:s3) { ::Aws::S3::Resource.new(stub_responses: true) }
      let(:ec2) { ::Aws::EC2::Client.new(stub_responses: true) }
      let(:cloud) { Cloudkeeper::Aws::Cloud.new(s3service: s3, ec2service: ec2) }
      let(:core_connector) { Cloudkeeper::Aws::CoreConnector.new(cloud) }

      describe 'add_appliance' do
        let(:stub_data) { 'image data' }
        let(:image) { CloudkeeperGrpc::Image.new(mode: image_mode, location: image_location) }
        let(:appliance) { CloudkeeperGrpc::Appliance.new(image: image) }

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
        end

        context 'when in local mode' do
          let(:image_mode) { :LOCAL }

          context 'with existing file' do
            let(:image_location) { File.join(FIXTURES_DIR, 'mock_image') }
            let(:s3object_mock) { instance_double(::Aws::S3::Object) }

            before do
              allow(::Aws::S3::Object).to receive(:new).and_return(s3object_mock)
              allow(s3object_mock).to receive(:upload_file) { |file_name| @file_name = file_name }
              allow(s3object_mock).to receive(:exists?).and_return(false)
              core_connector.add_appliance(appliance, nil)
            end

            it 'uploads image' do
              expect(@file_name).to eq(image_location)
            end
          end

          context 'with not existing file' do
            let(:image_location) { File.join(SPEC_DIR, 'notexist') }

            it 'raises error' do
              expect { core_connector.add_appliance(appliance, nil) }.to \
                raise_error(GRPC::BadStatus)
            end
          end

          context 'with already uploaded image' do
            let(:image_location) { File.join(SPEC_DIR, 'mock_image') }

            before do
              s3.client.stub_responses(:head_object,
                                       status_code: 200,
                                       headers: {},
                                       body: stub_data)
            end

            it 'does not upload image' do
              expect { core_connector.add_appliance(appliance, nil) }.to \
                raise_error(GRPC::BadStatus)
            end
          end
        end

        context 'when in remote mode' do
          let(:image_mode) { :REMOTE }

          before do
            # Stubs for downloading images
            stub_request(:get, /testserver.com/).to_return(body: stub_data)
            stub_request(:get, /wrongserver.com/).to_return(status: 404)
          end

          context 'with valid appliance' do
            let(:image_location) { 'https://testserver.com/test.img' }

            before do
              s3.client.stub_responses(:head_object, [{ status_code: 404, headers: {}, body: '' },
                                                      { status_code: 200, headers: {}, body: stub_data }])
              core_connector.add_appliance(appliance, nil)
            end

            it 'uploads image' do
              expect(@body).to eq(stub_data)
            end
          end

          context 'with invalid image uri' do
            let(:image_location) { 'https://wrongserver.com/test.img' }

            it 'does not upload image' do
              expect { core_connector.add_appliance(appliance, nil) }.to \
                raise_error(GRPC::BadStatus)
            end
          end

          context 'with already uploaded image' do
            let(:image_location) { 'https://testserver.com/test.img' }

            before do
              s3.client.stub_responses(:head_object,
                                       status_code: 200,
                                       headers: {},
                                       body: stub_data)
            end

            it 'does not upload image' do
              expect { core_connector.add_appliance(appliance, nil) }.to \
                raise_error(GRPC::BadStatus)
            end
          end
        end
      end
    end
  end
end
