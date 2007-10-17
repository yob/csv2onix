module GemTracker

  def self.included(base)
    base.alias_method_chain :after_initialize, :gem_tracking
  end
    
  def after_initialize_with_gem_tracking
    failures = []
    GemList.instance.each_pair do |g,v|
      begin
        gem(g, v)
      rescue Gem::LoadError => ex
        failures << ex.to_s
      end
    end
    raise failures.join.insert(0, "\n") unless failures.empty?
    after_initialize_without_gem_tracking
  end

end
