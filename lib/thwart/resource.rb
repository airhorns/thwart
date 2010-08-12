require 'active_support/inflector'
module Thwart::Resource
  include Thwart::Ables
  # Included hooks
  def self.included(base) 
    base.extend ClassMethods
  end
  
  def thwart_name
    self.class.thwart_name
  end
  
  module ClassMethods
    attr_accessor :thwart_name
    
    def thwart_name
      return nil unless @thwarted
      return @thwart_name unless @thwart_name.nil?      
      ActiveSupport::Inflector.singularize(self.table_name).to_sym if self.respond_to?(:table_name)
    end
    def thwart_access(&block) 
      @thwarted = true
      
      # Set up DSL using dsl helper
      if block_given? 
        dsl = Thwart::Dsl.new(:name => :thwart_name=)
        dsl.evaluate(self, &block)
      end
      self.ensure_attributes_set!
    end
    
    def ensure_attributes_set!
      raise Thwart::MissingAttributeError if self.thwart_name == nil
    end
  end
end