" ==============================================================================
" Cscope & Ctags
" ==============================================================================
let s:ctags_cmd 	= g:wh_ctags_cmd." --c++-kinds=+px --fields=+ialS --extra=+q --excmd=number --if0=yes -L "
let s:cscope_cmd 	= g:wh_cscope_cmd." -bkq -i "

function! vimproject#tags#update_ctags_cscope(file_list_path, tags_name, cscope_name)
    " change file path to abs path
    if filereadable(a:file_list_path)
    	let temp_file_path = '.temp_file'

        let file_list = readfile(a:file_list_path)
        let idx = 0
        for file in file_list
            let file_list[idx] = fnamemodify(file, ":p")
            let idx += 1
        endfor

        call writefile(file_list, temp_file_path)

        call s:gen_ctags(temp_file_path, a:tags_name)
        call s:gen_cscope(temp_file_path, a:cscope_name)

        call s:reset_ctag_connect(a:tags_name)
        call s:reset_cscope_connect(a:cscope_name)

        call delete(temp_file_path)
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

function vimproject#tags#reset_ctag_connect(tags_name)
    return s:reset_ctag_connect(a:tags_name)
endfunction

function! s:reset_ctag_connect(tag_name)
    let tag_name = fnamemodify(a:tag_name, ":p")
    if filereadable(tag_name)
        silent! execute "set tags-=".tag_name 
        silent! execute "set tags+=".tag_name
    endif
endfunction

function vimproject#tags#reset_cscope_connect(cscope_name)
    return s:reset_cscope_connect(a:cscope_name)
endfunction

function! s:reset_cscope_connect(cscope_name)
    let cscope_name = fnamemodify(a:cscope_name, ":p")
    if has("cscope")
        silent! execute "cs kill ".cscope_name
        if filereadable(a:cscope_name)
            silent! execute "cs add ".cscope_name
        endif
    endif
endfunction
