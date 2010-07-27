module Thwart
  class DuplicateRoleError < StandardError; end
  class MissingRoleError < StandardError; end
  
  class RoleRegistry
    def roles
      @roles ||= []
      @roles
    end
    
    def add(role)
      raise DuplicateRoleError, "Role #{role} already exists in the role registry!" if self.has_role?(role)
      @roles << role
    end
    
    def query(actor, resource, action)
      role = self.find_actor_role(actor)
      resource = self.find_resource_identifier(resource)
      if role.nil? || !self.has_role?(role) 
        raise MissingRoleError, "Role #{role} could not be found in the registry!" if Thwart.actor_must_play_role
      else
        q = [role]
        while r = q.shift
          resp = r.query(actor, resource, action)
          if resp != nil 
            return resp # positive/negative response from the role, a rule governs the role on this query
          else
            q = q | r.parents # add this roles parents to the query queue
          end
        end
      end
    
      Thwart.default_query_response # return was not called above, return the default
    end
  
    def has_role?(role)
      self.roles.include?(role)
    end
  
    def find_actor_role(actor)
      r = actor.thwart_role if actor.respond_to?(:thwart_role)
      r ||= r.to_sym if r.respond_to?(:to_sym)
      if r.is_a?(Symbol)
        r = self.roles.find {|a| a.name == r}
      end
      r
    end
  
    def find_resource_identifier(resource)
      r ||= resource.thwart_name if resource.respond_to?(:thwart_name)
      if resource.class != Class
        r ||= resource.class.thwart_name if resource.class.respond_to?(:thwart_name)
        r ||= resource.class.name.downcase.to_sym if Thwart.all_classes_are_resources
      end
      r
    end
  
    def initialize(role_creator = nil)
      self.monitor_builder(role_creator) if !role_creator.nil?
      self
    end
  
    def monitor_builder(role_creator)
      registry = self
      unless role_creator.nil?
        role_creator.class.set_callback :build_role, :after do |object|
          registry.add(object.last_built_role)
        end
      else
        @role_creator.class.reset_callbacks(:build_role)
      end
      @role_creator = role_creator
    end
  end
end