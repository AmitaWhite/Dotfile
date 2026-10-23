-- JS/TS 프로젝트가 검사 · 포맷을 eslint(+prettier)와 biome 중 무엇으로 할지 정한다.
-- lua/plugins/lsp.lua(어느 LSP 를 붙일지)와 lua/plugins/conform.lua(어느 포맷터를 돌릴지)가 같이 쓴다.
--
-- 규칙: 프로젝트에 eslint 설정이 있으면 eslint 와 prettier(프로젝트 규칙을 따른다).
--       그 외에는 biome 이 검사와 포맷을 맡는다. biome.json 이 없어도 biome 기본 규칙으로 돈다.
--       biome.json 이 있으면 eslint 설정이 같이 있어도 biome 을 쓴다.
local M = {}

-- lspconfig 의 eslint 와 같은 목록 (nvim-lspconfig/lsp/eslint.lua)
local eslint_files = {
  ".eslintrc",
  ".eslintrc.js",
  ".eslintrc.cjs",
  ".eslintrc.yaml",
  ".eslintrc.yml",
  ".eslintrc.json",
  "eslint.config.js",
  "eslint.config.mjs",
  "eslint.config.cjs",
  "eslint.config.ts",
  "eslint.config.mts",
  "eslint.config.cts",
}
local biome_files = { "biome.json", "biome.jsonc" }

-- biome 이 다루는 파일 형식 (LazyVim biome extra 의 supported 와 같다). 이 밖의 것은 늘 prettier
M.biome_filetypes = {
  "astro",
  "css",
  "scss",
  "graphql",
  "javascript",
  "javascriptreact",
  "json",
  "jsonc",
  "svelte",
  "typescript",
  "typescriptreact",
  "vue",
}

local function find_up(names, bufnr)
  local file = vim.api.nvim_buf_get_name(bufnr)
  if file == "" then
    return nil
  end
  return vim.fs.find(names, { path = vim.fs.dirname(file), upward = true, type = "file", limit = 1 })[1]
end

---@param bufnr integer
function M.uses_eslint(bufnr)
  local file = vim.api.nvim_buf_get_name(bufnr)
  -- CRA 처럼 package.json 의 "eslintConfig" 로 설정한 경우도 eslint 로 친다
  local names = require("lspconfig.util").insert_package_json(vim.deepcopy(eslint_files), "eslintConfig", file)
  return find_up(names, bufnr) ~= nil
end

---@param bufnr integer
function M.uses_biome(bufnr)
  return find_up(biome_files, bufnr) ~= nil or not M.uses_eslint(bufnr)
end

return M
