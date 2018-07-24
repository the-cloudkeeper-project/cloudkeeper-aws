require 'spec_helper'

module Cloudkeeper
  module Aws
    describe Cloud do
      let(:s3) do
        ::Aws::S3::Resource.new(stub_responses: true)
      end

      let(:ec2) do
        ::Aws::EC2::Client.new(stub_responses: true)
      end

      let(:cloud) do
        described_class.new(s3service: s3, ec2service: ec2)
      end

      describe '.upload_data' do
        let(:filename) { 'test' }
        let(:data) { 'Dusan is cool' }

        context 'with empty bucket' do
          before do
            s3.client.stub_responses(:head_object,
                                     status_code: 404, headers: {}, body: '')
          end

          it 'uploads data' do
            expect do
              cloud.upload_data(filename) \
                { |write_stream| write_stream << data }
            end.not_to raise_error
          end
        end

        context 'with existing file' do
          it 'raises error' do
            expect do
              cloud.upload_data(filename) \
                { |write_stream| write_stream << data }
            end.to raise_error(Cloudkeeper::Aws::Errors::BackendError)
          end
        end
      end

      describe '.poll_import_task' do
        let(:import_id) { 'ii-69' }

        context 'with status \'deleted\'' do
          before do
            ec2.stub_responses(:describe_import_image_tasks,
                               import_image_tasks: [{ status: 'deleted' }])
          end

          it 'returns false' do
            expect(cloud.poll_import_task(import_id)).to be(false)
          end
        end

        context 'with status \'completed\'' do
          before do
            ec2.stub_responses(:describe_import_image_tasks,
                               import_image_tasks: [{ status: 'completed' }])
          end

          it 'returns true' do
            expect(cloud.poll_import_task(import_id)).to be(true)
          end
        end
      end

      describe '.search_tags' do
        context 'with no resources' do
          before do
            stub_tags = []
            ec2.stub_responses(:describe_tags, lambda do |context|
              filtered_tags = stub_tags.select do |t|
                context.params[:filters].find do |f|
                  n = f[:name] == t[:key]
                  v = f[:values].empty? ? true : f[:values].include?(t[:value])
                  n && v
                end
              end

              { tags: filtered_tags }
            end)
          end

          it 'returns empty array' do
            tags = cloud.search_tags([{ name: 'cloudkeeper', values: [] }])
            expect(tags).to be_empty
          end
        end

        context 'with no image resources' do
          before do
            stub_tags = [
              { key: 'cloudkeeper', resource_id: '0', resource_type: 'instance', value: 'yes' },
              { key: 'image-list-id', resource_id: '0', resource_type: 'instance', value: '8' }
            ]

            ec2.stub_responses(:describe_tags, lambda do |context|
              filtered_tags = stub_tags.select do |t|
                context.params[:filters].find do |f|
                  n = f[:name] == t[:key]
                  v = f[:values].empty? ? true : f[:values].include?(t[:value])
                  n && v
                end
              end

              { tags: filtered_tags }
            end)
          end

          it 'searches for cloudkeeper tag' do
            tags = cloud.search_tags([{ name: 'cloudkeeper', values: [] }])
            expect(tags).to be_empty
          end

          it 'searches for image-list-id tag and value' do
            tags = cloud.search_tags([{ name: 'image-list-id', values: ['8'] }])
            expect(tags).to be_empty
          end
        end

        context 'with multiple resources' do
          before do
            stub_tags = [
              { key: 'cloudkeeper', resource_id: '0', resource_type: 'instance', value: 'yes' },
              { key: 'image-list-id', resource_id: '0', resource_type: 'instance', value: '8' },
              { key: 'cloudkeeper', resource_id: '1', resource_type: 'image', value: 'yes' },
              { key: 'image-list-id', resource_id: '1', resource_type: 'image', value: '8' }
            ]

            ec2.stub_responses(:describe_tags, lambda do |context|
              filtered_tags = stub_tags.select do |t|
                context.params[:filters].find do |f|
                  n = f[:name] == t[:key]
                  v = f[:values].empty? ? true : f[:values].include?(t[:value])
                  n && v
                end
              end

              { tags: filtered_tags }
            end)
          end

          it 'searches for cloudkeeper tag' do
            tags = cloud.search_tags([{ name: 'cloudkeeper', values: [] }])
            expect(tags.length).to eq(1)
          end

          it 'searches for image-list-id tag and value' do
            tags = cloud.search_tags([{ name: 'image-list-id', values: ['8'] }])
            expect(tags.length).to eq(1)
          end
        end
      end
    end
  end
end
