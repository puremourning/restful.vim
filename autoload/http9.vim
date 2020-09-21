vim9script

const CRLF = "\r\n"
let request_state: dict< dict< any > > = {}


def Write( method: string,
           host: string,
           port: number,
           uri: string,
           headers: dict< string >,
           data: string,
           callback: func ): number

  let ch = ch_open( host .. ':' .. string( port ), #{
    mode: 'raw',
    callback: funcref( 's:OnData' ),
    close_cb: funcref( 's:OnClose' ),
    waittime: 100,
  } )

  if ch_status( ch ) != 'open'
    return 0
  endif

  let id = ch_info( ch ).id
  request_state[ id ] = #{ data: '', handle: ch, callback: callback }

  let all_headers = copy( headers )
  all_headers->extend( {
    'Host': host,
    'Connection': 'close',
    'Accept': 'application/json',
  } )

  if !empty( data )
    all_headers->extend( {
      'Content-Length': string( len( data ) )
    } )
  endif

  let msg = method .. ' ' .. uri .. ' HTTP/1.1' .. CRLF
  for h in keys( all_headers )
    msg ..= h .. ':' .. all_headers[h] .. CRLF
  endfor
  msg ..= s:CRLF
  msg ..= data
  call ch_sendraw( ch, msg )
  return id
enddef

def OnData( channel: channel, msg: string )
  let id = ch_info( channel ).id
  let data = request_state[id].data
  request_state[id]->extend( #{
    data: data .. msg
  } )
enddef

def OnClose( channel: channel )
  let id = ch_info( channel ).id
  let data = request_state[id].data
  let callback = request_state[id].callback
  remove( request_state, id )

  let boundary = match( data, CRLF .. CRLF )
  let header_data = data->strpart( 0, boundary )
  let body = data->strpart( boundary + 2 * len( CRLF ) )

  let headers = split( header_data, CRLF )
  let status_line = headers[0]
  remove( headers, 0 )

  let header_map: dict< string > = {}
  for header in headers
    let colon = match( header, ':' )
    let key = header->strpart( 0, colon )
    let value = header->strpart( colon + 1 )
    header_map[ tolower( key ) ] = trim( value )
  endfor

  let status_code = split( status_line )[1]

  callback->call( [ id, status_code, header_map, body ] )
enddef

def http9#GET( host: string,
               port: number,
               uri: string,
               query_string: string,
               headers: dict< string >,
               callback: func ): number
  return Write( 'GET',
                host,
                port,
                empty( query_string ) ? uri : uri .. '?' .. query_string,
                headers,
                '',
                callback )
enddef


def http9#POST( host: string,
                port: number,
                uri: string,
                headers: dict< string>,
                data: string,
                callback: func ): number
  return Write( 'POST', host, port, uri, headers, data, callback )
enddef

def http9#Block( id: number, timeout: number )
  let ch = request_state[id].handle
  ch_setoptions( ch, { 'close_cb': '' } )
  while count( [ 'open', 'buffered' ],  ch_status( ch ) ) == 1
    let data  = ch_read( ch, { 'timeout': timeout } )
    OnData( ch, data )
  endwhile
  OnClose( ch )
enddef

defcompile
