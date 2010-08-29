require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

def enforced_controller(&block) 
  class_with_module(Thwart::Enforcer, &block)
end
describe Thwart::Enforcer do
  before do
    Thwart::Actions.stub(:has_can? => true)
    @controller_klass = enforced_controller do
      def current_user
        :user
      end
    end
    @r = double("resource")
  end
  
  context "access enforcment" do
    it "should need the current user method defined on the controller" do
      lambda { enforced_controller.new.thwart_access }.should raise_error(ArgumentError)
    end
    it "should need either the params hash or be passed action key" do
      i = @controller_klass.new
      lambda { i.thwart_access(@r) }.should raise_error(ArgumentError)
      lambda { i.thwart_access(@r, :some_action) }.should_not raise_error(ArgumentError)

      i2 = @controller_klass.new
      i2.should_receive(:params).at_least(:once).and_return({:action => :an_action})
      lambda { i2.thwart_access(@r) }.should_not raise_error(ArgumentError)
    end

    it "should thwart access by raising an error if the user doesn't have permission" do
      Thwart.stub(:query => false)
      lambda { @controller_klass.new.thwart_access(@r, :an_action) }.should raise_error(Thwart::NoPermissionError)
    end
    it "should return true if the user does have permission" do
      Thwart.stub(:query => true)
      lambda { @controller_klass.new.thwart_access(@r, :an_action) }.should_not raise_error(Thwart::NoPermissionError)
    end
    it "should convert string actions" do
      Thwart.stub(:query => true)
      lambda { @controller_klass.new.thwart_access(@r, "an_action") }.should_not raise_error(Thwart::NoPermissionError)
    end
    
  end
end