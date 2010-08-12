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
      if Thwart.log_query_path
        Thwart.last_query_path = [] 
        Thwart.last_query_path.push({:actor => actor, :resource => resource, :action => action})
        name = resource.thwart_name if resource.respond_to?(:thwart_name)
        name ||= resource
        Thwart.last_query_path.push({:actor_role => role.name, :resource_name => resource})
      end
      
      if role.nil? || !self.has_role?(role) 
        raise MissingRoleError, "Role #{role} could not be found in the registry!" if Thwart.actor_must_play_role
      else
        q = [role]
        while r = q.shift
          resp = r.query(actor, resource, action,)
          
          if Thwart.log_query_path
            Thwart.last_query_path.push("Querying #{r.name}")
            Thwart.last_query_path.push(r)
            Thwart.last_query_path.push("Response: #{resp}")
          end
          
          if resp != nil
            return resp # positive/negative response from the role, a rule governs the role on this query
          else
            q = q | r.parents.map do |a| 
              a = self.find_role(a) if a.is_a?(Symbol)
              a 
            end # add this roles parents to the query queue
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
      r = r.to_sym if r.respond_to?(:to_sym)
      r = find_role(r) if r.is_a?(Symbol)
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
    
    def find_role(name)
      self.roles.find {|a| a.name == name}
    end
  end
end