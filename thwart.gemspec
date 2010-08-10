# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{thwart}
  s.version = "0.0.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Harry Brundage"]
  s.date = %q{2010-08-10}
  s.description = %q{Implements a robust Role Based Access System where Actors are granted permission to preform Actions by playing any number of Roles. All defined programatically in one place using a super easy DSL.}
  s.email = %q{harry@skylightlabs.ca}
  s.extra_rdoc_files = [
    "LICENSE",
     "README.rdoc"
  ]
  s.files = [
    ".document",
     ".gitignore",
     "LICENSE",
     "README.rdoc",
     "Rakefile",
     "VERSION",
     "autotest/discover.rb",
     "examples/a_complete_example.rb",
     "examples/example_helper.rb",
     "lib/thwart.rb",
     "lib/thwart/action_group_builder.rb",
     "lib/thwart/actions_store.rb",
     "lib/thwart/actor.rb",
     "lib/thwart/canable.rb",
     "lib/thwart/dsl.rb",
     "lib/thwart/enforcer.rb",
     "lib/thwart/resource.rb",
     "lib/thwart/role.rb",
     "lib/thwart/role_builder.rb",
     "lib/thwart/role_registry.rb",
     "spec/action_group_builder_spec.rb",
     "spec/actions_store_spec.rb",
     "spec/actor_spec.rb",
     "spec/canable_spec.rb",
     "spec/dsl_spec.rb",
     "spec/enforcer_spec.rb",
     "spec/resource_spec.rb",
     "spec/role_builder_spec.rb",
     "spec/role_registry_spec.rb",
     "spec/role_spec.rb",
     "spec/spec_helper.rb",
     "spec/thwart_spec.rb",
     "thwart.gemspec"
  ]
  s.homepage = %q{http://github.com/hornairs/thwart}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{A simple, powerful, and developer friendly authorization plugin. Still WIP.}
  s.test_files = [
    "spec/action_group_builder_spec.rb",
     "spec/actions_store_spec.rb",
     "spec/actor_spec.rb",
     "spec/canable_spec.rb",
     "spec/dsl_spec.rb",
     "spec/enforcer_spec.rb",
     "spec/resource_spec.rb",
     "spec/role_builder_spec.rb",
     "spec/role_registry_spec.rb",
     "spec/role_spec.rb",
     "spec/spec_helper.rb",
     "spec/thwart_spec.rb",
     "examples/a_complete_example.rb",
     "examples/example_helper.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rspec>, [">= 2.0.0.beta19"])
      s.add_runtime_dependency(%q<activesupport>, [">= 3.0.rc1"])
    else
      s.add_dependency(%q<rspec>, [">= 2.0.0.beta19"])
      s.add_dependency(%q<activesupport>, [">= 3.0.rc1"])
    end
  else
    s.add_dependency(%q<rspec>, [">= 2.0.0.beta19"])
    s.add_dependency(%q<activesupport>, [">= 3.0.rc1"])
  end
end

