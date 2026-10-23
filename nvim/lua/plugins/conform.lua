-- JS/TS 포맷터를 프로젝트에 따라 하나만 돌린다 (판단은 lua/util/jslint.lua).
--   eslint 설정이 있는 프로젝트 → prettier (지금까지와 같다)
--   그 외 → biome (biome.json 이 없어도 기본 규칙)
-- conform 은 formatters_by_ft 의 포맷터를 차례로 전부 돌린다. LazyVim 의 prettier · biome extra 가 둘 다
-- 목록에 넣어 두므로, 조건을 서로 반대로 걸어 한쪽만 돌게 한다. biome 이 다루지 않는 형식(markdown, yaml, html …)은
-- 늘 prettier 다.
return {
  "stevearc/conform.nvim",
  optional = true,
  opts = function(_, opts)
    local jslint = require("util.jslint")
    local biome_ft = {}
    for _, ft in ipairs(jslint.biome_filetypes) do
      biome_ft[ft] = true
    end
    local function biome_mode(ctx)
      return biome_ft[vim.bo[ctx.buf].filetype] and jslint.uses_biome(ctx.buf)
    end

    opts.formatters = opts.formatters or {}

    -- LazyVim biome extra 는 require_cwd = true(biome.json 필요)로 둔다. 설정 없이도 돌게 푼다
    opts.formatters["biome-check"] = vim.tbl_extend("force", opts.formatters["biome-check"] or {}, {
      require_cwd = false,
      condition = function(_, ctx)
        return biome_mode(ctx)
      end,
      -- biome 기본 들여쓰기는 탭이다. biome.json 이 없을 때는 prettier 와 같은 공백 2칸으로 맞춘다
      -- (biome.json 이 있으면 그 설정을 따른다)
      append_args = function(_, ctx)
        if vim.fs.find({ "biome.json", "biome.jsonc" }, { path = ctx.dirname, upward = true, limit = 1 })[1] then
          return {}
        end
        return { "--indent-style=space", "--indent-width=2" }
      end,
    })

    -- LazyVim prettier extra 의 조건(파서 있음, needs_config)은 그대로 두고 biome 차례면 빠진다
    local prettier = opts.formatters.prettier or {}
    local prettier_cond = prettier.condition
    prettier.condition = function(self, ctx)
      if biome_mode(ctx) then
        return false
      end
      return prettier_cond == nil or prettier_cond(self, ctx)
    end
    opts.formatters.prettier = prettier
  end,
}
