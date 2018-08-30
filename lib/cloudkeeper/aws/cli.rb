require 'thor'
require 'yell'

module Cloudkeeper
  module Aws
    # Class defining CLI of cloudkeeper-aws
    class CLI < Thor
      SIGINT = 2
      SIGTERM = 15
      SIGNALS = [SIGTERM, SIGINT].freeze

      class_option :'logging-level',
                   required: true,
                   default: Cloudkeeper::Aws::Settings['logging']['level'],
                   type: :string,
                   enum: Yell::Severities
      class_option :'logging-file',
                   default: Cloudkeeper::Aws::Settings['logging']['file'],
                   type: :string,
                   desc: 'File to write logs to'
      class_option :debug,
                   default: Cloudkeeper::Aws::Settings['debug'],
                   type: :boolean,
                   desc: 'Runs cloudkeeper in debug mode'

      method_option :'polling-timeout',
                    default: Cloudkeeper::Aws::Settings['polling-timeout'],
                    type: :numeric,
                    desc: 'Polling timeout value in seconds'
      method_option :'polling-interval',
                    default: Cloudkeeper::Aws::Settings['polling-interval'],
                    type: :numeric,
                    desc: 'Polling interval value in seconds'
      method_option :'bucket-name',
                    default: Cloudkeeper::Aws::Settings['bucket-name'],
                    type: :string,
                    desc: 'Name of AWS bucket for storing temp image files'
      method_option :'listen-address',
                    default: Cloudkeeper::Aws::Settings['listen-address'],
                    type: :string,
                    desc: 'IP address gRPC server will listen on'
      method_option :authentication,
                    default: Cloudkeeper::Aws::Settings['authentication'],
                    type: :boolean,
                    desc: 'Client <-> server authentication'
      method_option :certificate,
                    required: false,
                    default: Cloudkeeper::Aws::Settings['certificate'],
                    type: :string,
                    desc: "Backend's host certificate"
      method_option :key,
                    required: false,
                    default: Cloudkeeper::Aws::Settings['key'],
                    type: :string,
                    desc: "Backend's host key"
      method_option :identifier,
                    default: Cloudkeeper::Aws::Settings['identifier'],
                    type: :string,
                    desc: 'Instance identifier'
      method_option :'core-certificate',
                    required: false,
                    default: Cloudkeeper::Aws::Settings['core']['certificate'],
                    type: :string,
                    desc: "Core's certificate"
      method_option :progress,
                    default: Cloudkeeper::Aws::Settings['progress'],
                    type: :boolean,
                    desc: 'Print progress for each import image task'

      desc 'sync', 'Runs synchronization process'
      def sync
        initialize_config
        initialize_logger
        grpc_server = GRPC::RpcServer.new
        grpc_server.add_http2_port Cloudkeeper::Aws::Settings[:'listen-address'], credentials
        grpc_server.handle Cloudkeeper::Aws::CoreConnector.new(Cloudkeeper::Aws::Cloud.new)
        grpc_server.run_till_terminated
      rescue SignalException => ex
        raise ex unless SIGNALS.include? ex.signo
        grpc_server.stop
      rescue Cloudkeeper::Aws::Errors::InvalidConfigurationError => ex
        abort ex.message
      rescue StandardError => ex
        logger.error "Unexpected error: #{ex.message}"
        raise ex
      end

      desc 'version', 'Prints Cloudkeeper-AWS version'
      def version
        $stdout.puts Cloudkeeper::Aws::VERSION
      end

      default_task :sync

      private

      def initialize_config
        aws_config = Cloudkeeper::Aws::Settings[:aws]
        Cloudkeeper::Aws::Settings.clear
        Cloudkeeper::Aws::Settings.merge! options.to_hash
        Cloudkeeper::Aws::Settings[:aws] = aws_config
      end

      def credentials
        return :this_port_is_insecure unless Cloudkeeper::Aws::Settings[:authentication]

        GRPC::Core::ServerCredentials.new(
          File.read(Cloudkeeper::Aws::Settings[:'core-certificate']),
          [private_key: File.read(Cloudkeeper::Aws::Settings[:key]),
           cert_chain: File.read(Cloudkeeper::Aws::Settings[:certificate])],
          true
        )
      end

      def validate_configuration!
        validate_configuration_group! :authentication,
                                      %i[certificate key core-certificate],
                                      'Authentication configuration missing'
      end

      def validate_configuration_group!(flag, required_options, error_message)
        return unless Cloudkeeper::Aws::Settings[flag]

        raise Cloudkeeper::Aws::Errors::InvalidConfigurationError, error_message unless all_options_available(required_options)
      end

      def all_options_available(required_options)
        required_options.reduce(true) { |acc, elem| Cloudkeeper::Aws::Settings[elem] && acc }
      end

      def initialize_logger
        logging_level = options['logging-level']
        logging_level = 'debug' if options['debug']

        Yell.new :stdout, name: Object, level: logging_level.downcase, format: Yell::DefaultFormat
        Object.send :include, Yell::Loggable

        setup_file_logger if options['logging-file']

        logger.debug { 'Running in debug mode...' }
      end

      def setup_file_logger
        logging_file = options['logging-file']
        unless (File.exist?(logging_file) && File.writable?(logging_file)) || File.writable?(File.dirname(logging_file))
          logger.error "File #{logging_file} isn't writable"
          return
        end
        logger.adapter :file, logging_file
      end
    end
  end
end
