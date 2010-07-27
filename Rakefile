require "rake"
require "rake/clean"
require "rake/gempackagetask"
require "spec/rake/spectask"

require 'lib/cinch'

NAME = 'cinch'
VERSION = Cinch::VERSION
TITLE = "Cinch: The IRC Bot Building Framework"
CLEAN.include ["*.gem", "rdoc"]

require 'hanna'
require 'rdoc/task'
RDoc::Task.new do |rdoc|
  rdoc.options.push '-f', 'hanna'
  rdoc.main = 'README.rdoc'
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = TITLE
  rdoc.rdoc_files.include('README.rdoc')
  rdoc.rdoc_files.include('lib/**/*.rb')
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

