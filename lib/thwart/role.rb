module Thwart
  # Internal module encapsulating the various permissions an actor may play. Fields queries.
  module Role
    attr_accessor :name, :default_response, :responses

    def responses
      @responses ||= {}
      @responses
    end
    
    def parents
      @parents ||= []
      @parents
    end
    
    def parents=(p)
      @parents = p.uniq
      @parents
    end    
    
    # Queries this role to see if it has any rules that govern the actor trying to perform the action on the resource.
    # @param {Thwart::Actor} actor The actor trying to perform the action on the resource
    # @param {Thwart::Resource|Class|Symbol} resource The resource to which the actor might act upon
    # @param {Symbol} action The name of the action being attempted
    # @return {true|false|nil} Returns a boolean if this role has a rule that applies, or nil if no rules apply. The action can be performed if the query returns true.
    def query(actor, resource, action) 
      @query_result_found = false
      resp = nil
      if self.responses.has_key?(action)
        # Find the resource scope response if it exists {:view => {:foo => bool}}
        resp = self.resource_response(self.responses[action], self.find_resource_name(resource)) if !found? 
        # Find the action scope response if it exists {:view => bool}
        resp = self.action_response(action) if !found?
      end
      
      # Return the default if it exists
      resp = found!(self.default_response) if !found? && !self.default_response.nil?
      # Call it if it is a proc
      resp = resp.call(actor, resource, action) if resp.respond_to?(:call) 

      resp
    end
   
    # Traverses the rule tree to see if a rule exists governing the class of resources the queried resource belongs to. 
    # @private
    def resource_response(resources, name)
      # Return the resource scoped response if it exists
      if resources.respond_to?(:[]) && resources.respond_to?(:include?) 
        if resources.include?(name)
          return found!(resources[name])
        elsif resources.include?(:_other)
          return found!(resources[:_other])
        end
      end
      nil
    end
    
    # Traverses the rule tree to see if a rule exists governing the class of action the actor is trying to perform
    # @private
    def action_response(action)
      # Return the action level boolean, proc, or nil if it exists is the responses array
      response = self.responses[action]
      if self.responses.has_key?(action) && (response.is_a?(TrueClass) || response.is_a?(FalseClass) || response.nil? || response.respond_to?(:call))
        return found!(response)
      end
      nil
    end
    
    # Normalizes the name of the resource being queried as might be found in the rule tree
    # @param {Symbol|Thwart::Resource|Class|Object} resource An object which may be a Thwart::Resource, a string/symbol resource name, or a class/object.
    def find_resource_name(resource)
      return resource if resource.is_a?(Symbol)
      r ||= resource.thwart_name if resource.respond_to?(:thwart_name)
      if resource.class != Class
        r ||= resource.class.thwart_name if resource.class.respond_to?(:thwart_name)
        r ||= resource.class.name.downcase if Thwart.all_classes_are_resources
      end
      r = r.to_sym if r.respond_to?(:to_sym)
      r
    end
    
    private

    # Internal tracking method for tracking if an applicable rule has been discovered.   
    def found!(response)
      @query_result_found = true
      response
    end

    # Internal tracking method for tracking if an applicable rule has been discovered.       
    def found?
      @query_result_found ||= false
      @query_result_found == true
    end
  end
 
  # Internal class adopted by actors as the default response. 
  class DefaultRole
    include Thwart::Role
    def query(*args)
      return Thwart.default_query_response
    end
  end
end
