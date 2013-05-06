" ===============================================================================
" Project Setting
" ===============================================================================

" 

function! vimproject#setting#init_proj_setting(proj_type, proj_dir)
    execute "call vimproject#".a:proj_type."#init_setting('".a:proj_dir."')"
endfunction

function! vimproject#setting#source(setting_file)
    let setting_list = readfile(a:setting_file)
    for setting in setting_list
        execute setting
    endfor
endfunction

function! vimproject#setting#add_proj_setting(var_str, comment, other)
    call s:add_setting_to_dict(g:vp_proj_setting_dict, a:var_str, a:comment, a:other)
endfunction

function! s:add_setting_to_dict(dict, var_str, comment, other)
    exe "let a:dict['".a:var_str."'] = {}"

    exe "let a:dict['".a:var_str."']['value']   = ".a:var_str
    exe "let a:dict['".a:var_str."']['comment'] = '".a:comment."'"
    exe "let a:dict['".a:var_str."']['other']   = '".a:other."'"
endfunction


function! vimproject#setting#save(proj_type, setting_file)
    call s:add_all_common_setting()
    execute "call vimproject#".a:proj_type."#add_all_setting()"

    " save the common setting
    call s:save_common_setting(a:setting_file)
    " save the project special setting 
    call s:save_proj_setting(a:proj_type, a:setting_file)
endfunction

function! s:add_all_common_setting()
    call s:add_setting_to_dict(g:vp_common_setting_dict, "g:vp_proj_type", "", "")   
endfunction

function! s:save_common_setting(setting_file)
    let setting_list = []
    call add(setting_list, "\"==================== Vim Project Setting File ====================")
    call add(setting_list, "\"\t\tAuthor: Wu Hong")
    call add(setting_list, "\"\t\tE-mail: wuhong400@gmail.com")
    call add(setting_list, "\"\tLast Modify Time: ".strftime("%Y-%m-%d %T"))
    call add(setting_list, "\"==================================================================")
    call add(setting_list, "")

    call add(setting_list, "\"========================= Common Setting =========================")
    for setting in keys(g:vp_common_setting_dict)
        "call add(setting_list, "let ".setting." = '".s:common_setting_dict[setting]."'")
        call s:add_setting_to_str_list(setting_list, setting, g:vp_common_setting_dict)
    endfor
    call add(setting_list, "")

    call writefile(setting_list, a:setting_file)
endfunction

function! s:add_setting_to_str_list(list, setting, setting_dict)
    call add(a:list, "\" ".a:setting_dict[a:setting]["comment"])
    call add(a:list, "let ".a:setting." = '".a:setting_dict[a:setting]["value"]."'")
endfunction

function! s:save_proj_setting(proj_type, setting_file)
    let setting_list = []
    if filereadable(a:setting_file) | let setting_list = readfile(a:setting_file) | endif

    call add(setting_list, "\"========================= ".a:proj_type." Setting =========================")
    for setting in keys(g:vp_proj_setting_dict)
        "call add(setting_list, "let ".setting." = '".s:proj_setting_dict[setting]."'")
        call s:add_setting_to_str_list(setting_list, setting, g:vp_proj_setting_dict)
    endfor
    call add(setting_list, "")

    call writefile(setting_list, a:setting_file)
endfunction


