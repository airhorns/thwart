require 'active_support'
require 'active_support/callbacks'
require 'active_support/core_ext/module/attribute_accessors'
require "active_support/core_ext/module/delegation"
require "active_support/core_ext/array/wrap"


require 'thwart/canable'
require 'thwart/actions_store'
require 'thwart/action_group_builder'
require 'thwart/role_registry'
require 'thwart/role_builder'
require 'thwart/role'
require 'thwart/resource'
require 'thwart/actor'
require 'thwart/enforcer'
require 'thwart/dsl'

module Thwart
  # autoload :Cans, 'thwart/canable'
  # autoload :Ables, 'thwart/canable'
  # autoload :ActionsStore, 'thwart/actions_store'
  # autoload :ActionGroupBuilder, 'thwart/action_group_builder'
  # autoload :RoleRegistry, 'thwart/role_registry'
  # autoload :RoleBuilder, 'thwart/role_builder'
  # autoload :Role, 'thwart/role'
  # autoload :DefaultRole, 'thwart/role'
  # autoload :Resource, 'thwart/resource'
  # autoload :Actor, 'thwart/actor'
  # autoload :Dsl, 'thwart/dsl'
  
  # The default can => able methods for CRUD
  CrudActions = {:create => :creatable, :view => :viewable, :update => :updatable, :destroy => :destroyable}
  
  Actions       = ActionsStore.new
  Roles         = RoleRegistry.new
  
  class << self
    attr_reader :actionables_dsl, :role_dsl
    attr_accessor :default_query_response, :role_registry, :actor_must_play_role, :all_classes_are_resources
    delegate :create_action, :to => "Thwart::Actions"
    delegate :create_action_group, :to => :actionables_dsl
    delegate :create_role, :to => :role_dsl
    delegate :query, :to => "Thwart::Roles"
    
    def configure(&block)
      # Create builder DSLs for this configuration block
      @actionables_dsl = ActionGroupBuilder.new(Actions)
      @role_dsl = RoleBuilder.new(@actionables_dsl)
      Roles.monitor_builder(@role_dsl)
      
      # Configure
      dsl = Thwart::Dsl.new(:role => :create_role, :action => :create_action, :action_group => :create_action_group)
      dsl.all = false
      dsl.evaluate(self, &block)
      
      # Unset and stop monitoring builder DSLs so they can be GC'd
      @actionables_dsl = nil
      @role_dsl = nil
      Roles.monitor_builder(nil)
      self
    end
  end
  
  class MissingAttributeError < StandardError; end
  class NoPermissionError < StandardError; end
end