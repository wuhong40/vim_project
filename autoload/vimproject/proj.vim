" ==============================================================================
" Interface
" ==============================================================================
"
function! vimproject#proj#is_project()
    return s:is_project()
endfunction

function! vimproject#proj#do_after_write_file()
    call s:do_after_write_file()
endfunction

function! vimproject#proj#get_proj_file_list()
    let file_list = []

    call extend(file_list, vimproject#file#load_list(s:proj_files[s:file_type_read]))
    call extend(file_list, vimproject#file#load_list(s:proj_files[s:file_type_edit]))

    return file_list
endfunction

function! vimproject#proj#get_project_dir()
    return g:vp_proj_directory
endfunction

function! vimproject#proj#get_proj_dir_name()
    return s:vp_proj_directory_name
endfunction

let s:vp_version             = "4.0"
let s:vp_working_directory   = getcwd()
let s:vp_proj_directory_name = ".vimproject"

let s:file_type_read = 0
let s:file_type_edit = 1
let s:file_oper_add = 0
let s:file_oper_del = 1
let s:proj_types = {
            \"c"      : "c or c++ project",
            \"kernel" : "linux kernel project",
            \"python" : "python project",
            \"java"   : "java project",
            \"lua"    : "lua project",
            \"vim"    : "vim srcipt project",
            \}

let g:vp_proj_directory      = fnamemodify(s:vp_working_directory, ":p")."".s:vp_proj_directory_name."/"
let g:vp_proj_setting_file   = g:vp_proj_directory."setting"

let s:proj_files = ["edit", "read"]
let s:tags_files = ["edit", "read"]
let s:cscope_files = ["edit", "read"]
let s:is_check_syntastic = "1"
let s:session_path  = "session.vim"
let s:vim_info_path = "info.vim"


function! s:choose_proj_type()
    " echo the project type list
    echo "Please choose the project's type that you want create:"
    echo "idx\tname\tinfo"
    let idx = 0
    for type in keys(s:proj_types)
        echo idx."\t".type."\t".s:proj_types[type]
        let idx += 1
    endfor

    " wait user input
    echo "Input the idx:"
    let input = getchar()
    if input >= char2nr('0') && input < char2nr(len(s:proj_types).'')
        let idx = 0
        for type in keys(s:proj_types)
            if input - char2nr('0') == idx
                return type
            endif
            let idx += 1
        endfor
    else "re choose project type
        redraw
        echo "!!!!! Input error !!!!!"
        call s:choose_proj_type()
    endif
endfunction

"command! Dbg :ProjAdd
function! s:create_proj()
    let name = fnamemodify(s:vp_working_directory, ":t")

    " create project directory
    if !isdirectory(g:vp_proj_directory)
        call mkdir(g:vp_proj_directory, "", 0700)
    else
        echo "It's already a project! If you want creat again, remove the directory:".s:vp_proj_directory_name
        return
    endif

    let g:vp_proj_type = s:choose_proj_type()

    " init & save the setting
    call vimproject#setting#init_proj_setting(g:vp_proj_type, g:vp_proj_directory)
    call vimproject#setting#save(g:vp_proj_type, g:vp_proj_setting_file)

"function! vimproject#setting#save(proj_type, setting_file)
    " create project file
    call vimproject#proj_list#add_proj(name, s:vp_working_directory, g:vp_proj_type)
endfunction

function s:set_proj_var(work_dir)
    let proj_dir = a:work_dir."".s:vp_proj_directory_name."/"
    let s:proj_files[s:file_type_edit]      = proj_dir."proj_files_edit"   " files usually edit
    let s:proj_files[s:file_type_read]      = proj_dir."proj_files_read"   " files usually read only
    "let s:proj_files_edit_abs               = proj_dir."proj_files_edit_abs"
    "let s:proj_files_read_abs               = proj_dir."proj_files_read_abs"
    let s:tags_files[s:file_type_edit]      = proj_dir."tags_edit"
    let s:tags_files[s:file_type_read]      = proj_dir."tags_read"
    let s:cscope_files[s:file_type_edit]    = proj_dir."cscope_edit"
    let s:cscope_files[s:file_type_read]    = proj_dir."cscope_read"

    let s:session_path                      = proj_dir."session.vim"
    let s:vim_info_path                     = proj_dir."info.vim"
    "let s:proj_setting_file                 = proj_dir."vp_setting.vim"

    let g:wh_mru_mode  = ":."
endfunction

function! vimproject#proj#load_proj(work_dir)
    return s:load_proj(a:work_dir)
endfunction

function! s:load_proj(work_dir)
    if s:is_project() != 1 | return | endif
    "echo "change the current directory to ".a:work_dir."\n"
    exec "cd! ".a:work_dir

    call s:set_proj_var(a:work_dir)
    call vimproject#setting#source(g:vp_proj_setting_file)
    call s:set_other_plugin()
    call s:map_key_and_cmd()

    " Init proj
    exec "call vimproject#".g:vp_proj_type."#init()"
    call vimproject#setting#save(g:vp_proj_type, g:vp_proj_setting_file)

    call vimproject#tags#reset_ctag_connect(s:tags_files[s:file_type_edit])
    call vimproject#tags#reset_ctag_connect(s:tags_files[s:file_type_read])

    call vimproject#tags#reset_cscope_connect(s:cscope_files[s:file_type_edit])
    call vimproject#tags#reset_cscope_connect(s:cscope_files[s:file_type_read])
    "call vimproject#tags#update_ctags_cscope(s:proj_files[a:file_type], s:tags_files[a:file_type], s:cscope_files[a:file_type])
    "if filereadable(s:tags_files[s:file
        "call vimproject#common#reset_ctag_connect(s:tags_files[s:file_type_edit])
    "endif
    "if filereadable(s:tags_read)
        "call vimproject#common#reset_ctag_connect(s:tags_read)
    "endif

    "" load cscope
    "if has("cscope")
        "" add any database in current directory
        "if filereadable(s:cscope_edit)
            "silent! execute "cs add ".s:cscope_edit
        "endif
        "if filereadable(s:cscope_read)
            "silent! execute "cs add ".s:cscope_read
        "endif
    "endif
    "call vimproject#common#source_session(s:session_path, s:vim_info_path)
endfunction

function vimproject#proj#source_session()
    call vimproject#common#source_session(s:session_path, s:vim_info_path)
endfunction

function! vimproject#proj#unload_proj(work_dir)
    if s:is_project() != 1 | return | endif
    call s:unmap_key_and_cmd()
    "call s:unset_other_plugin()

    call vimproject#common#save_sesseion(s:session_path, s:vim_info_path)
endfunction

function! vimproject#proj#file_oper(file_type, file_oper_mode, ...)
    " Get the path to operat
    if a:0 == 1
        let path = a:1
    else
        let path = bufname("%")
    endif

    if a:file_type == s:file_type_edit
        let file_type_2 = s:file_type_read
    elseif a:file_type == s:file_type_read
        let file_type_2 = s:file_type_edit
    else
        return
    endif

    if a:file_oper_mode == s:file_oper_add
        if s:is_project() == 0
            call s:create_proj()
            call s:load_proj("./")
        endif
        call vimproject#file#add_path(s:proj_files[a:file_type], path)
        call vimproject#file#del_path(s:proj_files[file_type_2], path)
    elseif a:file_oper_mode == s:file_oper_del
        call vimproject#file#del_path(s:proj_files[a:file_type], path)
        call vimproject#file#del_path(s:proj_files[file_type_2], path)
        "call s:del_from_mru_edit_file
    else
        return
    endif

    call s:do_after_oper_project_file(a:file_type, a:file_oper_mode)
endfunction


function! s:do_after_oper_project_file(file_type, file_oper_mode)
    "if a:file_type == s:file_type_edit
        " Gen the ctags & cscope
        "call s:update_tags(a:file_type)
    "endif
    call s:update_tags(s:file_type_edit)
    call s:update_tags(s:file_type_read)

    "call vimproject#tags#reset_ctag_connect(s:tags_files[s:file_type_edit])
    "call vimproject#tags#reset_ctag_connect(s:tags_files[s:file_type_read])

    "call vimproject#tags#reset_cscope_connect(s:cscope_files[s:file_type_edit])
    "call vimproject#tags#reset_cscope_connect(s:cscope_files[s:file_type_read])

    "exec "vimproject#".s:proj_type."#do_after_write_file(file_name"
endfunction

function! s:mv_file_to_edit(file)
    if vimproject#file#is_file_include(s:proj_files[s:file_type_edit], a:file) == 0
        call vimproject#file#add_path(s:proj_files[s:file_type_edit], a:file)
        call vimproject#file#del_path(s:proj_files[s:file_type_read], a:file)
    endif
endfunction

function! s:update_tags(file_type)
    call vimproject#tags#update_ctags_cscope(s:proj_files[a:file_type], s:tags_files[a:file_type], s:cscope_files[a:file_type])
endfunction

function! s:do_after_write_file()
    if s:is_project() != g:vp_true | return | endif
    let file_path = bufname("%")
    if !filereadable(file_path) | return | endif

    call s:update_tags(s:file_type_edit)
    call s:mv_file_to_edit(file_path)

    " need move it to file type special
    call MacroDefineUpdate()
endfunction

command! -nargs=? -complete=file PAdd    call vimproject#proj#file_oper(s:file_type_read, s:file_oper_add, <f-args>)
command! -nargs=? -complete=file PDel    call vimproject#proj#file_oper(s:file_type_edit, s:file_oper_del, <f-args>)
function! s:map_key_and_cmd()
    command! -nargs=0 -complete=file PUpTags  call <SID>update_tags(s:file_type_read)

	" map project type cmd & key
	execute "call vimproject#".g:vp_proj_type."#map_key_and_cmd()"

	" map compile cmd
	call vimproject#compile#map_key_and_cmd()
endfunction

function! s:unmap_key_and_cmd()
    "delcommand PAdd
    "delcommand PDel
    delcommand PUpTags
endfunction

function! s:is_project()
    if isdirectory(g:vp_proj_directory)
        return g:vp_true
    endif
    return g:vp_false
endfunction

" ==============================================================================
" Other Plugin's File
" ==============================================================================
let s:nerd_bookmarks      = g:vp_proj_directory."nerd_bookmarks"
let s:yank_history_file   = g:vp_proj_directory."yankring_history"
let s:mru_file            = g:vp_proj_directory."mru_file"

" Nerd Bookmark
function! s:set_nerd_bookmark()
    let g:NERDTreeBookmarksFile = s:nerd_bookmarks
endfunction

" Yankring
function! s:set_yank_history()
    let g:yankring_history_dir = g:vp_proj_directory
    call ReSetYankDir()
endfunction

" Mru File
function! s:set_mru_file()
    let g:wh_mru_file = s:mru_file
endfunction

" Syntastic
function! s:set_syntastic()
    if exists("g:loaded_syntastic_plugin")
        if s:is_check_syntastic == "1"
            let g:syntastic_check_on_open=1
            " Move to file type special setting
            "call s:set_syntastic_c_include_dirs()
        else
            "SyntasticClose
            let g:syntastic_check_on_open=0
        endif
    endif
endfunction

function! s:set_other_plugin()
    call s:set_nerd_bookmark()
    "call s:set_yank_history()
    call s:set_syntastic()
    call s:set_mru_file()
endfunction
