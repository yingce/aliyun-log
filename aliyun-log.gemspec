# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'aliyun/version'

Gem::Specification.new do |spec|
  spec.name          = 'aliyun-log'
  spec.version       = Aliyun::Log::VERSION
  spec.authors       = ['Yingce Liu']
  spec.email         = ['yingce@live.com']

  spec.summary       = 'Aliyun Log SDK for Ruby'
  spec.description   = 'Aliyun Log SDK for Ruby 阿里云日志服务(SLS) Ruby SDK, 目前仅实现基于Restfull部分接口和简单Model映射'
  spec.homepage      = 'https://github.com/yingce/aliyun-log'
  spec.license       = 'MIT'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = 'https://rubygems.org'

    spec.metadata['homepage_uri'] = spec.homepage
    spec.metadata['source_code_uri'] = 'https://github.com/yingce/aliyun-log'
    spec.metadata['changelog_uri'] = 'https://github.com/yingce/aliyun-log/blob/master/CHANGELOG.md'
  else
    raise 'RubyGems 2.0 or newer is required to protect against ' \
      'public gem pushes.'
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  # spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
  #   `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  # end
  spec.files         = Dir['lib/**/*.rb']
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'activemodel'
  spec.add_dependency 'activesupport'
  spec.add_dependency 'protobuf', '~> 3.10.0'
  spec.add_dependency 'rest-client', '~> 2.0.0'

  spec.add_development_dependency 'bundler', '~> 1.17'
  spec.add_development_dependency 'rake', '~> 12.3', '>= 12.3.3'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'webmock', '~> 3.0'
end
