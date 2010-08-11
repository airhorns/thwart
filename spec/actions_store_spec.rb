require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Thwart::ActionsStore do
  before do
    @actions = Thwart::ActionsStore.new
  end
  describe "with no actions set up" do
    before do
      @actions.should_receive(:actions).and_return({})
    end
    it "shouldn't find any can methods" do
      @actions.find_can(:can_view?).should == false
    end
    it "shouldn't find any able methods" do
      @actions.find_able(:viewable_by?).should == false
    end
  end
  describe "with a custom action" do
    before do
      @actions.create_action(:foo, :fooable)
    end
    it "should have the can and able present" do
      @actions.has_can?(:foo).should == true
      @actions.has_able?(:fooable).should == true
    end
    it "shouln't have any other cans or ables present" do
      @actions.has_can?(:bar).should == false
      @actions.has_able?(:barable).should == false
    end
    it "should find the can method" do
      @actions.find_can(:can_foo?).should == :foo
    end
    it "should find the able method" do
      @actions.find_able(:fooable_by?).should == :fooable
    end
    it "should get the can from the able" do
      @actions.can_from_able(:fooable).should == :foo
    end
  end
  it "should create several actions from an array" do
    some_actions = {:bleh => :blehable, :beef => :beefable}
    @actions.create_action(some_actions)
    @actions.actions.should == some_actions
  end
  describe "with the crud actions" do
    before do
      @actions.add_crud!
    end
    # This isnt DRY at all but I want to know which one is failing
    it "should have C for create" do
      @actions.has_can?(:create).should == true
    end
    it "should have R for .. er ... show" do
      @actions.has_can?(:show).should == true
    end
    it "should have U for update" do
      @actions.has_can?(:update).should == true
    end
    it "should have D for destroy" do
      @actions.has_can?(:destroy).should == true
    end
  end
  
  it "should fire the add callback and set the last added" do
    klass = Thwart::ActionsStore.clone
    actionz = klass.new
    receiver = double('receiver')
    receiver.should_receive(:before).with(actionz)
    klass.set_callback :add, :before, receiver
    
    actionz.create_action(:do, :doable)
    actionz.last_action.should == :do
  end
end