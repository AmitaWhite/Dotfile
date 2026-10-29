# CLI / TUI 도구 카탈로그

"있으면 좋은" 개인 취향 도구. **nvim 이 요구하는 필수 도구는 [SETUP.md](SETUP.md)** 에 있다.
각 항목: 무엇 / 언제 쓰나 / 설치 / nvim·셸과의 관계.

설치 열의 표기: `b:` = `brew install`, `p:` = `pacman -S`, `u:` = `uv tool install`, `n:` = `npm i -g`, `c:` = `cargo install`.

## 셸 · 탐색 — 매일 쓰는 것

| 도구 | 무엇 | 언제 | 설치 | 관계 |
| --- | --- | --- | --- | --- |
| **fish** + **fisher** | 셸 + 플러그인 매니저 | 항상 | `b:fish` `p:fish` / fisher 는 스크립트 | sdkman-for-fish 로 JDK 초기화 → jdtls |
| **starship** | 프롬프트 | 항상 | `b:starship` `p:starship` | `starship.toml` 은 저장소 백업 참고 |
| **zoxide** | 방문 이력으로 점프하는 `cd` (`z proj`) | 디렉토리 왕복이 잦을 때 | `b:zoxide` `p:zoxide` | fish 에서 `zoxide init fish` |
| **yazi** | 터미널 파일 매니저 (미리보기·벌크 rename) | 파일 정리·이동, 이미지 훑기 | `b:yazi` `p:yazi` | nvim 밖에서 탐색할 때. 안에서는 `<leader>e` |
| **eza** | `ls` 대체 — git 상태·트리·아이콘 | `ls`, `eza --tree --git` | `b:eza` `p:eza` | Nerd Font 필요 |
| **bat** | `cat` 대체 — 신택스 하이라이트·git diff 표시 | 파일 잠깐 볼 때 | `b:bat` `p:bat` | fzf/picker 프리뷰가 bat 을 쓰면 색이 붙음 |
| **tldr** | `man` 요약 예제 | 명령 옵션이 기억 안 날 때 | `b:tlrc` `p:tlrc` | |
| **nushell** | 구조화 데이터 셸 (`ls \| where size > 1mb`, json/csv 파이프) | 로그·json·csv 가공 | `b:nushell` `p:nushell` | 기본 셸은 fish 유지, 데이터 작업용으로만 |

## 터미널 · 에디터

| 도구 | 무엇 | 언제 | 설치 | 관계 |
| --- | --- | --- | --- | --- |
| **ghostty** | 터미널 에뮬레이터 | 항상, 맥과 리눅스의 주 터미널 | `b:--cask ghostty` `p:ghostty` | kitty graphics 지원이라 snacks.image 가 된다. 설정은 `ghostty/config.mac`, `config.arch` 를 링크 |
| **foot** | Wayland 경량 터미널 | 리눅스 보조 터미널 | `p:foot` | 이미지 렌더, 리가처 안 됨 |
| **helix** (`hx`) | 모달 에디터 (설정 거의 불필요) | nvim 없이 빠르게 고칠 때, 서버, 회사 Windows | `b:helix` `p:helix` | 설정은 `helix/` 를 링크. 리눅스 실행 파일은 `helix`. Windows 용은 `windows/helix` |
| **zed** | GUI 에디터 | 대용량 파일, 페어링 | `b:--cask zed` `p:zed`(Linux 는 `zeditor`) | |

## 개발 보조

| 도구 | 무엇 | 언제 | 설치 | 관계 |
| --- | --- | --- | --- | --- |
| **lazygit** | Git TUI | 스테이징·커밋·리베이스 | `b:lazygit` `p:lazygit` | nvim `<leader>gg` (필수 도구) |
| **hyperfine** | 커맨드 벤치마크 (`hyperfine 'cmd a' 'cmd b'`) | 스크립트/빌드 속도 비교 | `b:hyperfine` `p:hyperfine` | nvim 시작 시간 비교엔 `nvim --startuptime` |
| **tokei** | 코드 라인 수 (언어별) | 프로젝트 규모 파악 | `b:tokei` `p:tokei` | |
| **silicon** | 코드 → 이미지 | 코드 공유 (한글 ✘) | `b:silicon` `p:silicon` | |

## DB / SQL

| 도구 | 무엇 | 언제 | 설치 | 관계 |
| --- | --- | --- | --- | --- |
| **harlequin** | 터미널 SQL IDE (기본 SQLite, 어댑터로 Postgres/MySQL/DuckDB) | 쿼리 탐색·결과 표 보기 | `u:harlequin` (+ `harlequin[postgres]`) | nvim 안에서는 `<leader>D` (dadbod-ui). dadbod 는 `psql`/`mysql`/`sqlite3` 바이너리 필요 |
| **squall-sql** | 또 다른 SQL TUI | harlequin 대안 | `u:squall-sql` | |
| **sqlite3** | SQLite CLI | dadbod 가 SQLite 접속에 사용 | mac 기본 / `p:sqlite` | 필수에 가까움 |
| **psql** | Postgres CLI | dadbod 가 Postgres 접속에 사용 | `b:libpq` (+ link) / `p:postgresql-libs` | Postgres 를 쓰면 필수 |

## 문서 · 발표

| 도구 | 무엇 | 언제 | 설치 | 관계 |
| --- | --- | --- | --- | --- |
| **presenterm** | 마크다운 → 터미널 프레젠테이션 (코드 하이라이트·이미지) | 발표·데모 | `b:presenterm` `p:presenterm` | nvim 으로 md 작성 → presenterm 으로 발표 |
| **slides** | 더 단순한 마크다운 프레젠테이션 | 가벼운 발표 | `b:slides` `p:slides` | |
| **mermaid-cli** (`mmdc`) | mermaid → svg/png | nvim 에서 mermaid 블록 렌더 | `n:@mermaid-js/mermaid-cli` | snacks.image 가 사용 (선택) |

## 미디어

| 도구 | 무엇 | 언제 | 설치 | 관계 |
| --- | --- | --- | --- | --- |
| **shellbeats** | 유튜브 음악 검색·다운로드 TUI | | `git clone` → `make && make install` | |
| **celluloid** | GNOME MPV 프론트엔드 | Linux 영상 재생 | `p:celluloid` | |

## 시스템 (mac)

| 도구 | 무엇 | 언제 | 설치 |
| --- | --- | --- | --- |
| **orbstack** | 컨테이너/VM (Docker 대체, colima 보다 가볍고 빠름) | docker 명령 필요할 때 | `b:--cask orbstack` |
| **taproom** | Homebrew TUI (검색·설치 여부·정보) | 뭐 깔았는지 볼 때 | `b:gromgit/brewtils/taproom` (tap trust 필요) |
| **mole** | 디스크 분석·정리 (CleanMyMac 류) | 용량 부족할 때 | `b:mole` (tw93/Mole, **macOS 전용** — linux 는 gdu · §12) |
| **duf** | `df` 대체 — 디스크 사용량 표 | | `b:duf` `p:duf` |

## 시스템 (linux)

| 도구 | 무엇 | 언제 | 설치 | 관계 |
| --- | --- | --- | --- | --- |
| **kime** | 한글 입력기 (Wayland input-method, XIM) | 항상 | AUR `kime` | 자동 시작은 패키지가 한다. 한영은 우측 Command, 트레이 아이콘은 DMS 다크/라이트를 따라간다. [SETUP §9](SETUP.md#9-환경별-주의) |
| **gdu** | 폴더별 디스크 용량 TUI, 그 자리에서 삭제 (`gdu ~`) | 용량이 어디로 갔는지 볼 때 | `p:gdu` | 맥의 mole "분석" 역할. ncdu 보다 빠르다 — [SETUP §12](SETUP.md#12-디스크-정리) |
| **loupe** | 이미지 뷰어 (GNOME). 트랙패드 확대, 넘기기 | 이미지 열 때 (기본 앱) | `p:loupe` | 투명 PNG 는 내용과 대비되는 배경 위에 보여준다 |
| **zathura** | 가벼운 PDF, 전자책 뷰어 (키보드: `j` `k` `J` `K` `/` `q`) | PDF 열 때 (기본 앱) | `p:zathura zathura-pdf-mupdf` | 기본 앱은 문서 형식만 지정 (mupdf 플러그인이 이미지도 등록해서) |
| **screenshot-window** | 창 캡처에 둥근 모서리, 그림자, 투명 여백 (맥 ⌘⇧4 Space) | `Alt+Shift+5` | `linux/bin` (imagemagick 필요) | 전체 `Alt+Shift+3`, 영역 `Alt+Shift+4`. [SETUP §13](SETUP.md#13-스크린샷-맥-단축키와-비슷하게) |
| *baobab* | GNOME 디스크 사용량 분석기 (원형 그래프 GUI) | 마우스로 훑어볼 때 | `p:baobab` | 안 깔았음 — gdu 로 충분. 필요할 때만 |
| *bleachbit* | 앱 캐시 · 로그 · 임시파일 정리 GUI (CleanMyMac 의 "정리" 쪽) | 대청소 | `p:bleachbit` | 안 깔았음. 정리 대상을 하나씩 고르는 방식이라 아래 명령들로 대부분 된다 |

> AUR 의 `mole` 은 SSH 터널 CLI(davrodpin/mole)로 이름만 같다. 맥의 Mole(tw93, 디스크 정리)은 macOS 전용이고 리눅스판이 없다.

## 연습

| 도구 | 무엇 | 설치 |
| --- | --- | --- |
| **tukai** | 타이핑 연습 TUI | `c:tukai` |

## 안 씀 (기록용)

- **paneru** — macOS 용 niri 스타일 타일링 WM. niri 만큼 부드럽지 않아 보류. 설정은 `~/.paneru.toml` 에 남아있고 저장소엔 `paneru.toml.bak`.
- **wezterm** — ghostty 로 이동. 설정은 `wezterm.lua.bak`.
