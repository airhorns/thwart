require 'active_support'
$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'thwart'

# require 'rubygems'
# require 'ruby-debug'

class User
  include Thwart::Actor
  thwart_access do
    role_method :role
  end
  attr_accessor :name, :role
  def initialize(n, r)
    self.name = n
    self.role = r
  end
end

class Thing
  include Thwart::Resource
  thwart_access do
    name :thing
  end
end

class This < Thing
  thwart_access do
    name :this
  end
end

class That < Thing
  thwart_access do
    name :that
  end
end

class Then < Thing
  thwart_access do
    name :then
  end
end

