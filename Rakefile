require "rake/testtask"
Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = Dir["test/lib/**/*.rb"]
end

task :default => :test
