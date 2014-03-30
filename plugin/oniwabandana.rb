require 'window'

module Oniwabandana
  class Opts
    attr_accessor :height
    def initialize
      @height = 10
    end
  end

  class App
    attr_accessor :window

    def initialize opts
      @opts = opts
      @window = Window.new opts
    end

    def search dir
      dir ||= '.'
      files = `git ls-files`.split "\n"
      unless @window.show files
        @window.show_matches
        @window.register_for_keys
      end
    end
  end
end
