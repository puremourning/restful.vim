# A simple REST client in pure vimscript

Provides a simple way to make a HTTP request and get a reply. Supports JSON
payloads only and very limited HTTP implementation. 

# Purpose

Experiment: Can we write the YouCompleteMe client in pure vimscript, and stop
using python requests/timers?

# Status

This is work in progress/toy, not ready to be used for anything yet.

# Usage

Call `restful#GET` or `restful#POST` passing:

* `host`, `port`
* `URI` - full URI including query string
* `headers` as a dictionary mapping header to value
* `payload` as a dictionary to be converted to JSON and sent as the request body
* `callback` a Funcref taking `( status_code, headers, message )`. Message is a
  dictionary decoded from the response body JSON.


