module Cloudkeeper
  module Aws
    # Class used for generating filter structures used by AWS .describe_tags
    class FilterHelper
      TAG_APPLIANCE_IMAGE_LIST_IDENTIFIER = 'cloudkeeper_appliance_image_list_identifier'.freeze
      TAG_APPLIANCE_IDENTIFIER = 'cloudkeeper_appliance_identifier'.freeze
      TAG_CLOUDKEEPER_IDENTIFIER = 'cloudkeeper_identifier'.freeze

      def self.all_image_lists
        [{ name: 'tag-key', values: [TAG_APPLIANCE_IMAGE_LIST_IDENTIFIER] }] + cloudkeeper_instance
      end

      def self.image_list(image_list_identifier)
        [{ name: "tag:#{TAG_APPLIANCE_IMAGE_LIST_IDENTIFIER}",
           values: [image_list_identifier] }] + cloudkeeper_instance
      end

      def self.appliance(identifier)
        [{ name: "tag:#{TAG_APPLIANCE_IDENTIFIER}",
           values: [identifier] }] + cloudkeeper_instance
      end

      def self.image(image_id)
        [{ name: 'image-id', values: [image_id] }] + cloudkeeper_instance
      end

      def self.cloudkeeper_instance
        [{ name: "tag:#{TAG_CLOUDKEEPER_IDENTIFIER}",
           values: [Cloudkeeper::Aws::Settings['identifier']] }]
      end
    end
  end
end
