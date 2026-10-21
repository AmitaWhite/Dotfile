# CachyOS 기본 설정을 먼저 누린다 (done 알림 · bat man 페이저 · !! / !$ · eza alias · pacman alias …).
# 아래는 그 위에 덮는 개인 설정만.
if test -f /usr/share/cachyos-fish-config/cachyos-config.fish
    source /usr/share/cachyos-fish-config/cachyos-config.fish
    # CachyOS 는 fish_greeting 을 여기서 정의해 버려 functions/fish_greeting.fish 가 autoload 되지 않는다.
    # (functions -e 로 지우면 이번 세션엔 autoload 도 막히므로 직접 다시 읽는다)
    test -f $__fish_config_dir/functions/fish_greeting.fish
    and source $__fish_config_dir/functions/fish_greeting.fish
end

if status is-interactive
    # Starship custom prompt
    starship init fish | source

    # Direnv + Zoxide
    command -v direnv &>/dev/null && direnv hook fish | source
    command -v zoxide &>/dev/null && zoxide init fish --cmd cd | source

    # Better ls
    alias ls='eza --icons --group-directories-first -1'

    # Abbrs
    abbr lg lazygit
    abbr gd 'git diff'
    abbr ga 'git add .'
    abbr gc 'git commit -am'
    abbr gl 'git log'
    abbr gs 'git status'
    abbr gst 'git stash'
    abbr gsp 'git stash pop'
    abbr gp 'git push'
    abbr gpl 'git pull'
    abbr gsw 'git switch'
    abbr gsm 'git switch main'
    abbr gb 'git branch'
    abbr gbd 'git branch -d'
    abbr gco 'git checkout'
    abbr gsh 'git show'

    abbr l ls
    abbr ll 'ls -l'
    abbr la 'ls -a'
    abbr lla 'ls -la'

    # Custom abbr
    abbr az yazi
    abbr lg lazygit
    abbr nv nvim
    abbr cat bat
    abbr th nautilus
    abbr zd zeditor

    # CLI - Youtube Music Player
    abbr sb shellbeats

    # For jumping between prompts in foot terminal
    function mark_prompt_start --on-event fish_prompt
        echo -en "\e]133;A\e\\"
    end
end
