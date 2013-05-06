" ===============================================================================
" Compile & Run 
" ===============================================================================

function! vimproject#compile#compile()
	execute "call vimproject#".g:vp_proj_type."#compile()"
endfunction

function! vimproject#compile#run()
    
endfunction

function! vimproject#compile#compile_and_run()
    
endfunction

function! vimproject#compile#clean()
    
endfunction

function! vimproject#compile#rebulid()
    
endfunction

" Map Key & Command
" Map PCompile/PRun/PClean/PCompileAndRun/PReBuild ...
function! vimproject#compile#map_key_and_cmd()
	command PCompile 		call vimproject#compile#compile()
	command PRun 	 		call vimproject#compile#run()
	command PClean 	 		call vimproject#compile#clean()
	command PReBuild 		call vimproject#compile#rebulid()
	command PCompileAndRun 	call vimproject#compile#compile_and_run()
endfunction

function! vimproject#compile#unmap_cmd()
	delcommand PCompile 		
	delcommand PRun 	 		
	delcommand PClean 	 		
	delcommand PReBuild 		
	delcommand PCompileAndRun 	
endfunction
