" define source
function! unite#sources#proj#define()
    return [s:source_proj]
endfunction

let s:source_proj = {
\   'name': 'proj',
\   'description': 'candidates from proj',
\   'max_candidates': 200,
\   'syntax': 'uniteSource__Proj',
\   'default_kind' : 'proj',
\}

function! s:source_proj.gather_candidates(args, context)
    let projs = map(g:proj_list, "{
          \ 'word': v:val.name,
          \ 'abbr': printf('%-32s%s',
          \                 v:val.name,
          \                 fnamemodify(v:val.dir, ':~')
          \               ),
          \ 'kind' : 'proj',
          \ 'action__path' : fnamemodify(v:val.dir, ':p'),
          \ }")

    return projs
endfunction
