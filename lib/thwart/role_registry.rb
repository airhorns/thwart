module Thwart
  class DuplicateRoleError < StandardError; end
  class MissingRoleError < StandardError; end

  # Internal class for handling the storage, adoption, and traversal of roles and role trees.  
  class RoleRegistry

    def initialize(role_creator = nil)
      self.monitor_builder(role_creator) if !role_creator.nil?
      self
    end  

    def roles
      @roles ||= []
      @roles
    end
   
    # Adds a uniquely named role to the registry.
    # @param {Thwart::Role} role The role to be added. Must have a unique name.
    def add(role)
      raise DuplicateRoleError, "Role #{role} already exists in the role registry!" if self.has_role?(role)
      @roles << role
    end
    
    # Boolean describing if a role exists in the registry.
    # @param {Thwart::Role} the role to search for.
    def has_role?(role)
      self.roles.include?(role)
    end

    # Queries the tree of roles to see if any have applicable rules and returns their result if they do.
    # Optionally logs the query path.
    # @param {Thwart::Actor} actor The actor trying to perform the action on the resource
    # @param {Thwart::Resource|Class|Symbol} resource The resource to which the actor might act upon
    # @param {Symbol} action The name of the action being attempted
    # @return {true|false} A boolean describing weather or not the actor can preform the action on the resource.
    def query(actor, resource, action)    
      role = self.find_actor_role(actor)
      # logging setup
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
        # Start DFS
        q = [role]
        while r = q.shift
          resp = r.query(actor, resource, action)
          
          if Thwart.log_query_path
            Thwart.last_query_path.push("Querying #{r.name}")
            Thwart.last_query_path.push(r)
            Thwart.last_query_path.push("Response: #{resp}")
          end
          
          if resp != nil
            return resp # positive/negative response from the role, a rule governs the role on this query
          else
            # nil response from the role, it has nothing to say about this query
            q = q | r.parents.map do |a| 
              a = self.find_role(a) if a.is_a?(Symbol)
              a 
            end # add this roles parents to the query queue
          end
        end
      end
    
      Thwart.default_query_response # return was not called above, return the default
    end

    # Method to get the `Thwart::Role` class played by an actor.
    # @param {Thwart::Actor} actor The actor in question
    # @return {Thwart::Role} The role class the actor plays.
    def find_actor_role(actor)
      r = actor.thwart_role if actor.respond_to?(:thwart_role)
      r = r.to_sym if r.respond_to?(:to_sym)
      r = find_role(r) if r.is_a?(Symbol)
      r
    end
 
    # Adds callback hooks to add all built roles to the registry.
    # @private
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
    
    # Finds a role based on a name
    # @private
    def find_role(name)
      self.roles.find {|a| a.name == name}
    end
  end
end
