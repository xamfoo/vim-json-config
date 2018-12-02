" vim-ranger - JSON as vim config
" Maintainer:   Max Foo
" Version:      0.1
"

function! s:VimStatements(body)
  let l:statements = type(a:body) == type([]) ? a:body : [a:body]
  let l:results = []

  for s in l:statements
    if type(s) == type('')
      let l:results = l:results + [s]
      continue
    endif

    if type(s) == type({})
      if !has_key(s, 'type') || type(s.type) != type('')
        continue
      endif

      if s.type == 'if'
        let l:results = l:results +
          \ ['if ' . s.condition, s:VimStatements(s.then), 'else', s:VimStatements(s.else), "endif"]
        continue
      endif
    endif
  endfor

  return join(l:results, "\n")
endfunction

function! s:VimFunctions(m)
  let l:m = a:m

  if !has_key(m, 'functions')
    return
  endif

  let l:functions = type(m.functions) == type([]) ? m.functions : [m.functions]

  for f in l:functions
    if !has_key(f, 'name')
      echoerr "function has no name - " . string(m)
      return
    endif

    exec 'function! ' . f.name . '(' . join(f.args, ', ') . ")\n"
      \ s:VimStatements(f.body) . "\nendfunction"
  endfor
endfunction

function! s:VimCommands(module)
  let l:module = a:module

  if !has_key(module, 'commands')
    return
  endif

  let l:commands = type(module.commands) == type([]) ? module.commands : [module.commands]

  for c in l:commands
    if !has_key(c, 'input')
      echoerr "command has no input - " . string(module)
      return
    endif

    if !has_key(c, 'output')
      echoerr "command has no output - " . string(module)
      return
    endif

    let l:hasRemap = has_key(c, 'remap') && type(c.remap) == type(1) && c.remap == 1
    let l:hasBang = has_key(c, 'bang') && type(c.bang) == type(1) && c.bang == 1
    let l:hasNArgs = has_key(c, 'nargs') && type(c.nargs) == type('')

    exec 'command' . (l:hasRemap ? '!' : '') .
      \(l:hasBang ? ' -bang' : '') .
      \(l:hasNArgs ? (' -nargs=' . c.nargs) : '') .
      \' ' . c.input . ' ' . c.output
  endfor
endfunction

function! s:VimConfig(m)
  let l:m = a:m

  if has_key(m, 'setOptions')
    for setOption in items(m.setOptions)
      if type(setOption[1]) == type(1)
        execute 'set ' . (setOption[1] ? '' : 'no') . setOption[0]

      elseif type(setOption[1]) == type(v:true)
        execute 'set ' . (setOption[1] == v:true ? '' : 'no') . setOption[0]

      elseif type(setOption[1]) == type({})
        if has_key(setOption[1], '+')
          execute 'set ' . setOption[0] . '+=' . setOption[1]['+']
        elseif has_key(setOption[1], '-')
          execute 'set ' . setOption[0] . '-=' . setOption[1]['-']
        elseif has_key(setOption[1], '=')
          execute 'set ' . setOption[0] . '=' . setOption[1]['=']
        endif
      endif
    endfor
  endif

  if has_key(m, 'variables')
    for variable in items(m.variables)
      execute 'let ' . variable[0] . ' = ' . variable[1]
    endfor
  endif

  if has_key(m, 'colorscheme') && type(m.colorscheme) == type('')
    execute 'colorscheme ' . m.colorscheme
  endif
endfunction

function! IsInvalidMode(idx, pair)
  return type(a:pair[1]) != type('') || (
    \a:pair[0] != 'insertMode' && a:pair[0] != 'normalMode' && a:pair[0] != 'visualMode' && a:pair[0] != 'commandLineMode'
  \)
endfunction

function! s:map_keys(pairs)
  for pair in a:pairs
    if pair[0] == 'insertMode'
      for keymapSpec in pair[1]
        let l:remap = has_key(keymapSpec, 'remap') && keymapSpec.remap
              \? 1
              \: 0

        let l:command = l:remap ? 'imap' : 'inoremap'

        let l:input = has_key(keymapSpec, 'expr')
              \? '<expr> ' . keymapSpec.input
              \: keymapSpec.input

        let l:output = has_key(keymapSpec, 'expr')
              \? keymapSpec.expr
              \: keymapSpec.output

        execute l:command . ' ' . l:input . ' '. l:output
      endfor
    endif

    if pair[0] == 'normalMode'
      for keymapSpec in pair[1]
        let l:remap = has_key(keymapSpec, 'remap') && keymapSpec.remap
              \? 1
              \: 0

        let l:command = l:remap ? 'nmap' : 'nnoremap'

        let l:input = has_key(keymapSpec, 'expr')
              \? '<expr> ' . keymapSpec.input
              \: keymapSpec.input

        let l:output = has_key(keymapSpec, 'expr')
              \? keymapSpec.expr
              \: keymapSpec.output

        execute l:command . ' ' . l:input . ' '. l:output
      endfor
    endif

    if pair[0] == 'commandLineMode'
      for keymapSpec in pair[1]
        let l:remap = has_key(keymapSpec, 'remap') && keymapSpec.remap
              \? 1
              \: 0

        let l:command = l:remap ? 'cmap' : 'cnoremap'

        let l:input = has_key(keymapSpec, 'expr')
              \? '<expr> ' . keymapSpec.input
              \: keymapSpec.input

        let l:output = has_key(keymapSpec, 'expr')
              \? keymapSpec.expr
              \: keymapSpec.output

        execute l:command . ' ' . l:input . ' '. l:output
      endfor
    endif
  endfor
endfunction

function! s:VimKeymap(m)
  let l:m = a:m

  if !has_key(m, 'keymap')
    return
  endif

  let keymapItems = items(m.keymap)
  call filter(keymapItems, function('IsInvalidMode'))
  call s:map_keys(keymapItems)
endfunction

function! s:load_single_config(opts, config)
  call s:VimFunctions(a:config)
  call s:VimKeymap(a:config)
  call s:VimCommands(a:config)
  call s:VimConfig(a:config)
endfunction

function! s:for_each_plugin(plugins, config, opts, iter)
  if type(a:plugins) != type([])
    throw "plugins should be a list but is " . string(a:plugins)
  endif

  for p in a:plugins
    if type(p) != type({})
      throw "plugins[*] should be an object but is " . string(p)
    endif

    let l:key = get(p, 'key', '')
    let l:options = extend(copy(get(a:opts, l:key, {})), { 'key': l:key })

    call a:iter(a:config, l:options, p)
  endfor
endfunction

function! s:run_plugin_before_all(config, options, plugin)
  if has_key(a:plugin, 'beforeAll')
    if type(a:plugin.beforeAll) != type(function("tr"))
      throw "plugin.beforeAll should be a function but is " . string(a:plugin.beforeAll)
    endif

    call a:plugin.beforeAll(a:config, a:options)
  endif
endfunction

function! s:run_plugin_after_all(config, options, plugin)
  if has_key(a:plugin, 'afterAll')
    if type(a:plugin.afterAll) != type(function("tr"))
      throw "plugin.afterAll should be a function but is " . string(a:plugin.afterAll)
    endif

    call a:plugin.afterAll(a:config, a:options)
  endif
endfunction

function! json_config#for_each_config(config, iter)
  if type(a:config) != type([])
    throw "config should be a list but is " . string(a:config)
  endif

  for c in a:config
    if type(c) != type({})
      throw "config[*] should be an object but is " . string(c)
    endif

    call a:iter(c)
  endfor
endfunction

function! json_config#read_file(path)
  return json_decode(join(readfile(expand(a:path)), ''))
endfunction

function! json_config#load(config, ...)
  let l:opts = get(a:, 1, {})

  let l:plugins = get(
    \opts,
    \'plugins',
    \[g:json_config#junegunn_vim_plug]
  \)

  if type(opts) != type({})
    throw "options should be an object but is " . string(opts)
  endif

  call s:for_each_plugin(plugins, a:config, opts, function('s:run_plugin_before_all'))

  call json_config#for_each_config(a:config, function('s:load_single_config', [opts]))

  call s:for_each_plugin(plugins, a:config, opts, function('s:run_plugin_after_all'))
endfunction

function! json_config#load_file(path, ...)
  return call('json_config#load', [json_config#read_file(a:path)] + a:000)
endfunction


function! json_config#junegunn_vim_plug_before_all(config, opts)
  if !has_key(a:opts, 'directory') || type(a:opts.directory) != type('')
    throw 'junegunn/vim-plug options.directory should be a string but is '
      \. string(get(a:opts, 'directory', 'undefined'))
  endif

  function Junegunn_vim_plug_before_all(opts, m)
    let l:m = a:m
    let l:key = get(a:opts, 'key', '')

    if has_key(m, l:key)
      let l:plugins = type(m[key]) == type([]) ? m[key] : [m[key]]

      for p in l:plugins
        if type(p) == type('') && !empty(p)
          Plug p
        endif

        if type(p) == type({}) && has_key(p, 'name') && !empty(p.name)
          let l:options = copy(p)
          call remove(options, 'name')
          execute 'Plug ''' . p.name . ''', ' . string(options)
        endif
      endfor
    endif
  endfunction

  call plug#begin(a:opts.directory)
    call json_config#for_each_config(a:config, function('Junegunn_vim_plug_before_all', [a:opts]))
  call plug#end()
endfunction

let g:json_config#junegunn_vim_plug = {
\  'beforeAll': function('json_config#junegunn_vim_plug_before_all'),
\  'key': 'junegunn/vim-plug',
\}

" vim:set sw=2 sts=2:
