# A simple REST client in pure vimscript

Provides a simple way to make a HTTP request and get a reply. Supports JSON
payloads only and very limited HTTP implementation. 

# Purpose

Experiment: Can we write the YouCompleteMe client in pure vimscript, and stop
using python requests/timers?

Answer: yes we can

Experiment: Can we write it in vim9script ?

Answer: yes we can... nearly. Seems there are some crazy shenanigans when a vim9script callback invokes a legacy vimscript function (e.g. 

```
Caught exception in Test_Compl_After_Trigger(): Vim(py3):vim.error: Vim(redir):E1016: Cannot declare a buffer variable: b:ycm_command @ /Users/ben/.vim/bundle/YouCompleteMe/test/completion_info.test.vim:command line..script /Users/ben/.vim/bundle/YouCompleteMe/test/lib/run_test.vim[376]..function RunTheTest[66]..Test_Compl_After_Trigger[1]..youcompleteme#test#setup#OpenFile[30]..<SNR>37_OnClose[26]..<SNR>37_Resolve, line 12
```

# Status

This is work in progress/toy, not ready to be used for anything yet.

# Legacy Vimscript or Vim9script

Both are implemented :

* `restful#` functions are legacy vimscript
* `http9#` functions are vim9 API is the same

# Usage

Call `restful#GET`, `restful#POST`, `http9#GET`, `http9#POST` passing:

* `host`, `port`
* `URI` - full URI including query string
* `query_string` - any query string to add for GET requests (must be urlencoded)
* `headers` as a dictionary mapping header to value
* `payload` as a dictionary to be converted to JSON and sent as the request body
* `callback` a Funcref taking `( id, status_code, headers, message )`. Message is a
  dictionary decoded from the response body JSON.

All return a request ID, which can be used e.g. in the Block call.

Call `restful#Block` or `http9#Block` to wait for a particualr request to
complete (and its callback to be called)

