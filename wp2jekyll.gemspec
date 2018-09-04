
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "wp2jekyll/version"

Gem::Specification.new do |spec|
  spec.name          = "wp2jekyll"
  spec.version       = Wp2jekyll::VERSION
  spec.authors       = ["theme"]
  spec.email         = []

  spec.summary       = %q{Patch Wordpress exported md to use in Jekyll.}
  spec.description   = %q{Patch Wordpress exported md (md, html and xml are mixed) to use in Jekyll.}
  spec.homepage      = "https://github.com/theme/wp2jekyll"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "pretty-diffs", "~> 1.0"
  
  
  spec.add_dependency "nokogiri", "~> 1.8"
  spec.add_dependency "colorize", "~> 0.8"
  spec.add_dependency "diff-lcs", "~> 1.3"
  spec.add_dependency "googleauth", "~> 0.6"
  
end
