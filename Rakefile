require "rake"
require "rake/clean"
require "rake/gempackagetask"
require "rake/rdoctask"
require "spec/rake/spectask"

require 'lib/cinch'

NAME = 'cinch'
VERSION = Cinch::VERSION
TITLE = "Cinch: The IRC Bot Building Framework"
CLEAN.include ["*.gem", "rdoc"]
RDOC_OPTS = [
  "-U", "--title", TITLE,
  "--op", "rdoc",
  "--main", "README.rdoc"
]

Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = "rdoc"
  rdoc.options += RDOC_OPTS
  rdoc.rdoc_files.add %w(README.rdoc lib/**/*.rb)
end

desc "Package"
task :package => [:clean] do |p|
  sh "gem build #{NAME}.gemspec"
end

desc "Install gem"
task :install => [:package] do
  sh "sudo gem install ./#{NAME}-#{VERSION} --local"
end

desc "Uninstall gem"
task :uninstall => [:clean] do
  sh "sudo gem uninstall #{NAME}"
end

desc "Upload gem to gemcutter"
task :release => [:package] do
  sh "gem push ./#{NAME}-#{VERSION}.gem"
end

desc "Run all specs"
Spec::Rake::SpecTask.new(:spec) do |t|
  t.spec_files = Dir['spec/**/*_spec.rb']
end

task :default => [:clean, :spec]

