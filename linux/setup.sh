#!/usr/bin/env bash
# CachyOS(No desktop) + DankMaterialShell(niri) 새 설치를 이 저장소 상태로 맞춘다.
# 순서와 이유는 SETUP.md §10. 여러 번 돌려도 안전하다 — 이미 된 단계는 건너뛴다.
#
#   linux/setup.sh                 전체 (packages → link → shell → restore → qylock → apps)
#   linux/setup.sh qylock          특정 단계만 (여러 개 가능)
#   linux/setup.sh --dry-run       무엇을 할지만 출력
#
# 전제: DMS 설치 프로그램(curl -fsSL https://install.danklinux.com | sh)을 먼저 돌리고
#       niri 세션에 한 번 로그인해 DMS 가 기본 파일을 만든 상태.
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
pkgfile="$repo/linux/packages.txt"
patchfile="$repo/linux/qylock/lockscreen-pam-hang.patch"

qylock_repo="https://github.com/Darkkal44/qylock.git"
qylock_dir="$HOME/.local/share/qylock"
lock_dir="$HOME/.local/share/quickshell-lockscreen"
theme="enfield"
# sdkman 으로 깔 JDK. jdtls 는 JDK 21+ 에서만 돈다 (SETUP §3). 바꾸려면 `sdk list java` 의 Identifier 로
java_id="${JAVA_ID:-21.0.12+1.1-tem}"

dry=0
steps=()
for a in "$@"; do
  case "$a" in
    --dry-run) dry=1 ;;
    packages|link|shell|restore|qylock|apps) steps+=("$a") ;;
    -h|--help) sed -n '2,10p' "$0"; exit 0 ;;
    *) echo "unknown: $a" >&2; exit 2 ;;
  esac
done
[ ${#steps[@]} -eq 0 ] && steps=(packages link shell restore qylock apps)

say()  { printf '\n\033[1;36m== %s\033[0m\n' "$*"; }
note() { printf '   %s\n' "$*"; }
run()  { printf '   $ %s\n' "$*"; [ "$dry" = 1 ] || "$@"; }
has()  { pacman -Qq "$1" >/dev/null 2>&1; }

[ "$(id -u)" = 0 ] && { echo "root 로 돌리지 말 것 (필요한 곳에서만 sudo 를 쓴다)" >&2; exit 1; }
command -v pacman >/dev/null || { echo "pacman 이 없다 — Arch 계열 전용" >&2; exit 1; }

# ---- 1. 패키지 ----
step_packages() {
  say "패키지 (linux/packages.txt)"
  local src pkg miss_pacman=() miss_aur=() miss_dms=()
  while read -r src pkg _; do
    case "$src" in ''|'#'*) continue ;; esac
    has "$pkg" && continue
    case "$src" in
      pacman) miss_pacman+=("$pkg") ;;
      aur)    miss_aur+=("$pkg") ;;
      dms)    miss_dms+=("$pkg") ;;
    esac
  done < "$pkgfile"

  if [ ${#miss_dms[@]} -gt 0 ]; then
    note "DMS 설치 프로그램 쪽이 빠져 있다: ${miss_dms[*]}"
    note "→ curl -fsSL https://install.danklinux.com | sh 를 먼저 돌릴 것"
  fi
  if [ ${#miss_pacman[@]} -gt 0 ]; then
    run sudo pacman -S --needed "${miss_pacman[@]}"
  else
    note "pacman 항목 전부 설치됨"
  fi
  if [ ${#miss_aur[@]} -gt 0 ]; then
    if ! command -v paru >/dev/null && [ "$dry" = 0 ]; then
      echo "paru 가 없다 — pacman 항목(paru 포함) 설치가 실패했는지 확인" >&2; return 1
    fi
    run paru -S --needed "${miss_aur[@]}"
  else
    note "aur 항목 전부 설치됨"
  fi
}

# ---- 2. 심링크 ----
step_link() {
  say "심링크 (link.sh)"
  if [ "$dry" = 1 ]; then "$repo/link.sh" --dry-run; else "$repo/link.sh"; fi
}

# ---- 3. 셸 도구 — fisher 플러그인 · sdkman + JDK (SETUP §11) ----
# fish_plugins 는 link 단계에서 걸린다. fisher 는 그 목록을 읽어 설치한다.
step_shell() {
  say "셸 도구 — fisher · sdkman · JDK"

  if fish -c 'functions -q fisher' 2>/dev/null; then
    note "fisher 있음 — 플러그인: $(fish -c 'fisher list' 2>/dev/null | tr '\n' ' ')"
  else
    # fisher 자신도 fish_plugins 에 있으므로 한 번 source 한 뒤 update 하면 목록 전체가 깔린다
    run fish -c 'curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher update'
  fi

  if [ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
    note "sdkman 있음"
  else
    # rcupdate=false: bashrc · zshrc 를 고치지 않는다 (fish 는 sdkman-for-fish 플러그인이 초기화)
    printf '   $ curl -s "https://get.sdkman.io?rcupdate=false" | bash\n'
    [ "$dry" = 1 ] || curl -s "https://get.sdkman.io?rcupdate=false" | bash
  fi

  if [ -d "$HOME/.sdkman/candidates/java/$java_id" ]; then
    note "JDK 있음: $java_id (current → $(readlink "$HOME/.sdkman/candidates/java/current" 2>/dev/null))"
  else
    # sdkman 기본 설정은 다운로드를 10초에 끊는다(sdkman_curl_max_time=10) — 200MB 넘는 JDK 는 실패한다.
    # 설정 파일이 init 때 읽히므로 그 *뒤에* 덮어쓴다
    run bash -c "source \"\$HOME/.sdkman/bin/sdkman-init.sh\" && sdkman_curl_max_time=900 sdkman_auto_answer=true sdk install java $java_id"
  fi
}

# ---- 4. DMS · niri 설정 복원 ----
step_restore() {
  say "DMS · niri 설정 복원 (link.sh --restore)"
  "$repo/link.sh" --restore --dry-run | grep -v '^same' || true
  if "$repo/link.sh" --restore --dry-run | grep -q '^restore'; then
    if [ "$dry" = 1 ]; then return; fi
    read -rp "   위 파일을 저장소 스냅샷으로 덮을까? 기존 파일은 .pre-restore-* 로 백업된다 [y/N] " ans
    case "$ans" in
      [yY]*) "$repo/link.sh" --restore
             command -v dms >/dev/null && dms restart >/dev/null 2>&1 || true ;;
      *) note "건너뜀" ;;
    esac
  else
    note "이미 스냅샷과 같다"
  fi

  # 플러그인: lock 파일은 위에서 돌아오지만 플러그인 자체는 설치해야 한다 (이미 있으면 그대로 둔다)
  local lock="$HOME/.config/DankMaterialShell/plugins.lock.json"
  if [ -f "$lock" ] && command -v dms >/dev/null; then
    printf '   $ dms plugins restore %s\n' "$lock"
    [ "$dry" = 1 ] || dms plugins restore "$lock" 2>/dev/null | tail -1
  fi
}

# ---- 5. qylock — SDDM 로그인 화면 + quickshell 잠금 화면 ----
# qylock 의 sddm.sh / quickshell.sh 는 대화형(테마 선택)이라 부르지 않고, 하는 일만 그대로 한다.
step_qylock() {
  say "qylock ($theme) — SDDM 테마 · 잠금 화면 · 패치"

  if [ -d "$qylock_dir/.git" ]; then
    note "clone 있음: $qylock_dir"
  else
    run git clone --depth 1 "$qylock_repo" "$qylock_dir"
  fi

  # 잠금 화면 (quickshell.sh 가 하는 일)
  if [ -f "$lock_dir/lock.sh" ]; then
    note "잠금 화면 설치됨: $lock_dir"
  else
    run cp -r "$qylock_dir/quickshell-lockscreen" "$lock_dir"
    run ln -sfn "$qylock_dir/themes" "$lock_dir/themes_link"
    run sed -i "s|export QS_THEME=.*\$|export QS_THEME=\"\${1:-$theme}\"|" "$lock_dir/lock.sh"
    run chmod +x "$lock_dir/lock.sh"
    run mkdir -p "$HOME/.config/qylock"
    [ "$dry" = 1 ] || echo "$theme" > "$HOME/.config/qylock/theme"
  fi

  # 빈 Enter 후 영구히 안 풀리던 버그 패치 (SETUP §10-2, REFACTOR Phase 9)
  if grep -q '\[dotfiles patch\]' "$lock_dir/shim/SddmShim.qml" 2>/dev/null; then
    note "PAM 멈춤 패치 적용됨"
  else
    run patch -d "$lock_dir" -p1 -i "$patchfile"
  fi

  # SDDM 테마 (sddm.sh 가 하는 일)
  if diff -rq "$qylock_dir/themes/$theme" "/usr/share/sddm/themes/$theme" >/dev/null 2>&1; then
    note "SDDM 테마 설치됨: /usr/share/sddm/themes/$theme"
  else
    run sudo rm -rf "/usr/share/sddm/themes/$theme"
    run sudo cp -r "$qylock_dir/themes/$theme" "/usr/share/sddm/themes/$theme"
  fi
  if grep -qx "Current=$theme" /etc/sddm.conf.d/theme.conf 2>/dev/null; then
    note "SDDM 테마 지정됨: /etc/sddm.conf.d/theme.conf"
  else
    run sudo mkdir -p /etc/sddm.conf.d
    printf '   $ printf "[Theme]\\nCurrent=%s\\n" | sudo tee /etc/sddm.conf.d/theme.conf\n' "$theme"
    [ "$dry" = 1 ] || printf '[Theme]\nCurrent=%s\n' "$theme" | sudo tee /etc/sddm.conf.d/theme.conf >/dev/null
  fi
  if systemctl is-enabled sddm >/dev/null 2>&1; then
    note "sddm 활성화됨"
  else
    run sudo systemctl enable sddm
  fi
}

# ---- 6. 기본 앱 (~/.config/mimeapps.list) ----
# 지정이 없으면 이미지는 zen 브라우저, PDF 는 onlyoffice 가 연다.
# 형식은 하나씩 지정한다 (xdg-mime 에 여러 개를 한 인자로 넘기면 mimeapps.list 에 한 줄로 뭉친다)
set_default() { # <desktop 파일 이름> <MIME 형식…>
  local app=$1 m
  shift
  if [ ! -f "/usr/share/applications/$app" ]; then
    note "$app 가 없다. packages 단계 먼저"
    return
  fi
  # 형식 하나만 보면 안 된다: image/apng 처럼 그 앱만 다루는 형식은 지정이 없어도 그 앱으로 나온다
  local todo=()
  for m in "$@"; do
    [ "$(xdg-mime query default "$m")" = "$app" ] || todo+=("$m")
  done
  if [ ${#todo[@]} -eq 0 ]; then
    note "이미 $app"
    return
  fi
  for m in "${todo[@]}"; do
    run xdg-mime default "$app" "$m"
  done
}

step_apps() {
  say "기본 앱: 이미지는 Loupe, PDF 와 전자책은 zathura"
  local loupe=/usr/share/applications/org.gnome.Loupe.desktop
  # Loupe 의 .desktop 이 다루는 형식 전부
  # shellcheck disable=SC2046
  set_default org.gnome.Loupe.desktop $(grep '^MimeType=' "$loupe" 2>/dev/null | sed 's/^MimeType=//' | tr ';' ' ')
  # zathura 의 mupdf 플러그인 .desktop 에는 png, jpeg 같은 이미지도 들어 있어서 문서 형식만 고른다
  set_default org.pwmt.zathura-pdf-mupdf.desktop application/pdf application/oxps application/epub+zip \
    application/x-fictionbook application/x-mobipocket-ebook
}

for s in "${steps[@]}"; do "step_$s"; done

say "손으로 확인할 것"
note "1. DMS 설정 → Power → Custom Power Actions 의 잠금 명령 = ~/.local/share/quickshell-lockscreen/lock.sh"
note "   · Lock before suspend 켜짐  (둘 다 restore 한 settings.json 에 들어 있다)"
note "2. Ctrl+Cmd+Q → qylock 이 뜨는지, 덮개 닫았다 열면 qylock 인지"
note "3. kime: DMS 다크/라이트를 한 번 오가 kime 설정을 만든 뒤, 우측 Command 로 한영 전환 (설정은 matugen 이 만든다)"
note "4. 새 fish 에서 java -version (sdkman-for-fish 가 초기화) → nvim 첫 실행 → :Lazy sync → :checkhealth (SETUP §6)"
