-- markdownlint-cli2 에 저장소의 기본 설정(nvim/.markdownlint-cli2.yaml)을 넘긴다.
-- LazyVim markdown extra 는 이 도구를 린터(nvim-lint)와 포맷터(conform, 저장 시 --fix) 둘 다로 쓰므로
-- 양쪽에 같은 --config 를 줘야 꺼 둔 규칙(목록 앞뒤 빈 줄 등)을 저장할 때 다시 "고치지" 않는다.
-- 프로젝트에 자기 .markdownlint* 가 있으면 그 설정이 이 위에 덧씌워진다.
local config = vim.fn.stdpath("config") .. "/.markdownlint-cli2.yaml"

return {
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = {
      linters = {
        ["markdownlint-cli2"] = { prepend_args = { "--config", config } },
      },
    },
  },
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters = {
        ["markdownlint-cli2"] = { prepend_args = { "--config", config } },
      },
    },
  },
}
