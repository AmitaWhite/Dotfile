# Dotfile

맥, CachyOS(niri + DankMaterialShell), WSL에서 같이 쓰는 설정 모음.
앱별 폴더에 설정을 두고 `link.sh`로 `~/.config` 아래에 심링크를 건다.

## 빠른 시작

```bash
git clone https://github.com/AmitaWhite/Dotfile.git ~/Dotfile
~/Dotfile/link.sh --dry-run   # 무엇을 바꿀지 먼저 보기
~/Dotfile/link.sh
```

필요한 도구, 언어별 툴체인, CachyOS 새 설치 순서는 [SETUP.md](SETUP.md)에 있다.
맥에서는 `brew install tree-sitter`를 하지 말 것. 라이브러리 패키지라 nvim이 실행되지 않게 된다(SETUP.md §5).

## 담는 것과 안 담는 것

LazyVim이나 DMS가 기본으로 해주는 건 그대로 쓰고, 내가 바꾼 것만 여기 둔다.
기본값과 같은 설정까지 들고 있으면 환경이 업데이트될 때마다 충돌이 난다.

| 담음 | 안 담음 |
| --- | --- |
| 직접 바꾼 키맵, 옵션, 색 보정 | 기본값과 같은 설정 |
| OS별로 쓰는 프로그램 목록 ([TOOLS.md](TOOLS.md)) | 프로그램이 알아서 만드는 설정과 상태 파일 |
| 셸 설정 중 손으로 쓴 부분 | fisher가 만드는 `conf.d/`, `fish_variables` |
| 도구가 직접 쓰는 설정의 사본 (`links.txt`의 `pull`) | DMS가 배경화면에서 뽑는 색 같은 생성값 |

nvim에 이 기준을 적용한 과정은 [REFACTOR.md](REFACTOR.md) Phase 1~5에 있다. 플러그인 설정 파일이 20개에서 10개로 줄었다.

## 구조

```txt
nvim/        Neovim (LazyVim). ~/.config/nvim 에 링크
ghostty/     config.mac, config.arch
helix/       config.toml, languages.toml, themes/
fish/        mac/, linux/
starship/    starship.toml
fastfetch/   config.jsonc (linux)
linux/       niri, dms, foot, btop, kime, qylock, matugen (linux 전용)
             hypr 는 예전 설정이라 링크하지 않고 보관만
             setup.sh, packages.txt: CachyOS + DMS 새 설치용
archive/     안 쓰지만 남겨둔 것 (wezterm, paneru, thunar, 예전 nvim 설정)
docs/        nvim 기능 가이드
link.sh      심링크 스크립트. 어디에 무엇을 거는지는 links.txt
```

## 문서

| 문서 | 내용 |
| --- | --- |
| [SETUP.md](SETUP.md) | 새 머신 세팅. 필요한 도구와 이유, 언어별 툴체인, 환경별 주의(§9), CachyOS + DMS 설치(§10), fisher와 sdkman(§11), 디스크 정리(§12) |
| [docs/guide.html](docs/guide.html) | nvim 기능 가이드. 상황별로 키를 직접 눌러보며 익히는 페이지 |
| [TOOLS.md](TOOLS.md) | 쓰는 CLI/TUI 도구 목록 |
| [REFACTOR.md](REFACTOR.md) | 정리하면서 내린 결정, 겪은 사고, 글쓰기 규칙 |

---

## Neovim

### 설정 파일

`~/.config/nvim`은 `~/Dotfile/nvim`으로 가는 심링크다. 아래 경로는 `nvim/` 기준.

```txt
init.lua                  시작점. lua/config/lazy.lua 를 부른다
lazyvim.json              켜둔 extras 목록 (:LazyExtras 로 관리, 직접 고쳐도 된다)
lazy-lock.json            플러그인 버전 고정 (lazy.nvim 이 심링크를 따라 여기에 쓴다)
lua/config/
  lazy.lua                lazy.nvim 설정, 성능/UI 옵션 (extras 는 여기 적지 않는다)
  options.lua             vim 옵션 (wrap, winborder, mason bin PATH 등)
  keymaps.lua             개인 키맵. LazyVim 과 겹치지 않는 것만
  autocmds.lua            PDF 페이지 넘기기, 터미널 테마 따라가기
lua/plugins/*.lua         플러그인별 설정 (파일 하나에 플러그인 하나)
  lsp.lua                 LSP 서버 설정. extras 가 안 다루는 서버와 기본값을 바꾼 것만
```

옵션, 키맵, 자동명령은 LazyVim이 `VeryLazy` 시점에 불러온다.
다른 플러그인이 이미 잡은 키맵을 바꾸려면 `lua/config/keymaps.lua`에서 다시 정의해야 한다.

### nvim 설정 규칙 (자세한 건 REFACTOR.md)

- 뭔가 추가하기 전에 LazyVim이 이미 해주는지 확인한다 (`:LazyExtras`, LazyVim 소스 검색)
- 키맵은 LazyVim 그룹 prefix(`<leader>s` `t` `d` `n` `w` `<tab>`)를 쓰지 않는다
- 플러그인 설정은 `opts`로 한다. `config = function()`은 LazyVim 기본 설정을 통째로 덮어써서 쓰지 않는다
- extras는 `lazyvim.json`에만 둔다. `lazy.lua`에 `import = "lazyvim.plugins.extras.*"`를 직접 쓰지 않는다

### 개인 키맵

| 키           | 모드 | 동작                                  |
| ------------ | ---- | ------------------------------------- |
| `jk`         | i    | ESC                                   |
| `<leader>fh` | n    | 오른쪽 세로 터미널 (snacks.terminal)  |
| `<C-\>`      | n, t | 플로팅 터미널 열기/닫기 (터미널 안에서도) |
| `]p` / `[p` / `gp` | n (PDF 버퍼) | PDF 다음 / 이전 / 번호로 이동 (`autocmds.lua`, snacks에는 페이지 키가 없음) |

나머지는 LazyVim 기본값이다. 자주 쓰는 것:

| 키                       | 동작                                      |
| ------------------------ | ----------------------------------------- |
| `<leader>qq`             | 전부 종료 (`:q`는 창 하나만 닫는다)       |
| `<C-/>` / `<leader>ft`   | 아래 터미널 열기/닫기                     |
| `<leader>-` / `<leader>\|` | 창 가로 / 세로 분할, `<leader>wd`로 닫기 |
| `<leader><tab><tab>`     | 새 탭 (`<leader><tab>` 그룹)              |
| `<leader>e`              | 파일 탐색기 (snacks.explorer)             |
| `<leader><space>` / `<leader>/` | 파일 찾기 / grep (snacks.picker)   |
| `<leader>sh`             | 도움말 검색                               |
| `<leader>tt` / `tr` / `ts` | 테스트 파일 실행 / 가장 가까운 테스트 / 요약 |
| `<leader>cD`             | docstring 생성 (vim-doge)                 |
| `]t` / `[t`              | 다음 / 이전 TODO 주석                     |

### extras와 언어 도구

전부 `lazyvim.json`에 있고 `:LazyExtras`로 켜고 끈다.

- 언어: clangd, docker, java, json, markdown, python, rust, sql, tailwind, toml, typescript(+biome), yaml
- 코딩: mini-surround
- 포맷/린트: prettier, eslint
- 디버그/테스트: dap.core, test.core (neotest + neotest-java)

`lua/plugins/lsp.lua`에서 직접 바꾼 것:

| 언어   | 서버           | 비고 |
| ------ | -------------- | ---- |
| Python | pyright + ruff | 진단은 ruff만 낸다. pyright는 자동완성, 정의 이동, hover 담당 (타입 에러는 표시 안 됨) |
| SQL    | postgres_lsp   | sql extra에 LSP가 없어서 직접 추가 |
| JS/TS  | vtsls + eslint | eslint가 붙은 버퍼에서는 vtsls의 "안 쓰는 변수, import" 진단을 버린다 (같은 경고가 두 번 뜨던 것) |
| HTML, JSP | html + emmet_language_server | JSP에서도 HTML 태그 완성과 Emmet. emmet은 html, jsp에만 켬 (React, CSS에는 안 켬) |

Java(jdtls, lombok 포함)는 extras 기본값 그대로다.
mason이 자동으로 까는 것은 `stylua`, `shellcheck`, `shfmt`, `lemminx`. rust-analyzer는 rustup 컴포넌트로 깐다(mason에서는 안 깐다).

### 알아둘 것

- 파일 찾기는 `snacks.picker`, 입력창은 `snacks.input`이다 (telescope와 dressing은 뺐다)
- 창 테두리는 `options.lua`의 `vim.opt.winborder` 하나로 정한다. noice와 lazy 창은 이 옵션을 안 따라서 따로 설정했다
- 다크/라이트: nvim이 터미널 배경색을 보고 `tokyonight-day`나 `tokyonight-night`를 고른다. nvim을 켜둔 채 OS 테마를 바꾸면 터미널 창을 다시 클릭할 때 따라온다(`autocmds.lua`). 터미널도 OS 테마를 따라가게 해둬야 하는데, 리눅스는 DMS가 foot과 ghostty 색을 만들어 주고, 맥 ghostty는 `theme = light:TokyoNight Day,dark:TokyoNight Night`로 해뒀다. 왜 이렇게 했는지는 REFACTOR.md에 있다
- 색 테마는 tokyonight에 `transparent = true`
- Markdown: 맞춤법 검사는 영어만 한다(`spelllang = en,cjk`로 한글 제외). markdownlint는 `nvim/.markdownlint-cli2.yaml`에서 줄 길이, 빈 줄, HTML 같은 스타일 규칙을 끄고 쓴다

---

## 셸과 터미널

- fish + fisher. `reitzig/sdkman-for-fish`가 JDK를 잡아주므로 nvim은 fish 터미널에서 켠다
- ghostty: 주로 쓰는 터미널. 이미지 표시(kitty graphics)를 지원하고, 테마는 OS를 따라간다
- starship: 프롬프트
- yazi: 파일 매니저, zoxide: 자주 가는 폴더로 `cd`
- bat, tldr: cat, man 대신
- 에디터: helix(`hx`), zed (리눅스에서는 `zeditor`)
