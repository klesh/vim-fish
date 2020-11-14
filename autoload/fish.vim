function! fish#Indent()
    let l:lnum = line('.')
    let l:shiftwidth = shiftwidth()
    let l:prevlnum = prevnonblank(l:lnum - 1)
    if l:prevlnum ==# 0
        return 0
    endif
    let l:indent = 0
    let l:prevline = getline(l:prevlnum)
    if l:prevline =~# '\v^\s*switch>'
        let l:indent = l:shiftwidth * 2
    elseif l:prevline =~# '\v^\s*%(begin|if|else|while|for|function|case)>'
        let l:indent = l:shiftwidth
    endif
    let l:line = getline(l:lnum)
    if l:line =~# '\v^\s*%(case|else|end)>'
        let l:indent = indent(l:prevlnum) - l:shiftwidth + l:indent
        " for switch case
        if l:line =~# '\v^\s*end>'
            let l:i = l:lnum - 1
            while indent(l:i) != l:indent && l:i > 0
                let l:i = l:i - 1
            endwhile
            if l:i && getline(l:i) =~# '\v^\s*case'
                let l:indent = l:indent - l:shiftwidth
            endif
        endif
        return l:indent
    endif
    return indent(l:prevlnum) + l:indent
endfunction

function! fish#Format()
    if mode() =~# '\v^%(i|R)$'
        return 1
    else
        let l:command = v:lnum.','.(v:lnum+v:count-1).'!fish_indent'
        echo l:command
        execute l:command
    endif
endfunction

function! fish#Fold()
    let l:line = getline(v:lnum)
    if l:line =~# '\v^\s*%(begin|if|while|for|function|switch)>'
        return 'a1'
    elseif l:line =~# '\v^\s*end>'
        return 's1'
    else
        return '='
    end
endfunction

function! fish#Complete(findstart, base)
    if a:findstart
        return getline('.') =~# '\v^\s*$' ? -1 : 0
    else
        if empty(a:base)
            return []
        endif
        let l:results = []
        let l:completions =
                    \ system('fish -c "complete -C'.shellescape(a:base).'"')
        let l:cmd = substitute(a:base, '\v\S+$', '', '')
        for l:line in split(l:completions, '\n')
            let l:tokens = split(l:line, '\t')
            call add(l:results, {'word': l:cmd.l:tokens[0],
                                \'abbr': l:tokens[0],
                                \'menu': get(l:tokens, 1, '')})
        endfor
        return l:results
    endif
endfunction

function! fish#errorformat()
    return '%Afish: %m,%-G%*\\ ^,%-Z%f (line %l):%s'
endfunction
