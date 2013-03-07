# -*- encoding: utf-8 -*-
require File.expand_path('../lib/toggle/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Jeff Iacono"]
  gem.email         = ["iacono@squareup.com"]
  gem.description   = %q{Easily control and change the path of your script}
  gem.summary       = %q{Easily control and change the path of your script}
  gem.homepage      = "https://github.com/square/toggle"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "toggle"
  gem.require_paths = ["lib"]
  gem.version       = Toggle::VERSION

  gem.add_runtime_dependency "activesupport", [">= 3.2.3"]

  gem.add_development_dependency "rake"
  gem.add_development_dependency "cane"
  gem.add_development_dependency "rspec", [">= 2"]
end
