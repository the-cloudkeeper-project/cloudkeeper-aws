module Cloudkeeper
  module Aws
    # Class used for generating filter structures used by AWS .describe_tags
    class FilterHelper
      TAG_IMAGE_LIST_IDENTIFIER = 'cloudkeeper_appliance_image_list_identifier'.freeze
      TAG_IDENTIFIER = 'cloudkeeper_appliance_identifier'.freeze
      # Searches AWS tags by name (key)
      #
      # @param tag_name [String] tag name (key)
      # @return [Hash] filter for specific tag name
      def self.by_name(tag_name)
        { name: tag_name, values: [] }
      end

      # Only specified filter will be used for filtering tags
      #
      # @param filter [Hash] filter that will only be used
      # @return [Array] final fiter for AWS describe_tags method
      def self.only(filter)
        [filter]
      end

      # Searches AWS tags by name (key) and value
      #
      # @param tag_name [String] tag name (key)
      # @param tag_value [String] value to match tag value
      # @return [Hash] filter for specific tag value for specific tag name (key)
      def self.by_value(tag_name, tag_value)
        { name: tag_name, values: [tag_value] }
      end

      # Lists all tags for specific resource
      #
      # @param image_id [String] id of image to list tags for
      # @return [Array] final filter for listing image tags
      def self.all_tags_for(image_id)
        only(name: 'resource-id', values: [image_id])
      end

      # Lists all image image_list_identifier values in AWS
      #
      # @return [Array] final filter for listing all image lists
      def self.all_image_lists
        only(by_name(TAG_IMAGE_LIST_IDENTIFIER))
      end

      # Lists all images in image list
      #
      # @return [Array] final filter for listing all images in image list
      def self.image_list(image_list_identifier)
        only(by_value(TAG_IMAGE_LIST_IDENTIFIER, image_list_identifier))
      end

      # Fetches specific appliance, that means appliance with spcific identifier
      #
      # @param identifier [String] appliance identifier
      # @return [Array] final filter for fetching appliance
      def self.appliance(identifier)
        only(by_value(TAG_IDENTIFIER, identifier))
      end
    end
  end
end
