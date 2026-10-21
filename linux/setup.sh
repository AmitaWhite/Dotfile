#!/usr/bin/env bash
# CachyOS(No desktop) + DankMaterialShell(niri) 새 설치를 이 저장소 상태로 맞춘다.
# 순서와 이유는 SETUP.md §10. 여러 번 돌려도 안전하다 — 이미 된 단계는 건너뛴다.
#
#   linux/setup.sh                 전체 (packages → link → restore → qylock)
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

dry=0
steps=()
for a in "$@"; do
  case "$a" in
    --dry-run) dry=1 ;;
    packages|link|restore|qylock) steps+=("$a") ;;
    -h|--help) sed -n '2,10p' "$0"; exit 0 ;;
    *) echo "unknown: $a" >&2; exit 2 ;;
  esac
done
[ ${#steps[@]} -eq 0 ] && steps=(packages link restore qylock)

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

# ---- 3. DMS · niri 설정 복원 ----
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
}

# ---- 4. qylock — SDDM 로그인 화면 + quickshell 잠금 화면 ----
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

for s in "${steps[@]}"; do "step_$s"; done

say "손으로 확인할 것"
note "1. DMS 설정 → Power → Custom Power Actions 의 잠금 명령 = ~/.local/share/quickshell-lockscreen/lock.sh"
note "   · Lock before suspend 켜짐  (둘 다 restore 한 settings.json 에 들어 있다)"
note "2. Ctrl+Cmd+Q → qylock 이 뜨는지, 덮개 닫았다 열면 qylock 인지"
note "3. kime: 새 터미널에서 우측 Command 로 한영 전환 (자동 시작은 kime 패키지가 등록)"
note "4. nvim 첫 실행 → :Lazy sync → :checkhealth (SETUP §6)"
