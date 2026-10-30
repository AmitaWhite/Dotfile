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

    abbr cat bat
    abbr nv nvim
    abbr gm gemini
    abbr az yazi
    abbr zd zed
    # obsidian 의 vault 경로
    abbr -a -g --position anywhere obsi '/Users/amitawhite/Library/Mobile\\ Documents/iCloud\\~md\\~obsidian/Documents/'

    # For jumping between prompts in foot terminal
    function mark_prompt_start --on-event fish_prompt
        echo -en "\e]133;A\e\\"
    end
end

# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH

# uv가 관리하는 파이썬 (python, python3 -> 3.13) 및 uv tool 실행파일.
# /usr/local/bin(python.org 3.11)보다 앞에 와야 한다.
# 되돌리려면 이 줄만 지우면 됨. 자세한 내용: ~/Downloads/geemap-docs/path-cleanup.md
fish_add_path --global --move --prepend $HOME/.local/bin

# nvim 의 mason 이 설치한 언어 서버를 helix 도 쓴다. 맨 뒤라 시스템에 깔린 게 있으면 그게 먼저
fish_add_path --global --append $HOME/.local/share/nvim/mason/bin

# Oracle 클라이언트 인코딩을 UTF-8로 고정
set -gx NLS_LANG AMERICAN_AMERICA.AL32UTF8

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init2.fish 2>/dev/null || :
