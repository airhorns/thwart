require 'thwart'
ActiveRecord::Base.send :include, Thwart::Resource
Thwart::Actions.add_crud!