function! unite#kinds#proj#define()
    return [s:kind_proj]
endfunction

let s:kind_proj = {
\ 'name' : 'proj',
\ 'defaut_action' : 'open',
\ 'action_table': {},
\}

let s:action_table = {}
let s:action_table.open = {
\'description' : 'open project info',
\}

function! s:action_table.open.func(candidate)
    " echoerr 'proj dir is' . a:candidate.action__path
    let proj_dir = a:candidate['action__path']
    execute 'cd '. proj_dir
    Pload
endfunction
let s:kind_proj.action_table = s:action_table
