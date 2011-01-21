require 'active_support/core_ext/hash/deep_merge'

module Thwart
  class ActionOrGroupNotFoundError < StandardError; end
  class OutsideRoleDefinitionError < StandardError; end
 
  # Internal class used to build the role objects during configuration
  class RoleBuilder
    include ActiveSupport::Callbacks
    define_callbacks :build_role, :scope => [:kind, :name]
    
    # Holds the last built role class, handy for using in callbacks.
    attr_accessor :last_built_role
    # Pointer to the storage engine for the actions and action groups.
    attr_reader :actionables_store
    delegate :actionables, :to => :actionables_store
    
    # Returns a new class including Thwart::Role, suitable for application
    # of rule definitions.
    def self.empty_role
      Class.new do
        include Thwart::Role
      end
    end
   
    # @param [Thwart::ActionsStore] storage_engine The actions storage engine used for action and group lookups
    def initialize(a_store)
      @actionables_store = a_store
    end
   
    # Called by #role in the configuration options. Creates a role with a particular name and
    # configures it using the given block
    # @param [Symbol] name The name of the role that can be played by actors
    # @param [Hash] options Options for the method. Supports `:include`, which takes an array of symbols, naming roles this role should inherit permissions from.
    # @param [Block] block DSL configuration block in which the permissions are defined.
    def create_role(name, options = {}, &block)
      @role = self.class.empty_role.new     # Start empty role
      @current_response = true              # Assume the first permission definitions are allows
      run_callbacks :build_role do
        # Add parents
        @role.name = name
        @role.parents = options[:parents] if options[:parents]
      
        # Run DSL block
        if block_given?
          @dsl ||= Thwart::Dsl.new
          @dsl.all = true
          @dsl.evaluate(self, &block)
        end
        self.last_built_role = @role
      end
      # Unset the @role instance variable to disable DSL methods and return the role
      r = @role
      @role = nil
      return r
    end
   
    # Called within role definitions to define permissions on resources. Usually proxied by the DSL, in
    # that you call `view :some_resource`, as opposed to `define_permission(:view, :some_resource)`
    # @see README
    # @param [Symbol] name The name of the action that this permission pertains to
    # @param [Symbol, Symbol ... ] resources Multiple names of resources this permission applies to
    # @param [Hash] options Options passed to this permission. Options right now include `:if` and `:unless` for defining conditional permissions.
    # @param [Block] if_block Shorthand for passing a block to determine the value or relevance of the permission. Corresponds to the `:if` option. 
    def define_permission(name, *resources, &block)
      ensure_in_dsl! 
      # Shift off first argument sent from method missing and convert any action groups to an array of actions
      raise ArgumentError, "Unrecognized action or action group #{name}" if !self.actionables.has_key?(name)
      names = self.actionables[name]
      
      # Pop of last hash argument from method missing and merge in default options and :if block
      options = {:if => false, :unless => false}
      options.merge!(resources.pop) if resources.last.respond_to?(:keys)
      options[:if] = block if block_given?
      # Allow :all or blank resource specifiers
      if resources.nil? || resources.empty? || resources.any? {|r| r == :all}
        resources = [:_other]
      end
      
      # Generate response based on @current_response and optional procs
      generated_response = generate_response(options)
      response_hash = hash_with_value(resources, generated_response)
      
      # Merge into existing role definition
      @role.responses.deep_merge!(hash_with_value(names) do |k|
        response_hash
      end)
    end
   
    # Sets the default response of the role being built. This should almost always be `false`.
    # @param [true|false] default_response The default response to return when the role is queried and no permissions apply.
    def default(bool)
      ensure_in_dsl!
      @role.default_response = bool
    end
   
    # Adds parent roles to this role's inheritance structure.
    def include(*args)
      ensure_in_dsl!
      @role.parents += args
    end
   
    # Syntactic sugar for giving blocks in which defined permissions allow the actions they specify.
    def allow(&block)
      evaluate_with_response(true, &block)
    end
    
    # Syntactic sugar for giving blocks in which defined permissions deny the actions they specify.
    def deny(&block)
      evaluate_with_response(false, &block)
    end

    # @private
    def evaluate_with_response(response, &block)
      ensure_in_dsl!
      old = @current_response
      @current_response = response
      @dsl.evaluate(self, &block)
      @current_response = old
    end

    def respond_to?(name,  other = false)
      return true if self.actionables.has_key?(name)
      super
    end
   
    # Hook for defining permissions in the `view :this` style, instead of having to call `define_permission` out right.
    def method_missing(name, *args, &block)
      return define_permission(name, *args, &block) if self.respond_to?(name)
      super
    end
    
    private
    # Futzes with the if and unless and block options to figure out what to do to get the permissions value.
    def generate_response(options) 
      # If a proc has been supplied
      if(options[:if].respond_to?(:call) || options[:unless].respond_to?(:call)) 
        # Copy variable for scope
        check = @current_response
        if options[:unless].respond_to?(:call)
          check = !check 
          options[:if] = options[:unless]
        end
        
        return Proc.new do |*args|
          check == options[:if].call(*args)
        end
      else
        @current_response
      end
    end
    
    # Calls a block for each value of an array to give a hash with the array's values as keys and the block/val for it's values.
    def hash_with_value(array, val = nil, &block) 
      array.inject({}) do |acc, k|
        acc[k] = if block_given?
          yield k
        else
          val
        end
        acc
      end
    end
   
    # @private
    def ensure_in_dsl!
      raise OutsideRoleDefinitionError, "You can only define role permissions inside a role defintion block!" if @role.nil?
    end
  end
  
end
