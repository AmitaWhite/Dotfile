-- 다크/라이트 전환은 nvim 이 터미널 배경색을 자동 감지해 'background' 를 세팅하고(:h 'background'),
-- tokyonight 가 background=light 일 때 light_style 을 쓰는 방식으로 처리한다. (셸 호출 없음)
-- 터미널(ghostty) 쪽도 OS 테마를 따라가도록 theme = light:...,dark:... 로 둬야 실제로 전환된다.
--
-- 팔레트는 helix 와 맞춘다:
--   helix 내장 tokyonight 테마는 night 팔레트를 쓴다. 여기서도 night 를 쓰면 13개 역할 중 12개가
--   helix 와 hex 단위로 같아진다 (constructor 만 다름: helix 는 aqua, tokyonight 은 purple).
--   배경은 양쪽 다 투명(nvim transparent = true, helix "ui.background" = {})이라 ghostty 것이 보인다 —
--   즉 ghostty 테마가 Moon 이든 Night 든 글자색은 이 설정이 정하고, helix 와 서로 일치한다.

-- 테마가 배경을 칠하지 않게 할 하이라이트 그룹 (transparent 와 맞추기 위해)
local transparent_groups = {
  "^DiagnosticVirtualText",
  "^LspInlayHint",
  "^TSDefinition",
  "^TSDefinitionUsage",
}

-- jdtls 의 semantic token 은 treesitter 보다 우선순위가 높아(125 > 100) treesitter 하이라이트를 덮는다.
-- 그 결과 Java 에서만 구분이 뭉개진다:
--   · static final 상수(MAX)가 일반 필드와 같은 색이 된다  (@constant → @lsp.type.property.java)
--   · 메서드가 @lsp.type.method.java 로 덮여 styles.functions 의 italic 이 먹지 않는다
-- 이 그룹들을 비워 두면 아래 treesitter 하이라이트가 그대로 드러난다.
-- (helix 는 semantic token 을 요청조차 하지 않아서 항상 treesitter 만으로 칠한다 — 그 모양에 맞춘 것)
--
-- namespace 도 포함한다: jdtls 는 import/package 의 경로(java.util)를 namespace 로 보내 cyan 이 되지만,
-- helix 의 java 쿼리는 scoped_identifier 를 대문자로 시작할 때만 @type 으로 잡아서(#match? "^[A-Z]")
-- 소문자 경로는 아예 캡처하지 않는다 → 기본 전경색(흰색). treesitter 의 @variable 이 같은 결과다.
local java_semantic_passthrough = {
  "@lsp.type.class.java",
  "@lsp.type.interface.java",
  "@lsp.type.enum.java",
  "@lsp.type.enumMember.java",
  "@lsp.type.method.java",
  "@lsp.type.property.java",
  "@lsp.type.parameter.java",
  "@lsp.type.variable.java",
  "@lsp.type.typeParameter.java",
  "@lsp.type.namespace.java",
}

return {
  -- 시스템(터미널) 라이트/다크를 따라 day / night 를 고른다.
  --
  -- nvim 은 시작 시 OSC 11 로 터미널 배경을 물어 'background' 를 정한다 (사용자 설정보다 먼저, 최대 100ms 대기).
  -- 그런데 `:colorscheme tokyonight` 은 opts.style(night)에 맞춰 'background' 를 dark 로 **덮어쓴다**
  -- (tokyonight M.load: 처음 로드면 vim.o.background = style_bg). light_style 은 로드 *뒤에* background 가
  -- 바뀔 때만 쓰인다. 그래서 라이트 터미널(DMS 라이트 · foot)에서도 night 가 떠, 글자색은 그럴듯해도
  -- 같은 단어 강조 · 선택 영역 · 메뉴 선택 배경이 남색(#3b4261 · #283457 · #343a55)으로 남았다.
  -- (맥 ghostty 에선 OSC 11 응답이 늦게 와 로드 뒤에 background 가 바뀌어 우연히 동작했다 — Phase 4 실측)
  --
  -- 해결: 감지된 'background' 를 보고 tokyonight-day / -night 를 직접 고른다.
  -- styles 를 미리 채워 두면 실행 중 :set background=dark|light 로 바꿀 때도 moon 이 아니라 night 로 간다.
  -- nvim 은 실행 중 터미널 테마 변경을 감지하지 않는다 — DMS 라이트/다크를 바꾸면 nvim 을 다시 열거나 :set background=…
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = function()
        require("tokyonight").styles = { light = "day", dark = "night" }
        vim.cmd.colorscheme(vim.o.background == "light" and "tokyonight-day" or "tokyonight-night")
      end,
    },
  },
  {
    "folke/tokyonight.nvim",
    opts = {
      style = "night", -- background=dark 일 때 (helix · ghostty 와 동일 팔레트)
      light_style = "day", -- background=light 일 때
      transparent = true,
      styles = {
        sidebars = "transparent",
        floats = "transparent",
        -- helix 내장 테마는 function 을 italic 으로 준다 (comment · keyword 는 tokyonight 기본값)
        functions = { italic = true },
      },
      on_highlights = function(hl, c)
        for group, opts in pairs(hl) do
          for _, pattern in ipairs(transparent_groups) do
            if group:match(pattern) then
              opts.bg = "none"
            end
          end
        end

        -- nvim 기본 팝업 메뉴(스니펫 선택지 · 명령줄 완성)를 blink 메뉴와 같은 모양으로: 투명 배경 + 같은 테두리색.
        -- 테두리 자체는 options.lua 의 pumborder. tokyonight 은 Pmenu 를 불투명하게 칠한다 (night #16161e · day 연파랑)
        hl.Pmenu = { fg = c.fg, bg = "none" }
        hl.PmenuSbar = { bg = "none" }
        hl.PmenuBorder = hl.FloatBorder

        -- helix: "variable.parameter" = { fg = yellow, modifiers = ["italic"] }
        hl["@variable.parameter"] = { fg = c.yellow, italic = true }

        -- helix 는 "type" 과 "type.builtin" 을 둘 다 aqua 로 준다. tokyonight 은 원시 타입(int, boolean …)만
        -- 어둡게 잡아서 일반 타입과 톤이 어긋나 보인다 — helix 쪽 일관성을 따른다.
        hl["@type.builtin"] = { fg = hl["@type"] and hl["@type"].fg or c.blue1 }

        -- helix 의 java 쿼리는 keyword capture 가 @keyword 하나뿐이라 import·package 도 보라 italic 이다.
        -- nvim 은 @keyword.import 로 쪼개 cyan 을 준다. helix 쪽이 더 낫다고 판단해 맞추되,
        -- python·typescript 는 helix 도 import 를 cyan 으로 세분화하므로 java 에서만 바꾼다.
        -- (treesitter 는 capture 마다 "@<capture>.<lang>" 그룹을 먼저 찾는다 — 실측 확인)
        hl["@keyword.import.java"] = { fg = c.purple, italic = true }
        hl["@keyword.repeat.java"] = { fg = c.purple, italic = true }

        -- tokyonight 은 @lsp.type.interface 만 70% 로 흐리게 블렌딩해 일반 타입(#2ac3de)과 톤이 갈린다.
        -- helix 는 interface 도 (type_identifier) @type 이라 같은 aqua 다. TS/TSX 에서 눈에 띈다.
        hl["@lsp.type.interface"] = { fg = hl["@type"] and hl["@type"].fg or c.blue1 }

        -- helix 의 _jsx 쿼리는 속성을 @attribute 로 잡고 테마가 attribute = cyan 을 준다.
        -- tokyonight 의 @tag.attribute 는 녹색이라 JSX/HTML 속성 색이 갈렸다.
        hl["@tag.attribute"] = { fg = c.cyan }

        -- 위 설명 참고: 비워서 treesitter 가 보이게 한다
        for _, group in ipairs(java_semantic_passthrough) do
          hl[group] = {}
        end
      end,
    },
  },
}
