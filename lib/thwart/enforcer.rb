module Thwart
  # A module for inclusion in intermediaries which need to prohibit access to resources, with easy integration.
  # This module is meant for things like Rails controllers which aren't Actors or Resources but end up federating access
  # to both of them. Again, the original idea for this comes from {http://railstips.org/ John Nunemaker} and his original 
  # gem {https://github.com/jnunemaker/canable Canable}.
  # ## Warning
  # This module has a few rather brittle constraints! First, it expects `current_user` to exist and return a {Thwart::Actor}
  # instance to query. You also must pass it a resource to potentially allow access to when `thwart_access` is called to
  # federate access. Finally, you must pass an action to `thwart_access`, or provide a params hash (Rails style) to find the
  # action in.
  module Enforcer

    # @param [Thwart::Resource] resource the resource who's access needs to be thwarted
    # @param [Symbol|String|nil] action The name of the action being attempted by an actor on the resource. Uses `params[:action]` if no action is passed.
    def thwart_access(resource, action = nil)
      if action.blank?
        raise ArgumentError, "thwart_access needs an action or the params hash to have an [:action] to enforce." if !self.respond_to?(:params) || !self.params.respond_to?(:[]) || self.params[:action].nil?
        action = params[:action] 
      end
      action = action.to_sym
      raise ArgumentError, "Thwart needs a current_user method to enforce permissions." unless self.respond_to?(:current_user)
      
      raise ArgumentError, "Unknown action #{action} to enforce" unless Thwart::Actions.has_can?(action)

      unless Thwart.query(current_user, resource, action)
        raise Thwart::NoPermissionError, "User #{current_user} doesn't have permission to #{action} #{resource}."
      else
        true
      end
    end
  end
end
