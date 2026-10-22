-- noice: hover 창 모양, jdtls 진행 알림 숨김
return {
  "folke/noice.nvim",
  event = "VeryLazy",
  opts = {
    -- noice 는 nvim 기본 팝업 메뉴(pum)를 가로채 테두리 있는 창으로 다시 그리는데, 테두리 윗줄을
    -- 커서가 있는 줄에 놓아 입력 중인 글자를 덮었다. 일반 자동완성은 blink 가 그리므로 noice 쪽이
    -- 쓰이는 곳은 스니펫 선택지(CSS border 의 ${2|solid,dashed,…|} 등) 정도 — 기본 pum 으로 돌린다.
    popupmenu = { enabled = false },
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
