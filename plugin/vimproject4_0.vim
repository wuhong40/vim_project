" ==============================================================================
"                           VIM Project Plugin
" Version:  4.0
" Author:   Wu Hong
" Email:    wuhong400@gmail.com
" Date:     2012-09-18
" ==============================================================================

" ==============================================================================
" Globle var
" ==============================================================================
let g:vp_auto_add_file = 1

" ==============================================================================
" Define the macro var
" ==============================================================================
let g:vp_ok 	= 0
let g:vp_failed = 1
let g:vp_true 	= 1
let g:vp_false  = 0

let g:vp_proj_setting_dict = {}
"let g:vp_proj_setting_dict = { "proj_type":{ "value":c,"comment":"the project type", "other":"the extra info"} ,
                                "\"proj_create_time":"2012-10-08 19:31",
                                \}
let g:vp_common_setting_dict = {}

" ==============================================================================
" Project List Manage
" ==============================================================================

"nmap <F9> :call <SID>load_proj_list()<CR>


" ==============================================================================
" Project Setting
" ==============================================================================

" ==============================================================================
" Cscope & Ctags
" ==============================================================================


"function! s:set_syntastic_c_include_dirs()
    "let inc_dirs = s:get_inc_dir_list()
    "let g:syntastic_cpp_include_dirs    =   inc_dirs
    "let g:syntastic_c_include_dirs      =   inc_dirs
"endfunction

"map <F9> call vimproject#proj#source_session()<CR>
augroup VimProject
    "autocmd VimProject VimEnter *       call vimproject#proj#load_proj("./")
    autocmd VimProject BufWritePost *   call vimproject#proj#do_after_write_file()
    autocmd VimProject VimLeavePre *    call vimproject#proj#unload_proj("./")
    "autocmd VimProject BufWritePost vp_setting.vim  call <SID>source_proj_setting()
    "autocmd VimProject VimLeavePre * call<SID>leave_vim()
augroup END
call vimproject#proj#load_proj("./")
