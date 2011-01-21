require 'active_support/inflector'

# Module to include in objects which represent system resources, which actors may or may not be given to perform a particular
# action upon. Includes the config code for defining how a resource gets its name, as well as the instance level code for 
# querying its permissions.
# @see Thwart::Resource::ClassMethods
# @see Thwart::Ables
module Thwart::Resource
  include Thwart::Ables
  # Included hooks
  def self.included(base) 
    base.extend ClassMethods
  end
 
  # Instance level name of the resource. By default returns the class level one,
  # but this can be overridden safely.
  def thwart_name
    self.class.thwart_name
  end
  
  module ClassMethods
    attr_accessor :thwart_name
    
    # Accessor for the name of this resource. By default, returns a singularized table_name.
    # If you aren't using an ORM or one without tables, please use {#thwart_access} to set a name.
    def thwart_name
      return nil unless @thwarted
      return @thwart_name unless @thwart_name.nil?      
      ActiveSupport::Inflector.singularize(self.table_name).to_sym if self.respond_to?(:table_name)
    end

    # Method to call once the Resource module has been included in a class to configure the resource class' behaviour.
    # @param [Block] Configuration block where `#thwart_name` can be set.
    def thwart_access(&block) 
      @thwarted = true
      
      # Set up DSL using dsl helper
      if block_given? 
        dsl = Thwart::Dsl.new(:name => :thwart_name=)
        dsl.evaluate(self, &block)
      end
      self.ensure_attributes_set!
    end
   
    # @private
    def ensure_attributes_set!
      raise Thwart::MissingAttributeError if self.thwart_name == nil
    end
  end
end
