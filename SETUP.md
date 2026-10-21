# 새 환경 세팅

이 저장소를 받아 **macOS · Arch/CachyOS · WSL(Arch)** 어디서든 같은 nvim 을 쓰기 위한 절차.
"무엇을 왜 깔아야 하는지"까지 적는다. 개인 취향 도구는 [TOOLS.md](TOOLS.md), 키 사용법은 [docs/guide.html](docs/guide.html).

## 0. 한눈에

```txt
1. git clone git@github.com:AmitaWhite/Dotfile.git ~/Dotfile
2. ~/Dotfile/link.sh --dry-run  →  ~/Dotfile/link.sh     (§1)
3. 필수 도구 설치 (§2)  ← 이것만 있으면 nvim 은 뜬다
4. 언어 툴체인 (§3)      ← 쓰는 언어만
5. 선택 기능 (§4)        ← 이미지·PDF·DB 등
6. nvim 첫 실행 → :Lazy sync → :checkhealth (§6)
```

**CachyOS + DankMaterialShell(niri) 를 새로 깔 때는 §10 의 `linux/setup.sh` 하나로** 패키지 · 링크 · DMS 설정 복원 ·
로그인/잠금 화면까지 맞춘다 (위 2~5 의 리눅스 부분을 포함).

## 1. 심링크 — `link.sh` + `links.txt`

저장소는 `~/Dotfile` 에 두고, 실제 경로엔 **심링크만** 있다. 어디에 무엇이 걸리는지는 [links.txt](links.txt) 한 파일이 전부다
(`<플랫폼> <저장소 경로> <실제 경로> [모드]`, 플랫폼은 `all` / `mac` / `linux`, WSL 은 linux).
숨김 폴더로 받아지지 않게 clone 대상을 `~/Dotfile` 로 준다. `link.sh` 는 자기 위치(`$0` 의 디렉토리)를 저장소로 보므로
위치를 옮겨도 동작하고, 옮긴 뒤 `link.sh` 를 다시 돌리면 옛 위치를 가리키던 링크가 `relink` 된다.
(예전 위치 `~/.dotfiles` 에서 옮길 때: `mv ~/.dotfiles ~/Dotfile && ~/Dotfile/link.sh`.
 GitHub 저장소 이름도 `.dotfile` → `Dotfile` 로 바뀌었다 — 옛 주소는 리다이렉트되지만 `git remote set-url origin …/Dotfile.git` 권장)

```bash
~/Dotfile/link.sh --dry-run     # 무엇을 할지만 본다
~/Dotfile/link.sh               # 현재 플랫폼 항목 링크
~/Dotfile/link.sh --pull        # 도구가 소유한 설정을 시스템 → 저장소로 가져온다 (스냅샷)
~/Dotfile/link.sh --restore     # 그 스냅샷을 저장소 → 시스템으로 되돌린다 (재설치 후 1회)
~/Dotfile/link.sh --unlink      # 이 스크립트가 건 링크만 해제
```

**모드** (4번째 칸, 생략하면 `link`):

| 모드 | 소유자 | 동작 |
| --- | --- | --- |
| `link` | 저장소 | 실제 경로에 심링크를 건다. 저장소가 진실 — 시스템에서 바꾸면 되돌아간다 |
| `pull` | 도구 | 링크하지 않는다. `--pull` 이면 시스템 → 저장소(스냅샷), `--restore` 면 저장소 → 시스템(1회 복원) |

`pull` 은 **고정이 아니라 스냅샷**이다. 평소엔 DMS 설정 화면에서 마음껏 바꾸고, 남겨두고 싶을 때 `--pull` → 커밋.
저장소엔 마지막으로 찍은 상태가 남고, 포맷 후엔 `--restore` 로 그 상태에서 다시 시작한다. 그 뒤로는 다시 도구가 주인이다.

`pull` 이 필요한 이유: DankMaterialShell 처럼 **도구가 설정 파일을 직접 쓰는** 경우, 저장 시
임시 파일 + rename 으로 **심링크가 일반 파일로 대체**된다. 그러면 다음 `link.sh` 가 그걸 실파일로 보고
`.pre-link-<시각>` 으로 백업한 뒤 저장소 것을 되돌려, 도구의 변경이 사라진 것처럼 보인다.
`pull` 항목은 평소 실행에서 `pull?` 로만 표시되고 건드리지 않는다. 반영하려면:

```bash
~/Dotfile/link.sh --pull && cd ~/Dotfile && git diff   # 확인 후 커밋
```

### 1-1. CachyOS + DMS 재설치 후 복원

DMS 는 첫 실행 때 `~/.config/niri/dms/*` · `settings.json` 을 기본값으로 만든다. 복원은 **그 다음에** 한다.

```bash
# CachyOS(No desktop) → niri + DMS 설치 → 로그인해서 DMS 를 한 번 띄운 상태에서
~/Dotfile/link.sh                       # link 항목 (nvim · foot · fish …)
~/Dotfile/link.sh --restore --dry-run   # 무엇을 덮을지 확인
~/Dotfile/link.sh --restore             # 기존 파일은 *.pre-restore-<시각> 으로 백업
dms restart                               # 실행 중인 DMS 가 메모리의 기본값으로 덮어쓰지 않게 바로 재시작
```

복원 대상 (`links.txt` 의 `pull`): niri `config.kdl`, `dms/binds.kdl` · `layout.kdl` · `input.kdl`, DMS `settings.json` · `plugin_settings.json`.
색(`colors.kdl`, `dank-colors.ini`, ghostty `dankcolors` …)은 배경화면에서 다시 생성되므로 담지 않는다.
`outputs.kdl` 은 모니터마다 달라 담지 않는다 — DMS 디스플레이 설정에서 새로 잡는다.

동작 규칙:
- 이미 올바른 링크면 `ok`, 다른 곳을 가리키는 링크면 `relink`(백업 없음 — 링크는 데이터가 아니다)
- **실파일이 있으면 절대 덮어쓰지 않고** `<파일>.pre-link-<시각>` 으로 옮긴다. 내용 확인 후 지우면 된다
- 저장소 쪽 파일이 없으면 `SKIP` (매니페스트 오타 방지)

새 앱을 번들에 넣을 때: 파일을 앱 디렉토리에 두고 `links.txt` 에 한 줄 추가 → `link.sh`.

주의:
- `~/.config/nvim` 자체가 `~/Dotfile/nvim` 링크다. lazy.nvim 은 `stdpath("config")` 를 통해 링크 너머의 `lazy-lock.json` 에 쓴다 (확인됨)
- fish 는 `config.fish` · `fish_plugins` · `functions/fish_greeting.fish` 만 링크. `conf.d/`·`fish_variables` 는 fisher/fish 가 만드는 머신 상태라 저장소에 없다. 새 머신에선 fisher 설치 후 `fisher update` 로 `fish_plugins` 목록이 복원된다
- `linux/` 의 niri · dms · foot · btop · kime 는 Wayland 세션에서만 의미 있다 (hypr 는 링크하지 않고 보관만). 파일 관리자는 nautilus — thunar 설정은 `archive/thunar`

## 2. 필수 — 없으면 `:checkhealth` 가 빨갛다

| 도구 | 왜 필요한가 | mac (brew) | Arch (pacman) |
| --- | --- | --- | --- |
| **neovim ≥ 0.11** (현재 0.12.5) | `winborder`, 배경 자동 감지, `vim.lsp.config` 사용 | `neovim` | `neovim` |
| **git, curl, wget, unzip, gzip, tar** | lazy.nvim 플러그인 clone, mason 이 LSP/포매터 다운로드·압축 해제 | 기본 + `wget` | `base` + `wget unzip` |
| **C 컴파일러** | treesitter 파서 컴파일 | `xcode-select --install` | `base-devel` |
| **ripgrep (`rg`), fd** | 파일·문자열 검색 (snacks.picker, grep) | `ripgrep fd` | `ripgrep fd` |
| **fzf** | 퍼지 검색 백엔드 | `fzf` | `fzf` |
| **lazygit** | Git UI (`<leader>gg`) | `lazygit` | `lazygit` |
| **Nerd Font** | 아이콘 (mini.icons, lualine, 탐색기) | `--cask font-jetbrains-mono-nerd-font` | `ttf-jetbrainsmono-nerd` |
| **node + npm** | mason 이 설치하는 LSP 대부분이 node 로 실행됨 (아래 §5) | `node` 또는 fnm | `nodejs npm` |
| **python3 + pip/venv** | ruff·debugpy·sqlfluff 실행, venv 선택 | `uv` 권장 | `python uv` |

터미널: 이미지 렌더(snacks.image)는 **kitty graphics protocol** 지원 터미널(ghostty · kitty · wezterm)에서만 된다. foot/기본 Terminal.app/WSL 콘솔은 안 됨.

## 3. 언어 툴체인 — 쓰는 언어만

LSP 자체는 mason 이 자동 설치하지만, **런타임/툴체인은 시스템에 있어야** 한다.

| 언어 | 필요한 것 | 왜 | 설치 |
| --- | --- | --- | --- |
| **Java** | JDK 21+ (`JAVA_HOME`) | jdtls 가 JDK 21 이상에서만 실행. lombok 은 java extra 가 자동 주입 | **sdkman** `sdk install java 21.0.10-amzn`. fish 는 fisher 의 `reitzig/sdkman-for-fish` 가 `conf.d/sdk.fish` 로 초기화 → **nvim 을 fish 터미널에서 실행**해야 java 가 잡힌다 (GUI 런처 ✘) |
| **Rust** | rustup + `rust-analyzer` 컴포넌트 | mason 것은 툴체인과 버전이 어긋날 수 있어 rustup 으로 통일 (D4) | `rustup component add rust-analyzer`. 디버거 codelldb 는 mason |
| **Python** | python3, uv | pyright(완성·이동) + ruff(진단·포맷). 진단은 ruff 만 (D1) | `uv python install 3.13`. 프로젝트 venv 는 `<leader>cv` 로 선택 |
| **TS/JS** | node | vtsls · eslint · biome · prettier 전부 node. 디버그 실행기는 `tsx` 있으면 사용 | `npm i -g tsx` (선택) |
| **C/C++** | clangd (mason) + 프로젝트의 `compile_commands.json` | 없으면 헤더 못 찾음 | CMake: `-DCMAKE_EXPORT_COMPILE_COMMANDS=ON`, 또는 `bear` |
| **SQL** | DB 클라이언트 바이너리 | vim-dadbod 가 `psql`/`mysql`/`sqlite3` 를 **셸로 호출**한다. LSP 는 postgres_lsp(mason) — 단 **프로젝트 루트에 `postgres-language-server.jsonc` 가 있어야 붙는다** (`workspace_required`). 낱개 .sql 파일엔 안 붙음 | `postgresql`(psql), `mysql-client`, `sqlite`. 프로젝트에서 `postgres-language-server init` |
| **Docker** | (없음) | dockerls · hadolint 모두 mason | |
| **Markdown** | (없음) | markdown-preview 는 첫 빌드 때 바이너리 다운로드(인터넷 필요) | |

## 4. 선택 기능

| 기능 | 필요한 것 | 설치 |
| --- | --- | --- |
| 이미지 렌더 (png/jpg/webp…) | `imagemagick` | `brew install imagemagick` / `pacman -S imagemagick` |
| **PDF 렌더** | imagemagick + **ghostscript (`gs`)** — imagemagick 이 PDF 를 gs 에 위임. `magick -list format` 에 PDF 가 있어도 gs 없으면 실패 | `brew install ghostscript` / `pacman -S ghostscript` |
| Mermaid 다이어그램 | `mmdc` | `npm i -g @mermaid-js/mermaid-cli` |
| LaTeX 수식 렌더 | `tectonic` 또는 `pdflatex` | `brew install tectonic` |
| 클립보드 (Linux) | `wl-clipboard`(Wayland) / `xclip`(X11) | WSL 은 `win32yank` |
| 셸 편의 | `bat`(프리뷰 하이라이트) `eza`(ls) | TOOLS.md |

## 5. mason 이 자동 설치하는 것과 그 런타임

`:Mason` 에서 확인. **런타임이 없으면 설치는 돼도 실행이 안 된다.**

| 런타임 | mason 패키지 |
| --- | --- |
| node | vtsls, eslint-lsp, biome, prettier, tailwindcss-language-server, json-lsp, yaml-language-server, dockerfile-language-server, docker-compose-language-service, markdownlint-cli2, markdown-toc, pyright, js-debug-adapter |
| python | ruff, debugpy, sqlfluff |
| JDK | jdtls, java-debug-adapter, java-test, lemminx |
| 없음 (정적 바이너리) | clangd, codelldb, lua-language-server, marksman, shellcheck, shfmt, stylua, taplo, hadolint, postgres-language-server, tree-sitter-cli |

Go · luarocks · PHP · julia 는 `:checkhealth mason` 이 경고하지만 **현재 패키지엔 불필요**.

`tree-sitter-cli` 는 mason 것을 쓴다. `options.lua` 가 시작 시 `~/.local/share/nvim/mason/bin` 을 PATH 앞에 넣어
mason 이 로드되기 전(대시보드 `:TSUpdate`, `:Lazy sync` build)에도 찾는다.
⚠️ mac 에서 `brew install tree-sitter` 는 **라이브러리**라 nvim 링크를 깨고, `tree-sitter-cli` 는 Intel 맥에서 llvm+rust 를 끌어온다 — 둘 다 쓰지 말 것.

## 6. 첫 실행 체크리스트

```txt
nvim                      플러그인 자동 설치 (lazy.nvim bootstrap). 끝나면 :q 후 재실행
:Lazy sync                lazy-lock.json 기준으로 플러그인 정렬
:Mason                    ensure_installed 자동 진행 확인 (실패한 게 있으면 런타임 §3/§5 확인)
:TSUpdate                 treesitter 파서
:checkhealth lazyvim      필수 도구
:checkhealth mason        런타임
:checkhealth snacks       이미지/터미널 지원
:checkhealth which-key    키맵 충돌 (내 설정 기인 0 이어야 정상)
```

그 다음 언어별로 파일 하나 열어 확인: `:LspInfo` 에 서버가 붙는지, `<leader>cf` 포맷, `]d` 진단 이동.

## 7. 설정 플래그 (LazyVim `vim.g.*`) — 현재값

바꾸려면 `lua/config/options.lua` 에서 **lazy 로드 전에** 설정해야 한다.

| 플래그 | 현재 | 의미 |
| --- | --- | --- |
| `lazyvim_python_lsp` | `pyright` | `basedpyright` 로 교체 가능 |
| `lazyvim_python_ruff` | `ruff` | |
| `lazyvim_rust_diagnostics` | `rust-analyzer` | `bacon-ls` 로 교체 가능 |
| `lazyvim_ts_lsp` | `vtsls` | `tsgo` 실험 가능 |
| `lazyvim_prettier_needs_config` | `false` | true 면 프로젝트에 prettier 설정 있을 때만 포맷 |
| `lazyvim_eslint_auto_format` | `true` | 저장 시 eslint fix |

## 8. 머신별 상태 (저장소 밖, 백업 대상 아님)

| 경로 | 내용 |
| --- | --- |
| `~/.local/share/nvim/lazy/` | 플러그인 본체 (lazy-lock.json 으로 재현) |
| `~/.local/share/nvim/mason/` | LSP/포매터 바이너리 |
| `~/.local/share/nvim/dadbod_ui/connections.json` | **DB 접속 정보** — `:DBUIAddConnection` 으로 등록. 저장소에 넣지 말 것 |
| `~/.local/state/nvim/` | 세션·undo·shada |

## 9. 환경별 주의

- **macOS (Intel)**: Homebrew 가 x86_64 지원을 종료해 bottle 이 없는 포뮬러는 소스 빌드로 빠진다. nvim 런타임 의존성(tree-sitter, libuv)은 단독 업그레이드 금지 — `brew upgrade` 로 함께.
- **Arch / CachyOS**: 대부분 pacman 에 있음. `ttf-jetbrains-mono-nerd`, `wl-clipboard`. 고른 패키지 전체는 [linux/packages.txt](linux/packages.txt) (§10).
- **한글 입력 (kime, CachyOS + DMS niri)**: 공식 저장소에 없어 AUR(`paru -S kime`). 자동 시작은 kime 패키지가 `/etc/xdg/autostart/kime.desktop` 로 등록한다
  (지금 기기엔 DMS 시작 앱으로 만든 `~/.config/autostart/kime.desktop` 가 이를 덮지만 결과는 같다 — 따로 할 일 없음).
  설정은 `linux/kime/config.yaml` 링크 — **한영 = 우측 Command(`SuperR`)**, 우측 Option 은 일반 Alt 로 돌려줌.
  - `global_hotkeys` 는 맵 통째 교체라 기본 항목(Hangul · Super-Space · Esc …)도 함께 적혀 있다. 키 이름은 kime 엔진 기준(`SuperR` `AltR` `ControlR` …)
  - 우측 Command 는 niri 의 Mod 이기도 하다. 단독으로 눌렀다 떼면 한영, 누른 채 다른 키면 niri 단축키
  - 키가 안 먹으면 `wev -f wl_keyboard:key` 로 키 이름 확인 (MacBook 은 `hid_apple swap_opt_cmd=0` 에서 `Super_R`)
  - `kime-check` 의 `GTK_IM_MODULE` / `QT_IM_MODULE` Fail 은 Wayland 네이티브 앱에선 무시해도 된다.
    Chrome · Electron · 일부 Qt 앱에서 한글이 안 써지면 그때 환경변수 / 앱 플래그를 손본다
- **WSL(Arch)**: 클립보드 `win32yank`, 이미지 렌더는 Windows Terminal 이 kitty protocol 을 지원하지 않아 ✘. `:checkhealth snacks` 로 확인.
- 다크/라이트: nvim 이 **터미널 배경색**을 감지한다. 터미널 테마가 OS 를 따라가게 설정해야 nvim 도 따라간다 (ghostty: `theme = light:TokyoNight Day,dark:TokyoNight Moon`).

## 10. CachyOS + DankMaterialShell 새 설치 — `linux/setup.sh`

MacBook Air 2014 에서 쓰는 구성. 순서가 중요하다 — DMS 가 기본 파일을 만든 **뒤에** 저장소 상태로 덮는다.

```txt
1. CachyOS 설치 프로그램 → 데스크톱 "No desktop"
2. curl -fsSL https://install.danklinux.com | sh         DMS 설치 프로그램 (niri · quickshell · ghostty · matugen …)
3. 재부팅 → niri 세션에 로그인해 DMS 를 한 번 띄운다      ~/.config/niri/dms/* · settings.json 생성
4. git clone git@github.com:AmitaWhite/Dotfile.git ~/Dotfile
5. ~/Dotfile/linux/setup.sh --dry-run  →  ~/Dotfile/linux/setup.sh
6. 재부팅 (SDDM 로그인 화면 확인)
```

`setup.sh` 가 하는 일 (단계 이름으로 골라 돌릴 수 있다: `setup.sh qylock`). 여러 번 돌려도 이미 된 단계는 건너뛴다.

| 단계 | 내용 |
| --- | --- |
| `packages` | [linux/packages.txt](linux/packages.txt) 에서 빠진 것만 `pacman -S --needed` → `paru -S --needed`. `dms` 항목은 확인만 |
| `link` | `link.sh` — nvim · foot · fish · kime … 심링크 |
| `restore` | `link.sh --restore` — DMS · niri 설정 스냅샷(§1-1). 덮기 전에 묻는다 |
| `qylock` | 로그인 · 잠금 화면 (아래). sudo 가 필요하다 |

### 10-1. 패키지 목록 — `linux/packages.txt`

"내가 고른 것" 만 적는다. CachyOS 설치 프로그램의 기본 패키지와 의존성으로 딸려 오는 것은 적지 않는다.
줄마다 왜 깔았는지 주석이 있다. 새로 깔면 여기에 한 줄 추가 — 그래야 다음 설치에서도 따라온다.
(목록은 `/var/log/pacman.log` 의 직접 설치 이력에서 뽑았다: `grep "Running 'pacman -S" /var/log/pacman.log`)

- pacman 외 설치: JDK 는 sdkman(§3), jdtls 는 mason 이 넣는다
- 지운 것과 이유: `firefox`(zen) · `alacritty`(foot · ghostty) · `qt5-graphicaleffects` 와 Qt5 일체 · `qt6-multimedia-gstreamer`(아래)

### 10-2. 로그인 · 잠금 화면 — qylock

[Darkkal44/qylock](https://github.com/Darkkal44/qylock) 의 `enfield` 테마. **둘은 다른 프로그램이 같은 테마를 띄우는 것**이다.

| | 프로그램 | 위치 |
| --- | --- | --- |
| 로그인 화면 | SDDM (Qt6 greeter) | 테마 `/usr/share/sddm/themes/enfield`, 지정 `/etc/sddm.conf.d/theme.conf` |
| 잠금 화면 | quickshell (`WlSessionLock`) + qylock 의 SDDM 흉내 shim | `~/.local/share/quickshell-lockscreen/lock.sh` |
| 원본 | qylock clone | `~/.local/share/qylock` (잠금 화면의 `themes_link` 가 여기를 가리킨다) |

필요한 패키지 (`packages.txt` 의 "잠금 · 로그인 화면"):
- `qt6-multimedia` + `qt6-multimedia-ffmpeg` — 배경 영상 `bg.mp4`. Qt 는 FFmpeg 엔진을 쓴다 (gstreamer 엔진 불필요)
- `qt6-5compat` — 테마가 `import Qt5Compat.GraphicalEffects` (블러 · 그림자)
- **Qt5 패키지는 필요 없다** — README 의 "Qt5 Legacy Mode"(`qt5.sh`, `qt5-graphicaleffects`)는 Qt5 SDDM 을 쓰는 배포판용. Arch 의 SDDM 은 Qt6

qylock 의 `sddm.sh` · `quickshell.sh` 는 테마를 고르는 대화형 스크립트라 `setup.sh` 는 부르지 않고 같은 일을 직접 한다:
테마 폴더 복사 + `theme.conf`, 잠금 화면 폴더 복사 + `themes_link` + `lock.sh` 에 테마 고정. 그리고 **패치**를 적용한다.

**패치 — [linux/qylock/lockscreen-pam-hang.patch](linux/qylock/lockscreen-pam-hang.patch)**: 원본은 빈 칸에서 Enter 를 누르면
PAM 이 "Password:" 를 물은 채 멈추고, 이후 어떤 비밀번호도 받지 않는다(재부팅해야 했다). 덮개를 열고 화면을 깨우려 Enter 를
누르는 습관에서 생긴다. 빈 Enter 를 무시하고, 대기 중인 PAM 이 있으면 그 세션에 답하게 고쳤다. 원리는 REFACTOR Phase 9.
qylock 을 다시 설치(`quickshell.sh`)하면 패치가 사라지므로 `setup.sh qylock` 을 다시 돌릴 것.

### 10-3. DMS 와 잠금 연동

DMS 는 자체 잠금 화면 대신 외부 명령을 쓰게 할 수 있다. 둘 다 `settings.json` 에 있어 `restore` 로 함께 돌아온다.

| DMS 설정 (Settings → Power) | 값 | 효과 |
| --- | --- | --- |
| Custom Power Actions → Lock | `~/.local/share/quickshell-lockscreen/lock.sh` | DMS 가 잠글 일이 생기면 qylock 을 띄운다 |
| Lock before suspend | 켬 | **덮개만 닫아도** 잠긴다 (logind 의 sleep delay inhibitor 로 확인: `systemd-inhibit --list`) |

- 단축키 Ctrl+Cmd+Q(`Mod+Ctrl+Q`)는 `dms ipc call lock lock` — `lock.sh` 를 직접 부르면 DMS 가 모르고 자기 잠금을 또 시도해
  niri 가 "refusing lock as already locked" 로 거절하던 경합이 생긴다. DMS 를 거치면 한 번만 뜬다
- 덮개를 닫으면 영상 로딩(약 2초) 때문에 잠금 화면이 조금 늦게 뜬다 — 정상

### 10-4. 잠금 화면에서 맞는 비밀번호가 거부될 때

CachyOS 기본 `pam_faillock` 은 **3번 틀리면 10분간** 계정을 잠근다. 그동안은 맞는 비밀번호도 `access denied` 이고 sudo 도 막힌다.

```bash
faillock --user $USER     # 실패 기록 확인 (Valid V 가 3개면 잠긴 상태)
```

10분 기다리면 풀린다. 횟수 · 시간은 `/etc/security/faillock.conf` 의 `deny` · `unlock_time` (기본값 유지 중).
틀린 적이 없는데 안 풀리면 위의 PAM 멈춤 — 패치가 적용됐는지 `grep -c 'dotfiles patch' ~/.local/share/quickshell-lockscreen/shim/SddmShim.qml`.

