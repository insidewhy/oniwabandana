ruby <<EOF
$LOAD_PATH << File.dirname(VIM::evaluate 'expand("<sfile>")')
require 'oniwabandana.rb'
module Oniwabandana
  $oniwapp = Oniwapp.new(OniwaOpts.new)
end
EOF

function OniwaHandleKey(k)
  ruby $oniwapp.key_press VIM::evaluate('a:k')
endfunction

function OniwaAccept()
  ruby $oniwapp.accept
endfunction

function OniwaHide()
  ruby $oniwapp.hide
endfunction

function OniwaSelectNext()
  ruby $oniwapp.select 1
endfunction

function OniwaSelectPrev()
  ruby $oniwapp.select -1
endfunction

function OniwaIgnore()
endfunction

function s:Oniwabandana(...)
  ruby $oniwapp.search VIM::evaluate('a:1')
endfunction

command -nargs=? Oniwabandana call s:Oniwabandana(<q-args>)
