
let g:vp_proj_vim_dir   = g:wh_temporary_dir."vimproject/"
let s:vp_proj_list_file = g:vp_proj_vim_dir."proj_list_file"
let s:vp_proj_list_max_cnt = 20

" Print project list
function! s:print_project_list(proj_list)
    echo "------------ Project List -------------------\n"
    echo "\t\tVersion: ".s:vp_version."\n"
    echo "\n"

    if len(a:proj_list) == 0
        echohl "!!! The project list is null !!!"
        return
    endif

    echo "idx\tType\tName\tPath"
    let idx = 1
    for proj in a:proj_list
        echo idx."\t".proj["type"]."\t".proj["name"]."\t"proj["path"]
    endfor
endfunction

function! s:load_proj_list()
    let proj_list = s:get_project_list(s:vp_proj_list_file)
    call s:print_project_list(proj_list)

    if len(proj_list) != 0
        echo "Please choose the project, enter the idx:"
    endif
endfunction

function! vimproject#proj_list#add_proj(name, path, type)
    call s:proj_list_add(a:name, a:path, a:type, s:vp_proj_list_file)
endfunction

function! s:proj_list_add(name, path, type, proj_list_path)
    " search if the proj already
    let proj_list = s:get_project_list(a:proj_list_path)
    let path = fnamemodify(a:path, ":p")
    let idx = 0
    for proj in proj_list
        if path == fnamemodify(proj["path"], ":p")
            "remove it 
            call remove(proj_list, idx, idx)
        endif
        let idx = idx + 1
    endfor

    " add it 
    call insert(proj_list, {"name":a:name, "path":path, "type":a:type})
    "echoer proj_list
    call s:proj_list_save(a:proj_list_path, proj_list)
endfunction


function! s:proj_list_save(proj_list_path, proj_list)
    let file_list = []

    for proj in a:proj_list
        call insert(file_list, proj["type"])
        call insert(file_list, proj["path"])
        call insert(file_list, proj["name"])
    endfor
    
    call writefile(file_list, a:proj_list_path)
endfunction

" Load project list from a:proj_list_file
" Project return {Name, Path}
function! s:get_project_list(proj_list_file)
    if !isdirectory(g:vp_proj_vim_dir)
        call mkdir(g:vp_proj_vim_dir, "", 0700)
    endif

    let proj_list = []

    if filereadable(a:proj_list_file)
        let content_list = readfile(a:proj_list_file)
    else 
        let content_list = []
    endif

    let idx = 0
    let len = len(content_list)
    while idx < len && (idx + 1) < len && (idx + 2) < len
        let name = content_list[idx]
        let path = content_list[idx + 1]
        let type = content_list[idx + 2]

        if isdirectory(path) && isdirectory(path."/".vimproject#proj#get_proj_dir_name())
            call insert(proj_list, {"name":name, "path":path, "type":type})
        endif
        let idx = idx + 3
    endwhile

    return proj_list
endfunction
