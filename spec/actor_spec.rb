require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Thwart::Actor do
  it "should not add the thwart_role method until thwart_access is called" do
    actor_class = generic_model("Generic Resource") do 
      include Thwart::Actor
    end
    actor_class.new.should_not respond_to(:thwart_role)
    actor_class.thwart_access
    actor_class.new.should respond_to(:thwart_role)
  end

  context "thwart_role defining and finding" do
    before do
      @actor_class = generic_model("Generic Resource") do 
        include Thwart::Actor
        def arbitrary_attribute
          :arb_return
        end
      end
    end
    it "should return a default role" do
      @actor_class.thwart_access do
        role :a_role
      end
      @actor_class.new.thwart_role.should == :a_role
    end
    it "should allow the specifcation of a method" do
      @actor_class.thwart_access do
        role_method :arbitrary_attribute
      end
      @actor_class.new.thwart_role.should == :arb_return
    end
    it "should allow the specification of a proc" do
      @actor_class.thwart_access do
        role_proc Proc.new { |a|
          a.nil?.should == false
          :proc_return
        }
      end
      @actor_class.new.thwart_role.should == :proc_return
    end
  end
    
end