require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

def actor_with_role(a_role)
  double("Actor", :thwart_role => a_role.name)
end

describe Thwart::RoleRegistry do
  before do 
    @role_builder = double("Role Builder")
    @role_builder.class.stub(:set_callback => true)
    @registry = Thwart::RoleRegistry.new(@role_builder)
  end

  it "should initialize a callback on the action creator" do
    store_class = Class.new do
      include ActiveSupport::Callbacks
    end
    store_class.should_receive(:set_callback)
    Thwart::RoleRegistry.new(store_class.new)
  end

  it "should add roles to the registry" do
    role = double("Role")
    @registry.add(role)
    @registry.roles.should include(role)
    @registry.has_role?(role).should == true
  end
  
  it "should prevent addition of duplicate roles" do
    role = double("Role")
    @registry.add(role)
    lambda {
      @registry.add(role)
    }.should raise_error(Thwart::DuplicateRoleError)
  end
  context "role finding" do
    before do
      @role = double("A Role", :name => :role1)
      @registry.add(@role)
    end
    it "should find nil for nil" do
      @registry.find_actor_role(nil).should == nil
    end
    it "should use the thwart_role attribute" do
      actor = double("Actor", :thwart_role => @role)
      @registry.find_actor_role(actor).should == @role
    end
    it "should convert symbols to roles" do
      actor = double("Actor", :thwart_role => :role1)
      @registry.find_actor_role(actor).should == @role
    end
    it "should find nil for symbols pointing to non registered roles " do
      actor = double("Actor", :thwart_role => :role2)
      @registry.find_actor_role(actor).should == nil
    end
  end
  context "resource finding" do
    it "should find nil for nil" do
      @registry.find_resource_identifier(nil).should == nil
    end
    it "should find using the thwart_name attribute" do
      resource = double("Resource", :thwart_name => :balls)
      @registry.find_resource_identifier(resource).should == :balls
    end
    it "should find using the class thwart_name attribute" do
      klass = Class.new do
        def thwart_name
          :balls
        end
      end
      @registry.find_resource_identifier(klass.new).should == :balls
    end
    it "should find using the class name if the gem wide setting is set" do
      Thwart.all_classes_are_resources = true
      class Bollocks; end
      @registry.find_resource_identifier(Bollocks.new).should == :bollocks
      Thwart.all_classes_are_resources = false
    end
    
  end
  context "querying" do
    it "should return the default if the role can't be found and the gem wide setting is set" do
      Thwart.actor_must_play_role = false
      resp = double("A Bool")
      Thwart.should_receive(:default_query_response).and_return(resp)
      @registry.query(nil, nil, nil).should == resp
    end
    
    it "should raise an error if the role can't be found and the gem wide setting is set" do 
      Thwart.actor_must_play_role = true
      lambda { 
        @registry.query(nil, nil, nil)
      }.should raise_error(Thwart::MissingRoleError)
    end
    
    context "with roles in the registry" do
      before do
        Thwart.actor_must_play_role = true
        Thwart.default_query_response = false
        @role1 = double("Low Level Role", :name => :role1, :query => false)
        @role2 = double("High Level Role", :name => :role2, :query => true)
        @role3 = double("No Rules Role", :name => :role3, :query => nil, :parents => [@role2, @role1])
        @role4 = double("Really low role", :name => :role4, :query => nil, :parents => [@role3])
        [@role1, @role2, @role3, @role4].each do |r|
          @registry.add(r)
        end
      end
      
      it "should query the role" do
        @registry.query(actor_with_role(@role1), nil, nil).should == false
      end
      
      it "should query the parents in a breadth first order if the role query is unsuccessful" do 
        @role3.should_receive(:parents)
        @registry.query(actor_with_role(@role3), nil, nil).should == true # this ensures role2 is checked before role1
      end
       
      it "should query more than one level of parents" do
        @role3.should_receive(:parents)
        @role4.should_receive(:parents)
        @registry.query(actor_with_role(@role4), nil, nil).should == true # this ensures role2 is checked before role1
      end
      
      it "should return the default if the role can't be found and the gem wide setting is set" do
        Thwart.actor_must_play_role = false
        @registry.query(actor_with_role(double("A role not in the registry", :name => :not_present)), nil, nil).should == false
      end
      
      it "should raise an error if the role can't be found and the gem wide setting is set" do
        Thwart.actor_must_play_role = true
        lambda {
          @registry.query(actor_with_role(double("A role not in the registry", :name => :not_present)), nil, nil)
        }.should raise_error(Thwart::MissingRoleError)
      end
    end
  end
end