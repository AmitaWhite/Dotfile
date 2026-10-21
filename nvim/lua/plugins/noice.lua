-- noice: hover 창 모양, jdtls 진행 알림 숨김
return {
  "folke/noice.nvim",
  event = "VeryLazy",
  opts = {
    views = {
      hover = {
        border = {
          style = "rounded",
        },
        position = { row = 2, col = 2 },
      },
    },
    routes = {
      {
        filter = {
          event = "lsp",
          kind = "progress",
          -- jdtls 는 저장 · 편집마다 "Validate documents" · "Building" 진행 알림을 우측 하단(mini 뷰)에 띄운다.
          -- 클라이언트 이름은 message.opts.progress.client 에 있다 (noice/lsp/progress.lua).
          -- 예전엔 message.opts.client 를 봐서 항상 nil → 한 번도 걸러지지 않았다.
          cond = function(message)
            local progress = message.opts and message.opts.progress
            return progress ~= nil and progress.client == "jdtls"
          end,
        },
        opts = { skip = true },
      },
    },
  },
}
