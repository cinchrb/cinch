require 'rubygems'
require 'rake'
require 'rake/clean'

$LOAD_PATH.unshift('lib') unless $LOAD_PATH.include?('lib')
require 'cinch'

CLEAN.include ["doc"]

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

require 'yard'
YARD::Rake::YardocTask.new do |t|
  t.files   = ['lib/**/*.rb', 'README.md']
  t.options = [
    '-m', 'markdown', 
    '--hide-void-return',
    '--quiet',
    '--title', "Cinch #{Cinch::VERSION} Documentation",
    '--main', 'README.md',
  ] 
end

namespace :gem do
  desc "Build gem"
  task :build => ["rake:clean"] do
    sh("gem build cinch.gemspec")
  end

  desc "Uninstall gem (not root)"
  task :uninstall do
    sh("gem uninstall cinch -v #{Cinch::VERSION}")
  end

  desc "Release to rubygems"
  task :release => [:build] do
    sh("gem push ./cinch-#{Cinch::VERSION}.gem")
  end

  desc "Install gem (not root)"
  task :install => :build do
    sh("gem install ./cinch-#{Cinch::VERSION} --local")
  end
end

namespace :doc do
  desc "Upload documentation"
  task :push => [:yard] do
    sh("scp -r doc/* injekt:injekt.net/doc/cinch")
  end
end

task :version do
  puts "Cinch version #{Cinch::VERSION}"
end

desc "Install gem (not root)"
task :install => "gem:install"

task :default => :spec

