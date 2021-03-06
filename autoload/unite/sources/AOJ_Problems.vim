let s:save_cpo = &cpo
set cpo&vim

let s:aoj_problem_volume_lst = [100, 0, 1, 2, 5, 10, 11, 12, 13, 15, 20, 21, 22, 23, 24, 25]


function! unite#sources#AOJ_Problems#define()
    return s:source
endfunction


" sourceの設定
" actionの振る舞いを独自に実装
let s:source = {
            \ 'name' : 'AOJ_Problems',
            \ 'description' : 'candidates from AOJ some Problem Volume List',
            \ 'is_volatile' : 0,
            \ 'action_table' : {
            \   'openable' : {
            \       'vsplit' : {
            \           'description' : 'get Selected Problem Description',
            \           'is_selectable' : 0,
            \       },
            \   },
            \ },
            \ 'default_action' : {
            \   'openable' : 'vsplit'
            \ },
            \}


" 候補を集めている時、redrawされるとき、入力文字列が変更された時に呼ばれる
" argsとcontextの2つの引数をとる
"   args (List) - Uniteコマンド実行時、sourceに与えられるパラメータのリスト いわゆるコマンドの引数
"   context (Dictionary) - sourceが呼ばれた時のコンテキスト
"   引数がない時は""が渡される。ゆえに、この関数は空文字を扱わなければならない
"   詳しくは unite-notation-{context}
" 戻り値は候補のリスト
"   unite-notation-{candidate}
function! s:source.gather_candidates(args, context)
    let candidates = []

    if len(a:args) == 0
        " 説明用のdummy
        call add(candidates, {
                    \ 'word' : 'Please Select Volume',
                    \ 'is_dummy' : 1,
                    \ 'is_matched' : 0,
                    \ })

        " kind を source にし
        " もう一度uniteをこのsourceで起動し、menuとして扱う
        " 次のuniteへはvolume番号を渡す
        for i in s:aoj_problem_volume_lst
            call add(candidates, {
                        \ 'word' : 'Volume - ' . i,
                        \ 'kind' : 'source',
                        \ 'action__source_name' : 'AOJ_Problems',
                        \ 'action__source_args' : [i],
                        \ })
        endfor
    elseif type(a:args[0]) == type(0)
        " 説明用のdummy
        call add(candidates, {
                    \ 'word' : 'Please Select Problem',
                    \ 'is_dummy' : 1,
                    \ 'is_matched' : 0,
                    \ })

        " 選択されたvolume番号の問題一覧を取得
        for problem in api4aoj#get_problem_lst(a:args[0])
             " contextへ渡すためsource__selected_problemとして問題詳細を追加
            call add(candidates, {
                        \ 'word' : problem.id . ' - ' . problem.name,
                        \ 'kind' : 'openable',
                        \ 'source__selected_problem' : [problem],
                        \ })
        endfor
    endif

    return candidates
endfunction


" kind openableの各action実行関数
function! s:source.action_table.openable.vsplit.func(candidate)
    let selected_problem = a:candidate.source__selected_problem[0]
    let description_lst = api4aoj#get_problem_description_lst(selected_problem.id)

    if bufexists('==AOJ==')
        execute 'bwipeout! ==AOJ=='
    endif
    execute 'topleft vsplit ==AOJ=='

    setlocal buftype=nowrite
    setlocal noswapfile
    setlocal bufhidden=wipe
    setlocal buftype=nofile
    setlocal nolist
    setlocal nofoldenable
    setlocal textwidth=0
    setlocal wrap
    setlocal fileencodings=utf-8 fileencoding=utf-8
    setlocal filetype=text

    setlocal modifiable
    call append(0, selected_problem.id . ' - ' . selected_problem.name)
    call append(1, '')
    call append(2, description_lst)
    setlocal nomodifiable
    call cursor(1, 1)

    let g:aoj#now_selected_problem_id = selected_problem.id
    " let b:aoj_now_selected_problem_id = selected_problem.id
endfunction



let &cpo = s:save_cpo
unlet s:save_cpo
