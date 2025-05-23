lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'report_generator/version'

Gem::Specification.new do |spec|
  spec.name          = 'report_generator'
  spec.version       = ReportGenerator::VERSION
  spec.authors       = ['Createk']
  spec.email         = ['dev@createk.io']

  spec.summary       = 'Generate CSV reports'
  spec.homepage      = 'https://github.com/CreatekIO/report_generator'
  spec.licenses      = ['MIT']

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = ''

    spec.metadata['homepage_uri'] = spec.homepage
    spec.metadata['source_code_uri'] = 'https://github.com/CreatekIO/report_generator'
  else
    raise 'RubyGems 2.0 or newer is required to protect against ' \
      'public gem pushes.'
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  current_ruby_version = Gem::Version.new(RUBY_VERSION)

  spec.add_dependency 'activerecord', '>= 4.2', '< 7.1'
  spec.add_dependency 'activesupport', '>= 4.2', '< 7.1'
  spec.add_dependency 'csv-safe', '>= 3.2.1' if Gem::Requirement.new('>= 2.6').satisfied_by?(current_ruby_version)
  spec.add_dependency 'dragonfly', '~> 1'
  spec.add_dependency 'jwt', '~> 1.5'
  spec.add_dependency 'rails-html-sanitizer', '~> 1'
  spec.add_dependency 'railties', '>= 4.2', '< 7.1'
  spec.add_dependency 'sidekiq', '>= 3'

  spec.add_development_dependency 'bundler', '>= 2.2.18', '< 3'
  spec.add_development_dependency 'byebug'
  spec.add_development_dependency 'dragonfly-s3_data_store', '~> 1.3'
  spec.add_development_dependency 'mysql2', '~> 0.5.3'
  spec.add_development_dependency 'rake', '~> 12.3.3'
  spec.add_development_dependency 'rspec-rails', '~> 3.0'
end
