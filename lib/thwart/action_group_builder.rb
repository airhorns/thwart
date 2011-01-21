module Thwart
  # Responsible for building and managing the available actions and the groups that alias them.
  class ActionGroupBuilder
    # Holds all the different action groups in actionables[:name] => [array of resolved actions]
    attr_accessor :actionables 
    def actionables
      @actionables ||= {}
      @actionables
    end
    
    # Adds an actionable to the list of actionable things.
    # @param name [symbol] The name of the action
    # @param actions [symbol|array|nil] The actions this actionable resolves to. If nil, this is set to the name argument.
    def add_actionable(name, actions = nil)
      if actions.nil?
        actions = Array.wrap(name)
      else
        actions = Array.wrap(actions)
      end 
      self.actionables[name] = actions
    end
    
    # Creates an action group from an array of actionables.
    # @param name [symbol] The name of the new action group
    # @param others [symbol|array] One or an array symbols reffering to action or action groups
    def create_action_group(name, others)
      self.add_actionable(name, resolve_action_group(others))
    end
    
    # Resolves some actionables recursively down to the raw actions it corresponds to.
    # @param name [symbol|array] the symbol (or symbol array) referring to the existing actionables
    def resolve_action_group(name)
      # - if name is an array => resolve it recursively
      # - if name is in the action groups, pull out its existing resolution
      # - otherwise, raise an error because we don't know what this is.
      # Simple action groups (an action itself) must be added to the actions before they
      # are referenced, which is accomplished using the :save callback on Actions
      
      return name.map{|n| resolve_action_group(n)}.flatten.uniq if name.respond_to?(:map)
      return self.actionables[name].flatten.uniq if self.actionables.include?(name)
      raise Thwart::ActionOrGroupNotFoundError, "Action or group #{name} could not be found!"
    end
    
    # Adds the :create, :read, :update, and :destroy actionables
    def add_crud_group!
      @actions_store.add_crud! if @actions_store.respond_to?(:add_crud!)
      if @crud.nil? || @crud == false    
        self.create_action_group(:crud, Thwart::CrudActions.keys)
        @crud = true
      end
    end
    
    # @param actions_store [Thwart::Actions] the Actions repository. Internally maintained. 
    def initialize(actions_store = Thwart::Actions)
      builder = self
      @actions_store = actions_store
      @actions_store.class.set_callback :add, :after do |object|
        builder.add_actionable(actions_store.last_action)
      end
      builder
    end
  end
end
