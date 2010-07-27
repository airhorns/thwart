require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "with some inheriting models set up" do
  before do
    @with_cans = generic_model do 
      include Thwart::Cans
    end.new
    @with_ables = generic_model do 
      include Thwart::Ables
    end.new
  end
  
  describe Thwart::Cans do
    it "shouldn't find non existant methods" do
      Thwart::Actions.should_receive(:find_can).with(:can_view?).at_least(1).and_return(false)
      lambda {@with_cans.can_view?(@with_ables) }.should raise_error(NoMethodError)
    end
    it "should find a method" do
      # rspec seems to call respond_to which calls this and it needs to work        
      # Thwart::Actions.should_receive(:find_can).with(:can_view?).at_least(1).and_return(:view) 
      Thwart::Actions.should_receive(:actions).any_number_of_times.and_return({:view => :viewable})
      Thwart.should_receive(:query).with(@with_cans, @with_ables, :view)
      @with_cans.can_view?(@with_ables)
    end
  end
  
  describe Thwart::Ables do
    it "shouldn't find any methods" do
      Thwart::Actions.should_receive(:find_able).with(:viewable_by?).at_least(1).and_return(false)
      lambda {@with_ables.viewable_by?(@with_cans) }.should raise_error(NoMethodError)
    end
    it "should find a method" do
      # rspec seems to call respond_to which calls this and it needs to work properly
      # Thwart::Actions.should_receive(:find_able).with(:viewable_by?).at_least(1).and_return(:viewable)
      Thwart::Actions.should_receive(:actions).any_number_of_times.and_return({:view => :viewable})
      Thwart::Actions.should_receive(:can_from_able).with(:viewable).and_return(:view)
      Thwart.should_receive(:query).with(@with_cans, @with_ables, :view)
      @with_ables.viewable_by?(@with_cans)
    end
  end
end