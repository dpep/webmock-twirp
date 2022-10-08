package_name = File.basename(__FILE__).split(".")[0]
load Dir.glob("lib/**/version.rb")[0]

package = WebMock::Twirp


Gem::Specification.new do |s|
  s.name        = package_name
  s.version     = package.const_get "VERSION"
  s.authors     = ["Daniel Pepper"]
  s.summary     = package.to_s
  s.description = "Twirp support for WebMock"
  s.homepage    = "https://github.com/dpep/#{package_name}"
  s.license     = "MIT"

  s.files       = Dir[
    __FILE__,
    'lib/**/*',
    'CHANGELOG*',
    'LICENSE*',
    'README*',
  ]

  s.add_dependency "webmock", ">= 3"
  s.add_dependency "twirp", ">= 1"

  s.add_development_dependency "byebug"
  s.add_development_dependency "codecov"
  s.add_development_dependency "rspec"
  s.add_development_dependency "simplecov"
end
