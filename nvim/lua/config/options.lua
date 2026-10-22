-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- 줄바꿈
vim.opt.wrap = true
-- 단어 단위로 줄 바꿈
vim.opt.linebreak = true
-- SQLcl 사용시 , 결과 파싱 오류 방지 설정
-- vim.g.dbext_default_ORA_bin = "sql"
vim.opt.termguicolors = true

-- 전역 창 테두리 (nvim 0.11+). blink.cmp / mason / lspconfig float 등
-- winborder 를 존중하는 플러그인은 이 한 줄로 모두 rounded 처리됨
vim.opt.winborder = "rounded"
-- nvim 기본 팝업 메뉴(pum)는 winborder 를 따르지 않아 따로 준다 (nvim 0.12+). 스니펫 선택지 등이
-- blink 메뉴와 같은 둥근 테두리로 뜬다. 배경 투명은 colorscheme.lua 의 Pmenu
vim.opt.pumborder = vim.o.winborder

-- ghostty 가 background-opacity 0.85 + blur 라, 글자 뒤에 뭘 그릴수록 지저분해 보인다.
-- helix 화면처럼 비우기 위해 LazyVim 기본값 두 개를 끈다 (helix 쪽엔 아예 없는 기능들).
--   cursorline : 현재 줄에 불투명한 띠(#292e42)가 깔려 반투명 배경 위에서 가장 튄다
--   list       : 탭 화살표 · 헛공백 점 표시
-- 되돌리려면 true 로. 일시 토글은 :set cursorline! / :set list!
vim.opt.cursorline = false
vim.opt.list = false

-- mason 이 설치한 도구(tree-sitter-cli 등)를 mason 이 로드되기 전에도 찾을 수 있게 PATH 앞에 둔다.
-- mason 은 lazy-load 라, 대시보드에서 바로 :TSUpdate 하거나 :Lazy sync 의 build 단계에서는
-- 아직 PATH 에 없어 tree-sitter CLI 를 못 찾는다. (D3 — brew 의 tree-sitter-cli 는 Intel 맥에서 llvm+rust 를 끌어옴)
vim.env.PATH = vim.fn.stdpath("data") .. "/mason/bin:" .. vim.env.PATH
