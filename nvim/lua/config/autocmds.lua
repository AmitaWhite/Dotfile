-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua

-- PDF 를 직접 열었을 때 페이지 넘기기: ]p 다음 / [p 이전 / gp 번호로 이동
--
-- snacks.image 에는 페이지 이동 키가 없다. 페이지는 src 경로 뒤 "#page=N" 으로 고르는 구조라
-- (snacks/image/convert.lua 의 get_page), 같은 버퍼에 src 만 바꿔 다시 attach 하면 페이지가 바뀐다.
-- 총 페이지 수는 ghostscript(gs) 가 있을 때만 구한다 (없으면 상한 없이 넘긴다).
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("my_pdf_pages", { clear = true }),
  pattern = "image",
  callback = function(ev)
    local buf = ev.buf
    local file = vim.api.nvim_buf_get_name(buf)
    if not file:lower():match("%.pdf$") then
      return
    end
    vim.b[buf].pdf_page = vim.b[buf].pdf_page or 1

    -- 재-attach 때마다 FileType 이 다시 불리므로, 페이지 수는 한 번만 센다
    if vim.b[buf].pdf_pages == nil and vim.fn.executable("gs") == 1 then
      vim.b[buf].pdf_pages = false -- 조회 중
      vim.system(
        { "gs", "-q", "-dNODISPLAY", "-dNOSAFER", "-c", ("(%s) (r) file runpdfbegin pdfpagecount = quit"):format(file) },
        { text = true },
        function(r)
          local n = tonumber((r.stdout or ""):match("%d+"))
          vim.schedule(function()
            if vim.api.nvim_buf_is_valid(buf) then
              vim.b[buf].pdf_pages = n or nil
            end
          end)
        end
      )
    end

    local function goto_page(page)
      local total = vim.b[buf].pdf_pages
      page = math.max(1, page)
      if type(total) == "number" and page > total then
        page = total
      end
      if page == vim.b[buf].pdf_page then
        return
      end
      vim.b[buf].pdf_page = page
      Snacks.image.buf.attach(buf, { src = file .. "#page=" .. page })
      vim.notify(
        ("PDF %d / %s"):format(page, type(total) == "number" and total or "?"),
        vim.log.levels.INFO,
        { title = "PDF" }
      )
    end

    local map = function(lhs, fn, desc)
      vim.keymap.set("n", lhs, fn, { buffer = buf, desc = desc })
    end
    map("]p", function()
      goto_page(vim.b[buf].pdf_page + 1)
    end, "PDF 다음 페이지")
    map("[p", function()
      goto_page(vim.b[buf].pdf_page - 1)
    end, "PDF 이전 페이지")
    map("gp", function()
      vim.ui.input({ prompt = "PDF 페이지: " }, function(s)
        local n = tonumber(s)
        if n then
          goto_page(n)
        end
      end)
    end, "PDF 페이지 번호로 이동")
  end,
})

-- 터미널의 라이트/다크 전환을 따라간다 (맥 ghostty · linux DMS 공통).
--
-- 구조: nvim 은 시작할 때 OSC 11 로 터미널 배경색을 물어 'background' 를 정한다. 그 응답을 받는
-- TermResponse 자동명령은 그 뒤로도 계속 살아 있어서(사용자가 'background' 를 직접 설정하지 않은 경우),
-- 응답이 또 오면 언제든 'background' 를 다시 계산한다. 그리고 'background' 가 바뀌면 nvim 이 컬러스킴을
-- 다시 읽으므로 colorscheme.lua 의 tokyonight styles 가 day/night 를 골라준다.
--
-- 빠진 고리는 "언제 다시 묻느냐" 하나다. 터미널은 테마가 바뀌면 알려줄 수 있지만(ghostty 의
-- color_scheme_updates, DEC 모드 2031) nvim 이 그 알림을 구독하지 않아 스스로는 알지 못한다.
-- 그래서 창에 포커스가 돌아올 때 한 번씩 직접 물어본다 — 응답 처리는 nvim 이 이미 하고 있다.
-- 질의 방법은 nvim 자신이 시작 시 쓰는 것과 같다 (runtime/lua/vim/_core/defaults.lua).
vim.api.nvim_create_autocmd({ "FocusGained", "VimResume" }, {
  group = vim.api.nvim_create_augroup("my_term_background_follow", { clear = true }),
  desc = "터미널 배경색을 다시 물어 라이트/다크 전환을 반영",
  callback = function()
    local ui = vim.api.nvim_list_uis()[1]
    if ui and ui.stdout_tty then
      vim.api.nvim_ui_send("\027]11;?\007")
    end
  end,
})
