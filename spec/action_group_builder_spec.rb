require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Thwart::ActionGroupBuilder do
  before do
    @store = double("Actions Store")
    @store.class.stub(:set_callback)
    @builder = Thwart::ActionGroupBuilder.new(@store)
  end

  it "should add some simple actionables" do
    @builder.add_actionable(:sing)
    @builder.add_actionable(:dance, [:laugh, :play])
    @builder.actionables.should == {:sing => [:sing], :dance => [:laugh, :play]}      
  end
  it "should have the crud action group if added" do
    @store.should_receive(:add_crud!)
    Thwart::CrudActions.keys.each do |k|
      @builder.add_actionable(k)
    end
    @builder.add_crud_group!
    @builder.actionables.include?(:crud).should == true
  end
  it "should set an action group" do
    @builder.add_actionable(:one)
    @builder.add_actionable(:two)
    @builder.create_action_group(:stuff, [:one, :two])
    @builder.actionables[:stuff].should == [:one, :two]
  end
  
  it "should initialize a callback on the action creator" do
    store_class = Class.new do
      include ActiveSupport::Callbacks
    end
    store_class.should_receive(:set_callback)
    Thwart::ActionGroupBuilder.new(store_class.new)
  end
  
  describe "action group resolution" do
    it "should find existing actions" do 
      @builder.stub(:actionables).and_return({:view => [:view]})
      @builder.resolve_action_group(:view).should == [:view]
    end

    context "with crud and one group" do
      before do
        @actions = [:create, :update, :destroy]
        @actionables = @actions.inject({}) {|acc, k| acc[k] = [k]; acc}.merge({:manage => @actions})
        @builder.stub(:actionables).and_return(@actionables)
      end
      it "should find arrays of existing actions" do        
        @builder.resolve_action_group(@actions).should == @actions
      end
      it "should build action groups of other action groups" do
        @builder.resolve_action_group(:manage).should == @actions
      end    

      context "and extra actions" do
        before do
          @actionables = @actionables.merge([:one, :two, :three].inject({}) {|acc, k| acc[k] = [k]; acc}).merge({:another => [:one, :two]})
          @builder.stub(:actionables).and_return(@actionables)
        end
        it "should build action groups of other action groups and other actions" do
          @builder.resolve_action_group([:manage, :another, :three]).should include(:one, :two, :three, :create, :update, :destroy)
        end
      end
    end    
  end
end