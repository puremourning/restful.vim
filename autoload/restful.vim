" restful.vim - A REST client in pure vimscript
" Copyright 2020 Ben Jackson
"
" Licensed under the Apache License, Version 2.0 (the "License");
" you may not use this file except in compliance with the License.
" You may obtain a copy of the License at
"
"   http://www.apache.org/licenses/LICENSE-2.0
"
" Unless required by applicable law or agreed to in writing, software
" distributed under the License is distributed on an "AS IS" BASIS,
" WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
" See the License for the specific language governing permissions and
" limitations under the License.

let s:CRLF = "\r\n"

let s:request_state = {}

function! s:OnData( callback, channel, msg )
  echom "DATA"
  let s:request_state[ ch_info( a:channel ).id ].data .= a:msg
endfunction

function! s:OnClose( callback, channel )
  echom "CLOSE"
  let data = s:request_state[ ch_info( a:channel ).id ].data
  unlet s:request_state[ ch_info( a:channel ).id ]
  let bounary = match( data, s:CRLF . s:CRLF )
  if bounary < 0
    throw "Invalid data: " . data
  endif

  let header = data[ 0:(bounary - 1) ]
  let body = data[ bounary + 2*len( s:CRLF ): ]

  let headers = split( header, s:CRLF )
  let status_line = headers[ 0 ]
  let headers = headers[ 1: ]

  let header_map = {}
  for header in headers
    let colon = match( header, ':' )
    let header_map[ header[ : colon-1 ] ] = trim( header[ colon+1: ] )
  endfor

  let status_code = split( status_line )[ 1 ]

  call a:callback( status_code, header_map, json_decode( body ) )
endfunction


function! restful#GET( host, port, uri, headers, callback ) abort

  let ch = ch_open( a:host . ':' . a:port, #{
        \ mode: 'raw',
        \ callback: funcref( 's:OnData', [ a:callback ] ),
        \ close_cb: funcref( 's:OnClose', [ a:callback ] ),
        \ waittime: 1000,
        \ } )
  let s:request_state[ ch_info( ch ).id ] = #{ data: '' }

  call ch_sendraw( ch, 'GET ' . a:uri . ' HTTP/1.1' . s:CRLF )
  call ch_sendraw( ch, 'Host: ' . a:host . s:CRLF )
  call ch_sendraw( ch, 'Connection: close' . s:CRLF )
  call ch_sendraw( ch, 'Accept: application/json' . s:CRLF )
  for h in keys( a:headers )
    call ch_sendraw( ch, h . ':' . a:headers[ h ] . s:CRLF )
  endfor
  call ch_sendraw( ch, s:CRLF )
endfunction

function! restful#POST( host, port, uri, headers, payload, callback ) abort
  let ch = ch_open( a:host . ':' . a:port, #{
        \ mode: 'raw',
        \ callback: funcref( 's:OnData', [ a:callback ] ),
        \ close_cb: funcref( 's:OnClose', [ a:callback ] ),
        \ waittime: 1000,
        \ } )
  let s:request_state[ ch_info( ch ).id ] = #{ data: '' }

  let data = json_encode( a:payload )

  call ch_sendraw( ch, 'POST ' . a:uri . ' HTTP/1.1' . s:CRLF )
  call ch_sendraw( ch, 'Host: ' . a:host . s:CRLF )
  call ch_sendraw( ch, 'Connection: close' . s:CRLF )
  call ch_sendraw( ch, 'Content-Length: ' . len( data ) . s:CRLF )
  call ch_sendraw( ch, 'Accept: application/json' . s:CRLF )
  for h in keys( a:headers )
    call ch_sendraw( ch, h . ':' . a:headers[ h ] . s:CRLF )
  endfor
  call ch_sendraw( ch, s:CRLF )
  call ch_sendraw( ch, data )
endfunction

function! Callback( status_code, headers, body )
  echom "CALLED"
  call popup_dialog( [ 'status_code: ' . string( a:status_code ),
                     \ 'headers: ' . string( a:headers ),
                     \ 'body: ' . string( a:body ) ], {} )
endfunction

function! TestGet()
  call restful#GET( 'localhost',
                  \ 25000,
                  \ '/',
                  \ #{ Test: 'header' },
                  \ function( 'Callback' ) )
endfunction

function! TestPost()
  call restful#POST( 'localhost',
                   \ 25000,
                   \ '/eat',
                   \ #{ Test: 'header' },
                   \ #{ food: 'apple', drink: 'water' },
                   \ function( 'Callback' ) )
endfunction

call TestPost()
