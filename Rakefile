require 'rubygems'
require 'rake'
require 'bundler'
begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "thwart"
    gem.summary = %Q{A simple, powerful, and developer friendly authorization plugin. Still WIP.}
    gem.description = %Q{Implements a robust Role Based Access System where Actors are granted permission to preform Actions by playing any number of Roles. All defined programatically in one place using a super easy DSL.}
    gem.email = "harry@skylightlabs.ca"
    gem.homepage = "http://github.com/hornairs/thwart"
    gem.authors = ["Harry Brundage"]
    gem.add_bundler_dependencies
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "thwart #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
