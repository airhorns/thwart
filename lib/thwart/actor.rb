module Thwart
  module Actor
    def self.included(base)
      base.extend(ClassMethods)
    end
    
    module ClassMethods
      attr_accessor :default_role, :role_from
      # Thwart enabling hook on actors
      def thwart_access(&block)
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
    
    module InstanceMethods
      # The role of this particular actor instance
      # If the class level @role_from is a symbol, it is the name of the instance method to get the role
      # If the class level @role_from is a proc, call it
      # If the above are unsuccessful, use the default if it exists
      def thwart_role
        r = self.send(self.class.role_from) if self.class.role_from.is_a?(Symbol) && self.respond_to?(self.class.role_from)
        r ||= self.class.role_from.call(self) if self.class.role_from.respond_to?(:call)
        r ||= self.class.default_role unless self.class.default_role.nil?
        r
      end
    end
  end
end