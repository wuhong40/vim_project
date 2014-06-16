let g:proj_buf_list = []

function! s:find_buf(buf)
    let buf_path = fnamemodify(a:buf, ":p")

    let idx = 0
    for buf in g:proj_buf_list

        if fnamemodify(buf, ":p") == buf_path
            return idx
        endif

        let idx = idx + 1
    endfor

    return -1
endfunction

function! s:add_buf(buf_path)
    if !filereadable(a:buf_path)
        return
    endif

    let buf_idx = s:find_buf(a:buf_path)
    if buf_idx != -1
        call remove(g:proj_buf_list, buf_idx)
    endif

    call insert(g:proj_buf_list, a:buf_path)
endfunction

function! VimProjGetBufList(pattern)
    let buf_list = []

    for buf in g:proj_buf_list
        if fnamemodify(buf, ":t") =~ a:pattern
            call add(buf_list, buf)
        endif
    endfor

    return buf_list
endfunction

function! VimProjBufEnter()
    let buf_name = bufname("%")

    call s:add_buf(fnamemodify(buf_name, ":p"))
endfunction

function! VimProjBufInit()
    let buf_nr = bufnr("$")

    let buf_idx = 0
    while buf_idx < buf_nr
        call s:add_buf(bufname(buf_idx))

        let buf_idx = buf_idx + 1
    endwhile
endfunction
