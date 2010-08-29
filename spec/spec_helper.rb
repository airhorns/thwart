require 'rubygems'
require 'bundler'
Bundler.setup

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'thwart'
require 'rspec'
require 'rspec/autorun'

RSpec.configure do |c|
end

class User
  include Thwart::Actor
  attr_accessor :name
end

class Post
  include Thwart::Resource
  attr_accessor :title
end

def generic_model(name=nil, &block)
  klass = Class.new do
    def self.table_name
      "generics"
    end
    if name
      class_eval "def self.name; '#{name}' end"
      class_eval "def self.to_s; '#{name}' end"
    end
  end

  klass.class_eval(&block) if block_given?
  klass
end

def class_with_module(mod, &block)
  klass = Class.new do
    include mod
  end
  klass.class_eval(&block) if block_given?
  klass
end

def instance_with_module(mod, &block)
  class_with_module(mod, &block).new
end

def instance_with_role_definition(&block)
  role = instance_with_module(Thwart::Role)
  role.instance_eval(&block) if block_given?
  role
end