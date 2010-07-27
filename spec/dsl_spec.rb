require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Thwart::Dsl do
  before do
    @target = double("target")
  end
  describe "with no given map" do
    before do
      @dsl = Thwart::Dsl.new
    end
    
    it "should pass methods on to the target" do
      @target.should_receive(:foo)
      @dsl.evaluate(@target) do
        foo
      end
    end
    
    it "should pass writer methods on to the target" do
      @target.should_receive(:foo=).with("bar")
      @dsl.evaluate(@target) do
        foo "bar"
      end
    end
    
    it "shouldn't find non existant methods" do
      lambda { @dsl.evaluate(@target) do
        foo "bar"
      end }.should raise_error(NoMethodError)
    end
  end
  
  describe "with an extra map" do
    before do
      @dsl = Thwart::Dsl.new :imperative => :foo=
    end
    it "should map attributes on to the target" do 
      @target.should_receive(:foo=).with("bar")
      @dsl.evaluate(@target) do
        imperative "bar"
      end
    end
  end
  
  describe "with method_missing defined on the target" do
    before do
      target_class = Class.new do
        def respond_to?(name)
          return true if [:test1, :test2].include?(name)
          super
        end
        def method_missing(name, *args)
          return self.test_method_called(name, *args) if self.respond_to?(name)
          super
        end
      end
      @target = target_class.new
    end
    it "should have a proper target to test with" do
      @target.should_receive(:test_method_called).with(:test1)
      @target.should_receive(:test_method_called).with(:test2)
      @target.should_receive(:test_method_called).with(:test1, :foo, :bar)
      @target.respond_to?(:test1).should == true
      @target.respond_to?(:test2).should == true
      @target.test1
      @target.test2
      @target.test1 :foo, :bar
    end
    context "with a all = true DSL" do
      before do 
        @dsl = Thwart::Dsl.new :test2 => :something_else
        @dsl.all = true
      end
      it "should call method missing on the target if the DSL doesn't have the method defined" do
        @target.should_receive(:test_method_called).with(:test1)
        @dsl.evaluate @target do
          test1
        end
      end
      it "should call the method in the method map if the DSL has the method in the map" do
        @target.should_not_receive(:method_missing)
        @target.should_receive(:something_else)
        @dsl.evaluate @target do
          test2
        end
      end
      it "should properly pass arguments to the missing method" do
        @target.should_receive(:test_method_called).with(:test1, :foo, :baz)
        @dsl.evaluate @target do
          test1 :foo, :baz
        end
      end
    end
    it "shouldn't call method missing on the target if the DSL doesn't have the method defined and all is false" do
      @target.should_not_receive(:test_method_called).with(:test1)
      @dsl = Thwart::Dsl.new
      @dsl.all = false
      lambda { @dsl.evaluate @target do
        test1
      end }.should raise_error(NameError)
    end
  end
end