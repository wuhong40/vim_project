" ============================================================================
" proj dir
" ============================================================================
function! vimproject#common#get_proj_dir()
    if exists(g:vp_proj_dir)
        return g:vp_proj_dir)
    else 
        if has("unix")
            return getcwd() . "/.vimproject/"
        else 
            return getcwd() . "\\vimproject\\"
        endif
    endif
endfunction
" ============================================================================
"  sesseion
" ============================================================================
function! vimproject#common#save_sesseion(session_file, viminfo_file)
    silent! execute "mksession! " . a:session_file
    silent! execute "wviminfo! ". a:viminfo_file
endfunction

function! vimproject#common#source_session(session_file, viminfo_file)
    if filereadable(a:session_file)
        execute "source ".a:session_file
    endif
    if filereadable(a:viminfo_file)
        silent! execute "rviminfo! ".a:viminfo_file
    endif
endfunction

" Get the main edit window nr
function! vimproject#common#get_main_edit_winnr()
    let window_count = winnr("$")
    let i = 1
    let is_found = 0

    while i <= window_count
        let is_found = 0
        for window_name in g:plgun_window_name_list
            if bufwinnr(window_name) == i 
                let is_found = 1
                break 
            endif
        endfor

        " the current window is main edit window
        if is_found == 0
            break 
        endif
        let i = i + 1
    endwhile

    return i
endfunction

function! vimproject#common#replace_str(oldstr, newstring, file)
    if filereadable(a:file)
        let file_line_list = readfile(a:file)
        let i   = 0
        let len = len(file_line_list)
        while i < len
            let line = file_line_list[i]
            if line =~# a:oldstr
                let line = substitute(line, a:oldstr, a:newstring, "g")
                let file_line_list[i] = line
            endif
            let i = i + 1
        endwhile
        call writefile(file_line_list, a:file)
    endif
endfunction


" vim:fen:fdm=marker:fmr={{{,}}}:fdl=0:fdc=1
