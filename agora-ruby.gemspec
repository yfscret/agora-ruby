require_relative 'lib/agora/version'

Gem::Specification.new do |spec|
  spec.name          = "agora-ruby"
  spec.version       = Agora::VERSION
  spec.authors       = ["yfscret"]
  spec.email         = ["yfscret@gmail.com"]

  spec.summary       = %q{A Ruby client for Agora.io RESTful APIs, starting with Cloud Recording.}
  spec.description   = %q{This gem provides an easy-to-use interface for interacting with Agora.io's RESTful services, initially focusing on cloud recording functionalities, including uploading to Aliyun OSS.}
  spec.homepage      = "https://rubygems.org/gems/agora-ruby"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.5.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/yfscret/agora-ruby"
  spec.metadata["changelog_uri"] = "https://github.com/yfscret/agora-ruby"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "httparty", "~> 0.20"
end
