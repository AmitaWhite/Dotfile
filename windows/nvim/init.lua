-- =============================================================================
-- Windows 용 단일 init.lua — 플러그인 없음, 이 파일 하나로 끝
--
-- 위치   %LOCALAPPDATA%\nvim\init.lua
--        (PowerShell: notepad $env:LOCALAPPDATA\nvim\init.lua — 폴더가 없으면 먼저 mkdir)
--        nvim 안에서 :echo stdpath('config') 로 확인
-- 붙여넣기  메모장에 붙여 UTF-8 로 저장하는 게 가장 안전하다.
--        nvim 안에 직접 붙일 땐 자동 들여쓰기가 계단처럼 쌓일 수 있으니 :set paste 후 붙이고 :set nopaste
-- 요구   nvim 0.10+ (0.11+ 권장). 버전에 따라 없는 옵션은 건너뛰도록 해 두었다
-- 선택   rg.exe(ripgrep) 가 PATH 에 있으면 파일 찾기(:find)·키워드 검색(:Grep)이 빨라진다.
--        없으면 nvim 내장(path=**, vimgrep)으로 동작 — 느리지만 된다
-- 출처   nvim/lua/config/{options,keymaps}.lua + LazyVim 기본값 중 플러그인과 무관한 것.
--        키는 LazyVim 과 같게 맞춰 맥 · 리눅스와 손이 헷갈리지 않게 했다
-- 셸     :! · :grep · netrw(복사/이동/삭제)는 Windows 기본 cmd.exe 를 그대로 쓴다 (호환성).
--        터미널 창(<C-\> · <leader>ft · <leader>fh)만 PowerShell 로 띄운다
-- =============================================================================

local is_win = vim.fn.has("win32") == 1
local has_rg = vim.fn.executable("rg") == 1

-- leader 는 키맵보다 먼저
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- -----------------------------------------------------------------------------
-- 옵션
-- -----------------------------------------------------------------------------
local opt = vim.opt

-- 줄 번호
opt.number = true
opt.relativenumber = true
opt.signcolumn = "yes"

-- 줄바꿈 (단어 단위)
opt.wrap = true
opt.linebreak = true

-- 들여쓰기: 공백 2칸
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.shiftround = true
opt.smartindent = true

-- 검색: 소문자면 대소문자 무시, 대문자가 섞이면 구분
opt.ignorecase = true
opt.smartcase = true
-- :%s/a/b/ 입력 중 바뀔 결과를 아래 창에 미리 보여준다
opt.inccommand = "split"

-- 창 분할은 오른쪽 · 아래로, 분할해도 화면이 출렁이지 않게
opt.splitright = true
opt.splitbelow = true
opt.splitkeep = "screen"
opt.scrolloff = 4
opt.sidescrolloff = 8

-- y / p 가 Windows 클립보드와 바로 연결 (안 되면 :checkhealth 의 clipboard 항목 확인)
opt.clipboard = "unnamedplus"
-- 파일을 닫았다 열어도 undo 기록 유지. :earlier 10m 처럼 시간 단위로도 되돌린다
opt.undofile = true
opt.undolevels = 10000
-- 저장 안 하고 :q 하면 에러 대신 "저장할까요?" 로 묻는다
opt.confirm = true
-- 블록 선택(Ctrl-v)을 줄 길이와 상관없이 직사각형으로
opt.virtualedit = "block"
opt.mouse = "a"
opt.jumpoptions = "view"
opt.laststatus = 3
-- jk 를 칠 때 j 다음 k 를 기다리는 시간(ms)
opt.timeoutlen = 300
opt.updatetime = 200
opt.termguicolors = true

-- 한국 회사 Windows 파일은 CP949(EUC-KR) 인 경우가 많다. UTF-8 로 안 읽히면 CP949 로 다시 시도.
-- 그래도 깨지면 :e ++enc=cp949 / 저장 인코딩 바꾸기는 :set fenc=utf-8 후 :w
opt.fileencodings = { "ucs-bom", "utf-8", "cp949", "latin1" }

-- 메인 설정에서 가져온 것
opt.cursorline = false -- 투명 배경 위에서 현재 줄 띠가 튀어 보여 끔
opt.list = false
opt.modeline = false -- 메모의 "ex: …" 같은 줄을 설정으로 읽어 E518 이 나던 문제
opt.spelllang = { "en", "cjk" } -- 맞춤법 검사 시 한글은 제외 (켜기: <leader>us)

-- 창 테두리 둥글게 (0.11+ 에만 있는 옵션이라 확인 후)
if vim.fn.exists("+winborder") == 1 then
  opt.winborder = "rounded"
end

-- 명령줄 자동완성: 첫 Tab 은 공통 부분까지 채우고 목록 표시, 다음 Tab 부터 후보 순환.
-- fuzzy 는 :b(버퍼) 같은 이름 완성에 적용된다 (파일 이름 완성은 nvim 이 와일드카드로만 처리)
opt.wildmode = { "longest:full", "full" }
opt.wildoptions:append("fuzzy")
opt.pumheight = 10

-- -----------------------------------------------------------------------------
-- 파일 찾기 (:find)
-- -----------------------------------------------------------------------------
-- 현재 폴더 아래 전부를 뒤진다. 큰 프로젝트에선 느리니 무거운 폴더는 wildignore 로 뺀다
opt.path:append("**")
opt.wildignore:append({
  "*/node_modules/*",
  "*/.git/*",
  "*/target/*",
  "*/build/*",
  "*/dist/*",
  "*/bin/*",
  "*/obj/*",
  "*.class",
  "*.jar",
  "*.exe",
  "*.dll",
})

-- rg 가 있고 nvim 이 findfunc 를 지원하면(0.11+) :find 를 rg 파일 목록 + 퍼지 매칭으로 바꾼다.
-- .gitignore 를 존중하므로 wildignore 보다 정확하고 빠르다
if has_rg and vim.fn.exists("+findfunc") == 1 then
  function _G.RgFindFiles(arg, _)
    local files = vim.fn.systemlist({ "rg", "--files", "--hidden", "--glob", "!.git", "--glob", "!node_modules" })
    arg = arg:gsub("%*", "")
    if arg == "" then
      return files
    end
    return vim.fn.matchfuzzy(files, arg)
  end
  opt.findfunc = "v:lua.RgFindFiles"
end

-- -----------------------------------------------------------------------------
-- 키워드 검색 (:Grep 패턴 → 결과는 quickfix 창, ]q [q 로 이동)
-- -----------------------------------------------------------------------------
if has_rg then
  -- nvim 이 rg 를 알아서 쓰긴 하지만 기본값(-uu)은 node_modules · 숨김 파일까지 뒤져서 직접 지정.
  -- rg 는 git 레포 안에서만 .gitignore 를 읽으므로, 레포가 아닌 폴더용으로 node_modules 는 따로 뺀다
  opt.grepprg = "rg --vimgrep --smart-case --hidden --glob !.git --glob !node_modules"
  opt.grepformat = "%f:%l:%c:%m"
end

-- rg 가 없으면 nvim 내장 vimgrep(느림)으로 대신한다. 공백이 든 패턴은 rg 일 때 "따옴표" 로 감싼다
vim.api.nvim_create_user_command("Grep", function(o)
  if has_rg then
    vim.cmd("silent grep! " .. vim.fn.escape(o.args, "%#|"))
  else
    vim.cmd("silent! vimgrep /" .. vim.fn.escape(o.args, "/") .. "/gj **/*")
  end
  vim.cmd("copen | redraw!")
end, { nargs = "+", desc = "Grep in cwd (rg or vimgrep)" })

-- -----------------------------------------------------------------------------
-- netrw (:Lex 파일 탐색기)
--   %  새 파일 (이름 입력 → :w 해야 실제로 생김)    d  새 폴더
--   R  이름 변경 · 이동                              D  삭제 (Windows 에선 비어 있지 않은 폴더는 실패할 수 있다)
--   mf 표시 → mt 대상 폴더 지정 → mc 복사 / mm 이동  -  상위 폴더
--   gh 숨김 파일 토글   v / o / t  세로 / 가로 분할 / 새 탭으로 열기   x  Windows 기본 앱으로 열기
-- -----------------------------------------------------------------------------
vim.g.netrw_banner = 0 -- 위쪽 도움말 배너 숨김 (I 로 일시 표시)
vim.g.netrw_liststyle = 3 -- 트리 보기
vim.g.netrw_winsize = 25 -- :Lex 폭 25%
vim.g.netrw_keepdir = 0 -- 탐색 중인 폴더를 현재 경로로 (mc / mm 이 엉뚱한 곳으로 가지 않게)

-- -----------------------------------------------------------------------------
-- 키맵 — LazyVim 과 같은 키
-- -----------------------------------------------------------------------------
local map = vim.keymap.set

-- jk 로 insert 모드 탈출
map("i", "jk", "<Esc>", { desc = "Exit insert mode with jk" })

-- Esc: 검색 하이라이트도 함께 끈다
map({ "i", "n" }, "<Esc>", "<cmd>nohlsearch<cr><Esc>", { desc = "Escape and clear hlsearch" })

-- 줄바꿈된 긴 줄에서 j / k 가 화면 줄 단위로 움직이게 (5j 처럼 숫자를 주면 실제 줄 단위)
map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })

-- 저장 · 종료
map({ "i", "x", "n", "s" }, "<C-s>", "<cmd>w<cr><Esc>", { desc = "Save file" })
map("n", "<leader>qq", "<cmd>qa<cr>", { desc = "Quit all" })

-- 창: 이동 · 분할 · 닫기 · 크기
map("n", "<C-h>", "<C-w>h", { desc = "Go to left window" })
map("n", "<C-j>", "<C-w>j", { desc = "Go to lower window" })
map("n", "<C-k>", "<C-w>k", { desc = "Go to upper window" })
map("n", "<C-l>", "<C-w>l", { desc = "Go to right window" })
map("n", "<leader>-", "<C-w>s", { desc = "Split window below" })
map("n", "<leader>|", "<C-w>v", { desc = "Split window right" })
map("n", "<leader>wd", "<C-w>c", { desc = "Delete window" })
map("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase window height" })
map("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease window height" })
map("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease window width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase window width" })

-- 줄 옮기기 Alt-j / Alt-k (VSCode 의 Alt+↑↓)
map("n", "<A-j>", "<cmd>execute 'move .+' . v:count1<cr>==", { desc = "Move line down" })
map("n", "<A-k>", "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==", { desc = "Move line up" })
map("i", "<A-j>", "<Esc><cmd>m .+1<cr>==gi", { desc = "Move line down" })
map("i", "<A-k>", "<Esc><cmd>m .-2<cr>==gi", { desc = "Move line up" })
map("v", "<A-j>", ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv", { desc = "Move lines down" })
map("v", "<A-k>", ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv", { desc = "Move lines up" })

-- 비주얼 모드 들여쓰기 후에도 선택 유지 (>>> 처럼 연속으로)
map("v", "<", "<gv")
map("v", ">", ">gv")

-- 버퍼
-- 창은 그대로 두고 버퍼만 닫는다 (:bd 는 분할 창까지 닫아 버림). 수정된 버퍼면 저장 여부를 묻는다
local function buf_delete()
  local cur = vim.api.nvim_get_current_buf()
  if vim.bo[cur].modified then
    local choice = vim.fn.confirm(("Save changes to %q?"):format(vim.fn.bufname(cur)), "&Yes\n&No\n&Cancel")
    if choice == 1 then
      vim.cmd.write()
    elseif choice ~= 2 then
      return
    end
  end
  for _, win in ipairs(vim.fn.win_findbuf(cur)) do
    vim.api.nvim_win_call(win, function()
      local alt = vim.fn.bufnr("#")
      if alt > 0 and alt ~= cur and vim.fn.buflisted(alt) == 1 then
        vim.api.nvim_win_set_buf(win, alt)
      else
        vim.cmd("bprevious")
        if vim.api.nvim_win_get_buf(win) == cur then
          vim.cmd.enew()
        end
      end
    end)
  end
  pcall(vim.api.nvim_buf_delete, cur, { force = true })
end

map("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Prev buffer" })
map("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next buffer" })
map("n", "[b", "<cmd>bprevious<cr>", { desc = "Prev buffer" })
map("n", "]b", "<cmd>bnext<cr>", { desc = "Next buffer" })
map("n", "<leader>bb", "<cmd>e #<cr>", { desc = "Switch to other buffer" })
map("n", "<leader>`", "<cmd>e #<cr>", { desc = "Switch to other buffer" })
map("n", "<leader>bd", buf_delete, { desc = "Delete buffer" })
-- 버퍼 목록을 보여주고 :b 를 입력해 둔다 → 번호나 이름 일부 + Enter (Tab 으로 후보)
map("n", "<leader>,", ":ls<cr>:b ", { desc = "Switch buffer" })

-- 파일 찾기 · 최근 파일 · 탐색기
-- :find 뒤에 이름 일부 + Tab (rg 가 없으면 *ser* 처럼 별표로 감싸면 중간 일치)
map("n", "<leader><space>", ":find *", { desc = "Find files" })
map("n", "<leader>ff", ":find *", { desc = "Find files" })
map("n", "<leader>fr", "<cmd>browse oldfiles<cr>", { desc = "Recent files" })
map("n", "<leader>e", "<cmd>Lexplore<cr>", { desc = "Explorer (cwd)" })
map("n", "<leader>E", "<cmd>Lexplore %:p:h<cr>", { desc = "Explorer (current file dir)" })

-- 키워드 검색 · quickfix
map("n", "<leader>/", ":Grep ", { desc = "Grep" })
map("n", "<leader>sw", function()
  vim.cmd("Grep " .. vim.fn.expand("<cword>"))
end, { desc = "Grep word under cursor" })
map("n", "[q", "<cmd>cprevious<cr>", { desc = "Prev quickfix" })
map("n", "]q", "<cmd>cnext<cr>", { desc = "Next quickfix" })
map("n", "<leader>xq", function()
  if vim.fn.getqflist({ winid = 0 }).winid ~= 0 then
    vim.cmd.cclose()
  else
    vim.cmd.copen()
  end
end, { desc = "Quickfix list" })

-- 토글
map("n", "<leader>uw", "<cmd>set wrap!<cr>", { desc = "Toggle wrap" })
map("n", "<leader>us", "<cmd>set spell!<cr>", { desc = "Toggle spelling" })
map("n", "<leader>ur", "<cmd>set relativenumber!<cr>", { desc = "Toggle relative number" })

-- 주석은 nvim 0.10+ 내장: gcc (한 줄) · gc + 동작 (gcip 문단) · 비주얼 gc

-- -----------------------------------------------------------------------------
-- 터미널 — PowerShell
-- -----------------------------------------------------------------------------
local term_shell = is_win and ((vim.fn.executable("pwsh") == 1 and "pwsh" or "powershell") .. " -NoLogo")
  or vim.o.shell

-- 터미널 안에서 Esc 두 번 → 노멀 모드 (스크롤 · 복사용)
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Enter normal mode" })

-- 플로팅 터미널 토글 (맥 설정의 <C-\> 와 같은 키). 닫았다 다시 열면 같은 세션이 그대로 있다
local float_term = { buf = -1, win = -1 }
local function toggle_float_term()
  if vim.api.nvim_win_is_valid(float_term.win) then
    vim.api.nvim_win_hide(float_term.win)
    return
  end
  local width = math.floor(vim.o.columns * 0.85)
  local height = math.floor(vim.o.lines * 0.85)
  local reuse = vim.api.nvim_buf_is_valid(float_term.buf)
  local buf = reuse and float_term.buf or vim.api.nvim_create_buf(false, true)
  float_term.win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = "rounded",
  })
  if not reuse then
    -- :terminal 은 지금 창(플로팅)에서 터미널을 연다. 빈 버퍼를 그대로 쓸 수도, 새로 만들 수도 있어서
    -- 새로 만들었을 때만 자리만 잡던 빈 버퍼를 지운다
    vim.cmd.terminal(term_shell)
    float_term.buf = vim.api.nvim_get_current_buf()
    vim.bo[float_term.buf].buflisted = false
    if buf ~= float_term.buf then
      pcall(vim.api.nvim_buf_delete, buf, { force = true })
    end
    -- 셸에서 exit 하면 버퍼도 지워 다음 토글 때 새로 띄운다
    vim.api.nvim_create_autocmd("TermClose", {
      buffer = float_term.buf,
      once = true,
      callback = function(ev)
        vim.schedule(function()
          pcall(vim.api.nvim_buf_delete, ev.buf, { force = true })
        end)
      end,
    })
  end
  vim.cmd.startinsert()
end
map({ "n", "t" }, "<C-\\>", toggle_float_term, { desc = "Terminal (Float)" })

-- 아래 / 오른쪽 분할 터미널
map("n", "<leader>ft", function()
  vim.cmd("botright 15split")
  vim.cmd.terminal(term_shell)
  vim.cmd.startinsert()
end, { desc = "Terminal (Bottom)" })
map("n", "<leader>fh", function()
  vim.cmd("botright vsplit")
  vim.cmd("vertical resize " .. math.floor(vim.o.columns * 0.4))
  vim.cmd.terminal(term_shell)
  vim.cmd.startinsert()
end, { desc = "Terminal (Right Vertical)" })

-- -----------------------------------------------------------------------------
-- 자동 동작
-- -----------------------------------------------------------------------------
local group = vim.api.nvim_create_augroup("win_init", { clear = true })
local autocmd = vim.api.nvim_create_autocmd

-- 복사한 영역을 잠깐 강조
autocmd("TextYankPost", {
  group = group,
  callback = function()
    (vim.hl or vim.highlight).on_yank()
  end,
})

-- 파일을 다시 열면 닫을 때 있던 줄로
autocmd("BufReadPost", {
  group = group,
  callback = function(ev)
    if vim.bo[ev.buf].filetype == "gitcommit" or vim.b[ev.buf].last_loc_done then
      return
    end
    vim.b[ev.buf].last_loc_done = true
    local mark = vim.api.nvim_buf_get_mark(ev.buf, '"')
    if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(ev.buf) then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- 다른 프로그램(VSCode 등)이 파일을 고쳤으면 포커스가 돌아올 때 다시 읽는다
autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
  group = group,
  callback = function()
    if vim.o.buftype ~= "nofile" then
      vim.cmd("checktime")
    end
  end,
})

-- 창 크기를 바꾸면 분할 비율을 다시 맞춘다
autocmd("VimResized", {
  group = group,
  callback = function()
    local tab = vim.fn.tabpagenr()
    vim.cmd("tabdo wincmd =")
    vim.cmd("tabnext " .. tab)
  end,
})

-- 도움말 · quickfix 같은 창은 q 로 닫기
autocmd("FileType", {
  group = group,
  pattern = { "help", "qf", "man", "checkhealth" },
  callback = function(ev)
    vim.bo[ev.buf].buflisted = false
    map("n", "q", function()
      pcall(vim.cmd.close)
    end, { buffer = ev.buf, silent = true, desc = "Close window" })
  end,
})

-- -----------------------------------------------------------------------------
-- 투명 배경 (터미널 쪽 투명도를 쓸 때만 주석 해제 — 기본 테마는 배경을 칠한다)
-- -----------------------------------------------------------------------------
-- for _, g in ipairs({ "Normal", "NormalNC", "NormalFloat", "SignColumn", "EndOfBuffer" }) do
--   vim.api.nvim_set_hl(0, g, { bg = "none" })
-- end
