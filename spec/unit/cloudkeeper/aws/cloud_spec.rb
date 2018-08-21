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
            end.to raise_error(Cloudkeeper::Aws::Errors::Backend::BackendError)
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

          it 'raises error' do
            expect { cloud.poll_import_task(import_id) }.to \
              raise_error(Cloudkeeper::Aws::Errors::Backend::ImageImportError)
          end
        end

        context 'with status \'completed\'' do
          before do
            ec2.stub_responses(:describe_import_image_tasks,
                               import_image_tasks: [{ status: 'completed' }])
          end

          it 'wont raise error' do
            expect { cloud.poll_import_task(import_id) }.not_to raise_error
          end
        end

        context 'with changing status' do
          before do
            ec2.stub_responses(:describe_import_image_tasks, lambda do |_|
              { import_image_tasks: [{ status: status_sequence.shift }] }
            end)
          end

          context 'with final deleted' do
            let(:status_sequence) { %w[active active active deleted] }

            it 'returns false' do
              expect { cloud.poll_import_task(import_id) }.to \
                raise_error(Cloudkeeper::Aws::Errors::Backend::ImageImportError)
            end
          end

          context 'with final completed' do
            let(:status_sequence) { %w[active active active completed] }

            it 'returns true' do
              expect { cloud.poll_import_task(import_id) }.not_to raise_error
            end
          end
        end

        context 'with timeout' do
          before do
            Cloudkeeper::Aws::Settings['polling_timeout'] = 1
          end

          after do
            Cloudkeeper::Aws::Settings['polling_timeout'] = 3600
          end

          it 'raises exception' do
            expect { cloud.poll_import_task(import_id) }.to \
              raise_error(Cloudkeeper::Aws::Errors::Backend::TimeoutError)
          end
        end
      end
    end
  end
end
