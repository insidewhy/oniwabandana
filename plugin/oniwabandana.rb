require 'window'

module Oniwabandana
  class Opts
    attr_reader :height, :case_sensitive, :backspace, :open, :close,
                :tabopen, :tabopen_all, :tabopen_cmd, :smart_tabopen,
                :grep, :accept, :select_prev, :select_next

    def initialize
      @height = key_setting 'height', 10
      @case_sensitive = key_setting('case_sensitive', 0) != 0
      @backspace = key_setting 'backspace', '<c-h>'
      @tabopen = key_setting 'tabopen', '<c-t>'
      @tabopen_all = key_setting 'tabopen_all', '<c-e>'
      @open = key_setting 'open', '<cr>'
      @close = key_setting 'close', '<c-c>'
      @smart_tabopen = key_setting('smart_tabopen', '0') != 0
      @tabopen_cmd = key_setting 'tabopen_cmd', 'tabe'
      @grep = key_setting 'grep', '<c-g>'
      @accept = key_setting 'accept', '<cr>'
      @select_prev = key_setting 'select_prev', '<Up>'
      @select_next = key_setting 'select_next', '<Down>'
    end

    private
    def key_setting name, default
      default = "\"#{default}\"" if default.kind_of? String
      VIM::evaluate("OniwaSetting(\"#{name}\", #{default})")
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

    def window_shown?
      ! @window.nil?
    end

    def close
      @window.close
      @window = nil
    end

    def search dir
      return if window_shown?

      dir ||= '.'
      # todo: determine source from @opts
      files = `git ls-files`.split "\n"
      wildignore = VIM::evaluate('&wildignore').split(',').map do |igpat|
        Regexp.new('^' + Regexp.escape(igpat).gsub('\*','.*?') + '$')
      end

      # filter by wildignore
      files.reject! do |file|
        wildignore.detect { |pattern| file.match pattern }
      end

      win = window
      unless win.show files
        win.show_matches
        win.criteria_input.enter_search_mode
      end
    end

    def grep
      search '.' unless window_shown?
      window.criteria_input.enter_grep_mode
    end
  end
end
