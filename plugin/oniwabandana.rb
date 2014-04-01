require 'window'

module Oniwabandana
  class Opts
    attr_reader :height, :case_sensitive
    def initialize
      @height = VIM::evaluate('OniwaSetting("height", 10)')
      @case_sensitive = VIM::evaluate('OniwaSetting("case_sensitive", 0)') != 0
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

    def close
      @window.close
      @window = nil
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
