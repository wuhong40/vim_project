" ==============================================================================
"                           VIM Project Plugin
" Version:  3.0
" Author:   Wu Hong 
" Email:    wuhong400@gmail.com
" Date:     2012-04-02
" ==============================================================================
finish

" setting 
let s:vp_working_directory   = getcwd()
let s:vp_proj_directory_name = ".vimproject"
let s:vp_proj_directory      = fnamemodify(s:vp_working_directory, ":p")."".s:vp_proj_directory_name."/"
let s:vp_proj_type           = "c"
let s:proj_name              = fnamemodify(s:vp_working_directory, ":t")

let s:vp_version             = "3.0"

let s:nerd_bookmarks      = s:vp_proj_directory."nerd_bookmarks"
let s:yank_history_file   = s:vp_proj_directory."yankring_history"
let s:proj_attr_path      = s:vp_proj_directory."proj_attr.vim"
let s:makefile_path       = s:vp_proj_directory."Makefile"
"let g:ctrlp_bookmark_file = s:nerd_bookmarks

let s:is_check_syntastic  = "1"

let s:makefile_template   = g:wh_template_dir."makefile_template"
" compile setting 
let s:target_mode_debug  = "debug"
let s:target_mode_rel    = "release"
let s:target_mode        = s:target_mode_debug
let s:target_dir         = s:vp_working_directory."/target/"
let s:target_debug_dir   = s:target_dir."".s:target_mode_debug
let s:target_release_dir = s:target_dir."".s:target_mode_rel
let s:inc_dir_globle     = ""
let s:inc_dir_local      = ""
let s:exe_name           = s:proj_name
let s:exe_path           = ""
let s:libs_local         = ""
let s:lib_dir_local      = ""
let s:compiler_gcc       = "gcc"
let s:compiler_gpp       = "g++"
"let s:cmd_line           = ""
let s:gcc_dbg_flags      = "-Wall -ansi -pedantic -O0 -g"
let s:gcc_rel_flags      = "-Wall -ansi -pedantic -O0"
let s:make_cmd           = "make -f ".s:makefile_path
let s:run_paras          = ""

let s:op_add    = "add"
let s:op_del    = "del"
let s:list_read = "read"
let s:list_edit = "edit"

let g:vp_file_ignore_dir =[".svn", ".git"] 
let g:vp_file_include_list = ["*.h", "*.c", "*.cpp", "*.java", "*.cs", "*.cxx", "*.hxx"]

let g:ctags_cmd = g:wh_ctags_cmd." --c++-kinds=+px --fields=+ialS --extra=+q --excmd=number --if0=yes -L "
let g:cscope_cmd = g:wh_cscope_cmd." -bkq -i "

let s:proj_types = {
            \"c":       "c or c++ project",
            \"kernel":  "linux kernel project",
            \"python":  "python project",
            \"java":    "java project",
            \"lua":     "lua project",
            \"vim":     "vim srcipt project",
            \}
"command! Dbg call <SID>manage_proj_file(".", "edit", "add")
"command! Dbg call <SID>update_ctag_cscope_edit()
"command! Dbg call <SID>gen_makefile()
"command! Dbg call <SID>get_buf_list()


" ==============================================================================
"           Project Manage Functions 
" ==============================================================================

" Create project wizard {{{1
" step 1: select working directory 
function! s:select_working_directory(...)

    if a:0 == 0 " No argument , set current directory
        let old_dir = fnamemodify(getcwd(), ":p")
    else 
        let old_dir = a:1
    endif


    echo "Step 1: Set working directory:"
    let input_dir = input("", old_dir)

    if(!isdirectory(input_dir))
        " the directory doesn't exist 
        redraw
        echo "Error: The directory doesn't exist! "
        echo " Do you want to create directory: ".input_dir."?"
        echo " (Y/n)"
        if(nr2char(getchar()) ==# "Y")
            if(!mkdir(input_dir, "p"))
                redraw
                echo "Error: Faile to create directory!"
                call s:select_working_directory(input_dir)
            endif
        else  "Don't want create new directory, re-do
            call s:select_working_directory(input_dir)
        endif
    endif

    return  input_dir
endfunction

" step 2: choose proj type
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

function! s:create_project()
    let s:vp_working_directory = s:select_working_directory()
    let s:vp_proj_type = s:choose_proj_type()

    "echoerr s:vp_working_directory
    execute "cd ".s:vp_working_directory

    " create vim project directory under working directory 
    let s:vp_proj_directory = fnamemodify(s:vp_working_directory, ":p")."".s:vp_proj_directory_name
    if !create_proj_dir()
        echoerr " create proj directory failed!"
    else 
        echo "Finish! Press any key to continue!"
    endif
    "call s:choose_proj_type()
endfunction
"}}}

function! s:is_project()
    if isdirectory(s:vp_proj_directory)
        return 1
    endif

    return 0
endfunction
" Load recent projects
" Load project 
function! VimProjectLoad()
    return s:proj_load()
endfunction

function! s:proj_load()
    if s:is_project() != 1
        return 
    endif 
    "call s:source_proj_attr()
    " load tags 
    if filereadable(s:tags_edit)
        call vimproject#common#reset_ctag_connect(s:tags_edit)
    endif
    if filereadable(s:tags_read)
        call vimproject#common#reset_ctag_connect(s:tags_read)
    endif

    " load cscope
    if has("cscope")
        " add any database in current directory
        if filereadable(s:cscope_edit)
            silent! execute "cs add ".s:cscope_edit
        endif
        if filereadable(s:cscope_read)
            silent! execute "cs add ".s:cscope_read
        endif
    endif

    
    call s:source_proj_setting()
    call s:set_nerd_bookmark()
    call s:set_yank_history()
    call s:set_loc_inc()
    call s:set_ctrlp_user_cmd()
    call s:set_syntastic()

    call s:open_vim()
endfunction
" Close project
" Save project 
" Project Setting 
function! s:proj_setting()
    call s:save_proj_setting()
    execute "e ".s:proj_setting_file
endfunction
function! s:source_proj_setting()
    if filereadable(s:proj_setting_file)
        "execute "source ".s:proj_setting_file
        let setting_list = readfile(s:proj_setting_file)
        for setting in setting_list
            execute setting
        endfor
        call s:gen_makefile()
    endif
endfunction
function! s:save_proj_setting()
    let setting_list = []

    call add(setting_list,"\"===========================================================")
    call add(setting_list,"\"          VIM Project Setting File ")
    call add(setting_list,"\"      Version:  ".s:vp_version)  
    call add(setting_list,"\"      Author:   Wu Hong ")
    call add(setting_list,"\"      Email:    wuhong40@163.com")
    call add(setting_list,"\"")
    call add(setting_list,"\"      Type:    ".s:proj_types[s:get_proj_type()])
    call add(setting_list,"\"===========================================================")
    call add(setting_list, "")

    call s:add_setting(setting_list, "s:is_check_syntastic", "")

    "if exists("s:add_proj_setting_".s:get_proj_type())
        execute "call s:add_proj_setting_".s:get_proj_type()."(setting_list)"
    "endif

    call writefile(setting_list, s:proj_setting_file)
endfunction
" Compile 
function! s:compile(...)
    if s:is_project() != 1
        SingleCompile 
    else 
        let target = ""
        if a:0 > 0
            let target = a:1
        endif
        execute "return s:compile_".s:get_proj_type()."('".target."')"
        "echo "return s:compile_".s:get_proj_type()."('".target."')"
    endif
endfunction
" Run target
function! s:run()
    execute "return s:run_".s:get_proj_type()."()"
endfunction
" Compile & Run 
function! s:compile_and_run()
    if s:is_project()
        call s:compile() 
        call s:run()
    else 
        SingleCompileRun 
    endif
endfunction
" Clean 
function! s:clean()
    if exists("s:clean_c".s:get_proj_type())
        execute "return s:clean_".s:get_proj_type()."()"
    else 
        call s:compile("clean")
    endif
endfunction
" Rebuild
function! s:rebuild()
    call s:clean()
    call s:compile()
endfunction
" Generate Makefile
function! s:gen_makefile()
    let fn_name = "s:gen_makefile_".s:get_proj_type()
    "if exists("s:gen_makefile_".s:get_proj_type())
        execute "return s:gen_makefile_".s:get_proj_type()."()"
    "endif
endfunction

function! s:leave_vim()
    if s:is_project() != 1 
        return 
    endif

    call vimproject#common#save_sesseion(s:session_path)
endfunction

function! s:open_vim()
    if s:is_project() != 1 
        return 
    endif

    call vimproject#common#source_session(s:session_path)
endfunction

function! s:do_after_write_file()
    if s:is_project() == 1 
        call s:auto_update_edit()
        call s:set_syntastic()
        "call s:save_proj_setting()
    endif
endfunction

function! s:auto_update_edit()
    if s:is_project() == 1 
        call s:update_ctag_cscope_edit()
    endif
endfunction

function! s:update_ctag_cscope_read()
    call vimproject#common#update_ctag_cscope(s:proj_files_read, s:tags_read, s:cscope_read)
endfunction

function! s:update_ctag_cscope_edit()
    call vimproject#common#update_ctag_cscope(s:proj_files_edit, s:tags_edit, s:cscope_edit)
endfunction

" Add path to project 
function! s:manage_proj_file(path, file_list_type, op)
    let file_list       = ""
    let file_list_other = ""

    if a:file_list_type == s:list_edit
        let file_list       = s:proj_files_edit
        let file_list_other = s:proj_files_read
    elseif a:file_list_type == s:list_read
        let file_list       = s:proj_files_read
        let file_list_other = s:proj_files_edit
    else 
        return 0
    endif

    if a:op == s:op_add
        call s:add_path(a:path, file_list)
        call vimproject#common#del_path(a:path, file_list_other)
    else 
        call vimproject#common#del_path(a:path, file_list)
        call vimproject#common#del_path(a:path, file_list_other)
    endif

    call s:do_after_update_file_list()
endfunction

function! s:add_path(file_path, file_list_path)
    call s:create_proj_dir()
    call vimproject#common#add_path(a:file_path, a:file_list_path)
endfunction

function! s:add_setting(setting_list, var, comment)
    call add(a:setting_list, "\"".a:comment)
    exe "call add(a:setting_list,\"let ".a:var."='\".".a:var.".\"'\")"
endfunction

" Save project sesseion 
" Get/Set project attruibutes
" Set CtrlP 
function! s:set_ctrlp_user_cmd()
    let g:ctrlp_user_command = 'echo %s > /dev/null '

    if filereadable(s:proj_files_edit)
        let g:ctrlp_user_command = g:ctrlp_user_command . " & cat ".s:proj_files_edit
    endif 

    if filereadable(s:proj_files_read)
        let g:ctrlp_user_command = g:ctrlp_user_command . " & cat ".s:proj_files_read
    endif 

    let g:ctrlp_working_path_mode = 0

    if ( exists('g:loaded_ctrlp') && g:loaded_ctrlp ) || v:version < 700 || &cp
        CtrlPReload
    endif
endfunction

function! s:set_syntastic()
    if exists("g:loaded_syntastic_plugin")
        if s:is_check_syntastic == "1"
            SyntasticOpen 
        else 
            SyntasticClose 
        endif
    endif
endfunction

function! s:set_nerd_bookmark()
    call vimproject#common#set_nerd_bookmarks(s:vp_proj_directory, s:nerd_bookmarks)
endfunction

function! s:set_yank_history()
    let g:yankring_history_file = s:yank_history_file
endfunction

" common function {{{
function! s:get_proj_type()
    return s:vp_proj_type
endfunction

function! s:create_proj_dir()
    if isdirectory(s:vp_proj_directory_name)==0
        call mkdir(s:vp_proj_directory_name, "p")
        let s:vp_proj_type = s:choose_proj_type()
        call s:save_proj_setting()
            "if(!mkdir(input_dir, "p"))
    endif
endfunction

function! s:check_proj_file()
    if filereadable(s:proj_files_edit)
        let file_list = readfile(s:proj_files_edit)
        let idx = 0
        for file in file_list
            if !filereadable(file)
                call remove(file_list, idx)
            else 
                let idx += 1
            endif
        endfor
        call writefile(file_list, s:proj_files_edit)
    endif

    if filereadable(s:proj_files_read)
        let file_list = readfile(s:proj_files_read)
        let idx = 0
        for file in file_list
            if !filereadable(file)
                call remove(file_list, idx)
            else 
                let idx += 1
            endif
        endfor
        call writefile(file_list, s:proj_files_read)

    endif
endfunction

function! s:do_after_update_file_list()
    call s:update_ctag_cscope_edit()
    call s:set_ctrlp_user_cmd()
    call s:set_loc_inc()
    call s:gen_makefile()
endfunction



" }}}

" ==============================================================================
"  C & CPP Project Functions
" ==============================================================================
" Init 
function! s:init_c()
endfunction
" attruibutes 
function! s:proj_setting_c()
    " set Makefile path
endfunction
function! s:compile_c(target)
    "echoerr "Msg:".a:target."__".s:makefile_path
    if !filereadable(s:makefile_path)
        call s:gen_makefile()
    endif
    execute s:make_cmd." ".a:target
endfunction

function! s:run_c()
    let s:exe_path = s:target_dir."".s:target_mode."/".s:exe_name
    "echo s:exe_path
    "execute "!".s:exe_path." ".s:run_paras
    echo system(s:exe_path." ".s:run_paras)
endfunction

"function! s:compile_and_run_c(...)
    "execute s:make_cmd." EXE_START=yes"
"endfunction

function! s:get_inc_dir_list()
    let inc_dirs=[]
    let file_list=[]
    if filereadable(s:proj_files_edit)
        call extend(file_list, readfile(s:proj_files_edit))
    endif
    if filereadable(s:proj_files_read)
        call extend(file_list, readfile(s:proj_files_read))
    endif

    for file in file_list
        if file =~ ".h$"
            call add(inc_dirs, fnamemodify(file, ':.:h'))
        endif
    endfor

    call sort(inc_dirs)
    let temp_dir = ""
    let idx = 0
    for dir in inc_dirs 
        if dir == temp_dir " remove the same dir
            call remove(inc_dirs, idx)
        elseif dir == '.'  " it is current dir, no need to add
            call remove(inc_dirs, idx)
        else 
            let temp_dir = dir
            let idx = idx + 1
        endif
    endfor

    return inc_dirs
endfunction

function! s:set_loc_inc()
    let inc_dirs = s:get_inc_dir_list()
    let g:syntastic_cpp_include_dirs=inc_dirs
    let g:syntastic_c_include_dirs=inc_dirs

    let s:inc_dir_local = ""
    for dir in inc_dirs
        let s:inc_dir_local = s:inc_dir_local." ".dir
    endfor
endfunction

function! s:add_proj_setting_c(setting_list)
    call s:add_setting(a:setting_list, "s:exe_name", "executable program name")
    call s:add_setting(a:setting_list, "s:run_paras", "the argument when run program")
    call s:add_setting(a:setting_list, "s:make_cmd", "make command")
    call s:add_setting(a:setting_list, "s:compiler_gcc", "c compiler")
    call s:add_setting(a:setting_list, "s:compiler_gpp", "c++ compiler")
    call s:add_setting(a:setting_list, "s:gcc_dbg_flags", "gcc debug flags")
    call s:add_setting(a:setting_list, "s:gcc_rel_flags", "gcc release flags")
    call s:add_setting(a:setting_list, "s:inc_dir_globle", "globle include directory")
    call s:add_setting(a:setting_list, "s:lib_dir_local", "the library directory")
    call s:add_setting(a:setting_list, "s:libs_local", "the local librarys")
endfunction

function! s:gen_makefile_c()
    " copy the template
    let makefile = readfile(s:makefile_template)
    call writefile(makefile, s:makefile_path)

    call s:set_loc_inc()

    " replace the var
    call vimproject#common#replace_str("@EXECUTABLE@",      s:exe_name,             s:makefile_path)
    call vimproject#common#replace_str("@OUTPUTDIR_DEBUG@", s:target_debug_dir,     s:makefile_path)
    call vimproject#common#replace_str("@OUTPUTDIR_REL@",   s:target_release_dir,   s:makefile_path)
    call vimproject#common#replace_str("@GLOBAL_INC_DIR@",  s:inc_dir_globle,       s:makefile_path)
    call vimproject#common#replace_str("@LOCAL_INC_DIR@",   s:inc_dir_local,        s:makefile_path)
    call vimproject#common#replace_str("@LOCAL_LIB_DIR@",   s:lib_dir_local,        s:makefile_path)
    call vimproject#common#replace_str("@LOCAL_LIBS@",      s:libs_local,           s:makefile_path)
    call vimproject#common#replace_str("@GCC@",             s:compiler_gcc,         s:makefile_path)
    call vimproject#common#replace_str("@GPP@",             s:compiler_gpp,         s:makefile_path)
    call vimproject#common#replace_str("@DEBUG_CFLAGS@",    s:gcc_dbg_flags,        s:makefile_path)
    call vimproject#common#replace_str("@REL_CFLAGS@",      s:gcc_rel_flags,        s:makefile_path)

    " create src file list 
    let src_files = ""
    if filereadable(s:proj_files_edit)
        " read proj file list 
        for line in readfile(s:proj_files_edit, '')
            if filereadable(line)
                let line=fnamemodify(line, ":.")
                if line =~# ".\.c$" || line =~# ".\.cpp$"
                    let src_files = src_files." ".line
                endif
            endif
        endfor
    endif
    call vimproject#common#replace_str("@SOURCES@",      src_files,       s:makefile_path)
endfunction

" Key map and command {{{1
map <Leader>qq :qa<CR>

command -nargs=1 -complete=file AddToProj    call <SID>manage_proj_file(<q-args>, "edit", "add")
command -nargs=1 -complete=file AddToProjRead call <SID>manage_proj_file(<q-args>, "read", "add")
command -nargs=1 -complete=file DelFromProj  call <SID>manage_proj_file(<q-args>, "edit", "del")
command -nargs=? -complete=file MakeRun      call <SID>compile_and_run()(<q-args>)
command -nargs=? -complete=file Make         call <SID>compile(<q-args>)
command ProjCheckFile               call <SID>check_proj_file()
command MakeClean               call <SID>clean()
command MakeRebuild             call <SID>rebuild()
command UpCscopeCTagRead        call <SID>update_ctag_cscope_read()
command ProjSetting             call <SID>proj_setting()
augroup VimProject
    "autocmd VimProject VimEnter * call <SID>proj_load()
    autocmd VimProject BufWritePost * call <SID>do_after_write_file()
    "autocmd VimProject BufRead,BufNewFile,BufUnload * call <SID>update_buflist()
    "autocmd VimProject BufWritePost *.cpp,*.h,*c    call MacroDefineUpdate()
    "autocmd VimProject BufEnter     *.cpp,*.h,*.c   call MacroDefineUpdate()
    autocmd VimProject BufWritePost vp_setting.vim  call <SID>source_proj_setting()
    "autocmd VimProject VimEnter * call <SID>display_all_projs()
    "autocmd VimProject VimEnter * call<SID>open_vim()
    autocmd VimProject VimLeavePre * call<SID>leave_vim()
augroup END

"call <SID>proj_load()
"}}}

" vim:fen:fdm=marker:fmr={{{,}}}:fdl=0:fdc=1
