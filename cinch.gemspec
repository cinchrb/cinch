require File.expand_path("../lib/cinch", __FILE__)

spec = Gem::Specification.new do |s|
  s.name = 'cinch'
  s.version = Cinch::VERSION
  s.platform = Gem::Platform::RUBY
  s.has_rdoc = true
  s.extra_rdoc_files = ["README.rdoc"]
  s.rdoc_options += ["--quiet",  '--title', 'Cinch: The IRC Bot Building Framework', '--main', 'README.rdoc']
  s.summary = "An IRC Bot Building Framework"
  s.description = s.summary
  s.author = "Lee 'injekt' Jarvis"
  s.email = "ljjarvis@gmail.com"
  s.homepage = "http://doc.injekt.net/cinch"
  s.required_ruby_version = ">= 1.8.7"
  s.files = %w(README.rdoc Rakefile) + Dir["{rdoc,spec,lib,examples}/**/*"]
  s.require_path = "lib"

  s.add_development_dependency('rspec', '= 1.3.0')
end
