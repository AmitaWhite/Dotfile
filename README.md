# dotfiles

macOS · Arch/CachyOS · WSL 을 오가며 쓰는 설정 번들. 저장소는 `~/Dotfile` 에 두고, 앱별 디렉토리를
`link.sh` 가 실제 경로(`~/.config/...`)에 심링크로 건다. 어느 파일이 어디에 걸리는지는 `links.txt` 가 전부다.

## 원칙 — 오버라이드만 담는다

환경을 통째로 재구성하려는 저장소가 아니다. 프레임워크와 데스크톱 환경(LazyVim · DankMaterialShell …)이
주는 **편의와 외형은 그대로 누리고, 내가 바꾼 것만** 저장소가 소유한다.

| 담는다 | 담지 않는다 |
| --- | --- |
| 내가 바꾼 키맵 · 옵션 · 색 보정 | 프레임워크 기본값과 같은 설정 |
| OS 별로 쓰는 프로그램 목록 ([TOOLS.md](TOOLS.md)) | 그 프로그램들이 생성하는 설정 · 상태 파일 |
| 셸 설정 중 손으로 쓴 부분 | 플러그인 매니저가 만드는 것 (fisher `conf.d/`, `fish_variables` …) |
| 도구가 쓰는 설정의 사본 (`links.txt` 의 `pull`) | 런타임 파생값 (DMS 의 Material3 추출 색 …) |

애매하면 질문은 하나다 — **"환경이 이미 해주는가?"**
해준다면 담지 않는다. 담으면 환경이 업데이트될 때마다 그것과 싸우게 된다.
(이 원칙을 nvim 에 적용한 결과가 [REFACTOR.md](REFACTOR.md) 의 Phase 1~5 다: 플러그인 설정 파일 20 → 10)

---

```txt
nvim/        Neovim (LazyVim)  → ~/.config/nvim          ← 이 README 의 대부분은 이것
ghostty/     config.mac · config.arch                    (플랫폼별)
helix/       config.toml · languages.toml · themes/
fish/        mac/ · linux/     (config.fish · fish_plugins · functions/)
starship/    starship.toml
fastfetch/   config.jsonc                                (linux)
linux/       niri · dms · foot · btop · kime · qylock    (Wayland DE, linux 전용. hypr 는 보관만)
archive/     안 쓰지만 버리지 않은 것 (wezterm · paneru · thunar · 옛 nvim tsserver 설정)
docs/        기능 가이드
link.sh · links.txt   심링크 스크립트 · 매니페스트
linux/setup.sh · packages.txt   CachyOS + DMS 새 설치 스크립트 · 패키지 목록 (SETUP §10)
```

| 문서 | 내용 |
| --- | --- |
| [SETUP.md](SETUP.md) | **새 환경 세팅** — 심링크 매핑, 필수 도구와 이유, 언어 툴체인, 선택 기능, 첫 실행 체크리스트, CachyOS + DMS 새 설치(§10) |
| [docs/guide.html](docs/guide.html) | **기능 가이드** — 워크플로별로 "언제 · 어떻게" 직접 해보며 익히는 페이지 |
| [TOOLS.md](TOOLS.md) | 개인 CLI/TUI 도구 카탈로그 (용도 · 언제 · 설치) |
| [REFACTOR.md](REFACTOR.md) | 설정 리팩터링 기록 · 작성 규칙 · 결정 사항 · 사고 기록 |

이 저장소는 여러 환경(macOS Intel · Arch/CachyOS · WSL)을 오가며 쓴다. 환경 차이는 SETUP.md §9.

---

## Neovim

### 설정 파일 맵

`~/.config/nvim` → `~/Dotfile/nvim` 심링크. 아래 경로는 `nvim/` 기준.

```txt
init.lua                  부트스트랩 → lua/config/lazy.lua
lazyvim.json              활성 extras 목록 (:LazyExtras 가 관리, 직접 편집도 가능)
lazy-lock.json            플러그인 버전 고정 (lazy.nvim 이 심링크 너머로 여기에 쓴다)
lua/config/
  lazy.lua                lazy.nvim 셋업, 성능/UI 옵션 (extras 는 여기 안 적음)
  options.lua             vim 옵션 (wrap, winborder, mason bin PATH …)
  keymaps.lua             개인 키맵 — LazyVim 과 겹치지 않는 것만
  autocmds.lua            PDF 페이지 넘기기 (]p [p gp)
lua/plugins/*.lua         플러그인별 오버라이드 (파일 1개 = 플러그인 1개)
  lsp.lua                 LSP 서버 설정 — extras 가 안 다루는 서버 · extras 기본값 변경만
```

옵션/키맵/오토커맨드는 LazyVim 이 `VeryLazy` 에서 자동 로드한다.
**플러그인이 이미 잡은 키맵을 바꾸려면 `lua/config/keymaps.lua` 에서 재정의**해야 override 된다.

### 작성 규칙 (요약, 자세한 건 REFACTOR.md)

- 뭔가 추가하기 전에 **LazyVim 이 이미 해주는지** 확인 (`:LazyExtras`, LazyVim 소스 grep)
- 키맵은 LazyVim 그룹 prefix(`<leader>s` `t` `d` `n` `w` `<tab>`) 를 침범하지 않는다
- 플러그인 스펙은 `opts` 로. `config = function()` 은 LazyVim 기본 설정을 통째로 버리므로 금지
- extras 는 `lazyvim.json` 에만. `lazy.lua` 에 `import = "lazyvim.plugins.extras.*"` 를 직접 쓰지 않는다

### 개인 키맵

| 키           | 모드 | 동작                                  |
| ------------ | ---- | ------------------------------------- |
| `jk`         | i    | ESC                                   |
| `<leader>fh` | n    | 오른쪽 세로 터미널 (snacks.terminal)  |
| `<C-\>`      | n, t | 플로팅 터미널 토글 (터미널 안에서도)  |
| `]p` / `[p` / `gp` | n (PDF 버퍼) | PDF 다음 / 이전 / 번호로 페이지 (`autocmds.lua`, snacks 는 페이지 키가 없음) |

그 외는 전부 LazyVim 기본. 자주 쓰는 것:

| 키                       | 동작                                      |
| ------------------------ | ----------------------------------------- |
| `<leader>qq`             | 전체 종료 (`:q` 는 창 하나만 닫는다)      |
| `<C-/>` / `<leader>ft`   | 아래 터미널 토글                          |
| `<leader>-` / `<leader>\|` | 창 가로 / 세로 분할, `<leader>wd` 닫기  |
| `<leader><tab><tab>`     | 새 탭 (`<leader><tab>` 그룹)              |
| `<leader>e`              | 파일 탐색기 (snacks.explorer)             |
| `<leader><space>` / `<leader>/` | 파일 찾기 / grep (snacks.picker)   |
| `<leader>sh`             | 도움말 검색                               |
| `<leader>tt` / `tr` / `ts` | 테스트 파일 실행 / 가장 가까운 것 / 요약 |
| `<leader>cD`             | docstring 생성 (vim-doge)                 |
| `]t` / `[t`              | 다음 / 이전 TODO 주석                     |

### 활성 extras / 언어 도구

전부 `lazyvim.json` 에 있고 `:LazyExtras` 로 켜고 끈다.

- **언어**: clangd, docker, java, json, markdown, python, rust, sql, tailwind, toml, typescript(+biome), yaml
- **코딩**: mini-surround
- **포맷/린트**: prettier, eslint
- **디버그/테스트**: dap.core, test.core (neotest + neotest-java)

`lua/plugins/lsp.lua` 에서 직접 손댄 것:

| 언어   | 서버           | 비고                                                             |
| ------ | -------------- | ---------------------------------------------------------------- |
| Python | pyright + ruff | **진단은 ruff 만**, pyright 는 완성·정의 이동·hover 담당 (타입 에러는 안 보임) |
| SQL    | postgres_lsp   | sql extra 가 LSP 를 안 넣어서 직접 추가                          |

TS(vtsls) · Java(jdtls, lombok 포함) 는 extras 기본값 그대로.
mason 자동설치: `stylua`, `shellcheck`, `shfmt`, `lemminx`. **rust-analyzer 는 rustup 컴포넌트**로.

### 알아둘 점

- **Picker 는 `snacks.picker`**, 입력창은 `snacks.input` (telescope · dressing 제거함)
- **창 테두리는 `vim.opt.winborder`** 한 곳에서 제어 (`options.lua`). noice / lazy 는 미지원이라 각자 설정
- **다크/라이트**: nvim 이 터미널 배경색을 자동 감지해 `background` 를 세팅하고, tokyonight 가
  dark=`moon` / light=`day` 를 고른다. 셸 호출 없음. **터미널도 OS 를 따라가야** 실제로 전환됨
  → ghostty: `theme = light:TokyoNight Day,dark:TokyoNight Moon`
- colorscheme 는 tokyonight, `transparent = true`

---

## 새 머신 세팅

→ [SETUP.md](SETUP.md). 요약: 심링크 걸기 → 필수 도구(git·curl·rg·fd·fzf·lazygit·C 컴파일러·Nerd Font·node·python)
→ 쓰는 언어 툴체인(JDK 21 sdkman · rustup · uv) → `nvim` 첫 실행 → `:checkhealth`.

⚠️ mac 에서 `brew install tree-sitter` 금지 (라이브러리라 nvim 링크가 깨짐). CLI 는 mason 것을 쓴다.

---

## 셸 / 터미널 환경

- **fish** + **fisher** (`reitzig/sdkman-for-fish` 로 JDK 초기화 — nvim 은 fish 터미널에서 실행)
- **ghostty** — 터미널 에뮬레이터. 이미지 렌더(kitty graphics) 지원. 테마는 OS 를 따라가게 설정
- **starship** — 프롬프트
- **yazi** — 파일 매니저 · **zoxide** — 스마트 `cd`
- **bat**, **tldr** — cat / man 대체
- 에디터: **helix** (`hx`), **zed** (Linux 는 `zeditor`)
