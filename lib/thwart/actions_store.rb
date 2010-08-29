module Thwart
  class ActionsStore
    include ActiveSupport::Callbacks
    attr_accessor :last_action
    attr_reader :actions
    define_callbacks :add
  
    def initialize
      @actions = {}
    end
  
    # Returns true if Thwart is providing methods for the [action-able]_by? style action
    # identifier, false otherwise. 
    #
    #   @param [Symbol] able_method The name of the [action-able]_by? method to check for.  
    def has_able?(able)
      self.actions.has_value?(able.to_sym)
    end

    # Returns true if Thwart is providing methods for the can_[action]? style action 
    # identifer, false otherwise. 
    #
    #   @param [Symbol] able_method The name of the can_[action]? method to check for.  
    def has_can?(can)
      self.actions.has_key?(can.to_sym)
    end

    # Finds the corresponding can from an able. 
    #
    #   @param [Symbol] able_method The name of the [action-able]_by? method.  
    def can_from_able(able)
      pair = self.actions.find {|k, v| v == able}
      pair.first if pair
    end

    # Adds an action to actions and the correct methods to can and able modules.
    #
    #   @param [Symbol] can_method The name of the can_[action]? method.
    #   @param [Symbol] resource_method The name of the [action-able]_by? method.
    def create_action(can, able = nil)
      if able.nil?
        if can.respond_to?(:each) 
          can.each {|c,a| self.create_action(c,a)} 
        else
          raise ArgumentError, "able can't be nil"
        end
      else
        run_callbacks :add do
          @actions[can] = able
          @last_action = can
        end
      end
    end

    # Finds the able name of the action from a [action-able]_by? style method.
    #
    #   @param [Symbol] resource_method The name of the [action-able]_by? method.
    # Adds an action to actions and the correct methods to can and able modules.
    def find_able(name)
      md = name.to_s.match(/(.+)_by\?/)
      if md != nil && self.has_able?(md[1].intern)
        md[1].intern
      else
        false
      end
    end

    # Finds the can name of the action from a can_[action]? style method.
    #
    #   @param [Symbol] can_method The name of the can_[action]? method.
    def find_can(name)
      md = name.to_s.match(/can_(.+)\?/)
      if md != nil && self.has_can?(md[1].intern)
        md[1].intern
      else
        false
      end
    end

    # Add the CRUD methods to the Thwart actions (create, read, update, destroy)
    def add_crud!
      if @crud.nil? || @crud == false      
        Thwart::CrudActions.each do |(k,v)|
          self.create_action(k, v)
        end
        @crud = true  
      end
    end
  end
end