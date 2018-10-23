module Cloudkeeper
  module Aws
    # Module refining basic GRPC structs with additional methods
    #   used for conversion from one format to another
    class ProtoHelper
      class << self
        APPLIANCE_PREFIX = 'cloudkeeper_appliance_'.freeze
        IMAGE_PREFIX = 'cloudkeeper_image_'.freeze
        NAME_TAG_KEY = 'Name'.freeze
        EXTRA_APPLIANCE_TAGS = %i[description title].freeze

        def filter_tags(tags, prefix)
          tags.select { |tag| tag[:key].include?(prefix) }
        end

        def remove_prefix(tags, prefix)
          tags.map { |tag| { tag[:key].sub(prefix, '').to_sym => tag[:value] } }.reduce(&:merge)
        end

        def prepare_tags(tags, prefix)
          remove_prefix(filter_tags(tags, prefix), prefix)
        end

        def shorten_extra_tags!(appliance_hash)
          EXTRA_APPLIANCE_TAGS.each { |key| appliance_hash[key] = appliance_hash[key][0..254] }
        end

        def appliance_to_tags(appliance)
          appliance_hash = appliance.to_hash
          shorten_extra_tags!(appliance_hash)
          image = appliance_hash.delete(:image)
          tags = appliance_hash.map { |k, v| { key: "#{APPLIANCE_PREFIX}#{k}", value: v.to_s } }
          tags += image_to_tags(image) if image
          tags << { key: Cloudkeeper::Aws::FilterHelper::TAG_CLOUDKEEPER_IDENTIFIER,
                    value: Cloudkeeper::Aws::Settings['identifier'] }
          tags << { key: NAME_TAG_KEY, value: appliance_hash[:title] }
        end

        def appliance_from_tags(tags)
          appliance = appliance_prepare_values(prepare_tags(tags, APPLIANCE_PREFIX))
          appliance[:image] = image_from_tags(tags)
          CloudkeeperGrpc::Appliance.new(appliance)
        end

        def appliance_prepare_values(appliance)
          appliance[:ram] = appliance[:ram].to_i
          appliance[:core] = appliance[:core].to_i
          appliance[:expiration_date] = appliance[:expiration_date].to_i
          appliance
        end

        def image_to_tags(image)
          image.to_hash.map { |k, v| { key: "#{IMAGE_PREFIX}#{k}", value: v.to_s } }
        end

        def image_from_tags(tags)
          image = image_prepare_values(prepare_tags(tags, IMAGE_PREFIX))
          CloudkeeperGrpc::Image.new(image)
        end

        def image_prepare_values(image)
          image[:size] = image[:size].to_i
          image[:mode] = image[:mode].upcase.to_sym
          image[:format] = image[:format].upcase.to_sym
          image
        end
      end
    end
  end
end
