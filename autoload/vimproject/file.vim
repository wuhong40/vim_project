" ==============================================================================
" Files Manage
"  Date: 2012-09-20 23:00:06
" ==============================================================================

" ==============================================================================
" The Interface
" ==============================================================================
let s:oper_add = 1
let s:oper_del = 2

"let g:exclude_dir = [".vimproject", ".git", ".svn"]
let g:exclude_dir = ["*.vimproject", "*.git", "*.svn", "*.doc", "*.docx", "*.zip", "*.rar"]
let g:include_file_type = ["*.c", "*.h", "*.cpp", "*.vim", "*.java"] 
"let g:include_file_type = []
" = ["c", "cpp", "h"]

function! vimproject#file#load_list(file_list_path)
	if filereadable(a:file_list_path)
		return readfile(a:file_list_path)
	else 
		return []
	endif
endfunction

function! vimproject#file#add_path(file_list_path, path)
	let file_list = vimproject#file#load_list(a:file_list_path)

	call vimproject#file#add_path_to_list(file_list, a:path)

	call vimproject#file#save_file_list(file_list, a:file_list_path)
endfunction

function! vimproject#file#del_path(file_list_path, path)
	let file_list = vimproject#file#load_list(a:file_list_path)

	call vimproject#file#del_path_from_list(file_list, a:path)

	call vimproject#file#save_file_list(file_list, a:file_list_path)
endfunction

function! vimproject#file#save_file_list(file_list, file_list_path)
	call writefile(a:file_list, a:file_list_path)
endfunction

function! vimproject#file#add_path_to_list(file_list, path)
	return s:path_oper(a:file_list, a:path, s:oper_add)
endfunction

function! vimproject#file#del_path_from_list(file_list, path)
	return s:path_oper(a:file_list, a:path, s:oper_del)
endfunction

function! vimproject#file#is_file_include(file_list_path, file_path)
	if !filereadable(a:file_path) | return 1 | endif

	let file_list = []
	if filereadable(a:file_list_path) | let file_list = readfile(a:file_list_path) | endif

	for file in file_list
		if file == a:file_path 
			return 1
		endif
	endfor

	return 0
endfunction

" ==============================================================================
" File Operation Function
" ==============================================================================
function! s:path_oper(file_list, path, oper)
    if filereadable(a:path) "It's a file 
		call s:file_oper(a:file_list, a:path, a:oper)
	elseif isdirectory(a:path) "It's a directory 
		call s:dir_oper(a:file_list, a:path, a:oper)
	endif
endfunction

function! s:file_oper(file_list, file, oper)
	if a:oper == s:oper_add 
		call s:add_file_to_list(a:file_list, a:file)
	elseif a:oper == s:oper_del
		call s:del_file_from_list(a:file_list, a:file)
	endif
endfunction

function! s:dir_oper(file_list, dir, oper)
	if a:oper == s:oper_add 
		call s:add_dir_to_list(a:file_list, a:dir)
	elseif a:oper == s:oper_del 
        "echoerr a:oper
        "return
		call s:del_dir_from_list(a:file_list, a:dir)
	endif
endfunction

function! s:file_remove_same_file(file_list)
    call sort(a:file_list)

    let len = len(a:file_list)
    let idx = len - 1

    while idx >= 0 
        if isdirectory(a:file_list[idx])
            call remove(a:file_list, idx, idx)
        elseif idx - 1 >= 0
            if a:file_list[idx] == a:file_list[idx - 1] 
                call remove(a:file_list, idx, idx)
            endif
        endif

        let idx = idx - 1
    endwhile
endfunction

function! s:add_file_to_list(file_list, file)
    if isdirectory(a:file) | return | endif
    call insert(a:file_list, a:file)
    call s:file_remove_same_file(a:file_list)
	"echo a:file_list
endfunction

function! s:add_dir_to_list(file_list, dir)
	"let dir_file_list = s:get_dir_file_list(a:dir, [], [])
	let dir_file_list = s:get_dir_file_list(a:dir, g:exclude_dir, g:include_file_type) 
	let dir_file_list = map(dir_file_list, fnamemodify('v:val', ":."))

	call extend(a:file_list, dir_file_list)
	call s:file_remove_same_file(a:file_list)
endfunction

function! s:del_file_from_list(file_list, file)
    let len = len(a:file_list)
    let idx = len - 1

    while idx >= 0 
        if a:file_list[idx] == a:file
            call remove(a:file_list, idx, idx)
        endif

        let idx = idx - 1
    endwhile
endfunction

function! s:del_dir_from_list(file_list, dir)
	let dir_file_list = s:get_dir_file_list(a:dir, g:exclude_dir, g:include_file_type) 
	let dir_file_list = map(dir_file_list, fnamemodify('v:val', ":."))
	
	for file in dir_file_list
		call s:del_file_from_list(a:file_list, file)
	endfor
endfunction

" get dir file list{{{1
function! s:get_dir_file_list(dir_path, ignore_dir_list, include_file_type_list)
	let file_list = []
	if !isdirectory(a:dir_path) | return file_list | endif

    let temp_file_name = vimproject#proj#get_project_dir().".temp_file_list"
    let cmd = g:wh_find_cmd." ".a:dir_path

    " construct cmd
    let len = len(a:ignore_dir_list)
    if len > 0
        let cmd = cmd . " \\("
        let idx = 1
        for ignore in a:ignore_dir_list
            let cmd = cmd." -path '".ignore."'"
            if idx < len 
                let cmd = cmd." -o "
            endif
            let idx += 1
        endfor
        let cmd = cmd . " \\) -prune"
    endif

    let len = len(a:include_file_type_list)
    if len > 0
        if len(a:ignore_dir_list) > 0
            let cmd = cmd . " -o "
        endif
        let cmd = cmd . " \\("
        let idx = 1
        for inc_type in a:include_file_type_list
            let cmd = cmd." -name '".inc_type."'"
            if idx < len 
                let cmd = cmd." -o "
            endif
            let idx += 1
        endfor
        let cmd = cmd . " \\)"
    endif

    let cmd = cmd . " -type f -print"

    let cmd = cmd." > ".temp_file_name

    call system(cmd)

    let file_list = readfile(temp_file_name)

    call delete(temp_file_name)
    return file_list
endfunction
"}}}

" vim:fen:fdm=marker:fmr={{{,}}}:fdl=0:fdc=1
