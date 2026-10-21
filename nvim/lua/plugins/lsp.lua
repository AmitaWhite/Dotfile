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
      -- JS/TS 에서 eslint 와 vtsls 가 "안 쓰는 변수 · import" 를 각각 보고해 한 줄에 두 번씩 뜬다
      -- (vtsls HINT 'declared but its value is never read' + eslint WARN no-unused-vars, 실측).
      -- eslint 가 붙은 버퍼에서만 vtsls 쪽 해당 코드를 버린다. eslint 없는 프로젝트에선 vtsls 것이 그대로 남는다.
      -- 흐리게 표시(unnecessary 태그)는 eslint 진단에도 있어 유지된다.
      vtsls = {
        handlers = {
          ["textDocument/publishDiagnostics"] = function(err, result, ctx)
            local bufnr = result and vim.uri_to_bufnr(result.uri)
            if bufnr and #vim.lsp.get_clients({ bufnr = bufnr, name = "eslint" }) > 0 then
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
