" ODBC Adapter for vim-dadbod
" URL format: odbc://DSN_NAME or odbc://DSN_NAME/database
"
" Requires:
"   - uv (Python package manager)
"   - pyodbc (installed automatically via uv run --with)
"   - ODBC DSN configured in Windows ODBC Data Sources
"
" Features:
"   - Async operations via jobstart() to prevent UI freezing
"   - File-based caching with 8-hour TTL
"   - Lazy schema loading
"   - Loading indicators and error notifications

" Configuration variables
let g:db_adapter_odbc_debug = get(g:, 'db_adapter_odbc_debug', 0)
let g:db_adapter_odbc_cache_ttl = get(g:, 'db_adapter_odbc_cache_ttl', 28800)
let g:db_adapter_odbc_exclude_system = get(g:, 'db_adapter_odbc_exclude_system', 1)
let g:db_adapter_odbc_table_limit = get(g:, 'db_adapter_odbc_table_limit', 1000)

" State tracking for async operations
let s:pending_jobs = {}
let s:cached_results = {}

" Capture script directory at load time (works on Windows and Linux)
let s:script_dir = fnamemodify(resolve(expand('<sfile>:p')), ':h:h:h:h')

function! s:debug(msg) abort
  if g:db_adapter_odbc_debug
    echom '[odbc] ' . a:msg
  endif
endfunction

function! s:notify(msg, level) abort
  " level: 'info', 'warn', 'error'
  if has('nvim')
    let l:lvl = a:level ==# 'error' ? 'ERROR' : (a:level ==# 'warn' ? 'WARN' : 'INFO')
    call luaeval('vim.notify(_A[1], vim.log.levels[_A[2]])', [a:msg, l:lvl])
  else
    echom a:msg
  endif
endfunction

" Get path to the Python script (cross-platform)
function! s:script_path() abort
  let l:config_dir = has('nvim') ? stdpath('config') : s:script_dir
  let l:path = l:config_dir . '/scripts/db-odbc.py'
  if has('win32') || has('win64')
    let l:path = substitute(l:path, '/', '\', 'g')
  endif
  call s:debug('script_path: ' . l:path)
  return l:path
endfunction

" Parse URL into components: odbc://DSN or odbc://DSN/database
function! s:parse_url(url) abort
  call s:debug('parse_url input: ' . a:url)
  let l:pattern = '^odbc:\(//\)\?\([^/]\+\)\%(/\(.*\)\)\?$'
  let l:match = matchlist(a:url, l:pattern)
  call s:debug('parse_url match: ' . string(l:match))
  if empty(l:match) || empty(l:match[2])
    throw 'Invalid ODBC URL: ' . a:url
  endif
  let l:database = ''
  if len(l:match) > 3 && !empty(l:match[3])
    let l:database = l:match[3]
  endif
  let l:result = {
        \ 'dsn': l:match[2],
        \ 'database': l:database,
        \ }
  call s:debug('parse_url result: ' . string(l:result))
  return l:result
endfunction

" Build the base command as a List
function! s:command(url) abort
  let l:parsed = s:parse_url(a:url)
  let l:cmd = ['uv', 'run', '--with', 'pyodbc', 'python', s:script_path(), '--dsn', l:parsed.dsn]
  if !empty(l:parsed.database)
    let l:cmd += ['--database', l:parsed.database]
  endif
  " Add cache TTL
  let l:cmd += ['--cache-ttl', string(g:db_adapter_odbc_cache_ttl)]
  " Add exclude system if enabled
  if g:db_adapter_odbc_exclude_system
    let l:cmd += ['--exclude-system']
  else
    let l:cmd += ['--include-system']
  endif
  return l:cmd
endfunction

" Build command without cache/system options (for queries)
function! s:query_command(url) abort
  let l:parsed = s:parse_url(a:url)
  let l:cmd = ['uv', 'run', '--with', 'pyodbc', 'python', s:script_path(), '--dsn', l:parsed.dsn]
  if !empty(l:parsed.database)
    let l:cmd += ['--database', l:parsed.database]
  endif
  return l:cmd
endfunction

" Canonicalize the URL (normalize format)
function! db#adapter#odbc#canonicalize(url) abort
  let l:parsed = s:parse_url(a:url)
  let l:result = 'odbc://' . l:parsed.dsn
  if !empty(l:parsed.database)
    let l:result .= '/' . l:parsed.database
  endif
  return l:result
endfunction

" Return base command for interactive use
function! db#adapter#odbc#interactive(url) abort
  return s:query_command(a:url) + ['--interactive']
endfunction

" Filter command (for piping SQL)
function! db#adapter#odbc#filter(url) abort
  return s:query_command(a:url) + ['--query-stdin']
endfunction

" Input command (for running a SQL file)
function! db#adapter#odbc#input(url, in) abort
  return s:query_command(a:url) + ['--query-file', a:in]
endfunction

" ============================================================================
" SYNCHRONOUS API (used by dadbod directly)
" ============================================================================

" Get list of tables (synchronous, but uses Python-side caching)
function! db#adapter#odbc#tables(url) abort
  let l:cmd = s:command(a:url) + ['--tables', '--table-limit', string(g:db_adapter_odbc_table_limit)]
  call s:debug('tables cmd: ' . string(l:cmd))
  return db#systemlist(l:cmd)
endfunction

" Get list of columns for a table (synchronous, but uses Python-side caching)
function! db#adapter#odbc#columns(url, table) abort
  let l:cmd = s:command(a:url) + ['--columns', a:table]
  call s:debug('columns cmd: ' . string(l:cmd))
  return db#systemlist(l:cmd)
endfunction

" Input completion (what goes after odbc://)
function! db#adapter#odbc#complete_opaque(url) abort
  return []
endfunction

" ============================================================================
" ASYNC API (for manual operations)
" ============================================================================

" Generic async job runner
function! s:run_async(cmd, callback) abort
  let l:job_data = {
        \ 'output': [],
        \ 'errors': [],
        \ 'callback': a:callback,
        \ }
  
  let l:job_id = jobstart(a:cmd, {
        \ 'on_stdout': function('s:on_stdout', [l:job_data]),
        \ 'on_stderr': function('s:on_stderr', [l:job_data]),
        \ 'on_exit': function('s:on_exit', [l:job_data]),
        \ })
  
  if l:job_id <= 0
    call s:notify('Failed to start job', 'error')
    return -1
  endif
  
  let s:pending_jobs[l:job_id] = l:job_data
  return l:job_id
endfunction

function! s:on_stdout(job_data, job_id, data, event) abort
  call extend(a:job_data.output, a:data)
endfunction

function! s:on_stderr(job_data, job_id, data, event) abort
  call extend(a:job_data.errors, a:data)
endfunction

function! s:on_exit(job_data, job_id, exit_code, event) abort
  " Clean up empty lines from output
  let l:output = filter(copy(a:job_data.output), 'v:val !=# ""')
  let l:errors = filter(copy(a:job_data.errors), 'v:val !=# ""')
  
  " Remove from pending jobs
  if has_key(s:pending_jobs, a:job_id)
    unlet s:pending_jobs[a:job_id]
  endif
  
  " Call the callback with results
  call a:job_data.callback(l:output, l:errors, a:exit_code)
endfunction

" ============================================================================
" PUBLIC ASYNC FUNCTIONS
" ============================================================================

" Test connection asynchronously
function! db#adapter#odbc#test_connection_async(url, callback) abort
  let l:cmd = s:query_command(a:url) + ['--check-connection', '--json']
  call s:debug('test_connection_async cmd: ' . string(l:cmd))
  
  return s:run_async(l:cmd, { output, errors, code -> 
        \ s:handle_connection_result(output, errors, code, a:callback) })
endfunction

function! s:handle_connection_result(output, errors, code, callback) abort
  if a:code == 0 && !empty(a:output)
    try
      let l:result = json_decode(join(a:output, ''))
      call a:callback(l:result)
      return
    catch
    endtry
  endif
  call a:callback({'success': v:false, 'message': join(a:errors, "\n")})
endfunction

" List schemas asynchronously
function! db#adapter#odbc#schemas_async(url, callback) abort
  let l:cmd = s:command(a:url) + ['--schemas', '--json']
  call s:debug('schemas_async cmd: ' . string(l:cmd))
  
  return s:run_async(l:cmd, { output, errors, code -> 
        \ s:handle_list_result(output, errors, code, a:callback, 'schemas') })
endfunction

" List tables asynchronously
function! db#adapter#odbc#tables_async(url, callback, ...) abort
  let l:schema = a:0 > 0 ? a:1 : ''
  let l:cmd = s:command(a:url) + ['--tables', '--table-limit', string(g:db_adapter_odbc_table_limit), '--json']
  if !empty(l:schema)
    let l:cmd += ['--schema', l:schema]
  endif
  call s:debug('tables_async cmd: ' . string(l:cmd))
  
  return s:run_async(l:cmd, { output, errors, code -> 
        \ s:handle_list_result(output, errors, code, a:callback, 'tables') })
endfunction

" List columns asynchronously
function! db#adapter#odbc#columns_async(url, table, callback) abort
  let l:cmd = s:command(a:url) + ['--columns', a:table, '--json']
  call s:debug('columns_async cmd: ' . string(l:cmd))
  
  return s:run_async(l:cmd, { output, errors, code -> 
        \ s:handle_list_result(output, errors, code, a:callback, 'columns') })
endfunction

function! s:handle_list_result(output, errors, code, callback, type) abort
  if a:code == 0 && !empty(a:output)
    try
      let l:items = json_decode(join(a:output, ''))
      call a:callback(l:items, v:null)
      return
    catch
      call s:debug('JSON parse error: ' . v:exception)
    endtry
  endif
  let l:error_msg = !empty(a:errors) ? join(a:errors, "\n") : 'Unknown error'
  call a:callback([], l:error_msg)
endfunction

" ============================================================================
" CACHE MANAGEMENT
" ============================================================================

" Refresh cache for a URL (fetch fresh data)
function! db#adapter#odbc#refresh(url, ...) abort
  let l:callback = a:0 > 0 ? a:1 : v:null
  let l:cmd = s:command(a:url) + ['--tables', '--no-cache', '--json']
  call s:debug('refresh cmd: ' . string(l:cmd))
  
  call s:notify('Refreshing cache...', 'info')
  
  return s:run_async(l:cmd, { output, errors, code -> 
        \ s:handle_refresh_result(output, errors, code, l:callback) })
endfunction

function! s:handle_refresh_result(output, errors, code, callback) abort
  if a:code == 0
    call s:notify('Cache refreshed', 'info')
    if a:callback != v:null
      call a:callback(v:true, v:null)
    endif
  else
    let l:error_msg = !empty(a:errors) ? join(a:errors, "\n") : 'Unknown error'
    call s:notify('Refresh failed: ' . l:error_msg, 'error')
    if a:callback != v:null
      call a:callback(v:false, l:error_msg)
    endif
  endif
endfunction

" Clear cache for a URL
function! db#adapter#odbc#clear_cache(url, ...) abort
  let l:callback = a:0 > 0 ? a:1 : v:null
  let l:cmd = s:query_command(a:url) + ['--clear-cache', '--json']
  call s:debug('clear_cache cmd: ' . string(l:cmd))
  
  return s:run_async(l:cmd, { output, errors, code -> 
        \ s:handle_clear_cache_result(output, errors, code, l:callback) })
endfunction

function! s:handle_clear_cache_result(output, errors, code, callback) abort
  if a:code == 0 && !empty(a:output)
    try
      let l:result = json_decode(join(a:output, ''))
      call s:notify('Cleared ' . l:result.cleared . ' cache file(s)', 'info')
      if a:callback != v:null
        call a:callback(l:result.cleared, v:null)
      endif
      return
    catch
    endtry
  endif
  let l:error_msg = !empty(a:errors) ? join(a:errors, "\n") : 'Unknown error'
  call s:notify('Clear cache failed: ' . l:error_msg, 'error')
  if a:callback != v:null
    call a:callback(0, l:error_msg)
  endif
endfunction

" Get cache status for a URL
function! db#adapter#odbc#cache_status(url, ...) abort
  let l:callback = a:0 > 0 ? a:1 : v:null
  let l:cmd = s:query_command(a:url) + ['--cache-status', '--json']
  call s:debug('cache_status cmd: ' . string(l:cmd))
  
  return s:run_async(l:cmd, { output, errors, code -> 
        \ s:handle_cache_status_result(output, errors, code, l:callback) })
endfunction

function! s:handle_cache_status_result(output, errors, code, callback) abort
  if a:code == 0 && !empty(a:output)
    try
      let l:result = json_decode(join(a:output, ''))
      if a:callback != v:null
        call a:callback(l:result, v:null)
      else
        " Print status to messages
        echom 'Cache status for ' . l:result.dsn . (empty(l:result.database) ? '' : '/' . l:result.database)
        if empty(l:result.files)
          echom '  No cached data'
        else
          for l:f in l:result.files
            if has_key(l:f, 'error')
              echom '  ' . l:f.name . ': ' . l:f.error
            else
              echom '  ' . l:f.name . ': ' . l:f.items . ' items, ' . l:f.age_hours . 'h old'
            endif
          endfor
        endif
      endif
      return
    catch
    endtry
  endif
  let l:error_msg = !empty(a:errors) ? join(a:errors, "\n") : 'Unknown error'
  call s:notify('Cache status failed: ' . l:error_msg, 'error')
  if a:callback != v:null
    call a:callback(v:null, l:error_msg)
  endif
endfunction
