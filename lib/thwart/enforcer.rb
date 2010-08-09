module Thwart
  module Enforcer
    def thwart_access(resource)
      raise ArgumentError, "Thwart needs a current_user method to enforce permissions." unless self.respond_to?(:current_user)
      raise ArgumentError, "Thwart needs the params hash to have an [:action] to enforce." if params.nil? || params[:action].nil?
      raise ArgumentError, "Unknown action #{params[:action]} to enforce" unless Thwart::Actions.has_can?(params[:action])

      unless Thwart.query(current_user, resource, params[:action])
        raise Thwart::NoPermissionError, "User #{current_user} doesn't have permission to #{params[:action]} #{resource}."
      else
        true
      end
    end
  end
end