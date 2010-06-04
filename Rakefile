require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "http_url_validation_improved"
    gem.summary = %Q{a Rails gem that allows you to validate a URL 
entered in a form}
    gem.description = %Q{a Rails gem that allows you to validate a URL 
entered in a form. It validates if the URL exists by hitting it with a HEAD 
request.

The improved version includes retries for common patterns when the head request is refused before giving a failure notice.

It also looks up a SITE_URL constant to the user agent in the headers.

Also has the option to also check that the URL returns content of 
a specified type.}
    gem.email = "walter@katipo.co.nz"
    gem.homepage = "http://github.com/kete/http_url_validation_improved"
    gem.authors = ["Erik Gregg", "Walter McGinnis", "Kieran Pilkington"]
    gem.add_development_dependency "thoughtbot-shoulda", ">= 0"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/test_*.rb'
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

task :test => :check_dependencies

task :default => :test

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "http_url_validation_improved #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
