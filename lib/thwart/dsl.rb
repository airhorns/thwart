module Thwart
  class DslError < NoMethodError; end
  class Dsl
    attr_accessor :extra_methods, # Hash of the extra method mappings of this DSL => target
                  :method_map,    # Holds the whole method map hash
                  :target,         # What object the DSL maps methods on to
                  :all            # Wheather or not to allow all methods (including dynamic ones like method missing) to be mapped
    
    def initialize(map = {})
      self.extra_methods = map
    end
    
    def evaluate(a_target, &block)
      self.target = a_target
      self.method_map = target.public_methods.inject({}) do |acc, m| 
        key = m.to_s.gsub("=", "").intern
        acc[key] = m if acc[key].nil? || m != key
        acc 
      end.merge(self.extra_methods)
      
      self.instance_eval(&block)
      self.target
    end
    
    def respond_to?(name)
      if @all
        return target.respond_to?(name)
      else
        return true if self.method_map.has_key?(name) && !!self.method_map[name]
        super
      end
    end
    
    def method_missing(name, *args, &block)
      if self.respond_to?(name)
        return self.target.send(self.method_map[name], *args, &block) if self.method_map.has_key?(name)
        return self.target.send(name, *args, &block) if @all
      end
      super
    end
  end
  
end