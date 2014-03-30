require 'window'

module Oniwabandana
  class Opts
    attr_reader :height
    def initialize
      @height = 10
    end
  end

  class App
    attr_reader :window

    def initialize opts
      @opts = opts
    end

    def window
      @window ||= Window.new @opts
    end

    def search dir
      dir ||= '.'
      files = `git ls-files`.split "\n"
      win = window
      unless win.show files
        win.show_matches
        win.register_for_keys
      end
    end
  end
end
