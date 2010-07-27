require 'active_support/core_ext/hash/deep_merge'

module Thwart
  class ActionOrGroupNotFoundError < StandardError; end
  class OustideRoleDefinitionError < StandardError; end
  
  class RoleBuilder
    include ActiveSupport::Callbacks
    define_callbacks :build_role, :scope => [:kind, :name]
    
    attr_accessor :last_built_role
    attr_reader :actionables_store
    delegate :actionables, :to => :actionables_store
    
    def self.empty_role
      Class.new do
        include Thwart::Role
      end
    end
    
    def initialize(a_store)
      @actionables_store = a_store
    end
    
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
    
    def default(bool)
      ensure_in_dsl!
      @role.default_response = bool
    end
    
    def include(*args)
      ensure_in_dsl!
      @role.parents += args
    end
    
    def allow(&block)
      evaluate_with_response(true, &block)
    end
    
    def deny(&block)
      evaluate_with_response(false, &block)
    end

    def evaluate_with_response(response, &block)
      ensure_in_dsl!
      old = @current_response
      @current_response = response
      @dsl.evaluate(self, &block)
      @current_response = old
    end

    def respond_to?(name)
      return true if self.actionables.has_key?(name)
      super
    end
    
    def method_missing(name, *args, &block)
      return define_permission(name, *args, &block) if self.respond_to?(name)
      super
    end
    
    private
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
    
    def ensure_in_dsl!
      raise OustideRoleDefinitionError, "You can only define role permissions inside a role defintion block!" if @role.nil?
    end
  end
  
end