set number relativenumber

let mapleader = " "

" Do away with pesky shifts
noremap ' "
noremap " '
noremap , ;
noremap ; :
noremap : ,

" The way I like it
noremap ^ ``
noremap \ $
noremap ) zt
noremap ( zz
nnoremap Y y$
noremap <Leader>[ `
nnoremap <Leader>] @

" Colemak compensations
" noremap n j
" noremap e k
" noremap j e
" noremap k n
" noremap N J
" noremap E K
" noremap J E
" noremap K N
" noremap gn gj
" noremap ge gk
" noremap gk gn
" noremap gj ge

" Find my way around inside text objects
nnoremap [b [(
nnoremap ]b ])
nnoremap [r [{
nnoremap ]r ]}
nnoremap [d va]o<Esc>
nnoremap ]d va]<Esc>
nnoremap [T vato<Esc>
nnoremap ]T vat<Esc>
nnoremap [t vito<Esc>
nnoremap ]t vit<Esc>

vnoremap [d omao<Esc>"_ya]mb`av`b
vnoremap ]d omao<Esc>va]<Esc>mb`av`b
vnoremap [T omao<Esc>"_yatmb`av`b
vnoremap ]T omao<Esc>vat<Esc>mb`av`b
vnoremap [t omao<Esc>"_yitmb`av`b
vnoremap ]t omao<Esc>vit<Esc>mb`av`b

noremap [s (
noremap ]s )

" for search highlighting
set hlsearch
nnoremap <CR> :nohlsearch<CR>

" ~~~ Various Leader-macros ~~~

" easymotion
map <Leader> <Plug>(easymotion-prefix)
map <Leader><Leader> <Plug>(easymotion-s)
map <Leader>n <Plug>(easymotion-j)
map <Leader>e <Plug>(easymotion-k)
map <Leader>w <Plug>(easymotion-w)
map <Leader>W <Plug>(easymotion-W)
map <Leader>b <Plug>(easymotion-b)
map <Leader>B <Plug>(easymotion-B)

" Split lists into multi-line
nnoremap <Leader>sb "_yaba<CR><Esc>"_yab%i<CR><Esc>k:s/, /,\r/g<CR>:nohlsearch<CR>=ab
nnoremap <Leader>sd "_ya[a<CR><Esc>"_ya[%i<CR><Esc>k:s/, /,\r/g<CR>:nohlsearch<CR>=a[

" Split long string by concatenation
nnoremap <Leader>ss $h"qyl0115lbi<Esc>"qpa . <Esc>"qphs<CR><Esc>

" Select function (with doc)
nnoremap <Leader>f }?function<Enter>{jVN/{<Enter>%

" Block selections
vnoremap <Leader>vk oOmwoO{joO`w
vnoremap <Leader>vj oOmwoO}koO`w
nmap <Leader>vip <C-v>iW<Space>vjO<Space>vk
nmap <Leader>viw <C-v>iw<Space>vjO<Space>vk

" Select all
nnoremap <Leader>va ggVG

" Align and unalign
nnoremap <Leader>a W50i <Esc>B50ldwBj
nnoremap <Leader>u ElldwBj

" Quick edits
nnoremap <C-c> mwA;<Esc>`w
nnoremap <Leader>o mwO<Esc>0Dj`w
nnoremap <Leader>l mwo<Esc>0Dk`w

" Yank and pull clipboard
noremap <Leader>y "*y
noremap <Leader>p "*p

" Convert variable assignment to return statement
nnoremap <Leader>r _cf=return<Esc>j

" Markdown mappings
nnoremap <Leader>mb o<Esc>0C* [x]
nnoremap <Leader>mk 0f[lrx
nnoremap <Leader>mi $"wdibS<img src="<C-r>w" height=""><Esc>h
nnoremap <Leader>mc :set ft=markdown<CR>G$"cdiWdap{{k"cpggjjS
