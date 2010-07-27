require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Thwart::Resource do
  describe "without a special name" do
    before do
      resource_class = generic_model("Generic Resource") do 
        include Thwart::Resource
        thwart_access
      end
      @resource = resource_class.new
    end
    
    it "should have set its own name" do
      @resource.class.thwart_name.should == "generic"
    end
  end
  
  describe "with a special name" do
    before do
      resource_class = generic_model("Generic Resource") do 
        include Thwart::Resource
        thwart_access do
          name "special"
        end
      end
      @resource = resource_class.new
    end
    
    it "should have a different name" do
      @resource.class.thwart_name.should == "special"
    end
  end
  
  describe "without a name" do
    it "should raise an error if no name could be found" do
      lambda { @resource = Class.new do
        include Thwart::Resource
        thwart_access
      end }.should raise_error(Thwart::MissingAttributeError)
    end
  end
end