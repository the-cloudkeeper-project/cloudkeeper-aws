require 'net/https'

module Cloudkeeper
  module Aws
    # Class used for downloading images for cloudkeeper
    class ImageDownloader
      # Downloads file from uri by segments
      #
      # @param image_uri [String] uri of the image to download
      # @raise [Cloudkeeper::Aws:Errors::ImageDownloadError] if download failed
      def self.download(image_uri, limit = 10, &block)
        raise Cloudkeeper::Aws::Errors::ImageDownloadError, 'Too many redirects' \
          if limit.zero?

        uri = URI.parse(image_uri)
        Net::HTTP.start(uri.host) do |http|
          http.request_get(uri.path) do |resp|
            handle_response(resp, limit, &block)
          end
        end
      end

      # Method used for handeling responses from download requests.
      # It handles redirects as well as failures.
      #
      # @param resp [HTTP::Response] response to handle
      # @param limit [Number] redirect limit
      # @yield [segment] data segment
      def self.handle_response(resp, limit, &block)
        case resp
        when Net::HTTPRedirection then
          download(resp['location'], limit - 1, &block)
        when Net::HTTPSuccess then
          resp.read_body(&block)
        else
          raise Cloudkeeper::Aws::Errors::ImageDownloadError,
                'Failed to download image'
        end
      end
    end
  end
end
