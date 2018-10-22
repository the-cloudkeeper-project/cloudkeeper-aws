require 'spec_helper'
require 'mock_helper'

module Cloudkeeper
  module Aws
    describe ImageDownloader do
      describe '#download' do
        let(:uri) { 'https://testserver.com/test.img' }
        let(:stub_data) { 'send nudes' }

        context 'with success status' do
          before do
            stub_request(:any, /testserver.com/).to_return(body: stub_data)
          end

          it 'downloads correct file' do
            data = []
            described_class.download(uri) { |segment| data << segment }
            expect(data.join).to eq(stub_data)
          end
        end

        context 'with redirect status' do
          context 'with too many redirects' do
            before do
              stub_request(:any, /testserver.com/)
                .to_return(body: stub_data, status: 302,
                           headers: { 'location' => uri })
            end

            it 'raises error' do
              expect do
                described_class.download(uri) { |segment| data << segment }
              end.to raise_error(Cloudkeeper::Aws::Errors::ImageDownloadError)
            end
          end

          context 'with one redirect' do
            before do
              stub_request(:any, /testserver.com/)
                .to_return(body: stub_data, status: 302,
                           headers: { 'location' => 'https://redirectserver.com/test.img' })

              stub_request(:any, /redirectserver.com/).to_return(body: stub_data)
            end

            it 'downloads correct file' do
              data = []
              described_class.download(uri) { |segment| data << segment }
              expect(data.join).to eq(stub_data)
            end
          end
        end

        context 'with failed status' do
          before do
            stub_request(:any, /testserver.com/).to_return(status: 404)
          end

          it 'raises error' do
            expect do
              described_class.download(uri) { |segment| data << segment }
            end.to raise_error(Cloudkeeper::Aws::Errors::ImageDownloadError)
          end
        end
      end
    end
  end
end
