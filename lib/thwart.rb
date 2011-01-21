require 'active_support'
require 'active_support/ruby/shim'
require 'active_support/callbacks'
require 'active_support/core_ext/module/attribute_accessors'
require "active_support/core_ext/module/delegation"
require "active_support/core_ext/array/wrap"


module Thwart
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
  
  # The default can => able methods for CRUD
  CrudActions = {:create => :creatable, :show => :showable, :update => :updatable, :destroy => :destroyable}
  
  Actions       = ActionsStore.new
  Actionables   = ActionGroupBuilder.new(Actions)
  Roles         = RoleRegistry.new
  
  class << self
    attr_reader :role_dsl
    attr_accessor :default_query_response, :role_registry, :actor_must_play_role, :all_classes_are_resources, :log_query_path, :last_query_path
    delegate :create_action, :to => "Thwart::Actions"
    delegate :create_action_group, :to => "Thwart::Actionables"
    delegate :create_role, :to => :role_dsl
    delegate :query, :to => "Thwart::Roles"
    

    # Opens up a configuration block to add permission parameters into thwart.
    # Pass this a block defining your application's permissions structure before trying to enforce it.
    def configure(&block)
      # Create builder DSLs for this configuration block
      @role_dsl = RoleBuilder.new(Actionables)
      Roles.monitor_builder(@role_dsl)
      
      # Configure
      dsl = Thwart::Dsl.new(:role => :create_role, :action => :create_action, :action_group => :create_action_group)
      dsl.all = false
      dsl.evaluate(self, &block)
      
      # Unset and stop monitoring builder DSLs so they can be GC'd
      @role_dsl = nil
      Roles.monitor_builder(nil)
      self
    end
  end

  self.log_query_path = false
  
  class MissingAttributeError < StandardError; end
  class NoPermissionError < StandardError; end
end

require 'thwart/rails' if defined?(Rails)
