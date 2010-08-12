module Thwart
  
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
    
    def action_response(action)
      # Return the action level boolean, proc, or nil if it exists is the responses array
      response = self.responses[action]
      if self.responses.has_key?(action) && (response.is_a?(TrueClass) || response.is_a?(FalseClass) || response.nil? || response.respond_to?(:call))
        return found!(response)
      end
      nil
    end
    
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
    
    def found!(response)
      @query_result_found = true
      response
    end
    
    def found?
      @query_result_found ||= false
      @query_result_found == true
    end
  end
  
  class DefaultRole
    include Thwart::Role
    def query(*args)
      return Thwart.default_query_response
    end
  end
  
end