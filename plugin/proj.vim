let g:proj_ignore_dir = ['.git', '.svn', '.hg', '.vimproject', 'moc*']
let g:proj_search_file_type = ['cpp', 'h', 'c']
let g:proj_list_path = g:wh_temporary_dir . 'vimproj_list'
let g:proj_list = []

let g:proj_is_load = 0
let g:proj_is_updated = 0
function! s:do_vim_idle()
    if g:proj_is_updated == 1
        let g:proj_is_updated = 0
        call s:update_proj_file_list()
        call s:auto_save_session()
        call s:do_update()
    endif
endfunction

let s:proj_file_is_modify = []
function! s:init_file_modify_state()
    for ft in g:proj_search_file_type
        call add(s:proj_file_is_modify, 1)
    endfor
endfunction

function! s:set_file_modify_state(file_type, state)
    if !s:is_project() | return | endif
    let ft_idx = 0
    while ft_idx < len(g:proj_search_file_type)
        if g:proj_search_file_type[ft_idx] == a:file_type
            let s:proj_file_is_modify[ft_idx] = a:state
            break
        endif
        let ft_idx = ft_idx + 1
    endwhile
    if a:state == 1
        " set updatetime=4000
        let g:proj_is_updated = 1
    endif
endfunction

function! s:update_files()
    if !s:is_project() | return | endif

    let ft_idx = 0
    while ft_idx < len(g:proj_search_file_type)
        if s:proj_file_is_modify[ft_idx] == 1
            call s:do_update_by_ft(g:proj_search_file_type[ft_idx])
        endif
        let ft_idx = ft_idx + 1
    endwhile
endfunction

function! s:do_update()
    if !s:is_project() | return | endif

    call s:update_files()

    " syntastic check
    " execute ":SyntasticCheck"

    "set updatetime=4000 " Set updatetime to default
endfunction


function! s:do_update_by_ft(file_type)
    call s:update_tags_cscope(a:file_type)
endfunction

" ===========================================================================
" Project Setting
" ===========================================================================
function! s:save_proj_setting()
    let line_list = []
endfunction

function! s:load_proj_setting()
    execute "source " . s:get_proj_setting_file_path()
endfunction

" ===========================================================================
" Plugin Setting
" ===========================================================================
function! s:update_plugin()
    call s:set_nerd_bookmark()
    call s:set_yank_history()
    call s:set_syntastic()
    call s:update_lookup_file_tag()
    call s:update_neocomplete()
endfunction

" ===========================================================================
" Session
" ===========================================================================
function! s:auto_load_session()
    if !s:is_project()
        return
    endif

    call s:proj_list_set_mru(fnamemodify('.', ':p'))
    let g:proj_is_load = 1

    call s:init_file_modify_state()
    let session_file = s:get_session_path()
    let viminfo_file = s:get_viminfo_path()
    if filereadable(session_file)
        execute "source " . session_file
    endif
    if filereadable(viminfo_file)
        execute "rviminfo! ". viminfo_file
    endif
    call s:update_plugin()
    call s:update_tags_cscope_all()
endfunction

function! s:auto_save_session()
    if !s:is_project() | return | endif
    silent! execute "mksession! " . s:get_session_path()
    silent! execute "wviminfo! ". s:get_viminfo_path()
endfunction

" ===========================================================================
" CTags & Cscope
" ===========================================================================
let s:ctags_cmd  = g:wh_ctags_cmd . " -R --c++-kinds=+p --fields=+iaS --extra=+q -L "
let s:cscope_cmd = g:wh_cscope_cmd . " -bkq -i "
if g:wh_is_windows == 1
let s:ctags_cmd  = '"' . g:wh_ctags_cmd . '" -R --c++-kinds=+p --fields=+iaS --extra=+q -L '
let s:cscope_cmd = '"'. g:wh_cscope_cmd . '" -bkq -i '
endif
function! s:update_tags_cscope_all()
    for ft in g:proj_search_file_type
        call s:update_tags_cscope(ft)
    endfor
endfunction

function! s:update_tags_cscope(file_type)
    let file_list = s:get_file_list_path_by_ft(a:file_type)
    if !filereadable(file_list) | return | endif

    let tag_path    = s:get_proj_tag_path(a:file_type)
    let cscope_path = s:get_proj_cscope_path(a:file_type)

    call s:gen_ctags(file_list, tag_path)
    call s:gen_cscope(file_list, cscope_path)

    " reset tag & cscope connect
    call s:reset_ctag_connect(tag_path)
    call s:reset_cscope_connect(cscope_path)
endfunction

function! s:update_proj_file_list()
    call s:write_lookupfile_tag_head()
    call s:gen_lookupfile_tags()

    for ft in g:proj_search_file_type
        call s:update_proj_file_list_by_ft(ft)
    endfor
endfunction

function! s:write_lookupfile_tag_head()
    let lookup_file_cmd = 'echo "!_TAG_FILE_SORTED	2	/2=foldcase/"'
    let lookup_file_cmd = lookup_file_cmd . " > " . escape(s:get_lookup_file_tag_path(), ' \')

    if g:wh_is_windows == 1
        let lookup_file_cmd = '(' . lookup_file_cmd . ')'
    endif

    call system(lookup_file_cmd)
endfunction

function! s:gen_lookupfile_tags()
    let cmd = g:wh_find_cmd . ' ' . escape(fnamemodify("./", ":p"), ' \')
    if g:wh_is_windows == 1
        let cmd = '"' . g:wh_find_cmd . '" ' . escape(fnamemodify("./", ":p"), ' \')
    endif

    let cmd = cmd . ' -type f '

    let lookup_file_cmd = cmd . ' -printf "%f\t%p\t1\n"'
    let lookup_file_cmd = lookup_file_cmd . ' >> ' . escape(s:get_lookup_file_tag_path(), ' \')

    if g:wh_is_windows == 1
        let lookup_file_cmd = '(' . lookup_file_cmd . ')'
    endif

    call system(lookup_file_cmd)
endfunction

function! s:update_proj_file_list_by_ft(file_type)
    let cmd = g:wh_find_cmd. ' ' . escape(fnamemodify("./", ":p"), ' \')
    if g:wh_is_windows == 1
        let cmd = '"' . g:wh_find_cmd. '" ' . escape(fnamemodify("./", ":p"), ' \')
    endif

    let cmd = cmd . ' -type f -print | grep \.' . a:file_type . '$'

    let file_list_cmd = cmd . ' > ' . escape(s:get_file_list_path_by_ft(a:file_type), ' \')

    if g:wh_is_windows == 1
        let file_list_cmd = '(' . file_list_cmd . ')'
    endif

    call system(file_list_cmd)

    if a:file_type == 'cpp'
        let files = readfile(s:get_file_list_path_by_ft(a:file_type))
        let files_ok = []
        for file in files
            if file !~ 'moc_.*\.cpp$'
                call add(files_ok, file)
            endif
        endfor
        call writefile(files_ok, s:get_file_list_path_by_ft(a:file_type))
    endif
endfunction

function! s:update_lookup_file_tag()
    let g:LookupFile_TagExpr = string(s:get_lookup_file_tag_path())
endfunction

" Lookupfile
function! s:get_lookup_file_tag_path()
    return s:get_proj_file_path("lookup_file_tag")
endfunction

" Nerd Bookmark
function! s:set_nerd_bookmark()
    let g:NERDTreeBookmarksFile = s:get_nerd_bookmarks_path()
endfunction

" Yankring
function! s:set_yank_history()
    let g:yankring_history_dir = s:get_yankring_history_path()
endfunction

function! s:set_syntastic()
    let g:syntastic_c_include_dirs = [ 'includes', 'headers', 'inc' ]

    " let file_list_cmd = cmd . ' -print > ' . s:get_file_list_path_by_ft(a:file_type)
    let include_files = readfile(s:get_file_list_path_by_ft("h"))
    let include_dir_list = []

    for inc_file in include_files
        let inc_dir = fnamemodify(inc_file, ":h")
        if index(include_dir_list, inc_dir) < 0
            call add(include_dir_list, inc_dir)
        endif
    endfor

    call extend(g:syntastic_c_include_dirs, include_dir_list)

    let g:syntastic_cpp_include_dirs = deepcopy(g:syntastic_c_include_dirs)

    " let qt_inc_dir = g:wh_vim_dir.'/include/qt/'
    " if isdirectory("/usr/include/qt5")
    "     let qt_inc_dir = "/usr/include/qt5/"
    " endif
    " if isdirectory(qt_inc_dir)
    "     call add(g:syntastic_cpp_include_dirs, qt_inc_dir)
        " call add(g:syntastic_cpp_include_dirs, qt_inc_dir.'QtGui')
        " call add(g:syntastic_cpp_include_dirs, qt_inc_dir.'QtSql')
        " call add(g:syntastic_cpp_include_dirs, qt_inc_dir.'QtCore')
        " call add(g:syntastic_cpp_include_dirs, qt_inc_dir.'QtXml')
        " call add(g:syntastic_cpp_include_dirs, qt_inc_dir.'QtWidgets')
        " call add(g:syntastic_cpp_include_dirs, qt_inc_dir.'QtNetwork')
    " endif
    " echo g:syntastic_c_include_dirs
endfunction

function! s:update_neocomplete()
    " update include dir
    let include_files = readfile(s:get_file_list_path_by_ft("h"))
    let include_dir_str = ''
    let include_dir_list = []

    for inc_file in include_files
        let inc_dir = fnamemodify(inc_file, ":h")
        if index(include_dir_list, inc_dir) < 0
            call add(include_dir_list, inc_dir)
            let include_dir_str = include_dir_str . inc_dir . ','
        endif
    endfor

    let include_dir_str = include_dir_str . '/usr/include/, /usr/include/c++/*, /usr/include/*/c++/*, /usr/include/*/'
    if !exists('g:neocomplete#sources#include#paths')
      let g:neocomplete#sources#include#paths = {}
    endif
    let g:neocomplete#sources#include#paths.c = include_dir_str
    let g:neocomplete#sources#include#paths.cpp = include_dir_str

    " update tag
    " let tags_str = ''
    " for ft in g:proj_search_file_type
    "     let tags_str = s:get_proj_tag_path(ft) . ','
    " endfor
    " let g:neocomplete#sources#tags
endfunction

function! s:get_nerd_bookmarks_path()
    return s:get_proj_file_path("proj_nerd_bookmark")
endfunction

function! s:get_yankring_history_path()
    return s:get_proj_file_path("proj_yankring")
endfunction

function! s:get_proj_setting_file_path()
    return s:get_proj_file_path("proj_setting.vim")
endfunction

function! s:get_proj_tag_path(file_type)
    let file_type = strpart(a:file_type, 0)
    return s:get_proj_file_path("proj_tag") . "_" . file_type
endfunction

function! s:get_proj_cscope_path(file_type)
    let file_type = strpart(a:file_type, 0)
    return s:get_proj_file_path("proj_") . file_type . "_cscope"
endfunction

function! s:get_file_list_path()
    return s:get_proj_file_path("proj_files")
endfunction

function! s:get_file_list_path_by_ft(file_type)
    let file_type = strpart(a:file_type, 0)
    return s:get_proj_file_path("proj_files") . "_" . file_type
endfunction

function! s:get_session_path()
    return s:get_proj_file_path("proj_session")
endfunction

function! s:get_viminfo_path()
    return s:get_proj_file_path("proj_viminfo")
endfunction

function! s:is_project()
    if isdirectory(s:proj_dir)
        return 1
    else
        return 0
    endif
endfunction

let s:proj_dir = "./.vimproject/"
function! s:get_proj_file_path(file_path)
    return fnamemodify(s:proj_dir.a:file_path, ':p')
endfunction

function! s:reset_ctag_connect(tag_name)
    let tag_name = fnamemodify(a:tag_name, ":p")
    if filereadable(tag_name)
        silent! execute "set tags-=".tag_name
        silent! execute "set tags+=".tag_name
    endif
endfunction

function! s:reset_cscope_connect(cscope_name)
    let cscope_name = fnamemodify(a:cscope_name, ":p")
    if has("cscope")
        silent! execute "cscope kill ".cscope_name
        if filereadable(cscope_name)
            silent! execute "cscope add ".cscope_name
        endif
    endif
endfunction

function! s:gen_cscope(file_list, tags_path)
    let cmd = s:cscope_cmd." ".a:file_list." -f ".a:tags_path
    call system(cmd)
endfunction

function! s:gen_ctags(file_list, tags_path)
	let cmd = s:ctags_cmd." ".a:file_list." -f ".a:tags_path
   	call system(cmd)
endfunction

function! s:proj_list_remove(proj_dir)
    let proj_idx = 0
    while proj_idx < len(g:proj_list)
        let proj = g:proj_list[proj_idx]
        if fnamemodify(proj.dir, ':p') == fnamemodify(a:proj_dir, ':p')
            call remove(g:proj_list, proj_idx)
        else
            let proj_idx = proj_idx + 1
        endif
    endwhile
endfunction

function! s:proj_list_load()
    if len(g:proj_list) > 0
        call remove(g:proj_list, 0, len(g:proj_list) - 1)
    endif

    if !filereadable(g:proj_list_path)
        return
    endif

    let proj_str_lsit = readfile(g:proj_list_path)
    for proj_str in proj_str_lsit
        let split_list = split(proj_str, "\t")
        if len(split_list) < 2
            continue
        endif

        let proj_name = split_list[0]
        let proj_dir  = split_list[1]

        if isdirectory(proj_dir)
            call s:proj_list_add(proj_name, proj_dir)
        endif
    endfor
endfunction

function! s:proj_list_write()
    let proj_str_lsit = []
    for proj in g:proj_list
        call add(proj_str_lsit, proj.name . "\t" . proj.dir)
    endfor
    call writefile(proj_str_lsit, g:proj_list_path)
endfunction

function! s:proj_list_add(proj_name, proj_dir)
    call add(g:proj_list, {'name' : a:proj_name, 'dir' : fnamemodify(a:proj_dir, ':p')})
endfunction

function! s:proj_list_get_name(proj_dir)
    for proj in g:proj_list
        if  proj.dir == a:proj_dir
            return proj.name
        endif
    endfor
    return 'Unknown'
endfunction

function! s:proj_list_get_dir(proj_name)
    for proj in g:proj_list
        if  proj.name == a:proj_name
            return proj.dir
        endif
    endfor
    return ''
endfunction

function! s:proj_list_set_mru(proj_dir)
    let proj_dir = fnamemodify(a:proj_dir, ':p')
    let proj_name = s:proj_list_get_name(proj_dir)
    call s:proj_list_remove(proj_dir)
    call s:proj_list_add(proj_name, proj_dir)
    call s:proj_list_write()
endfunction

function! s:create_proj(proj_name)
    if !isdirectory(s:proj_dir)
        call mkdir(s:proj_dir)
        call s:init_file_modify_state()
        call s:update_files()
        let g:proj_is_updated = 1
        call s:do_vim_idle()

        " Add proj to list
        call s:proj_list_remove('.')
        call s:proj_list_add(a:proj_name, '.')
        call s:proj_list_write()
    endif
    echo "Job Done!"
endfunction

function! s:proj_open_by_dir(dir)
    if !isdirectory(a:dir)
        echomsg 'Please enter direcotry!'
    else
        if !isdirectory(a:dir."/.vimproject")
            echomsg a:dir . ' is not project direcotry!'
        else
            execute 'cd '.a:dir
            call s:auto_load_session()
        endif
    endif
endfunction

function! s:proj_open_by_name(name)
    let proj_dir = s:proj_list_get_dir(a:name)
    if proj_dir == ''
        echoms "No such proj!"
    elseif !isdirectory(proj_dir)
        echomsg a:name . "directory is:" . proj_dir . ", but is doesnt't exist! Please Check!"
    else
        if !isdirectory(proj_dir."/.vimproject")
            echoerr proj_dir . ' is not project direcotry!'
        else
            execute 'cd '.proj_dir
            call s:auto_load_session()
        endif
    endif
endfunction

function! s:proj_list_cmdline_complete(ArgLead, CmdLine, CursorPos)
    let str = ""

    for proj in g:proj_list
        let str = proj['name'] . "\n"
    endfor

    return str
endfunction

command -nargs=1 Pcreate  :call <SID>create_proj(<q-args>)
command Pupdate  :call <SID>update_files()
command Pload    :call <SID>auto_load_session()
command -complete=custom,s:proj_list_cmdline_complete -nargs=1 Popen  call <SID>proj_open_by_name(<q-args>)

augroup VimProj
  autocmd!
  au VimEnter * nested call s:proj_list_load()
  au VimEnter * nested call s:auto_load_session()
  au CursorHold,CursorHoldI *.h,*.c,*.cpp call s:do_vim_idle()
  au VimLeavePre *      call s:auto_save_session()
  au BufWritePost *.h   call s:set_file_modify_state("h", 1)
  au BufWritePost *.cpp call s:set_file_modify_state("cpp", 1)
  au BufWritePost *.c   call s:set_file_modify_state("c", 1)
augroup END
