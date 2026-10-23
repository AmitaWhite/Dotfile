-- LSP 서버 설정. LazyVim extras 가 다루지 않는 서버나, extras 기본값을 바꿀 때만 여기에 적는다
return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      -- D1 결정: 진단은 ruff 만, pyright 는 완성 · 정의 이동 · hover 담당
      -- analysis.ignore = {"*"} 는 pyright 의 "진단 출력"만 억제하고 나머지 기능은 유지한다
      -- (ruff 쪽 hover 비활성은 LazyVim python extra 가 처리)
      pyright = {
        settings = {
          python = {
            analysis = {
              ignore = { "*" },
            },
          },
        },
      },
      postgres_lsp = {},
      -- JSP 에 HTML 태그 · 속성 완성과 Emmet(div.box>ul>li*3 → 펼치기)을 붙인다.
      -- JSP 는 LSP 가 없고 treesitter 도 없어(하이라이트는 Vim 내장 syntax/jsp.vim) HTML 쪽을 빌려 쓴다.
      -- 일부러 html · jsp 에만: lspconfig 기본값은 React(jsx/tsx) · CSS 에도 emmet 을 켜는데,
      -- 거기선 vtsls · 스니펫과 제안이 겹쳐 시끄러워서 지금 동작을 바꾸지 않는다.
      html = {
        filetypes = { "html", "jsp" },
      },
      emmet_language_server = {
        filetypes = { "html", "jsp" },
        init_options = {
          includeLanguages = { jsp = "html" }, -- emmet 이 jsp 를 html 문법으로 펼치게
        },
      },
      -- biome: 프로젝트에 eslint 설정이 없으면 biome.json 이 없어도 붙인다 (판단은 lua/util/jslint.lua).
      -- lspconfig 기본값은 biome.json 이 있을 때만 붙는데, 설정 없는 새 프로젝트나 연습용 폴더도 biome 이 맡게 한다.
      -- eslint 쪽은 lspconfig 가 이미 eslint 설정이 있을 때만 붙인다.
      biome = {
        workspace_required = false,
        root_dir = function(bufnr, on_dir)
          if require("util.jslint").uses_biome(bufnr) then
            on_dir(vim.fs.root(bufnr, { "biome.json", "biome.jsonc", "package.json", ".git" }) or vim.fn.getcwd())
          end
        end,
      },
      -- JS/TS 에서 린터(eslint 나 biome)와 vtsls 가 "안 쓰는 변수와 import" 를 각각 보고해 한 줄에 두 번씩 뜬다
      -- (vtsls HINT 'declared but its value is never read' + eslint no-unused-vars 또는 biome noUnusedVariables, 실측).
      -- 린터가 붙은 버퍼에서만 vtsls 쪽 해당 코드를 버린다. 린터가 없으면 vtsls 것이 그대로 남는다.
      -- 흐리게 표시(unnecessary 태그)는 린터 진단에도 있어 유지된다.
      vtsls = {
        handlers = {
          ["textDocument/publishDiagnostics"] = function(err, result, ctx)
            local bufnr = result and vim.uri_to_bufnr(result.uri)
            local linted = bufnr
              and (
                #vim.lsp.get_clients({ bufnr = bufnr, name = "eslint" }) > 0
                or #vim.lsp.get_clients({ bufnr = bufnr, name = "biome" }) > 0
              )
            if linted then
              -- 6133 선언했지만 안 읽음 · 6138 안 쓰는 속성 · 6192 import 전체 미사용
              -- 6196 안 쓰는 타입 선언 · 6198 구조분해 전체 미사용
              local unused = { [6133] = true, [6138] = true, [6192] = true, [6196] = true, [6198] = true }
              result.diagnostics = vim.tbl_filter(function(d)
                return not unused[d.code]
              end, result.diagnostics)
            end
            return vim.lsp.diagnostic.on_publish_diagnostics(err, result, ctx)
          end,
        },
      },
    },
  },
}
