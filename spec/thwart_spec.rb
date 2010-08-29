require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Thwart do
  it "should autoload all the classes" do
    lambda {
      Thwart::Actor
      Thwart::Role
      Thwart::DefaultRole
      Thwart::Resource
      Thwart::Dsl
      Thwart::Cans
      Thwart::Ables
      Thwart::ActionsStore
      Thwart::ActionGroupBuilder
      Thwart::RoleRegistry
      Thwart::RoleBuilder
    }.should_not raise_error
  end
  
  describe "configuration" do
    it "should realize the configured values" do
      Thwart.configure do 
        role_registry 'role_registry'
        default_query_response 'false'
      end
      Thwart.role_registry.should == 'role_registry'
      Thwart.default_query_response.should == 'false'
    end
    it "should create new actions" do
      Thwart::Actions.should_receive(:create_action).with(:add, :addable)
      Thwart.configure do
        action :add, :addable
      end
    end
    it "should create new roles" do
      role_dsl = double("dsl")
      Thwart::RoleBuilder.should_receive(:new).and_return(role_dsl)
      role_dsl.should_receive(:create_role).with(:a)
      role_dsl.should_receive(:create_role).with(:b, 'something else')
      role_dsl.class.stub(:set_callback)
      role_dsl.class.stub(:reset_callbacks)
      Thwart.configure do
        role :a
        role :b, 'something else'
      end
    end
    it "should create new action groups" do
      Thwart::Actionables.should_receive(:create_action_group).with(:manage)
      Thwart::Actionables.should_receive(:create_action_group).with(:inspect, [])
      Thwart.configure do
        action_group :manage
        action_group :inspect, []
      end
    end
  end
  describe "query" do
  end
end