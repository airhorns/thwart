require File.expand_path(File.dirname(__FILE__) + '/spec_helper')


describe Thwart::Enforcer do
  context "access enforcment" do
    it "should need the current user method defined on the controller" do
      lambda { instance_with_module(Thwart::Enforcer).thwart_access }.should raise_error(ArgumentError)
    end
    it "should need the params hash to have an action key" do
      class_with_module(Thwart::Enforcer)
      lambda { @controller.thwart_access }.should raise_error(ArgumentError)
    end
    it "should need the params[:actions] to be a recognized action"
    it "should thwart access by raising an error if the user doesn't have permission"
    it "should return true if the user does have permission"
  end
end