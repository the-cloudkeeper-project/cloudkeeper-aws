<p align="center">
  <img alt="Cloudkeeper-AWS" src="https://i.imgur.com/1L2LcZ0.png" width="400"/>
</p>

# Cloudkeeper-AWS
AWS backend for [Cloudkeeper](https://github.com/the-cloudkeeper-project/cloudkeeper)

## What does Cloudkeeper-AWS do?
Cloudkeeper-AWS is able to manage [AWS](https://aws.amazon.com/) cloud - upload, update and remove images representing EGI AppDB appliances. Cloudkeeper-AWS runs as a server listening for [gRPC](http://www.grpc.io/) communication usually from core [cloudkeeper](https://github.com/the-cloudkeeper-project/cloudkeeper) component.

## Requirements
* Ruby >= 2.2.0
* Rubygems

## Installation

### From RubyGems.org
To install the most recent stable version
```bash
gem install cloudkeeper-aws
```

### From source
**Installation from source should never be your first choice! Especially, if you are not
familiar with RVM, Bundler, Rake and other dev tools for Ruby!**

**However, if you wish to contribute to our project, this is the right way to start.**

To build and install the bleeding edge version from master

```bash
git clone git://github.com/the-cloudkeeper-project/cloudkeeper-aws.git
cd cloudkeeper-aws
gem install bundler
bundle install
```

## Configuration

### Create a configuration file for Cloudkeeper-AWS
Configuration file can be read by Cloudkeeper-AWS from these
three locations:

* `~/.cloudkeeper-aws/cloudkeeper-aws.yml`
* `/etc/cloudkeeper-aws/cloudkeeper-aws.yml`
* `PATH_TO_GEM_DIR/config/cloudkeeper-aws.yml`

The default configuration file can be found at the last location
`PATH_TO_GEM_DIR/config/cloudkeeper-aws.yml`.

## Usage
Cloudkeeper-AWS is run with executable `cloudkeeper-aws`. For further assistance run `cloudkeeper-aws help sync`:
```bash
Usage:
  cloudkeeper-aws sync

Options:
  [--polling-timeout=N]                      # Polling timeout value in seconds
                                             # Default: 3600
  [--polling-interval=N]                     # Polling interval value in seconds
                                             # Default: 2
  [--bucket-name=BUCKET-NAME]                # Name of AWS bucket for storing temp image files
                                             # Default: cloudkeeper-aws
  [--listen-address=LISTEN-ADDRESS]          # IP address gRPC server will listen on
                                             # Default: 127.0.0.1:50051
  [--authentication], [--no-authentication]  # Client <-> server authentication
  [--certificate=CERTIFICATE]                # Backend's host certificate
                                             # Default: /etc/grid-security/hostcert.pem
  [--key=KEY]                                # Backend's host key
                                             # Default: /etc/grid-security/hostkey.pem
  [--identifier=IDENTIFIER]                  # Instance identifier
                                             # Default: cloudkeeper-aws
  [--core-certificate=CORE-CERTIFICATE]      # Core's certificate
                                             # Default: /etc/grid-security/corecert.pem
  [--progress], [--no-progress]              # Print progress for each import image task
  --logging-level=LOGGING-LEVEL              
                                             # Default: ERROR
                                             # Possible values: DEBUG, INFO, WARN, ERROR, FATAL, UNKNOWN
  [--logging-file=LOGGING-FILE]              # File to write logs to
                                             # Default: /var/log/cloudkeeper/cloudkeeper-aws.log
  [--debug], [--no-debug]                    # Runs cloudkeeper in debug mode

Runs synchronization process
```

## Contributing
1. Fork it ( https://github.com/the-cloudkeeper-project/cloudkeeper-aws/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
