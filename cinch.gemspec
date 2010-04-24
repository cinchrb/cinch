require File.expand_path("../lib/cinch", __FILE__)

spec = Gem::Specification.new do |s|
  s.name = 'cinch'
  s.version = Cinch::VERSION
  s.platform = Gem::Platform::RUBY
  s.has_rdoc = true
  s.extra_rdoc_files = ["README.rdoc"]
  s.rdoc_options += ["--quiet",  '--title', 'Cinch: The IRC Microframework', '--main', 'README.rdoc']
  s.summary = "An IRC Microframework"
  s.description = s.summary
  s.author = "Lee 'injekt' Jarvis"
  s.email = "ljjarvis@gmail.com"
  s.homepage = "http://rdoc.injekt.net/cinch"
  s.required_ruby_version = ">= 1.8.6"
  s.files = %w(README.rdoc Rakefile) + Dir["{rdoc,spec,lib}/**/*"]
  s.require_path = "lib"
end
