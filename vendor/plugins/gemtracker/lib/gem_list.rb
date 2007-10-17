require 'yaml'

class GemList

  include Singleton
  include Enumerable

  CONFIG_PATH = File.join(RAILS_ROOT, 'config', 'gems.yml')

  def initialize
    if File.file?(CONFIG_PATH)
      @hash = YAML.load_file(CONFIG_PATH)
    else
      @hash = {}
    end
  end

  def each_pair(&blk)
    @hash.each_pair &blk
  end

end
