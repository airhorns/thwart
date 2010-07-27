require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Thwart::Role do
  it "should be queryable" do
    instance_with_module(Thwart::Role).respond_to?(:query).should == true
  end
  
  it "should respond with nil if no rule applies" do
    instance_with_role_definition.query(nil, nil, nil).should == nil
  end
  
  it "should respond to queries with its role level default" do
    a_val = mock('default query response')
    @role1 = instance_with_role_definition do
      self.default_response = a_val
    end
    @role1.query(nil, nil, nil).should == a_val
    @role1.query(:foo, :bar, :baz).should == a_val
  end
  
  it "should uniqueify its parents upon assignment" do
    @role = instance_with_role_definition
    @role.parents = [:a, :b]
    @role.parents += [:a, :c]
    @role.parents.should == [:a, :b, :c]
  end
  
  context "with simple responses set" do
    before do
      @role = instance_with_role_definition do
        self.responses = {:view => true, :update => false}
      end
    end
    it "should respond to simple queries with actions" do
      @role.query(nil, nil, :view).should == true
      @role.query(nil, nil, :update).should == false
    end
    it "shouldn't respond to queries it has no rules for" do
      @role.query(nil, nil, nil).should == nil
    end
    it "should return the default if it is set" do
      @role.default_response = true
      @role.query(nil, nil, nil).should == true
    end
  end
  
  context "with response sets scoped by resource" do
    before do
      @role = instance_with_role_definition do
        self.responses = {:view => {:foo => true, :bar => false}, :update => false, :destroy => {:foo => true, :_other => false}}
      end
    end
    it "should respond to simple queries with actions" do
      @role.query(nil, :foo, :view).should == true
      @role.query(nil, :bar, :view).should == false
      @role.query(nil, :baz, :view).should == nil
      
      @role.query(nil, :foo, :update).should == false
      @role.query(nil, :bar, :update).should == false
    end
  end
  
  context "with defaults at all levels" do
    before do
      @role = instance_with_role_definition do
        self.default_response = true
        self.responses = {:view => nil, :update => false, :destroy => {:foo => true, :_other => false}}
      end
    end
    it "should respond with the role level default for an unknown action" do
      @role.query(nil, :foo, :create).should == true
    end
    it "should respond with the action level default for known actions" do
      @role.query(nil, :foo, :view).should == nil
      @role.query(nil, :foo, :update).should == false
    end
    it "should respond with the resource level default for known action and unknown permissions" do
      @role.query(nil, :foo, :destroy).should == true # Known permission
      @role.query(nil, :bar, :destroy).should == false
    end
  end
  
  context "with response sets with procs" do
    before do
      @good_actor = double("actor", :is_allowed => true)
      @bad_actor = double("actor", :is_allowed => false)
    end
    context "procs at action level" do
      before do
        @role = instance_with_role_definition do
          self.responses = {:view => Proc.new {|actor, resource| actor.is_allowed == true}, :update => false}
        end
      end
      it "should run the proc" do
        @good_actor.should_receive(:is_allowed).twice
        @role.query(@good_actor, :foo, :view).should == true
        @role.query(@good_actor, :bar, :view).should == true
        @role.query(@good_actor, :foo, :update).should == false
        @role.query(@good_actor, :bar, :update).should == false
        
        @bad_actor.should_receive(:is_allowed).twice
        @role.query(@bad_actor, :foo, :view).should == false
        @role.query(@bad_actor, :bar, :view).should == false
        @role.query(@bad_actor, :foo, :update).should == false
        @role.query(@bad_actor, :bar, :update).should == false
      end
    end
    
    context "procs at resource level" do      
      before do
        @role = instance_with_role_definition do
          self.responses = {:view => {:foo => true, 
                                      :bar => Proc.new {|actor, resource| actor.is_allowed == true},
                                      :_other => Proc.new {|actor, resource| actor.is_allowed == true}}, 
                            :update => false
                          }
        end
      end
      
      it "should respond to other actions without procs" do 
        @role.query(nil, :foo, :view).should == true
        @role.query(nil, :foo, :update).should == false
        @role.query(nil, :bar, :update).should == false
        @role.query(nil, :baz, :update).should == false
      end
      
      it "should respond to actions with procs by calling them" do
        @role.query(@good_actor, :bar, :view).should == true
        @role.query(@bad_actor, :bar, :view).should == false 
      end
      
      it "should respond to unknown resources by calling the :_other proc" do
        @role.query(@good_actor, :baz, :view).should == true
        @role.query(@bad_actor, :baz, :view).should == false 
      end
    end
  end
end

describe Thwart::DefaultRole do
  it "should respond to queries with the Thwart response default" do
    a_val = mock('default query')
    Thwart.should_receive(:default_query_response).and_return(a_val) 
    subject.query(nil, nil, nil).should == a_val
  end
end