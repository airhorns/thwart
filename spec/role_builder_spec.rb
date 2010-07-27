require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Thwart::RoleBuilder do  
  before do
    @example_actions = double("Actionables Store", :actionables => {:view => [:view], :update => [:update], :manage => [:view, :update]})
    @builder = Thwart::RoleBuilder.new(@example_actions)
  end
  
  it "should build roles" do
    role = @builder.create_role :a_name
    role.class.include?(Thwart::Role).should == true
  end
  
  it "should fire the build callback" do
    receiver = double("receiver")
    receiver.should_receive(:after_build_role)
    klass = Thwart::RoleBuilder.clone
    klass.set_callback :build_role, :after, receiver
    role = klass.new(@example_actions).create_role :a_name
  end
  
  it "should apply the default action to built roles" do 
    role = @builder.create_role :a_name do
      default false
    end
    role2 = @builder.create_role :another_name do
      default true
    end
    role.responses.should == {}
    role.default_response.should == false
    role.query(nil, nil, nil).should == false

    role2.responses.should == {}
    role2.default_response.should == true
    role2.query(nil, nil, nil).should == true
  end
  
  it "should only allow permissions to be defined using recognizable actions" do
    lambda {
      @builder.create_role :name do
        define_permission :non_existant_action, :resource
      end
    }.should raise_error(ArgumentError)
  end
  
  it "should default to allowing actions" do
    role1 = @builder.create_role :name do
      view :foo
      update :bar
    end
    role2 = @builder.create_role :a_name do
      allow do
        view :foo
        update :bar
      end
    end
    role1.responses.should == role2.responses
  end
  
  it "should provide deny blocks" do
    role = @builder.create_role :name do
      deny do
        view :foo
        update :bar
      end
    end
    role.responses.should == {:view => {:foo => false}, :update => {:bar => false}}
  end
  
  it "should accept permissions outside of deny blocks as allows on both sides" do
    role = @builder.create_role :name do
      view :foo
      deny do
        update :foo
      end
      view :bar
    end
    role.responses.should == {:view => {:foo => true, :bar => true}, :update => {:foo => false}}
  end
  
  it "should build responses with :all" do
    role = @builder.create_role :a_name do
      view :all
    end
    role.responses.should == {:view => {:_other => true}}
  end
  
  it "should build :all responses without arguments" do
    role = @builder.create_role :a_name do
      view
    end
    role.responses.should == {:view => {:_other => true}}
  end
  
  it "should build roles which respond to simple actions" do
    role = @builder.create_role :a_name do
      update :this, :that
    end
    role.responses.should == {:update => {:this => true, :that => true}}
  end
  
  it "should build roles which respond to simple actions" do
    role = @builder.create_role :a_name do
      update :this, :that
    end
    role.responses.should == {:update => {:this => true, :that => true}}
  end

  it "should build roles which respond to action groups" do
    role = @builder.create_role :a_name do
      manage :this, :that
    end
    role.responses.should == {:view => {:this => true, :that => true}, :update => {:this => true, :that => true}}
  end
  
  it "should merge all declarations with others" do
    role = @builder.create_role :a_name do
      update :this, :that
      deny do 
        update :all
      end
    end
    role.responses.should == {:update => {:this => true, :that => true, :_other => false}}
  end

  context "passed conditions" do
    before do
      @good_actor = double("actor", :is_allowed => true)
      @bad_actor = double("actor", :is_allowed => false)
    end    
    
    context "at the resource level" do
      before do
        @role = @builder.create_role :a_name do
          update :foo, :if => lambda {|actor| actor.is_allowed == true }
          update :bar, :unless => lambda {|actor| actor.is_allowed == true }
          update :baz do |actor| actor.is_allowed == true end
        end
      end  
      it "should build procs using the :if option" do
        @role.responses[:update][:foo].call(@good_actor).should == true
        @role.responses[:update][:foo].call(@bad_actor).should == false     
      end
      it "should build procs using the :unless option" do
        @role.responses[:update][:bar].call(@good_actor).should == false
        @role.responses[:update][:bar].call(@bad_actor).should == true
      end
      it "should build procs using action level blocks" do
        @role.responses[:update][:baz].call(@good_actor).should == true
        @role.responses[:update][:baz].call(@bad_actor).should == false
      end
    end
  
    context "at the action level" do
      it "should build procs using the :if option" do
        @role = @builder.create_role :a_name do
          update :if => lambda {|actor| actor.is_allowed == true }
        end
        @role.responses[:update][:_other].call(@good_actor).should == true
        @role.responses[:update][:_other].call(@bad_actor).should == false     
      end
      it "should build procs using the :unless option" do
        @role = @builder.create_role :a_name do
          update :unless => lambda {|actor| actor.is_allowed == true }
        end
        @role.responses[:update][:_other].call(@good_actor).should == false
        @role.responses[:update][:_other].call(@bad_actor).should == true
      end
      it "should build procs using action level blocks" do
        @role = @builder.create_role :a_name do
          update do |actor| actor.is_allowed == true end
        end
        @role.responses[:update][:_other].call(@good_actor).should == true
        @role.responses[:update][:_other].call(@bad_actor).should == false
      end
    end
  end
  
  context "building roles which include other roles" do
    it "should allow parents to be specified as options to the role" do
      @role = @builder.create_role :name, :parents => [:foo, :bar]
      @role.parents.should == [:foo, :bar]
    end
    it "should allow parents to be included in the role definition" do
      @role = @builder.create_role :name do
        include :foo
        include :bar
      end
    end
    it "should allow parents to be included on the same line in the role definition" do
      @role = @builder.create_role :name do
        include :foo, :bar
      end
    end
  end
  
end