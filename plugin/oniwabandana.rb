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
      @files = nil # all potential files
      @matches = nil # files matching current search paramters
      @offset = 0 # current offset from first match
    end

    def search dir
      dir ||= '.'
      @files = `git ls-files`.split "\n"
      @matches = @files

      unless show
        show_matches
        register_for_keys
      end
    end

    def show_matches
      # avoid copying the matches array in ruby 2.0+
      matches = @matches.respond_to?(:lazy) ? @matches.lazy : @matches
      matches.drop(@offset).take(n_visible_matches).each_with_index do |file, idx|
        $curbuf[idx + 2] = file
      end
    end

    def select offset
      # TODO: first scroll cursor down?
      new_offset = @offset + offset
      return if new_offset < 0 or new_offset > (@matches.length - n_visible_matches)
      @offset = new_offset
      show_matches
    end

    def n_visible_matches
      @opts.height - 1
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
        n_visible_matches.times do
          # create empty lines in the buffer for manipulation later
          $curbuf.append(0, '')
        end
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
        '<Up>' => 'SelectPrev',
        '<Down>' => 'SelectNext',
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
      # TODO: something like...
      # $curbuf.line += key.to_char
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
