module Thwart
  module Enforcer
    def thwart_access(resource, action = nil)
      if action.blank?
        raise ArgumentError, "thwart_access needs an action or the params hash to have an [:action] to enforce." if !self.respond_to?(:params) || !self.params.respond_to?(:[]) || self.params[:action].nil?
        action = params[:action] 
      end
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