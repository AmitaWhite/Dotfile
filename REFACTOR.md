# nvim 설정 리팩터링 계획

진단 기준: 2026-09-08, LazyVim `c10948c`, nvim 0.12.4 (Phase 5 중 0.12.5 로 업그레이드, 아래 사고 기록 참고).
근거는 LazyVim 소스와 런타임 실측(VeryLazy 후 `nvim_get_keymap`, which-key health, `vim.ui.*` 소유자).

한 줄 원인: 서로 다른 시대의 LazyVim 문서를 복붙한 설정이 재정렬 없이 쌓였고,
"LazyVim 이 이미 해주는가"를 확인하는 단계가 없었다.

각 Phase = 커밋 1개. 끝난 항목은 `[x]`.

---

## 글쓰기 규칙 (문서와 커밋)

이 저장소 문서는 맥과 리눅스의 Claude 세션이 번갈아 쓴다. 어느 쪽이 쓰든 같은 말투가 되도록 정해둔다.
2026-10-22에 README를 이 규칙대로 다시 썼다. SETUP.md, TOOLS.md, 이 파일의 예전 항목에는 옛 말투가 남아 있으니 고칠 일이 생길 때 같이 고친다.

문서

- 짧은 "~다" 문장이나 개조식으로 쓴다. 무엇이 어디 있는지, 어떻게 쓰는지, 왜 그렇게 했는지를 적는다
- 이유는 한두 문장으로 붙이고, 긴 경위는 이 파일에 둔다
- 아래 버릇은 쓰지 않는다. 사람이 읽으면 AI가 쓴 글처럼 보인다
  - 격언처럼 끊는 문장: "추측하지 않고 확인한다.", "질문은 하나다"
  - "X가 아니라 Y다"로 뒤집는 문장
  - 대시(—)로 문장이나 제목을 극적으로 잇기
  - 문단을 맺는 한 방 문장: "…그것과 싸우게 된다."
  - 굵은 글씨를 여기저기 쓰기. 정말 놓치면 안 되는 한 군데에만 쓴다
  - 가운뎃점(·)으로 나열하기. 쉼표나 "와/과"를 쓴다
  - 이모지로 경고하기(⚠️)

커밋

- 첫 줄은 `type : 요약` 또는 `type(범위) : 요약`. type은 feat, fix, docs, style, chore, refactor
- 요약과 본문은 한국어로 쓴다. 본문에는 무엇이 왜 깨졌는지와 어떻게 확인했는지를 적는다
- `Co-Authored-By` 같은 AI 서명 줄은 넣지 않는다

## Phase 0 — 규칙 (코드 변경 없음)

- [x] **키맵**: LazyVim 그룹 prefix(`<leader>s` 검색 · `t` 테스트 · `d` 디버그 · `n` 알림 · `<tab>` 탭 · `w` 창) 침범 금지. 개인 키맵은 빈 prefix 에만
- [x] **추가 전 확인**: `:LazyExtras` → LazyVim 소스 grep → 없을 때만 추가
- [x] **스타일**: `opts` 우선, `config = function()` 금지(예외는 주석으로 이유 명시). 플랫 `return { ... }`. 주석 한국어. LazyVim 문서 복붙 금지
- [x] **레이아웃**: 플러그인 오버라이드는 전부 `lua/plugins/`. LSP 서버는 `lua/plugins/lsp.lua` 한 파일

## Phase 1 — 삭제 (리스크 0, 동작 변화 없음)

- [x] `lua/plugins/ts-comment.lua` 삭제 — LazyVim 기본 포함
- [x] `lua/plugins/dressing.lua` 삭제 — archived, `snacks.input` 을 가로채고 있음
- [x] `lua/lsp/vtsls.lua` 삭제 — `updateImportsOnFileMove` LazyVim 동일, `autoImports` vtsls 기본 true
- [x] `lua/lsp/jdtls.lua` 삭제 — java extra 가 lombok 을 이미 주입 (이중 javaagent)
- [x] `lua/plugins/bufferline.lua` 삭제 — opts 전부 주석, `version="*"` 잠재 핀, devicons dep 불필요
- [x] `lua/plugins/trouble.lua` 삭제 — 유일한 opt `use_diagnostic_signs` 가 v3 에 없음 → 파일 전체 no-op
- [x] `lua/plugins/todo-comment.lua` 삭제 — `config = setup()` 이 LazyVim opts 를 덮어쓰던 것 외엔 전부 LazyVim 과 동일
- [x] `lua/plugins/nvim-treesitter.lua` 삭제 — 나열한 파서 18개 전부 LazyVim 기본 + python extra 에 이미 포함, highlight/indent/folds 도 기본값
- [x] `lua/plugins/snacks.lua` — `image.enable` → `enabled`
- [x] `lua/plugins/nvim-lspconfig.lua` — `diagnostics.float.border`(winborder 대체) · 구주석 · 빈 `ruff` 블록 · pyright `autoImportCompletion` 오타(정식 키 `autoImportCompletions`, 기본 true) 제거. D1 반영
- [x] `lua/plugins/docstrings.lua` — `ft=` 가 있어 무의미한 `cmd` 트리거 제거 (`keys` 는 `<leader>cD` 정의라 유지)
- [x] `lua/config/keymaps.lua` — LazyVim 중복 제거: `mapleader`, `]t`/`[t`, `<leader>sv/sh/se/sx`, 탭 5개, `<leader>nh`. 남긴 것: `jk`, `<leader>fh`
- [x] `lua/config/lazy.lua` — `{ import = "lsp" }` 제거 (Phase 3 에서 앞당김: `lua/lsp/` 에 `.bak` 만 남아 빈 모듈이 됨)

## Phase 2 — 충돌 해소 (LazyVim 기능 회복)

- [x] `<leader>tt` / `<leader>to` 를 neotest 에 반환 — `toggleterm.lua` 삭제, 플로팅 터미널은 `<C-\>` 로 snacks.terminal (D2)
- [x] `<leader>sh` 를 snacks Help Pages 에 반환 (Phase 1 keymaps 삭제로 해결)
- [x] `<leader>n` 알림 히스토리 지연 해소 (Phase 1 `<leader>nh` 삭제로 해결)
- [x] `docstrings.lua` — `vim.g.doge_*` 설정을 `config` → `init` 으로. `<leader>d` DAP 그룹 overlap 해소 (실측: `<leader>d` doge 매핑 소멸)
- [x] which-key health — 내 키맵 기인 overlap 0. 남은 1건(`<leader>dP` ↔ `dPc`/`dPt`)은 LazyVim python·dap extra 자체 것

## Phase 3 — 구조 재편

- [x] `lua/config/lazy.lua` 하드코딩 extras(typescript · json · toml · python · clangd) → `lazyvim.json` 으로 이동. 실측: 플러그인 55 · extras 22 · LSP 서버 25 로 전후 동일, `LazyVim.has_extra()` 5개 모두 true
- [x] `lua/plugins/nvim-lspconfig.lua` → `lua/plugins/lsp.lua` 로 rename
- [x] `lazy.lua` 의 `{ import = "lsp" }` 제거 (Phase 1 에서 처리)
- [ ] `lua/lsp/` 디렉토리 — `typescript.lua.bak` 만 남음. 백업 보존 정책상 유지, 단 새 파일 넣지 말 것

## Phase 4 — 성능 · 관용구

- [x] `lua/utils/system-color.lua` 삭제 — nvim TUI 의 터미널 배경 자동 감지(`:h 'background'`) + tokyonight `light_style = "day"` 로 대체. 셸 호출 0. 실측: background light/dark 전환 시 `tokyonight-day` ↔ `tokyonight-moon` 자동 재로드 (D 결정 (a))
- [x] `lua/plugins/colorscheme.lua` — `init = colorscheme("tokyonight")` 제거, LazyVim 기본 로더에 위임 (이중 적용 해소)
- [x] `nvim --startuptime` — 136ms(리팩터 전, 단일 측정) → **67ms**(Phase 4 후, 3회 중 최소). Phase 1 플러그인 삭제 + popen 제거 효과
- [x] ghostty 테마 `light:TokyoNight Day,dark:TokyoNight Moon` — `~/.config/ghostty/config` 가 저장소의 `caelestia-backup.bak/ghostty/mac-config.bak` 심링크라 그 파일을 수정. 적용은 ghostty 설정 리로드(⌘⇧,)

## Phase 5 — 설계 결정 반영

- [x] D1 pyright/ruff 역할 확정 → `nvim-lspconfig.lua` 반영 (Phase 1 에서 처리)
- [x] D2 터미널 단일화 → snacks.terminal 3 레이아웃 (`<C-/>` bottom · `<leader>fh` right · `<C-\>` float), Phase 2 에서 처리
- [x] D3 tree-sitter CLI — mason 것(0.26.8)을 그대로 쓰고 `options.lua` 에서 mason bin 을 PATH 앞에 선행 추가. 실측: mason 미로드 상태에서 `executable("tree-sitter") = 1`, `:checkhealth lazyvim` treesitter ERROR 소멸
- [x] D4 mason `rust-analyzer` 제거 (`mason.lua` + 설치본 삭제). rustup 컴포넌트는 사용자가 `rustup component add rust-analyzer` 로 설치
- [x] README 갱신 — 파일 맵 · 개인 키맵 3개 + LazyVim 자주 쓰는 키 · extras 일원화 · 다크모드 방식 · 의존성(tree-sitter CLI, rustup)
- [x] 사용자 측 설치 완료 확인 — `rustup component add rust-analyzer`(1.92.0, rustc 와 동일), `brew install ghostscript`(10.07.1, PDF→PNG 변환 실측)

## Phase 6 — 문서 · 가이드

- [x] `SETUP.md` — 새 환경 세팅 (심링크 매핑 실측, 필수/언어별/선택 의존성과 이유, mason 런타임 표, 체크리스트, 플래그, 환경별 주의)
- [x] `docs/guide.html` — 13 워크플로 × 언제·핵심 키·해보기·함정. 키는 `nvim_get_keymap` 실측(272 n-map) 기반, 버퍼 로컬 키(LSP·gitsigns·dadbod·탐색기)는 LazyVim/플러그인 기본값
- [x] `TOOLS.md` 확장 (무엇 · 언제 · brew/pacman · nvim 관계), README 를 문서 허브로
- [x] PDF 페이지 넘기기 — snacks.image 엔 키가 없고 `src#page=N` 으로 고르는 구조 → `autocmds.lua` 에 `]p` `[p` `gp` (filetype=image + .pdf 버퍼 한정, 총 페이지는 gs 로)
- [x] `lazy-lock.json` 현행화 (커밋본이 설치본보다 낡아 있었음, 36개)

## Phase 7 — 번들 구조 (dotfiles 레이아웃)

- [x] 저장소를 `~/.config/nvim` → **`~/.dotfiles`** 로 이동, `~/.config/nvim` 은 `~/.dotfiles/nvim` 심링크. lazy.nvim 은 링크 너머로 정상 동작 (stdpath · lockfile 경로 확인)
  - 2026-10-21: 숨김 폴더라 clone 후 안 보이는 불편 때문에 기본 위치를 **`~/Dotfile`** 로 변경
- [x] `caelestia-backup.bak/` 해체 → 앱별 디렉토리 (`ghostty/ helix/ fish/{mac,linux} starship/ fastfetch/ linux/{hypr,niri,foot,btop,thunar}`). 전부 `git mv` 라 이력 유지 (53 renames)
- [x] `.bak` 접미사 폐지. 안 쓰는 것은 `archive/` (wezterm.lua · paneru.toml · nvim-typescript.lua)
- [x] mac fish 를 번들에 편입 (`config.fish` · `fish_plugins` · `functions/fish_greeting.fish`). fisher 산출물(`conf.d/sdk.fish`)·`fish_variables`·terax 통합은 제외
- [x] `link.sh` + `links.txt` — 플랫폼별 매니페스트, 실파일은 `.pre-link-<시각>` 백업, 심링크는 relink, `--dry-run` / `--unlink`
- [x] 잘못 걸려 있던 `~/.config/fastfetch/config.jsonc.bak` 링크 제거 (fastfetch 가 읽지 않는 이름이었음). mac 에선 fastfetch 를 링크하지 않음
- [ ] 리눅스/WSL 에서 `link.sh` 실행해 `linux` 항목 검증 (특히 fish/linux, Thunar 경로)

### 사고 기록 (2026-09-08)

D3 처리 중 `brew install tree-sitter` 를 실행했더니 CLI 가 아니라 **라이브러리만 0.26 → 0.27 로 올라갔고**,
nvim 0.12.4 가 `libtree-sitter.0.26.dylib` 에 동적 링크돼 있어 nvim 이 실행 불가가 됐다 (옛 keg 는 brew 가 삭제).
호환 심링크는 ABI 불일치 위험이 있어 쓰지 않고 `brew upgrade neovim` (0.12.4 → 0.12.5_1, 0.27 링크) 으로 복구.
교훈: **Homebrew 에서 nvim 의 런타임 의존성(tree-sitter, libuv 등)을 단독으로 올리지 말 것** — `brew upgrade` 로 함께 올리거나, 올리기 전 `brew deps --installed neovim` 확인.

이어서 시도한 `brew install tree-sitter-cli` 는 Intel 맥에 bottle 이 없어 llvm@22(1.6GB) + Homebrew `rust` 툴체인을
의존성으로 설치하기 시작했고(rustup 과 PATH 충돌), 중단 후 llvm@22 · rust 를 제거했다 (cargo/rustc 는 rustup 것으로 복귀 확인).
부수 효과로 `pkgconf` 가 3.0.5 → 3.0.7 로 올라감 (옛 keg 는 `brew cleanup pkgconf` 로 정리 가능, 무해).

---

## Phase 8 — 도구가 소유하는 설정 (DankMaterialShell)

2026-10-09, MacBook Air 2014 + CachyOS + niri + DankMaterialShell 에 저장소를 적용하다 발견.

**증상**: DMS 에서 설정을 바꾼 뒤 `link.sh` 를 돌리면 DMS 의 변경이 사라지고 저장소의 `config.kdl` 로 돌아갔다.

**원인**: `link.sh` 는 "저장소가 유일한 진실" 을 전제한다. DMS 처럼 도구가 설정 파일을 직접 쓰는 경우
그 전제가 깨진다. 대부분의 프로그램은 임시 파일에 쓰고 rename 하는 방식으로 저장하는데,
이러면 **심링크가 일반 파일로 대체**된다. 다음 `link.sh` 실행이 그걸 실파일로 보고
`.pre-link-<시각>` 으로 백업한 뒤 저장소 것을 다시 링크한다. (변경이 날아간 게 아니라 백업에 있다.)

**설계 정리** — 설정 파일은 소유권이 셋으로 갈린다:

| 범주 | 예 | 방식 |
| --- | --- | --- |
| 저장소가 소유 (손으로 씀) | nvim · helix · fish · ghostty · foot · btop · starship | `link` (심링크) |
| 도구가 소유, 저장소는 사본 | DMS 가 쓰는 niri `config.kdl` | **`pull`** (시스템 → 저장소) |
| 파생 · 휘발성 | Material3 추출 색상 | 저장소에 넣지 않음 |

- [x] `link.sh` 에 `pull` 모드 추가 — `links.txt` 4번째 칸. 평소엔 건드리지 않고 `./link.sh --pull` 일 때만
      시스템 → 저장소로 복사. 동일하면 `same`, 시스템에 없으면 `SKIP`, 대상이 심링크면 `WARN`.
      샌드박스 7개 시나리오 검증 (최초 링크 · 멱등 · **도구가 덮어쓴 뒤 재실행** · pull · same · 없음 · unlink)
- [x] `links.txt` 에서 `linux/hypr` 링크 제거 — hyprland 시절 설정. 파일은 `linux/hypr/` 에 보관
- [x] `niri/config.kdl` 을 `pull` 모드로 전환
- [x] btop `caelestia.theme` 는 유지 — 유물이 아니라 `btop.conf` 의 `color_theme = "caelestia"` 가 참조한다 (2026-10-22: matugen 템플릿 `dank` 로 교체, archive 로)
- [x] **리눅스에서 확인할 것** — 2026-10-21 CachyOS(niri 26.04 · dms-shell 1.6.3) 에서 실측:
  - [x] DMS 의 `config.kdl` 을 저장소에 반영 (`61e93ad`). noctalia 시절 설정을 버리고 DMS 템플릿으로 교체
  - [x] DMS 는 터미널 설정을 **직접 고치지 않고 색 파일을 따로 생성**한다 — `~/.config/foot/dank-colors.ini`,
        `~/.config/ghostty/themes/dankcolors`. 그래서 `foot.ini` 는 `include`, ghostty 는 `theme = dankcolors` 로
        참조만 하면 되고 `link` 로 유지 (`95457a8`)
  - [x] DMS 가 관리하는 파일 전수 확인 → 아래 "Phase 8-2"
  - [x] 나머지 `linux` 항목 경로 — `link.sh --dry-run` 전부 `ok`
  - [x] 남은 `*.pre-link-*` 백업(niri · fish · btop)과 ghostty `config.ghostty` 를 휴지통으로 (2026-10-21)

### Phase 8-2 — DMS 설정 스냅샷 · 복원 (`--restore`)

**목표**: DMS 설정 화면에서 자유롭게 바꾸되, 포맷 후 재설치하면 그 상태에서 다시 시작한다.
`pull` 은 시스템 → 저장소 한 방향뿐이라 **되돌려 놓을 방법이 없었다**.

DMS 가 쓰는 파일 분류 (실측):

| 파일 | 담는가 | 이유 |
| --- | --- | --- |
| `DankMaterialShell/settings.json` · `plugin_settings.json` | ✅ pull | 내가 고른 값. 바 · 런처 · 스킴 · 커서 … |
| `niri/dms/binds.kdl` | ✅ pull | 키바인드 전부. `config.kdl` 엔 `binds {}` 가 없다 (→ niri 단독 실행 불가, DMS 전제로 결정) |
| `niri/dms/layout.kdl` · `input.kdl` | ✅ pull | gaps · 터치패드. settings.json 에 없고 **이 kdl 자체가 저장 위치** |
| `niri/dms/colors.kdl`, `foot/dank-colors.ini`, ghostty `dankcolors`, gtk `dank-colors.css` … | ❌ | 배경화면에서 매번 재생성 |
| `niri/dms/alttab.kdl` · `cursor.kdl` | ❌ | settings.json(`cornerRadius` · `cursorSettings`)에서 파생 |
| `niri/dms/outputs.kdl` | ❌ | 모니터마다 다르다 |
| `niri/dms/windowrules.kdl` · `wpblur.kdl` | ❌ | 아래 참고 |
| `~/.local/state/DankMaterialShell/session.json` | ❌ | 상태 (라이트 모드 여부 · 배경화면 경로 · 런처 기록) |

- [x] `link.sh --restore`: pull 항목만 저장소 → 시스템 1회 복사. 동일하면 `same`, 저장소에 없으면 `SKIP`,
      대상이 심링크면 `WARN` 후 건너뜀, 기존 파일은 `.pre-restore-<시각>` 백업. `--pull` 과 동시 사용 금지
- [x] 샌드박스 9개 시나리오 (스냅샷 없음 SKIP · 첫 pull · pull 멱등 · dry-run 무변경 · 기본값 위 restore+백업 ·
      restore 멱등 · 내용 일치 · 심링크 WARN · 평소 실행 무간섭 · 동시 옵션 거부)
- [x] 실시스템 `--pull` 로 첫 스냅샷, `--restore --dry-run` 전부 `same`
- [ ] 실제 재설치 때 `--restore` → `dms restart` 순서가 충분한지 확인 (DMS 실행 중 복원의 안전성은 미검증)

**`windowrules.kdl` · `wpblur.kdl` 이 include 되지 않은 이유**: 누락이 아니다. DMS 는 각 설정 탭이 열릴 때
`config.kdl` 에 해당 include 가 있는지 grep 하고, 없으면 그 탭에 "설정" 버튼을 띄워 누르면 include 줄을 덧붙인다
(바이너리 내장 QML `checkIncludeStatus` / `fixInclude`). 즉 그 기능(창 규칙 · 배경 blur)을 처음 쓸 때 DMS 가
`config.kdl` 을 고치고, 그 변경은 다음 `--pull` 에 잡힌다.
단, `windowrules` 는 실제로 **한 번 켜 둔 적이 있었다** — Phase 8 때 남은 `config.kdl.pre-link-*` 백업이 지금
`config.kdl` 과 정확히 `include "dms/windowrules.kdl"` 한 줄만 달랐다. link/백업 과정에서 잃은 것이라 되살리고 pull 했다.

---

## Phase 9 — 로그인 · 잠금 화면과 새 설치 스크립트 (2026-10-21 ~ 22)

**증상**: 잠금(Ctrl+Cmd+Q) 후 덮개를 닫았다 열면 가끔 비밀번호를 쳐도 안 풀려 재부팅해야 했다.

**조사**:
- 잠금 화면은 SDDM 이 아니라 qylock 의 quickshell 잠금 프로그램이 SDDM 테마를 흉내 내는 것 (`SddmShim.qml`)
- 10/21 16:35 잠금 → 21:28 재개 → 21:29 재부팅 사례: 그 사이 PAM 인증 실패 로그가 **0건**. 틀린 게 아니라 인증이 진행되지 않았다
- `SddmShim.login()` 은 빈 비밀번호로도 `pam.start()` 를 부른다. PAM 이 `Password:` 를 묻는데 `pendingPassword` 가 빈 문자열이라
  답하지 않고, 이후의 `start()` 는 이미 active 라 아무 일도 안 한다 → **영구 대기**. 잠금 없는 quickshell 하네스로 재현
- 덤: 잠글 때마다 DMS 도 자기 잠금을 시도해 niri 가 거절(`refusing lock as already locked`) — 두 잠금 프로그램의 경합

**수정**:
- [x] `linux/qylock/lockscreen-pam-hang.patch` — 빈 Enter 무시, 대기 중 PAM 이면 그 세션에 답함, 확인 중엔 결과를 기다림.
      하네스: 빈 Enter → 틀림 → 확인 중 연타 → 재시도 모두 `completed`, 멈춤 0. 실기기 테스트 창(`QS_TESTING=1`) · 실제 잠금 확인
- [x] DMS 를 외부 잠금으로: `customPowerActionLock` = `lock.sh`, `lockBeforeSuspend` = true, 단축키는 `dms ipc call lock lock`.
      경합 해소, 덮개만 닫아도 잠김 (DMS 소스에서 `spawnCustomLocker` · `handleLoginctlCustomLock` 경로 확인)
- [x] 패키지 정리: Qt5 일체(`qt5-graphicaleffects` 등 4개)와 `qt6-multimedia-gstreamer`(+gst-plugins 등 5개) 제거.
      테마는 `QtVersion=6`, 영상은 FFmpeg 엔진. 제거 전후 `sddm-greeter-qt6 --test-mode` 출력 동일, 잠금 화면 영상 정상
- [x] `linux/packages.txt` · `linux/setup.sh` — pacman 로그의 직접 설치 이력으로 목록화, 빠진 것(JetBrains Mono Nerd · wl-clipboard ·
      direnv)은 설치. 처음 설치 시나리오(임시 HOME)에서 잠금 화면이 현재 설치본과 동일, 재실행은 전 단계 skip

**사고 기록**:
- 패치 검증에 틀린 비밀번호 2번을 썼는데, 이어진 사용자 테스트의 1번과 합쳐 `pam_faillock`(3회 → 10분)에 걸렸다.
  비밀번호 검증 테스트는 틀린 시도 횟수를 센다 — 실계정으로는 하지 말 것 (SETUP §10-5)
- 설치 시뮬레이션에서 qylock clone(영상 포함 1.2GB)을 `/tmp` 로 복사 → `/tmp` 는 **tmpfs(RAM)** 라 RAM 4GB 기기에서
  systemd-oomd 가 앱을 강제 종료. 큰 파일은 복사하지 말고 링크하거나 디스크(`~/.cache`)에서 할 것

## Phase 10 — 리눅스 데스크톱 다듬기 (2026-10-22 ~ 29)

Phase 9 뒤로 리눅스 쪽에서 바꾼 것. 자세한 사용법은 SETUP, 이유와 확인 과정은 각 커밋 본문에 있다.

- 터미널: 주 터미널을 ghostty 로 바꿨다(niri `Mod+T`, 로그인 때 창 없이 미리 띄움). 탭 바는 얇게, 배경은 matugen 템플릿으로 터미널과 같은 색
- DMS 색 따라가기: btop 테마, ghostty 탭 바, kime 트레이 아이콘을 matugen 사용자 템플릿으로 만든다(SETUP §10-4).
  `config.toml` 의 `[templates]` 줄 위에 그 글자를 쓰면 DMS 색 생성 전체가 실패한다는 함정을 한 번 밟았다
- nvim: JS/TS 는 프로젝트에 eslint 설정이 있으면 eslint 와 prettier, 없으면 biome (`lua/util/jslint.lua`).
  vtsls 와 린터의 안 쓰는 변수 중복을 거르고, `K` 는 설명이 없으면 조용히. markdown 은 한글 맞춤법 제외, modeline 끔
- 스크린샷: `Alt+Shift+3/4/5`, 창 캡처는 그림자 넣는 스크립트(SETUP §13)
- 기본 앱: 이미지 Loupe, PDF zathura (`setup.sh apps`). 이미 지정됐는지를 형식 하나만 보고 판단하다 빈 설정에서 건너뛰는 버그를 고쳤다
- starship: 경로를 입력 줄 윗줄로, 프롬프트 앞에 빈 줄

사고 기록

- 테스트 프로세스를 `pkill -f` 로 정리하다 명령을 실행하던 셸까지 패턴에 걸려 끝난 적이 두 번 있다. pid 를 골라 끊을 것
- 맥 remote 를 SSH 주소로 안내해 HTTPS 인증이 깨졌다. 이 저장소는 HTTPS 를 쓴다 (`~/.claude/CLAUDE.md`)

## 결정 기록 (D)

| # | 주제 | 결정 | 날짜 |
|---|---|---|---|
| D1 | pyright 진단 끄고 ruff 만 진단 / 완성·이동은 pyright | **(a) 채택.** `analysis.ignore = {"*"}` 유지, `typeCheckingMode` 삭제. 타입 에러는 안 보임을 인지 | 2026-09-08 |
| D2 | toggleterm 제거, snacks.terminal 로 float·bottom·right | **`<C-\>` 채택.** `<leader>tt`/`to` 는 neotest 에 반환. float 인스턴스는 `count = 9` 로 분리 | 2026-09-08 |
| D3 | tree-sitter CLI | **mason 것 + PATH 선행 추가 채택.** brew 는 `tree-sitter`(라이브러리, nvim 링크 파손) / `tree-sitter-cli`(Intel 맥에서 llvm+rust 의존) 둘 다 부적합 | 2026-09-08 |
| D4 | rust-analyzer 출처 | **rustup 컴포넌트 채택.** mason 은 PATH 앞에 끼어들어 rustup 것을 가리므로 설치본까지 제거 | 2026-09-08 |
