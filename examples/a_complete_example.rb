require File.expand_path(File.dirname(__FILE__) + '/example_helper')

Thwart.configure do
  Thwart::Actions.add_crud!
  default_query_response false

  action_group :manage, [:view, :create, :update, :destroy]

  role :employee do
    view :all
    update :this, :that
  end

  role :manager, :include => :employee do
    allow do
      destroy :this
    end
    deny do
      destroy :that
    end
  end

  role :administrator do
    manage :all
  end
end

@ed    = User.new('Ed', :employee)
@mary  = User.new('Mary', :manager)
@admin = User.new('Admin', :administrator)

@a_this = This.new
@a_that = That.new
@a_then = Then.new

puts @ed.can_view?(@a_this)
puts @ed.can_view?(@a_that)
puts @ed.can_view?(@a_then)
puts @ed.can_update?(@a_this)
puts @ed.can_update?(@a_that)
puts @ed.can_update?(@a_then)

# Thwart.query(:employee, :this, :view).should == true
# Thwart.query(:employee, @a_this, :view).should == true
# Thwart.query(@ed, :this, :view).should == true
# Thwart.query(@ed, @a_this, :view).should == true
# 
# Thwart.query(:employee, :this, :update).should == true
# Thwart.query(:employee, @a_this, :update).should == true
# Thwart.query(@ed, :this, :update).should == true
# Thwart.query(@ed, @a_this, :update).should == true
# 
# Thwart.query(:employee, :then, :update).should == true
# Thwart.query(:employee, @a_then, :update).should == true
# Thwart.query(@ed, :then, :update).should == true
# Thwart.query(@ed, @a_then, :update).should == true
