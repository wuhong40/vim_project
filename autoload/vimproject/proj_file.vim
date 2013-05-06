let g:vp_proj_file_type_read = "read"
let g:vp_proj_file_type_edit = "edit"

"let s:proj_files = [{   "name"    :    g:vp_proj_file_type_edit,
                    "\   "info"    :    "the file often edit",
                    "\   "path"    :    "proj_edit_file",
                    "\   "list"    :    []},
                    "\{  "name"    :    g:vp_proj_file_type_read,
                    "\   "info"    :    "the file often read-only",
                    "\   "path"    :    "proj_read_file", 
                    "\   "list"    :    []}]
let s:proj_files = { g:vp_proj_file_type_edit : 
                        \ { "path" : "proj_edit_file",
                        \   "list" : []},
                    \ g:vp_proj_file_type_read :
                        \ { "path" : "proj_read_file",
                        \   "list" : []} }


" set the proj_files attr
" file_type         : the type to set, value is g:vp_proj_file_type_edit 
"                     or g:vp_proj_file_type_read
" path              : the value of attr["path"]
" file_list_path    : read the attr["list"] from "file_list_path"
function! vimproject#proj_file#set_attr(file_type, path, file_list_path)
    if !has_key(a:file_type) | echoerr " file type error" | return g:vp_failed | endif 

    if filereadable(a:file_list_path)
        let s:proj_files[a:file_type]["list"] = readfile(a:file_list_path)
    else 
        let s:proj_files[a:file_type]["list"] = []
    endif

    let s:proj_files[a:file_type]["path"] = a:path
endfunction
