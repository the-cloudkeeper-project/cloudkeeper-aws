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
              raise_error(GRPC::BadStatus)
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
              raise_error(GRPC::BadStatus)
          end
        end
      end
    end
  end
end
