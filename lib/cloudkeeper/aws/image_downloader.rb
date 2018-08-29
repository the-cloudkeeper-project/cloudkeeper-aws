require 'net/https'

module Cloudkeeper
  module Aws
    # Class used for downloading images for cloudkeeper
    class ImageDownloader
      # Downloads file from uri by segments
      #
      # @param image_uri [String] uri of the image to download
      # @param username [String] authentication username
      # @param password [String] authentication password
      # @param limit [Number] redirect limit to handle redirect infinite loops
      # @yield [segment] data segment
      # @raise [Cloudkeeper::Aws:Errors::ImageDownloadError] if download failed
      def self.download(image_uri, username = nil, password = nil, limit = 10, &block)
        raise Cloudkeeper::Aws::Errors::ImageDownloadError, 'Too many redirects' \
          if limit.zero?

        uri = URI.parse(image_uri)
        Net::HTTP.start(uri.host, uri.port) do |http|
          request = Net::HTTP::Get.new(uri)
          request.basic_auth username, password
          http.request(request) do |resp|
            handle_response(resp, username, password, limit, &block)
          end
        end
      rescue URI::InvalidURIError => e
        raise Cloudkeeper::Aws::Errors::ImageDownloadError, e.message
      end

      # Method used for handeling responses from download requests.
      # It handles redirects as well as failures.
      #
      # @param resp [HTTP::Response] response to handle
      # @param username [String] authentication username
      # @param password [String] authentication password
      # @param limit [Number] redirect limit
      # @yield [segment] data segment
      def self.handle_response(resp, username, password, limit, &block)
        case resp
        when Net::HTTPRedirection then
          download(resp['location'], username, password, limit - 1, &block)
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
