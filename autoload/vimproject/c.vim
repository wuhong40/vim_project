" ===============================================================================
" C/C++ Setting 
" ===============================================================================

" ===============================================================================
" Globle Var
"   These vars will be source in setting files 
" ===============================================================================
function! vimproject#c#init_setting(vp_dir)
    " == makefile 
    let g:vp_c_makefile_path = ""
    let g:vp_c_makefile_template_path = fnamemodify(g:wh_template_dir."makefile_template", ":.")
    " make argument
    let g:vp_c_makefile_make_arg = ""
    let g:vp_c_make_exec_target = ""
    let g:vp_c_make_clean_target = "clean"

    " output 
    let g:vp_c_target_dir   = "target/"
    let g:vp_c_debug_dir    = g:vp_c_target_dir."debug/"
    let g:vp_c_rel_dir      = g:vp_c_target_dir."rel/"
    let g:vp_c_exec_name    = fnamemodify(getcwd(), ":t")
    let g:vp_c_compile_mode = "debug"

    " gcc & g++
    let g:vp_c_gcc  = "gcc"
    let g:vp_c_gxx  = "g++"

    let g:vp_c_debug_c_flag   = "-Wall -ansi -pedantic -O0 -g"
    let g:vp_c_debug_cxx_flag = ""
    let g:vp_c_debug_ld_flag  = ""
    let g:vp_c_rel_c_flag     = "-Wall -ansi -pedantic -O0"
    let g:vp_c_rel_cxx_flag   = ""
    let g:vp_c_rel_ld_flag    = ""

    " include dir 
    let g:vp_c_include_dir       = ""
    let g:vp_c_lib_dir           = ""
    let g:vp_c_include_dir_local = ""
    let g:vp_c_local_libs        = ""

    " define macro 
    let g:vp_c_define_macro = ""
endfunction

function! vimproject#c#add_all_setting()
    call vimproject#setting#add_proj_setting("g:vp_c_makefile_path", "", "")
    call vimproject#setting#add_proj_setting("g:vp_c_makefile_template_path", "", "")
    call vimproject#setting#add_proj_setting("g:vp_c_makefile_make_arg", "", "")
    call vimproject#setting#add_proj_setting("g:vp_c_make_exec_target", "", "")
    call vimproject#setting#add_proj_setting("g:vp_c_make_clean_target", "", "")
    call vimproject#setting#add_proj_setting("g:vp_c_target_dir", "", "")
    call vimproject#setting#add_proj_setting("g:vp_c_debug_dir","", "@OUTPUTDIR_DEBUG@")
    call vimproject#setting#add_proj_setting("g:vp_c_rel_dir","", "@OUTPUTDIR_REL@")
    call vimproject#setting#add_proj_setting("g:vp_c_exec_name", "", "@EXECUTABLE@")
    call vimproject#setting#add_proj_setting("g:vp_c_compile_mode", "", "")
    call vimproject#setting#add_proj_setting("g:vp_c_gcc", "", "@GCC@")
    call vimproject#setting#add_proj_setting("g:vp_c_gxx", "", "@GPP@")
    call vimproject#setting#add_proj_setting("g:vp_c_debug_c_flag", "", "@DEBUG_CFLAGS@")
    call vimproject#setting#add_proj_setting("g:vp_c_debug_cxx_flag", "", "")
    call vimproject#setting#add_proj_setting("g:vp_c_debug_ld_flag", "", "")
    call vimproject#setting#add_proj_setting("g:vp_c_rel_c_flag", "", "@REL_CFLAGS@")
    call vimproject#setting#add_proj_setting("g:vp_c_rel_cxx_flag", "", "")
    call vimproject#setting#add_proj_setting("g:vp_c_rel_ld_flag", "", "")
    call vimproject#setting#add_proj_setting("g:vp_c_include_dir", "", "@GLOBAL_INC_DIR@")
    call vimproject#setting#add_proj_setting("g:vp_c_include_dir_local", "", "@LOCAL_INC_DIR@")
    call vimproject#setting#add_proj_setting("g:vp_c_lib_dir", "", "@LOCAL_LIB_DIR@")
    call vimproject#setting#add_proj_setting("g:vp_c_local_libs", "", "@LOCAL_LIBS@")
    call vimproject#setting#add_proj_setting("g:vp_c_define_macro", "", "")
    "call vimproject#setting#add_proj_setting("g:vp_c_")
endfunction

function! vimproject#c#compile()
    call s:compile()
endfunction

function! vimproject#c#clean()
    call s:clean()
endfunction

function! vimproject#c#run()
    call s:run()
endfunction

function! vimproject#c#compile_run()
    call s:compile()
    call s:run()
endfunction

function! vimproject#c#init()
    "call s:map_key_and_cmd()
    "echoerr "heee"
    call s:set_syntastic()
endfunction

function! vimproject#c#map_key_and_cmd()
    call s:map_key_and_cmd()
endfunction

function! vimproject#c#unmap_key_and_cmd()
    call s:unmap_key_and_cmd()
endfunction

"command! PUpMakefile call <SID>create_makefile(g:vp_c_makefile_template_path, g:vp_c_makefile_path)
function! s:map_key_and_cmd()
    command! PUpMakefile call <SID>create_makefile(g:vp_c_makefile_template_path, g:vp_c_makefile_path)
endfunction

function! s:unmap_key_and_cmd()
    
endfunction

function! s:get_default_makefile_path()
    return fnamemodify(vimproject#proj#get_project_dir() . "Makefile", ":.")
endfunction

function! s:make(makefile_path, target, options)
    let makefile_path = a:makefile_path
    if !filereadable(makefile_path) 
        let makefile_path =  s:create_makefile(g:vp_c_makefile_template_path, makefile_path) 
    endif
    
    let make_cmd = "make -f ".makefile_path." ".a:target." ".a:options
    echo "Make Cmd: ".make_cmd."\n"
    echo "Execute Program Path: ".fnamemodify(g:vp_c_target_dir."".g:vp_c_exec_name, ":.")."\n"
    echo "--------------------- Make Output ----------------\n"
    execute make_cmd
    echo "----------------------- END -----------------------\n"
endfunction

function! s:compile()
    call s:make(g:vp_c_makefile_path, g:vp_c_make_exec_target, g:vp_c_makefile_make_arg)
endfunction

function! s:clean()
    call s:make(g:vp_c_makefile_path, g:vp_c_make_clean_target, "")
endfunction

function! s:rebulid()
    call s:clean()
    call s:compile()
endfunction

function! s:run()
    call system(g:vp_c_target_dir."".g:vp_c_exec_name)
endfunction
function! s:get_inc_dir_list()
    let inc_dirs=[]
    let file_list=[]

    let file_list = vimproject#proj#get_proj_file_list()
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

function! s:set_syntastic()
    let inc_dirs = s:get_inc_dir_list()
    let g:syntastic_cpp_include_dirs=inc_dirs
    let g:syntastic_c_include_dirs=inc_dirs
endfunction

function! s:create_makefile(template_file, makefile_path)
    if !filereadable(a:template_file) | echoerr "Makefile template_file no exist!" | return | endif

    let makefile_path = a:makefile_path
    if !filereadable(makefile_path) 
        let makefile_path = s:get_default_makefile_path()
    endif
    
    "echoerr a:template_file." ".a:makefile_path
    " copy the template_file 
    call writefile(readfile(a:template_file), makefile_path)
    "echoerr a:template_file." ".makefile_path

    for setting in keys(g:vp_proj_setting_dict)
        let value   = g:vp_proj_setting_dict[setting]["value"]
        let rep_str = g:vp_proj_setting_dict[setting]["other"]
        "echoerr rep_str
        if rep_str == '' | continue | endif
        "echoerr value."___".rep_str
        call vimproject#common#replace_str(rep_str, value, makefile_path)
    endfor

    " create src file list 
    let src_files = ""
    let file_list = vimproject#proj#get_proj_file_list()

    " read proj file list 
    for file in file_list
        if filereadable(file)
            let file =fnamemodify(file, ":.")
            if file =~# ".\.c$" || file =~# ".\.cpp$"
                let src_files = src_files." ".file
            endif
        endif
    endfor

    call vimproject#common#replace_str("@SOURCES@",      src_files,       makefile_path)

    return makefile_path
endfunction
