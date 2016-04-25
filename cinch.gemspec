Gem::Specification.new do |s|
  s.name = 'cinch'
  s.version = '2.3.2'
  s.summary = 'An IRC Bot Building Framework'
  s.description = 'A simple, friendly DSL for creating IRC bots'
  s.authors = ['Dominik Honnef']
  s.email = ['dominikh@fork-bomb.org']
  s.homepage = 'http://cinchrb.org'
  s.required_ruby_version = '>= 1.9.1'
  s.files = Dir['LICENSE', 'README.md', '.yardopts', '{docs,lib,examples}/**/*']
  s.has_rdoc = "yard"
  s.license = "MIT"
end
