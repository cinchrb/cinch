spec = Gem::Specification.new do |s|
  s.name = 'cinch'
  s.version = "1.0.2"
  s.summary = 'An IRC Bot Building Framework'
  s.description = 'A simple, friendly DSL for creating IRC bots'
  s.authors = ['Lee Jarvis', 'Dominik Honnef']
  s.email = ['lee@jarvis.co', 'dominikh@fork-bomb.org']
  s.homepage = 'http://rubydoc.info/github/injekt/cinch'
  s.required_ruby_version = '>= 1.9.1'
  s.files = Dir['LICENSE', 'README.md', '{lib,examples}/**/*']
end
