module Cloudkeeper
  module Aws
    # Module refining basic GRPC structs with additional methods
    #   used for conversion from one format to another
    class ProtoHelper
      class << self
        APPLIANCE_VALUES = %w[identifier title
                              description mpuri
                              group ram
                              core version
                              architecture operating_system
                              vo expiration_date
                              image_list_identifier base_mpuri
                              appid digest].freeze

        IMAGE_VALUES = %w[mode location format uri checksum size
                          username password digest].freeze

        APPLIANCE_SUFFIX = 'cloudkeeper_appliance_'.freeze
        IMAGE_SUFFIX = 'cloudkeeper_image_'.freeze

        def filter_tags(tags, suffix)
          tags.select { |tag| tag[:key].include?(suffix) }
        end

        def remove_suffix(tags, suffix)
          tags.map { |tag| { tag[:key].sub(suffix, '').to_sym => tag[:value] } }.reduce(&:merge)
        end

        def prepare_tags(tags, suffix)
          remove_suffix(filter_tags(tags, suffix), suffix)
        end

        def appliance_to_tags(appliance)
          tags = APPLIANCE_VALUES.map { |v| { key: "#{APPLIANCE_SUFFIX}#{v}", value: appliance.send(v) } }
          tags += image_to_tags(appliance.image) unless appliance.image.nil?
          tags
        end

        def appliance_from_tags(tags)
          appliance = prepare_tags(tags, APPLIANCE_SUFFIX)
          appliance[:image] = image_from_tags(tags)
          CloudkeeperGrpc::Appliance.new(appliance)
        end

        def image_to_tags(image)
          IMAGE_VALUES.map { |v| { key: "#{IMAGE_SUFFIX}#{v}", value: image.send(v) } }
        end

        def image_from_tags(tags)
          image = prepare_tags(tags, IMAGE_SUFFIX)
          CloudkeeperGrpc::Image.new(image)
        end
      end
    end
  end
end
