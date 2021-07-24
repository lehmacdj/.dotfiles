" Vim syntax file
" Language: Gm Dynamic Continuation Grammars
" Maintainer: Devin Lehmacher

if exists("b:current_syntax")
  finish
endif

syntax clear

syntax match gmContinuation '\\\\'
syntax match gmContinuation '\/\/'

let b:current_syntax = "gm"

highlight def link gmContinuation Title
