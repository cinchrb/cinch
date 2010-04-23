require "rake"
require "rake/clean"
require "rake/gempackagetask"
require "rake/rdoctask"
require "spec/rake/spectask"

NAME = 'cinch'
VERSION = '0.1' 
TITLE = "Cinch: The IRC Microframework"
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

desc "Run all specs"
Spec::Rake::SpecTask.new(:spec) do |t|
  t.spec_files = Dir['spec/**/*_spec.rb']
end

namespace :spec do
  desc "Print with specdoc formatting"
  Spec::Rake::SpecTask.new(:doc) do |t|
    t.spec_opts = ["--format", "specdoc"]
    t.spec_files = Dir['spec/**/*_spec.rb']
  end
end


task :default => [:spec]
