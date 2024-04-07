require_relative "lib/webmock/twirp/version"
package = WebMock::Twirp

Gem::Specification.new do |s|
  s.authors     = ["Daniel Pepper"]
  s.description = "Twirp support for WebMock"
  s.files       = `git ls-files * ':!:spec'`.split("\n")
  s.homepage    = "https://github.com/dpep/webmock-twirp"
  s.license     = "MIT"
  s.name        = File.basename(__FILE__).split(".")[0]
  s.summary     = package.to_s
  s.version     = package.const_get "VERSION"

  s.required_ruby_version = ">= 3"

  s.add_dependency "webmock", ">= 3"
  s.add_dependency "twirp", ">= 1"

  s.add_development_dependency "byebug"
  s.add_development_dependency "rack"
  s.add_development_dependency "rspec"
  s.add_development_dependency "simplecov"
  s.add_development_dependency "webrick"
end
