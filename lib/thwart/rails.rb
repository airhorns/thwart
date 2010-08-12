require 'thwart'
class ActiveRecord::Base
  include Thwart::Resource
end
Thwart::Actions.add_crud!