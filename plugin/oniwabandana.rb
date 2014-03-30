module Oniwabandana
  class OniwaOpts
    attr_accessor :height
    def initialize
      @height = 10
    end
  end

  # TODO: move stuff from Oniwapp into this?
  class OniWindow
  end

  class Oniwapp
    GLOBAL_ONLY_OPTS = { 'hlsearch' => true, 'scrolloff' => true, 'omnifunc' => true  }
    SELECTED_PREFIX = '> '

    def initialize opts
      @opts = opts
      @selected_idx = 0 # of window entry from top
    end

    def search dir
      dir ||= '.'
      files = `git ls-files`.split "\n"

      unless show
        files.each_with_index do |file, idx|
          $curbuf.append(idx, file)
        end
        register_for_keys
      end
    end

    def select offset
    end

    def set cmd
      name = cmd.gsub /^no|=.*$|<$/, ''
      if GLOBAL_ONLY_OPTS[name]
        VIM::command("silent! SetBufferLocal #{cmd}")
      else
        VIM::command("setlocal #{cmd}")
      end
    end

    def show
      if @has_buffer
        VIM::command("silent! #{@opts.height} split SearchFiles")
        true
      else
        VIM::command("silent! #{@opts.height} new SearchFiles")
        set 'nohlsearch'
        set 'noinsertmode'
        set 'buftype=nofile'
        # set 'nomodifiable'
        set 'noswapfile'
        set 'nocursorline'
        set 'nospell'
        set 'nobuflisted'
        set 'textwidth=0'
        set 'scrolloff=0'
        @has_buffer = true
        false
      end
    end

    def register_for_keys
      numbers     = ('0'..'9').to_a.join
      lowercase   = ('a'..'z').to_a.join
      uppercase   = lowercase.upcase
      punctuation = '<>`@#~!"$%&/()=+*-_.,;:?\\\'{}[] ' # and space
      (numbers + lowercase + uppercase + punctuation).each_byte do |b|
        map "<Char-#{b}>", 'HandleKey', b
      end
      special = {
        '<CR>' => 'Accept',
        '<Left>' => 'Ignore',
        '<Right>' => 'Ignore',
        # '<Up>' => 'SelectNext',
        # '<Down>' => 'SelectPrev',
        '<C-c>' => 'Hide',
        # '<Esc>' => 'Hide'
      }
      special.each do |key, val|
        map key, val
      end
    end

    def map key, function, param = ''
      ::VIM::command "noremap <silent> <buffer> #{key} " \
        ":call Oniwa#{function}(#{param})<CR>"
    end

    def key_press key
      p key
    end

    def accept
      p "accept"
    end

    def hide
      VIM::command("silent! hide") if @has_buffer
    end
  end
end
