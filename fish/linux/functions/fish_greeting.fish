function fish_greeting
    set_color cyan # 팔레트 6 = DMS primary (256색 16번은 DMS 가 정의하지 않아 검정이 된다)
    # echo '     ______           __          __  _       '
    # echo '    / ____/___ ____  / /__  _____/ /_(_)___ _ '
    # echo '   / /   / __ `/ _ \/ / _ \/ ___/ __/ / __ `/ '
    # echo '  / /___/ /_/ /  __/ /  __(__  ) /_/ / /_/ /  '
    # echo '  \____/\__,_/\___/_/\___/____/\__/_/\__,_/   '
    echo ''
    echo '            Welcome Back! Amita!'
    set_color normal
    fastfetch --key-padding-left 5
end
