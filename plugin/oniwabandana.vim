ruby <<EOF
$LOAD_PATH << File.dirname(VIM::evaluate 'expand("<sfile>")')
require 'oniwabandana.rb'
module Oniwabandana
  $oniwapp = App.new(Opts.new)
end
EOF

function OniwaHandleKey(k)
  ruby $oniwapp.window.key_press VIM::evaluate('a:k')
endfunction

function OniwaAccept()
  ruby $oniwapp.window.accept
endfunction

function OniwaHide()
  ruby $oniwapp.window.hide
endfunction

function OniwaBackspace()
  ruby $oniwapp.window.backspace
endfunction

function OniwaSelectNext()
  ruby $oniwapp.window.select 1
endfunction

function OniwaSelectPrev()
  ruby $oniwapp.window.select -1
endfunction

function OniwaIgnore()
endfunction

function s:Oniwabandana(...)
  ruby $oniwapp.search VIM::evaluate('a:1')
endfunction

command -nargs=? Oniwabandana call s:Oniwabandana(<q-args>)
