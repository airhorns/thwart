module Thwart
  # Module in which the can_[action]? methods hang out
  module Cans   
  
    def respond_to?(name)
      return true if Thwart::Actions.find_can(name) != false
      super
    end
  
    def method_missing(name, *args)
      can = Thwart::Actions.find_can(name)
      return Thwart.query(self, args.first, can) if args.length == 1 && !!can
      super
    end
  end

  # Module in which the [action]able_by? methods hang out
  module Ables
    def respond_to?(name)
      return true if Thwart::Actions.find_able(name) != false
      super
    end
  
    def method_missing(name, *args)
      able = Thwart::Actions.find_able(name)
      return Thwart.query(args.first, self, Thwart::Actions.can_from_able(able)) if args.length == 1 && !!able
      super
    end
  end
end