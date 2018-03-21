lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cloudkeeper/aws/version'

Gem::Specification.new do |spec|
  spec.name = 'cloudkeeper-aws'
  spec.version = Cloudkeeper::Aws::VERSION
  spec.authors = ['Dušan Baran']
  spec.email = ['work.dusanbaran@gmail.com']

  spec.summary = 'AWS backend for cloudkeeper'
  spec.description = 'AWS backend for cloudkeeper'
  spec.homepage = 'https://github.com/the-cloudkeeper-project/cloudkeeper-aws'
  spec.license = 'GNU General Public License v3.0'

  spec.files = `git ls-files -z`.split("\x0").reject \
    { |f| f.match(%r{^(test|spec|features)/}) }
  spec.executables = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.16'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 0.54'
end
