function OniwaHandleKey(k)
  ruby $oniwapp.window.key_press VIM::evaluate('a:k')
endfunction

function OniwaSetting(name, default)
  let fullname = "g:oniwa_" . a:name
  if exists(fullname)
    return eval(fullname)
  else
    return a:default
  endif
endfunction

function OniwaAccept()
  ruby $oniwapp.window.accept
endfunction

function OniwaClose()
  ruby $oniwapp.close
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

ruby <<EOF
$LOAD_PATH << File.dirname(VIM::evaluate 'expand("<sfile>")')
require 'oniwabandana.rb'
module Oniwabandana
  $oniwapp = App.new(Opts.new)
end
EOF
