-- mason 으로 설치할 도구들
return {
  "mason-org/mason.nvim",
  opts = {
    ensure_installed = {
      "stylua",
      "shellcheck",
      "shfmt",
      "lemminx", -- XML LSP
      "css-lsp", -- CSS LSP (LazyVim 기본 목록에 없다. helix 도 이걸 쓴다)
      -- rust-analyzer 는 mason 이 아니라 rustup component 로 (툴체인과 버전 일치, D4)
    },
    -- ui.border 는 vim.o.winborder ("rounded") 를 따라감 (config/options.lua)
  },
}
