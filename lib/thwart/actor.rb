module Thwart
  # Module to include in objects which represent system actors, which may or may not have permission to perform a particular
  # action on a particular resource. Includes the config code for defining how an actor gets its role, as well as the instance
  # level code for determining an instance's final role and querying its permssions.
  # @see Thwart::Actor::ClassMethods
  # @see Thwart::Actor::InstanceMethods
  # @see Thwart::Actor::ClassMethods#thwart_access
  # @see Thwart::Cans
  module Actor
    def self.included(base)
      base.extend(ClassMethods)
    end
   
    module ClassMethods
      # Holds the default role for all actor instances
      attr_accessor :default_role
      
      # Holds the proc or symbol defining where to find an instance's role.
      # @private
      attr_accessor :role_from
      
      # Method to call once the Actor module has been included in a class to configure the actor class' behaviour.
      # @param [Block] Configuration block where `#role_method`, and `#default_role` can be set.
      def thwart_access(&block)
        # Include the actual meat of the actor code
        self.instance_eval do
          include Thwart::Cans
          include Thwart::Actor::InstanceMethods
        end
        # Set up DSL using dsl helper
        if block_given?
          dsl = Thwart::Dsl.new(:role_method => :role_from=, :role_proc => :role_from=, :role => :default_role=)
          dsl.evaluate(self, &block)
        end
      end
    end
    
    # Included in every Actor instance to add the {#thwart_role} method for determining an actor instance's role.
    # @see Thwart::Cans
    module InstanceMethods
      
      # Returns the role of this particular actor instance. Calls the instance method or proc if defined, and otherwise
      # falls back to the default role.
      # @return [Symbol] the name of the role this actor instance plays.
      def thwart_role
        # If the class level @role_from is a symbol, it is the name of the instance method to get the role
        # If the class level @role_from is a proc, call it
        # If the above are unsuccessful, use the default if it exists
        r = self.send(self.class.role_from) if self.class.role_from.is_a?(Symbol) && self.respond_to?(self.class.role_from)
        r ||= self.class.role_from.call(self) if self.class.role_from.respond_to?(:call)
        r ||= self.class.default_role unless self.class.default_role.nil?
        r
      end
    end
  end
end
