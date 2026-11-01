# ┌─────────────────────────────────────────────────────────────────────┐
# │                                                                     │
# │                        ____ _  _ _   _ _  _                         │
# │                        |___  \/   \_/  |\ |                         │
# │                        |___ _/\_   |   | \|                         │
# │                                                                     │
# │                                                                     │
# │   Exyn Installer                                                    │
# │                                                                     │
# │   Developer   : IANLLC                                              │
# │   System      : Exyn                                                │
# │   Script      : Interactive System Installer                        │
# │   Platform    : Linux (Arch)                                        │
# │   Build Date  : 11-01-2026                                          │
# │   Git Commit  : de4bb7ab085a3ffcc6db30e3648d82b9d9048a1f            │
# │                                                                     │
# │   Description :                                                     │
# │     Exyn is a complete system and toolkit environment designed      │
# │     for deployment, management, and operational use.                │
# │     Exyn provides a curated set of tools, scripts, packages,        │
# │     configurations, and supporting components intended to deliver   │
# │     a functional, consistent platform across supported use cases.   │
# │     Suitable for individual, team, and organizational               │
# │     environments. Components and configurations may be adapted to   │
# │     specific operational requirements.                              │
# │                                                                     │
# │   Disclaimer  :                                                     │
# │     Exyn and its associated toolkit, including all tools,           │
# │     scripts, packages, configurations, and supporting components,   │
# │     are provided "AS IS" without warranty of any kind, express or   │
# │     implied, including but not limited to merchantability,          │
# │     fitness for a particular purpose, or non-infringement.          │
# │                                                                     │
# │     By installing, deploying, configuring, or using any part of     │
# │     this environment, you acknowledge and agree that:               │
# │                                                                     │
# │     - You assume full responsibility for all installation,          │
# │     configuration, and operational decisions.                       │
# │     - The provider(s) shall not be liable for any damages arising   │
# │     from use, including data loss, downtime, security incidents,    │
# │     or degraded performance.                                        │
# │     - Verified backups, testing, and change-management procedures   │
# │     are strongly recommended before any deployment.                 │
# │     - Certain components operate with elevated privileges and, if   │
# │     misconfigured, may affect system integrity or operational       │
# │     continuity.                                                     │
# │     - Compliance with applicable policies, security standards,      │
# │     and regulatory requirements remains the responsibility of the   │
# │     deploying party.                                                │
# │                                                                     │
# │     If you do not accept these terms, do not install or use Exyn    │
# │     or any of its components.                                       │
# │                                                                     │
# │   WARNING                                                           │
# │     This script modifies system packages and configurations.        │
# │     Run at your own risk.                                           │
# │                                                                     │
# └─────────────────────────────────────────────────────────────────────┘

#!/usr/bin/env bash

# ─────────────────────────── LOGO

ascii=$(cat << 'ASCII'
____ _  _ _   _ _  _
|___  \/   \_/  |\ |
|___ _/\_   |   | \|
ASCII
)

# ─────────────────────────── GLOBAL

bold=$'\e[1m'
reset=$'\e[0m'
delay=0.02
menu_delay=0.005
menu_active=0
showed_warning=0
verbose=false
no_anim=false

# UNATTENDED PROVISIONING
# Runs the installer headless: no interface, no prompts, every message written
# to the log below. Intended for cloud-init, user-data and first-boot
# automation, where command-line arguments cannot be supplied. Requires root;
# passwordless sudo or doas is attempted automatically. Equivalent to -d.
deploy=false

# PACKAGE UPGRADE POLICY
# How far to go in preparing the package manager before anything is installed.
# auto:    Least intervention. Repair the package manager if it is broken and
#          install from the current index; refresh, and upgrade installed
#          packages, only if that fails. Any upgrade omits the running kernel
#          and its modules.
# never:   Use the index as it stands. No refresh, no upgrades.
# always:  Refresh the index and upgrade every installed package first. Suited
#          to a new system, or one due for maintenance regardless.
# Override at runtime: --upgrade-policy=auto|never|always
upgrade_policy=auto

# PACKAGE NAME TRANSLATION
# Applies when the package manager on this system is not the one this
# configuration was recorded with.
# auto:    Install the recorded names. Where a name is absent from the index,
#          resolve its equivalent against the built-in table, then an online
#          package index, and install that. Only the name is transmitted.
# never:   Install the recorded names verbatim. No lookups.
# Override at runtime: --translate=auto|never
translation=auto

# LOGGING
# The default path is temporary and is cleared on reboot. Set a permanent
# path here to keep the record. Override at runtime: -l <path>
log='/tmp/Exyn.log'

display_name='Exyn'
platform='Linux (Arch)'
platform_arch='x86_64'
resolution='5120x1440'
source_output='DP-1'
source_shell='zsh'
required_bytes=419148189
disk_requirement='399 MiB'

# ─────────────────────────── CORE

pacman_packages=(
    "bspwm:264205"
    "cava:233996"
    "figlet:656977"
    "firefox:316627009"
    "git:35168200"
    "jq:492406"
    "niri:26079705"
    "numlockx:15522"
    "polybar:2656116"
    "rofi:1120005"
    "solaar:7052305"
    "sxhkd:92712"
    "ufw:540764"
    "unclutter:26496"
    "wget:5974018"
    "xorg-server:4045285"
    "xorg-xinit:41549"
    "xorg-xrandr:75901"
    "zathura:1927406"
    "zathura-pdf-mupdf:33216"
    "zip:580992"
    "zsh:7281583"
    "zsh-autosuggestions:43826"
    "zsh-syntax-highlighting:174945"
)

paru_packages=(
    "betterlockscreen:31921"
    "picom-ftlabs-git:492041"
    "pipes.sh:17201"
    "python-pywal:331264"
)

FIREFOX_EXTENSIONS=(
    "theme:{9b84b6b4-07c4-4b4b-ba21-394d86f6e9ee}:Black:7779:3.0.2:1:https://addons.mozilla.org/firefox/downloads/file/3954735/black21-3.0.2.xpi"
    "extension:jid1-KKzOGWgsW3Ao4Q@jetpack:I don't care about cookies:455500:3.5.0:1:https://addons.mozilla.org/firefox/downloads/file/4202634/i_dont_care_about_cookies-3.5.0.xpi"
    "extension:myallychou@gmail.com:Unhook - Remove YouTube Recommended & Shorts:45312:1.6.9:1:https://addons.mozilla.org/firefox/downloads/file/4733035/youtube_recommended_videos-1.6.9.xpi"
    "extension:uBlock0@raymondhill.net:uBlock Origin:4650100:1.75.0:1:https://addons.mozilla.org/firefox/downloads/file/5034826/ublock_origin-1.75.0.xpi"
    "extension:addon@darkreader.org:Dark Reader:874434:4.9.134:1:https://addons.mozilla.org/firefox/downloads/file/5175215/darkreader-4.9.134.xpi"
)

FONTS=(
    ".local/share/fonts/JetBrains-Mono-Nerd-Font-Complete.ttf:979356"
)

SERVICES=(
    "/usr/lib/systemd/system/nginx.service:395:nginx web server:/usr/bin/nginx"
    "/usr/lib/systemd/system/sshd.service:316:OpenSSH Daemon:/usr/bin/sshd"
    "/usr/lib/systemd/system/ufw.service:351:CLI Netfilter Manager:/usr/lib/ufw/ufw-init"
)

SEQUENCES=(
    "echo Exyn > /etc/hostname:hostname Exyn:sed -i 's/^127\.0\.1\.1.*/127.0.1.1 Exyn/' /etc/hosts"
)

FILES=(
    ".config/bspwm/bspwmrc:535"
    ".config/bspwm/wal:0"
    ".config/picom/picom.conf:16722"
    ".config/sxhkd/sxhkdrc:8511"
    ".fehbg:75"
    ".local/bin/random-wallpaper:2363"
    ".local/bin/ss-draw:596"
    ".local/bin/ss-instant:479"
    ".local/bin/ss-temp-float:611"
    ".local/share/fonts/JetBrains-Mono-Nerd-Font-Complete.ttf:979356"
    "st/config.h:24978"
    "/usr/lib/systemd/system/nginx.service:395"
    "/usr/lib/systemd/system/sshd.service:316"
    "/usr/lib/systemd/system/ufw.service:351"
    "/usr/share/defaults/at-spi2/accessibility.conf:1475"
    ".zshrc:1797"
)

_want_log=0
for _a in "$@"; do
    if (( _want_log )); then
        log=$_a
        _want_log=0
        continue
    fi
    case $_a in
        -l|--log)         _want_log=1 ;;
        -l=*|--log=*)     log=${_a#*=} ;;
        --upgrade-policy=*)
            case ${_a#*=} in
                auto|never|always) upgrade_policy=${_a#*=} ;;
            esac ;;
        --translate=*)
            case ${_a#*=} in
                auto|never) translation=${_a#*=} ;;
            esac ;;
        --verbose)        verbose=true ;;
        --no-animations)  no_anim=true ;;
        --deploy)         deploy=true ;;
        -[a-z]*)
            [[ $_a == *v* ]] && verbose=true
            [[ $_a == *n* ]] && no_anim=true
            [[ $_a == *d* ]] && deploy=true ;;
    esac
done
if [[ $deploy == true ]]; then
    no_anim=true
    exec > /dev/null
fi

type_effect1() {
    if [[ $no_anim == true ]]; then
        printf '%b' "$1"
        return
    fi
    local _t _i
    printf -v _t '%b' "$1"
    for (( _i=0; _i<${#_t}; _i++ )); do
        printf '%s' "${_t:_i:1}"
        sleep "$2"
    done
}

timer_start() {
    _TIMER_START=$(date +%s)
}

timer_end() {
    local elapsed=$(( $(date +%s) - _TIMER_START ))
    local h=$(( elapsed / 3600 )) m=$(( (elapsed % 3600) / 60 )) s=$(( elapsed % 60 ))
    duration=""
    (( h )) && { duration="$h Hour"; (( h != 1 )) && duration+="s"; }
    (( m )) && { duration+="${duration:+, }$m Minute"; (( m != 1 )) && duration+="s"; }
    if (( s )) || [[ -z $duration ]]; then
        duration+="${duration:+, }$s Second"; (( s != 1 )) && duration+="s"
    fi
}

prompt() {
    local prompt_visible="$1"
    local prompt_styled="$2"; shift 2
    local -a placeholders=("$@")
    local ph_index=0
    local input=""
    local char rest
    local dim=$'\e[2m'
    local reset=$'\e[0m'
    : "${delay:=0}"
    find_match() {
        local s
        [[ -z "$input" ]] && return 1
        if (( ${#placeholders[@]} )) && [[ "${placeholders[$ph_index]}" == "$input"* ]]; then
            printf '%s' "${placeholders[$ph_index]}"
            return 0
        fi
        for s in "${placeholders[@]}"; do
            [[ "$s" == "$input"* ]] && { printf '%s' "$s"; return 0; }
        done
        return 1
    }
    render_line() {
        local match remainder
        printf "\r%b" "$prompt_styled"
        printf "\033[K"
        if [[ -z "$input" ]]; then
            if (( ${#placeholders[@]} )); then
                printf "%b%s%b" "$dim" "${placeholders[$ph_index]}" "$reset"
            fi
            [[ -n "${prompt_suffix:-}" ]] && printf "%b" "$prompt_suffix"
            printf "\r"
            (( ${#prompt_visible} > 0 )) && printf "\033[%dC" "${#prompt_visible}"
            return 0
        fi
        printf "%s" "$input"
        if match="$(find_match)"; then
            remainder="${match#$input}"
            if [[ -n "$remainder" ]]; then
                printf "%b%s%b" "$dim" "$remainder" "$reset"
            fi
        fi
        [[ -n "${prompt_suffix:-}" ]] && printf "%b" "$prompt_suffix"
        printf "\r"
        local back=$(( ${#prompt_visible} + ${#input} ))
        (( back > 0 )) && printf "\033[%dC" "$back"
    }
    case "${delay}" in
        ""|0|0.|0.0|0.00|0.000|0.0000)
            printf "%b" "$prompt_styled"
            ;;
        *)
            type_effect1 "$prompt_styled" "$delay"
            ;;
    esac
    printf '\e[?25h'; render_line
    while :; do
        IFS= read -rsn1 char < /dev/tty
        if [[ "$char" == $'\e' ]]; then
            if ! IFS= read -rsn1 -t 0.01 rest < /dev/tty 2>/dev/null; then
                return 1
            fi
            if [[ "$rest" == "[" ]]; then
                IFS= read -rsn2 -t 0.01 rest < /dev/tty 2>/dev/null || true
            fi
            continue
        fi
        case "$char" in
            "")
                REPLY="$input"
                if [[ -z "$REPLY" && ${#placeholders[@]} -gt 0 ]]; then
                    REPLY="${placeholders[$ph_index]}"
                fi
                return 0
                ;;
            $'\x7f'|$'\x08')
                if [[ -n "$input" ]]; then
                    input="${input%?}"
                    if [[ -z "$input" && ${#placeholders[@]} -gt 0 ]]; then
                        (( ph_index = (ph_index + 1) % ${#placeholders[@]} ))
                    fi
                    render_line
                fi
                ;;
            $'\x09')
                if [[ -n "$input" ]]; then
                    local m
                    if m="$(find_match)"; then
                        local i
                        for i in "${!placeholders[@]}"; do
                            if [[ "${placeholders[$i]}" == "$m" ]]; then
                                ph_index=$i
                                break
                            fi
                        done
                        input="$m"
                        render_line
                        continue
                    fi
                fi
                if [[ -z "$input" && ${#placeholders[@]} -gt 0 ]]; then
                    (( ph_index = (ph_index + 1) % ${#placeholders[@]} ))
                    render_line
                fi
                ;;
            *)
                input+="$char"
                render_line
                ;;
        esac
    done
}

_ui_restored=

restore_ui() {
    # Called from several exit paths and from the traps, so it must run once.
    # A second CSI ? 1049 l on the primary screen restores the DEC slot the
    # progress bar last wrote inside the alternate screen, which is how the
    # cursor ended up part way down the terminal.
    [[ -n ${_ui_restored:-} ]] && return 0
    _ui_restored=1
    if [[ -n ${spinner_pid:-} ]]; then
        kill "$spinner_pid" 2>/dev/null
        wait "$spinner_pid" 2>/dev/null || true
        spinner_pid=""
    fi
    printf '\033[?1000l\033[?1002l\033[?1003l\033[?1005l\033[?1006l\033[?1015l'
    printf '\033[0m\033[?25h\033[?1049l'
    stty sane 2>/dev/null
    local x; while IFS= read -rsn1 -t 0.001 x; do :; done
}

# Components and package sets the operator turned off in the manifest. It is
# read during the install, which may run without the manifest ever being
# opened, so it is declared here rather than there.
declare -A SKIP_MGR=()

# ─────────────────────────── NETWORK

# A TCP handshake against a well known resolver. No DNS, no downloads, no
# external tools: bash opens the socket itself and the attempt is bounded.
have_network() {
    local host
    for host in 1.1.1.1 8.8.8.8 9.9.9.9; do
        timeout 2 bash -c "exec 3<>/dev/tcp/${host}/443" 2>/dev/null && return 0
    done
    return 1
}

# Holds the installation until the machine is reachable again rather than
# abandoning a run that is otherwise fine. $1 names what needs the connection.
require_network() {
    have_network && return 0
    type_effect "\033[31mAn internet connection is required to ${1:-continue}.\033[0m" "$menu_delay"; echo
    type_effect "\033[31mWaiting for a connection. This will continue on its own.\033[0m" "$menu_delay"; echo
    printf 'Waiting for a network connection before %s\n' "${1:-continuing}" >> "${output:-/dev/null}" 2>/dev/null
    load_ui
    while ! have_network; do
        sleep 5
    done
    close_ui
    type_effect "\033[32mConnection restored.\033[0m" "$menu_delay"; echo
    return 0
}

# ─────────────────────────── ROOT

verify_root() {
    aur=false
    rule_added=false
    get_kernel; get_os
    is_root=0
    (( $(id -u) == 0 )) && { is_root=1; return; }
    local script name groups_
    script="$(realpath "$0")"
    name="./$(basename "$0")"
    groups_=$(groups 2>/dev/null)
    if command -v sudo >/dev/null 2>&1 && [[ $groups_ =~ sudo|wheel ]]; then
        suggested_cmd="sudo bash $script"
        suggested_cmd_display="sudo bash $name"
    elif command -v doas >/dev/null 2>&1 && [[ $groups_ =~ doas|wheel ]]; then
        suggested_cmd="doas bash $script"
        suggested_cmd_display="doas bash $name"
    else
        suggested_cmd="su -c 'bash $script'"
        suggested_cmd_display="su -c 'bash $name'"
    fi
}

# ─────────────────────────── MENU UX

center() {
    local pad=$(( (terminal_width - ${#1}) / 2 ))
    (( pad < 0 )) && pad=0
    printf '%*s%s\n' "$pad" '' "$1"
}

draw_ui() {
    local mode="${1:-static}" sz line pad i menu_h total top=0
    put() {
        local p=$(( (terminal_width - $1) / 2 ))
        (( p < 0 )) && p=0
        printf '%*s' "$p" ''
        if [[ $mode == animated ]]; then type_effect1 "$2" "$delay"; else printf '%b' "$2"; fi
    }
    clear
    sz=$(stty size 2>/dev/null) || sz="24 80"
    terminal_height=${sz% *}
    terminal_width=${sz#* }
    (( is_root )) && menu_h=2 || menu_h=7
    [[ $mode == backdrop ]] && menu_h=${2:-1}
    total=$(( ascii_h + 1 + 4 + 1 + menu_h ))
    (( terminal_height > total )) && top=$(( (terminal_height - total) / 2 ))
    for (( i=0; i<top; i++ )); do echo; done
    pad=$(( (terminal_width - ascii_w) / 2 ))
    (( pad < 0 )) && pad=0
    for line in "${ASCII_ART[@]}"; do
        printf '%*s%s\n' "$pad" '' "$line"
    done
    echo
    center "System Name: $display_name"
    if [[ -n ${platform_arch:-} ]]; then
        local _pl="Platform: $platform $platform_arch"
        pad=$(( (terminal_width - ${#_pl}) / 2 ))
        (( pad < 0 )) && pad=0
        printf '%*sPlatform: %s ' "$pad" '' "$platform"
        if (( arch_ok )); then
            printf '%s\n' "$platform_arch"
        else
            printf '\e[31m%s\e[0m\n' "$platform_arch"
        fi
    else
        center "Platform: $platform"
    fi
    center "$res_line"
    pad=$(( (terminal_width - ${#disk_label} - ${#disk_value}) / 2 ))
    (( pad < 0 )) && pad=0
    printf '%*s%s' "$pad" '' "$disk_label"
    if (( available_bytes < required_bytes )); then
        printf '\e[31m%s\e[0m\n' "$disk_value"
    else
        printf '%s\n' "$disk_value"
    fi
    echo
    ui_menu_row=$(( top + ascii_h + 7 ))
    if [[ $mode == backdrop ]]; then
        :
    elif (( is_root )); then
        local l1="1. Start Install        3. Review Install"
        local l2="2. Customize Install    4. Exit Installer"
        put ${#l1} "${bold}${l1}${reset}"; echo
        put ${#l2} "${bold}${l2}${reset}"
    else
        local dash="-----------------------------------------"
        center "$dash"
        center "[!] ROOT PRIVILEGE REQUIRED"
        center "$dash"
        echo
        local ml="1. Review Install       2. Exit Installer"
        put ${#ml} "${bold}${ml}${reset}"; echo; echo
        local cd="\$ $suggested_cmd_display"
        put $(( ${#cd} + 8 )) "$cd ${bold}[enter]${reset}"; echo
    fi
    printf '\033[?25l'
}

redraw() { _resized=1; }
redraw_now() {
    _resized=0
    (( menu_active )) || return 0
    if [[ ${is_finished:-false} == true ]]; then draw_end_ui true; else draw_ui; fi
}
trap redraw WINCH
stop_resize() { :; }
resize_loop() { :; }

# ─────────────────────────── MAIN MENU

main_menu() {
    printf '\033[?25l'
    menu_active=1
    _resized=0
    draw_ui animated
    local key
    if (( is_root )); then
        while true; do
            (( _resized )) && redraw_now
            read -t 0.05 -rn 1 -s key || continue
            case $key in
                1) menu_active=0; confirm_user; clear; get_info; break ;;
                2) menu_active=0; customize_install; menu_active=1; draw_ui animated; _resized=0 ;;
                3) menu_active=0; review_install; menu_active=1; draw_ui; _resized=0 ;;
                4|q|Q|$'\e'|$'\x03') exit 0 ;;
            esac
        done
    else
        while true; do
            (( _resized )) && redraw_now
            read -t 0.05 -rn 1 -s key || continue
            case $key in
                1) menu_active=0; review_install; menu_active=1; draw_ui; _resized=0 ;;
                2|q|Q|$'\e'|$'\x03') exit 0 ;;
                $'\n'|$'\r'|"") restore_ui; exec bash -c "$suggested_cmd" ;;
            esac
        done
    fi
}

# ─────────────────────────── MENUS

# ─────────────────────────── CUSTOMIZE INSTALL [2a]

customize_install() {
    printf '\033[?1000h\033[?1005h\033[?1006h\033[?1015h'
    stty -ixon -ixoff -echo 2>/dev/null
    local menus=(package_menu fonts_menu repositories_menu files_menu)
    local current=0 rc direction="forward"
    while (( current >= 0 && current < ${#menus[@]} )); do
        local menu_fn="${menus[current]}"
        if [[ $menu_fn == package_menu && $direction == reverse ]]; then
            "$menu_fn" reverse
        else
            "$menu_fn"
        fi
        rc=$?
        case $rc in
            0) (( current++ )); direction="forward" ;;
            2)
                if (( current > 0 )); then
                    (( current-- )); direction="reverse"
                else
                    break
                fi ;;
            *) break ;;
        esac
    done
    printf '\033[?1000l\033[?1005l\033[?1006l\033[?1015l'
    stty -echo 2>/dev/null
    clear
    unset __PKG_SELECT_MAP_INIT __FSMENU_INIT
    unset PACKAGE_SELECT_MAP PACKAGE_INDEX_MAP
    unset __mgr_page_cache __mgr_names_cache __mgr_entries_cache
    unset __mgr_hidden_cache __mgr_sizes_serial
    unset __fs_font_page __fs_svc_page FONT_SELECT_MAP
    unset _item_mode
    return ${rc:-0}
}

# ─────────────────────────── REVIEW INSTALL [3]

review_install() {
    local -a L=() HDR=() SEL_KEY=() SEL_ROW=() SEL_IND=() SEL_PRE=() SEL_POST=() SEL_W=() SEL_FIX=()
    # Where each toggleable section begins and ends, so its heading and prose
    # can be greyed out when the section is switched off.
    local -A GRP_FROM=() GRP_TO=()
    _grp_open()  { GRP_FROM[$1]=${#L[@]}; }
    _grp_close() { GRP_TO[$1]=${#L[@]}; }
    # the key covering a given line, if any
    _grp_of() {
        local k
        for k in "${!GRP_FROM[@]}"; do
            (( $1 >= ${GRP_FROM[$k]} && $1 < ${GRP_TO[$k]:-0} )) && { printf '%s' "$k"; return 0; }
        done
        return 1
    }
    local cols rows off=0 view i active=0 ROWTXT SRC_HEAD="" TOTAL_HEAD="" _built_cols="" _gk="" _lead=""
    local -A PKG_COUNT=()

    _add()  { L+=("  $1"); }
    _raw()  { L+=("$1"); }
    _row()  { local p="  "; (( is_root )) || p=""; L+=("$(printf '%s%-22s %s' "$p" "$1" "$2")"); }
    _sec()  { L+=("") ; L+=("${bold}$1${reset}"); }
    # key | tree prefix that must not move | text that shifts | aligned tail
    _pick() {
        SEL_KEY+=("$1"); SEL_ROW+=("${#L[@]}")
        SEL_IND+=("$2"); SEL_PRE+=("$3"); SEL_POST+=("$4"); SEL_W+=("$5")
        SEL_FIX+=("${6:-0}")
        L+=("__PICK__${#SEL_KEY[@]}")
    }
    _plural() { (( $1 == 1 )) && printf '%s' "$2" || printf '%ss' "$2"; }
    # variable forms: no subshell in the rebuild path
    _plu()     { (( $1 == 1 )) && _PL="$2" || _PL="${2}s"; }
    _bytes_v() { _BYTES=$(_bytes "$1"); }
    _bytes() {
        local b=${1:-0} u=0 w f
        local -a units=(B KiB MiB GiB TiB PiB)
        [[ $b =~ ^[0-9]+$ ]] || { printf 'unknown'; return; }
        w=$b; f=0
        while (( w >= 1024 && u < 5 )); do f=$(( (w % 1024) * 10 / 1024 )); w=$(( w / 1024 )); (( u++ )); done
        if (( u > 0 && w < 10 && f > 0 )); then printf '%d.%d %s' "$w" "$f" "${units[$u]}"
        else printf '%d %s' "$w" "${units[$u]}"; fi
    }

    declare -F get_pkg_manager >/dev/null 2>&1 && get_pkg_manager

    # Everything below describes the machine, not the window, so it is read
    # once. A resize only re-formats what these hold.
    local -a PLANNED_COMPONENTS=(
        'priv|sudo|sudo|Standard privilege escalation. Installed with the system package manager; a '\''<user> ALL=(ALL) ALL'\'' line is appended to /etc/sudoers for the install user.'
        'aur||AUR build access|makepkg refuses to run as root, so a NOPASSWD sudoers line for the install user is added for the duration of the build and removed when the install ends.'
        'xlat||Arch User Repository packages|This configuration includes packages built from the AUR. Without pacman they cannot be built here; their names are resolved against the local package manager and installed where an equivalent exists.'
        'aur|paru|paru|Built from source: base-devel and git are installed, paru is cloned from aur.archlinux.org, and makepkg runs as the install user. The build tree is removed afterwards.'
    )
    local _F_ARCH _F_KV _F_AVAIL _F_SOURCE
    local -a _F_MGR_ROWS=()
    local -A PKG_PRESENT=()
    local -A _F_SVC_ON=()
    _collect_facts() {
        # What this system already carries. The scan is the expensive part of
        # this menu, so it is done once per run and handed on: the install
        # phase reads the same list rather than building it again.
        # get_installed is defined further down the script than this menu, so
        # it cannot be relied on here. The same queries are available inline.
        _pkg_query() {
            installed_pkgs=""
            case $1 in
                apt)     installed_pkgs=$(apt-mark showmanual 2>/dev/null) ;;
                dpkg)    installed_pkgs=$(dpkg-query -f '${binary:Package}\n' -W 2>/dev/null) ;;
                pacman|paru|yay|trizen|pikaur|aurman|pacaur|aura|pakku)
                         installed_pkgs=$(pacman -Qq 2>/dev/null) ;;
                dnf)     installed_pkgs=$(dnf list installed 2>/dev/null | awk 'NR>1{sub(/\..*/,"",$1); print $1}') ;;
                yum)     installed_pkgs=$(yum list installed 2>/dev/null | awk 'NR>1{sub(/\..*/,"",$1); print $1}') ;;
                rpm)     installed_pkgs=$(rpm -qa --qf '%{NAME}\n' 2>/dev/null) ;;
                zypper)  installed_pkgs=$(rpm -qa --qf '%{NAME}\n' 2>/dev/null) ;;
                flatpak) installed_pkgs=$(flatpak list --app --columns=application 2>/dev/null) ;;
                snap)    installed_pkgs=$(snap list 2>/dev/null | awk 'NR>1{print $1}') ;;
                brew)    installed_pkgs=$(brew list --formula 2>/dev/null) ;;
                apk)     installed_pkgs=$(apk info 2>/dev/null) ;;
                xbps)    installed_pkgs=$(xbps-query -l 2>/dev/null | awk '{sub(/-[^-]*$/,"",$2); print $2}') ;;
                eopkg)   installed_pkgs=$(eopkg list-installed 2>/dev/null | awk '{print $1}') ;;
                portage) installed_pkgs=$(equery list -1 2>/dev/null | sed 's#.*/##; s/-[0-9].*//') ;;
                pkg)     installed_pkgs=$(pkg query '%n' 2>/dev/null) ;;
            esac
        }

        if [[ -z ${PKG_SCAN_DONE:-} ]]; then
            declare -ga all_installed=()
            declare -gA PKG_HAVE=()
            local _sm _sp
            for _sm in "${available_pkg_managers[@]}"; do
                installed_pkgs=""
                if declare -F get_installed >/dev/null 2>&1; then
                    get_installed "$_sm" 2>/dev/null
                fi
                [[ -z $installed_pkgs ]] && _pkg_query "$_sm"
                [[ -n $installed_pkgs ]] && all_installed+=($installed_pkgs)
            done
            for _sp in "${all_installed[@]}"; do
                [[ -n $_sp ]] || continue
                # some managers list "name version" or "ii name-1.0"; index the
                # whole token and its leading field so either form matches
                PKG_HAVE[$_sp]=1
                PKG_HAVE[${_sp%%[<>=]*}]=1
            done
            PKG_SCAN_DONE=1
        fi

        _F_SOURCE="embedded base64 archive"
        local _cl
        _cl=$(grep -m1 '^_cfg_url=' "${BASH_SOURCE[0]}" 2>/dev/null) && {
            _cl=${_cl#_cfg_url=}
            # finalize_files writes the value quoted
            _cl=${_cl%\'}; _cl=${_cl#\'}
            _cl=${_cl%\"}; _cl=${_cl#\"}
            [[ -n $_cl ]] && _F_SOURCE=$_cl
        }
        _F_ARCH=$(_norm_arch "$(uname -m)")
        _F_KV=${kernel_version:-$(uname -r)}
        _F_AVAIL=$(df -PB1 / 2>/dev/null | awk 'NR==2{print $4}')
        local _v _n
        for _v in $(compgen -A variable 2>/dev/null | grep '_packages$'); do
            _n=$(eval "printf '%s' \"\${#${_v}[@]}\"" 2>/dev/null) || _n=0
            [[ $_n =~ ^[0-9]+$ ]] || _n=0
            # split the queue into what is missing and what is already here
            local _have=0 _pkg
            if (( ${#PKG_HAVE[@]} )); then
                local -a _plist=()
                eval "_plist=(\"\${${_v}[@]}\")" 2>/dev/null
                for _pkg in "${_plist[@]}"; do
                    _pkg=${_pkg%%:*}
                    [[ -n $_pkg ]] || continue
                    [[ -n ${PKG_HAVE[$_pkg]:-} ]] && (( _have++ ))
                done
            fi
            PKG_PRESENT[${_v%_packages}]=$_have
            _F_MGR_ROWS+=("$(printf '%06d %s' "$(( _n - _have ))" "${_v%_packages}")")
        done
        (( ${#SERVICES[@]} )) || return 0
        local _line
        if command -v systemctl >/dev/null 2>&1 && [[ -d /run/systemd/system ]]; then
            while read -r _line _; do
                [[ -n $_line ]] && _F_SVC_ON["$_line"]=1
            done < <(systemctl list-unit-files --state=enabled --no-legend 2>/dev/null)
        elif command -v rc-update >/dev/null 2>&1; then
            while read -r _line _; do
                [[ -n $_line ]] && _F_SVC_ON["${_line}.service"]=1
            done < <(rc-update show 2>/dev/null | awk '{print $1}')
        elif command -v sv >/dev/null 2>&1; then
            local _d
            for _d in /var/service/* /run/runit/service/*; do
                [[ -e $_d ]] && _F_SVC_ON["${_d##*/}.service"]=1
            done
        fi
        return 0
    }
    _collect_facts

    # The manifest is laid out for a particular width: the header rule, the
    # centred subtitle and every wrapped description depend on it. A resize
    # therefore rebuilds the content rather than repainting the old lines.
    _build_manifest() {
        L=(); HDR=(); SEL_KEY=(); SEL_ROW=(); SEL_IND=(); SEL_PRE=()
        SEL_POST=(); SEL_W=(); PKG_COUNT=(); SRC_HEAD=""; TOTAL_HEAD=""
        _built_cols=$cols

        local title="INSTALLATION MANIFEST" hr="" pad
        for ((i=0;i<cols-2;i++)); do hr+="─"; done
        HDR+=("┌${hr}┐")
        pad=$(( (cols - ${#title} - 2) / 2 ))
        HDR+=("$(printf '│%*s%s%*s%s│' "$pad" "" "$title" "$pad" "" "$( (( (cols - ${#title}) % 2 )) && printf ' ')" )")
        HDR+=("└${hr}┘")
        local sub="${_F_ARCH} | ${os:-Linux} | ${_F_KV}"
        printf -v _t '%*s\033[0;90m%s\033[0m' $(( (cols - ${#sub}) / 2 )) "" "$sub"; HDR+=("$_t")

        L+=("${bold}EXECUTION${reset}") ; L+=("")
        _v1=interactive; [[ $deploy == true ]] && _v1='unattended (deploy)'
    _row "Mode" "$_v1"
        _v1=enabled; [[ $no_anim == true ]] && _v1=disabled
    _row "Animations" "$_v1"
        _v1=$log; [[ $verbose == true ]] && _v1="verbose — mirrored to screen"
    _row "Logging" "$_v1"
        _v1='ELEVATION REQUIRED'; (( is_root )) && _v1=root
    _row "Privilege" "$_v1"
        (( ${#EULA_TERMS[@]} )) && _row "Agreement" "${#EULA_TERMS[@]} term(s) require acceptance"

        _sec "PACKAGE MANAGERS"
        L+=("")
        if (( ${#available_pkg_managers[@]} == 0 )); then
            _row "Detected" "none — package installation will be skipped"
        else
            local _csv; _csv=$(printf '%s, ' "${available_pkg_managers[@]}"); _csv=${_csv%, }
            local _v _n _total=0 _m _w2
            _w2=24; (( is_root )) || _w2=22
            printf -v _t '%-*s %s' "$_w2" "Detected" "$_csv"; L+=("$_t")
            L+=("")
            local -a _mgr_rows=("${_F_MGR_ROWS[@]}")
            # largest queue first
            while IFS=' ' read -r _n _m; do
                [[ -n $_n && -n $_m ]] || continue
                _n=$(( 10#$_n ))
                # an array with nothing in it has nothing to install, so it is
                # shown unselected and skipped
                (( _n == 0 )) && SKIP_MGR[pkg:$_m]=1
                _total=$(( _total + _n ))
                PKG_COUNT[$_m]=$_n
                _plu "$_n" package
                _mp=${PKG_PRESENT[$_m]:-0}
                _mtxt="$_n $_PL queued"
                (( _mp )) && _mtxt+="  [$_mp already installed]"
                _pick "pkg:$_m" "" "[*] $_m" "$_mtxt" 22
            done < <( (( ${#_mgr_rows[@]} )) && printf '%s\n' "${_mgr_rows[@]}" | sort -rn )
            if (( _total )); then
                L+=("")
                TOTAL_HEAD=${#L[@]}
                _plu "$_total" package
                printf -v _t '%-*s %s' "$_w2" "Total queued" "$_total $_PL"; L+=("$_t")
            fi
        fi

        local -a _pc_comp=() _pc_mgr=()
        local _e _kind _cmd _ttl _dsc
        for _e in "${PLANNED_COMPONENTS[@]}"; do
            IFS='|' read -r _kind _cmd _ttl _dsc <<< "$_e"
            _ttl=${_ttl#"${_ttl%%[![:space:]]*}"}; _ttl=${_ttl%"${_ttl##*[![:space:]]}"}
            _dsc=${_dsc#"${_dsc%%[![:space:]]*}"}; _dsc=${_dsc%"${_dsc##*[![:space:]]}"}
            case $_kind in
                aur)  command -v pacman >/dev/null 2>&1 || continue ;;
                xlat) command -v pacman >/dev/null 2>&1 && continue ;;
            esac
            [[ -z $_cmd ]] && _kind=note
            case $_kind in
                mgr|aur)
                [[ -n $_cmd ]] && command -v "$_cmd" >/dev/null 2>&1 && continue
                _pc_mgr+=("$_kind|$_cmd|$_ttl|$_dsc") ;;
                priv)
                    command -v "$_cmd" >/dev/null 2>&1 && continue
                    _pc_comp+=("priv|$_cmd|$_ttl|$_dsc") ;;
                *)
                    [[ -n $_cmd ]] && command -v "$_cmd" >/dev/null 2>&1 && continue
                    _pc_comp+=("note||$_ttl|$_dsc") ;;
            esac
        done

        _wrap() {
            local cont=$1 d=$2 w line word
            w=$(( cols - ${#cont} - 2 )); (( w < 20 )) && w=20
            line=""
            for word in $d; do
                # a single token wider than the column, such as an address, is
                # split so it cannot run past the edge and disturb the layout
                while (( ${#word} > w )); do
                    [[ -n $line ]] && { _raw "${cont}${line}"; line=""; }
                    _raw "${cont}${word:0:w}"
                    word=${word:w}
                done
                if [[ -z $line ]]; then line=$word
                elif (( ${#line} + 1 + ${#word} > w )); then _raw "${cont}${line}"; line=$word
                else line+=" $word"; fi
            done
            [[ -n $line ]] && _raw "${cont}${line}"
        }

        _tree() {
            local ttl=$1; shift
            (( $# )) || return 0
            _sec "$ttl"
            _raw "│"
            local n=$# i=0 t d entry lead cont
            for entry in "$@"; do
                (( i++ ))
                t=${entry%%|*}; d=${entry#*|}
                if (( i == n )); then lead="└─"; cont="   "; else lead="├─"; cont="│  "; fi
                _raw "${lead} ${bold}${t}${reset}"
                _wrap "$cont" "$d"
                (( i < n )) && _raw "│"
            done
        }

        _sec "PREPARATION POLICY  [${upgrade_policy:-auto}]"
        _raw "│"
        case "${upgrade_policy:-auto}" in
            never)
                _raw "├─ Use the package index as it stands"
                _raw "├─ No index refresh"
                _raw "└─ No installed package is changed" ;;
            always)
                _raw "├─ Refresh the package index"
                _raw "├─ Upgrade every installed package"
                _raw "└─ Install afterwards" ;;
            *)
                _raw "├─ Fix the package manager, if it is broken"
                _raw "├─ Install from the current index, if that resolves"
                _raw "├─ Refresh the index, if it does not"
                _raw "└─ Upgrade installed packages, only if still unresolved,"
                _raw "   holding back the running kernel and its modules" ;;
        esac

        _sec "PACKAGE NAME RESOLUTION  [${translation:-auto}]"
        _raw "│"
        case "${translation:-auto}" in
            never)
                _raw "└─ Package names are used exactly as recorded" ;;
            *)
                _raw "├─ Applies only where the recorded package manager is not"
                _raw "│  the one in use"
                _raw "├─ A name this system does not carry is matched against the"
                _raw "│  built-in map, then an online package-name index"
                _raw "└─ Only the package name is sent" ;;
        esac

        if (( ${#_pc_comp[@]} )); then
            _sec "COMPONENTS"
            _raw "│"
            local n=${#_pc_comp[@]} i=0 entry lead cont
            for entry in "${_pc_comp[@]}"; do
                (( i++ ))
                IFS='|' read -r _kind _cmd _ttl _dsc <<< "$entry"
                if (( i == n )); then lead="└─"; cont="   "; else lead="├─"; cont="│  "; fi
                if [[ $_kind == priv ]]; then
                    _pick "mgr:${_cmd}" "${lead} " "[*] ${_ttl}" "" 0
                else
                    _raw "${lead} ${bold}${_ttl}${reset}"
                fi
                _raw "${cont%% }"
                _wrap "$cont" "$_dsc"
                (( i < n )) && _raw "│"
            done
        fi

        if (( ${#_pc_mgr[@]} )); then
            _sec "SUPPORTING PACKAGE MANAGERS"
            _raw "│"
            local n=${#_pc_mgr[@]} i=0 entry lead cont
            for entry in "${_pc_mgr[@]}"; do
                (( i++ ))
                IFS='|' read -r _kind _cmd _ttl _dsc <<< "$entry"
                if (( i == n )); then lead="└─"; cont="   "; else lead="├─"; cont="│  "; fi
                _pick "mgr:${_cmd:-$_ttl}" "${lead} " "[*] ${_ttl}" "" 0
                _raw "${cont%% }"
                _wrap "$cont" "$_dsc"
                (( i < n )) && _raw "│"
            done
        fi

        if (( ${#GNOME_EXTENSIONS[@]} )) || (( ${#KDE_EXTENSIONS[@]} )); then
            _sec "EXTENSIONS / ADD-ONS"
            _raw "│"
            local both=0
            (( ${#GNOME_EXTENSIONS[@]} )) && (( ${#KDE_EXTENSIONS[@]} )) && both=1
            if (( ${#GNOME_EXTENSIONS[@]} )); then
                local lead="└─" cont="   "
                (( both )) && { lead="├─"; cont="│  "; }
                _grp_open "ext:gnome"
                _pick "ext:gnome" "${lead} " "[*] GNOME — ${#GNOME_EXTENSIONS[@]} $(_plural "${#GNOME_EXTENSIONS[@]}" extension)" "" 0
                _raw "${cont%% }"
                _wrap "$cont" "Installs GNOME Shell if absent, then queries extensions.gnome.org for a build matching this Shell release, unpacks each into ~/.local/share/gnome-shell/extensions and enables them with gsettings."
                (( both )) && _raw "│"
            fi
            if (( ${#KDE_EXTENSIONS[@]} )); then
                _grp_close "ext:gnome"
                _grp_open "ext:kde"
                _pick "ext:kde" "└─ " "[*] KDE — ${#KDE_EXTENSIONS[@]} $(_plural "${#KDE_EXTENSIONS[@]}" extension)" "" 0
                _raw ""
                _wrap "   " "Installs Plasma if absent, downloads each package from the address recorded at capture, installs widgets and themes with kpackagetool, and re-applies the look-and-feel, colour and cursor themes."
                _grp_close "ext:kde"
            fi
        fi

        if (( ${#REPOS[@]} )); then
            L+=("")
            _w2=24; (( is_root )) || _w2=22
            SRC_HEAD=${#L[@]}
            L+=("$(printf '%s%-*s%s %s' "$bold" "$_w2" "BUILD FROM SOURCE" "$reset" \
                  "${#REPOS[@]} $(_plural "${#REPOS[@]}" item) queued")")
            _raw "│"
            local _r _rn _rcmds _ri _w2 _rlast=$(( ${#REPOS[@]} - 1 ))
            local _rlead _rcont _rraw _rtok _rurl _rseg _rpart
            local -a _rsteps
            for _ri in "${!REPOS[@]}"; do
                _rraw=${REPOS[$_ri]//:\/\//$'\001'}
                IFS=':' read -ra _rsteps <<< "$_rraw"
                for _rpart in "${!_rsteps[@]}"; do
                    _rsteps[_rpart]=${_rsteps[_rpart]//$'\001'/://}
                    _rsteps[_rpart]=${_rsteps[_rpart]#"${_rsteps[_rpart]%%[![:space:]]*}"}
                    _rsteps[_rpart]=${_rsteps[_rpart]%"${_rsteps[_rpart]##*[![:space:]]}"}
                done
                _rurl=""
                for _rtok in ${_rsteps[0]}; do
                    [[ $_rtok == *://* || $_rtok == *.*/* ]] && { _rurl=$_rtok; break; }
                done
                _rn=${_rurl%%\?*}; _rn=${_rn%/}; _rn=${_rn##*/}
                _rn=${_rn%.git}
                _rn=${_rn%.tar.gz}; _rn=${_rn%.tar.xz}; _rn=${_rn%.tar.bz2}
                _rn=${_rn%.tar.zst}; _rn=${_rn%.tgz}; _rn=${_rn%.zip}; _rn=${_rn%.tar}
                if [[ $_rn =~ ^v?[0-9] ]]; then
                    for _rseg in ${_rurl//\// }; do
                        case "$_rseg" in
                            archive|refs|tags|releases|download|*:|"") continue ;;
                            v?[0-9]*|[0-9]*) continue ;;
                            *) _rn=${_rseg%.git} ;;
                        esac
                    done
                fi
                _rcmds=""
                for (( _rpart=1; _rpart<${#_rsteps[@]}; _rpart++ )); do
                    _rtok=${_rsteps[_rpart]}
                    _rtok=${_rtok#sudo }; _rtok=${_rtok#doas }
                    [[ -n $_rtok ]] || continue
                    _rcmds+="${_rcmds:+; }${_rtok}"
                done
                if (( _ri == _rlast )); then _rlead="└─"; _rcont="   "; else _rlead="├─"; _rcont="│  "; fi
                _grp_open "src:$_ri"
                _pick "src:$_ri" "${_rlead} " "[*] ${_rn:-source}" "" 0
                _raw "${_rcont%% }"
                _wrap "$_rcont" "${_rurl:-address not recorded}"
                _wrap "$_rcont" "${_rcmds:-no build steps recorded}"
                (( _ri < _rlast )) && _raw "│"
                _grp_close "src:$_ri"
            done
        fi

        # a section for services that are all enabled already would be noise
        local -a _svc_pending=()
        local _sq
        for _sq in "${SERVICES[@]}"; do
            _sq=${_sq%%:*}
            [[ -n ${_F_SVC_ON[${_sq##*/}]:-} ]] && continue
            _svc_pending+=("$_sq")
        done
        if (( ${#_svc_pending[@]} )); then
            _sec "SYSTEM SERVICES"
            _raw "│"
            local _init_label="services"
            if command -v systemctl >/dev/null 2>&1 && [[ -d /run/systemd/system ]]; then _init_label="systemd"
            elif command -v rc-update >/dev/null 2>&1; then _init_label="OpenRC"
            elif command -v sv >/dev/null 2>&1 && [[ -d /etc/sv || -d /etc/runit ]]; then _init_label="runit"
            elif command -v dinitctl >/dev/null 2>&1; then _init_label="dinit"
            elif command -v s6-rc >/dev/null 2>&1; then _init_label="s6"
            elif command -v sysrc >/dev/null 2>&1; then _init_label="BSD rc"
            elif command -v update-rc.d >/dev/null 2>&1 || command -v chkconfig >/dev/null 2>&1; then _init_label="SysV"
            elif command -v systemctl >/dev/null 2>&1; then _init_label="systemd"
            fi
            __SVC_LABEL_ROW=${#L[@]}
            _grp_open "svc:all"
            _pick "svc:all" "└─ " "[*] ${_init_label} — ${#SERVICES[@]} $(_plural "${#SERVICES[@]}" service)" "" 0

            # The nested list lines up with the middle of the selection prefix,
            # the [*] itself. Without a prefix there is nothing to centre on, so it
            # sits under the first letter of the init system's name instead.
            local _nest="    "
            (( is_root )) || _nest="   "
            # One call to the service manager, not one per unit: anything already
            # enabled on this system needs nothing done and is left off the list.
            local -a _svc_show=()
            for _si in "${!SERVICES[@]}"; do
                _sp=${SERVICES[$_si]%%:*}
                [[ -n ${_F_SVC_ON[${_sp##*/}]:-} ]] && continue
                _svc_show+=("${SERVICES[$_si]}")
            done
            SEL_PRE[${#SEL_PRE[@]}-1]="[*] ${_init_label} — ${#_svc_show[@]} $(_plural "${#_svc_show[@]}" service)"


            local _s _sd _sx _srest _si2 _slast=$(( ${#_svc_show[@]} - 1 ))
            local _slead _scont _sunit _scmd
            _raw "${_nest}│"
            for _si2 in "${!_svc_show[@]}"; do
                _si=$_si2
                _s=${_svc_show[$_si]}
                _sp=${_s%%:*}; _srest=${_s#*:}
                _srest=${_srest#*:}
                _sd=${_srest%%:*}
                _sx=""
                [[ $_srest == *:* ]] && _sx=${_srest#*:}
                _sunit=${_sp##*/}
                if (( _si == _slast )); then _slead="└─"; _scont="   "; else _slead="├─"; _scont="│  "; fi
                _raw "${_nest}${_slead} ${bold}${_sunit}${reset}"
                _raw "${_nest}${_scont%% }"
                [[ -n $_sd ]] && _wrap "${_nest}${_scont}" "$_sd"
                # only mention what it runs when something was recorded
                [[ -n ${_sx//:/ } ]] && _wrap "${_nest}${_scont}" "runs ${_sx//:/ }"
                case "$_init_label" in
                    systemd) _scmd="systemctl enable ${_sunit}" ;;
                    OpenRC)  _scmd="rc-update add ${_sunit%.service} default" ;;
                    runit)   _scmd="ln -s /etc/sv/${_sunit%.service} /var/service/" ;;
                    dinit)   _scmd="dinitctl enable ${_sunit%.service}" ;;
                    s6)      _scmd="s6-rc-bundle-update add default ${_sunit%.service}" ;;
                    "BSD rc") _scmd="sysrc ${_sunit%.service}_enable=YES" ;;
                    SysV)    _scmd="update-rc.d ${_sunit%.service} defaults" ;;
                    *)       _scmd="" ;;
                esac
                [[ -n $_scmd ]] && _wrap "${_nest}${_scont}" "$_scmd"
                _wrap "${_nest}${_scont}" "unit at: $_sp"
                (( _si < _slast )) && _raw "${_nest}│"
            done
            _grp_close "svc:all"
        fi

        if [[ -n ${source_shell:-} ]]; then
            # $SHELL belongs to whoever launched the installer, and $user is
            # not chosen until after this menu, so the account is resolved
            # here the same way the installer resolves it later.
            local _acct _now=""
            _acct=${user:-}
            [[ -z $_acct ]] && _acct=${SUDO_USER:-}
            [[ -z $_acct ]] && _acct=$(logname 2>/dev/null)
            [[ -z $_acct || $_acct == root ]] && {
                local _h
                _h=$(getent passwd 2>/dev/null |
                     awk -F: '$3>=1000 && $3<65534 {print $1; exit}')
                [[ -n $_h ]] && _acct=$_h
            }
            [[ -z $_acct ]] && _acct=$(id -un)
            _now=$(getent passwd "$_acct" 2>/dev/null | cut -d: -f7)
            [[ -z $_now ]] && _now=$(awk -F: -v u="$_acct" '$1==u{print $7}' /etc/passwd 2>/dev/null)
            _now=${_now##*/}
            _now=${_now//[[:space:]]/}
            if [[ $_now != "$source_shell" ]]; then
                _grp_open "shell:set"
                _sec "LOGIN SHELL"
                _raw "│"
                _raw "├─ ${_acct} signs in with ${_now}"
                _raw "│"
                _pick "shell:set" "└─ " "[*] Change the login shell to ${source_shell}" "" 0
                _raw "   "
                _wrap "   " "The recorded configuration was written for ${source_shell}, and the files it places assume it. The account's login shell is set permanently; the change takes effect at the next sign-in. If ${source_shell} is absent it is installed first, and if it cannot be set the account is left as it is."
                _raw "   "
                _grp_close "shell:set"
            fi
        fi

        if [[ ${display:-} == X11 || -n ${source_output:-} ]]; then
            _sec "DISPLAY SERVER"
            _raw "│"
            _raw "├─ The recorded session used the X Window System"
            _wrap "│  " "This system's graphics hardware is identified and a driver chosen for it. Where the kernel already drives the card, the built-in modesetting driver is selected explicitly, because the server would otherwise rank a legacy driver above it and fail."
            _raw "│"
            _raw "├─ Configuration naming absent hardware is set aside"
            _wrap "│  " "A copied xorg.conf or fragment that names a driver this machine does not have is renamed rather than removed, so the server can fall back to detection."
            _raw "│"
            _raw "├─ The session is aligned with this display"
            if [[ -n ${source_output:-} || -n ${resolution:-} ]]; then
                _wrap "│  " "Files in this payload that name the source machine's output${source_output:+ (${source_output})} or its screen size${resolution:+ (${resolution})} are rewritten to the values this machine reports. Only files listed in this manifest are read."
            else
                _wrap "│  " "Files in this payload that name the source machine's output or screen size are rewritten to the values this machine reports."
            fi
            _raw "│"
            local _hv="" _vm_lead="" _vm_cont="" _ver_lead="└─ " _ver_cont="   "
            command -v systemd-detect-virt >/dev/null 2>&1 && _hv=$(systemd-detect-virt 2>/dev/null)
            # on bare metal nothing follows, so this entry closes the tree
            if [[ -n $_hv && $_hv != none ]]; then _ver_lead="├─ "; _ver_cont="│  "; fi
            _raw "${_ver_lead}The server is verified before the installer finishes"
            _wrap "$_ver_cont" "Any record of a previous attempt is read for known failures. Where none exists the server is started on a spare display, briefly and without taking the console, purely to produce one."
            if [[ -n $_hv && $_hv != none ]]; then
                _raw "│"
                _raw "└─ This machine is a guest under ${_hv}"
                _raw "   │"
                # the tweak closes the tree unless guest tools follow it
                _vm_lead="   └─ "; _vm_cont="      "
                case "$_hv" in
                    vmware)   command -v vmtoolsd      >/dev/null 2>&1 || { _vm_lead="   ├─ "; _vm_cont="   │  "; } ;;
                    oracle)   command -v VBoxClient    >/dev/null 2>&1 || { _vm_lead="   ├─ "; _vm_cont="   │  "; } ;;
                    kvm|qemu) command -v spice-vdagent >/dev/null 2>&1 || { _vm_lead="   ├─ "; _vm_cont="   │  "; } ;;
                    *)        _vm_lead="   ├─ "; _vm_cont="   │  " ;;
                esac
                _pick "vm:tweak" "$_vm_lead" "[*] Adjust display settings for virtualised graphics" "" 0
                _raw "${_vm_cont%% }"
                _wrap "$_vm_cont" "A virtual display reports refresh and damage information the host does not honour. Settings that wait on those signals leave the screen holding its first frame, so vertical synchronisation, damage tracking and hardware compositing are turned off in the configuration this installer places. The original is kept alongside it."
                # nothing is offered that this system already carries
                local _hv_have=0
                case "$_hv" in
                    vmware)  command -v vmtoolsd >/dev/null 2>&1 && _hv_have=1
                             [[ -x /usr/bin/vmtoolsd || -x /usr/sbin/vmtoolsd ]] && _hv_have=1 ;;
                    oracle)  command -v VBoxClient >/dev/null 2>&1 && _hv_have=1
                             command -v VBoxService >/dev/null 2>&1 && _hv_have=1 ;;
                    kvm|qemu) command -v spice-vdagent >/dev/null 2>&1 && _hv_have=1 ;;
                esac
                if (( ! _hv_have )); then
                    _raw "   │"
                    _pick "vm:tools" "   └─ " "[*] Install the ${_hv} guest tools" "" 0
                    _raw "      "
                    _wrap "      " "Clipboard, screen resizing and time synchronisation between guest and host. Not required for the display to work."
                fi
            fi
        fi

        _sec "PAYLOAD"
        L+=("")
        (( ${#FONTS[@]} ))    && _row "Fonts" "${#FONTS[@]}"
        (( ${#SERVICES[@]} )) && _row "Services" "${#SERVICES[@]}"
        (( ${#REPOS[@]} ))    && _row "Repositories" "${#REPOS[@]}"
        (( ${#FILES[@]} ))    && { _row "Files" "${#FILES[@]}"; L+=(""); }
        _row "Disk required" "$disk_requirement"
        local _avs; _bytes_v "${_F_AVAIL:-}"; _avs=$_BYTES
        _row "Disk available" "$_avs"
        if (( ${#FILES[@]} )); then
            L+=("")
            _row "Retrieval source" "$_F_SOURCE"
        fi

    }

    local sz; sz=$(stty size 2>/dev/null) || sz="24 80"
    rows=${sz% *}; cols=${sz#* }
    (( cols < 40 )) && cols=40
    _build_manifest


    _row_text() {
        local idx=$1
        local txt=${L[$idx]:-}
        local k ind pre post w pad
        ROWTXT=""
        pad="  "; (( is_root )) || pad=""
        if [[ $txt == __PICK__* ]]; then
            k=$(( ${txt#__PICK__} - 1 ))
            ind=${SEL_IND[$k]}; pre=${SEL_PRE[$k]}; post=${SEL_POST[$k]}; w=${SEL_W[$k]}
            # a row that starts with a tree glyph is already positioned
            [[ -n $ind ]] && pad=""
            [[ -n ${SKIP_MGR[${SEL_KEY[$k]}]:-} ]] && pre=${pre/\[\*\]/[ ]}
            if (( is_root == 0 )); then
                pre=${pre#\[[* ]\] }
                if (( w > 0 )); then printf -v ROWTXT '%s%-*s %s' "$ind" "$w" "$pre" "$post"
                else printf -v ROWTXT '%s%s' "$ind" "$pre"; fi
                return
            fi
            # A switched-off entry is shown dim, selected or not, and never
            # bold: the tree characters to its left keep their own colour.
            local _em=$bold _er=$reset _pm="" _pr=""
            if [[ -n ${SKIP_MGR[${SEL_KEY[$k]}]:-} ]]; then
                _em=$'\033[2m'; _er=$'\033[0m'
                # the value column follows the name into grey, but is never
                # emphasised when the entry is on
                _pm=$_em; _pr=$_er
            fi
            if (( k == active )); then
                if (( w > 0 )); then
                    printf -v ROWTXT ' %s%s%s%s%*s %s%s%s' "$ind" "$_em" "$pre" "$_er" \
                        $(( w - ${#pre} + 1 )) "" "$_pm" "$post" "$_pr"
                else
                    printf -v ROWTXT '%s%s%s%s' "${ind% }" "$_em" "$pre" "$_er"
                fi
            else
                if [[ -n ${SKIP_MGR[${SEL_KEY[$k]}]:-} ]]; then
                    if (( w > 0 )); then
                        printf -v ROWTXT '%s%s%s%s%s%*s %s%s%s' "$pad" "$ind" "$_em" "$pre" "$_er" \
                            $(( w - ${#pre} )) "" "$_pm" "$post" "$_pr"
                    else
                        printf -v ROWTXT '%s%s%s%s%s' "$pad" "$ind" "$_em" "$pre" "$_er"
                    fi
                elif (( w > 0 )); then
                    printf -v ROWTXT '%s%s%-*s %s' "$pad" "$ind" "$w" "$pre" "$post"
                else printf -v ROWTXT '%s%s%s' "$pad" "$ind" "$pre"; fi
            fi
            return
        fi
        ROWTXT=$txt
            if [[ -n $txt ]]; then
                if _gk=$(_grp_of "$idx") && [[ -n ${SKIP_MGR[$_gk]:-} ]]; then
                    # the leading tree keeps its colour; the words after it dim
                    _lead=${txt%%[![:space:]│├└─]*}
                    printf -v ROWTXT '%s\033[2m%s\033[0m' "$_lead" "${txt#"$_lead"}"
                fi
            fi
    }

    _line_at() {
        local idx=$1 screen_row=$2
        _row_text "$idx"
        printf '\033[%d;1H\033[2K%s' "$screen_row" "$ROWTXT"
    }

    _draw_body() {
        local n frame="" row
        for (( n=0; n<view; n++ )); do
            row=$(( ${#HDR[@]} + 2 + n ))
            _row_text $(( off + n ))
            frame+=$'\033['"$row"$';1H\033[2K'"$ROWTXT"
        done
        frame+=$'\033[?25l'
        printf '%s' "$frame"
    }

    _draw_all() {
        local sz; sz=$(stty size 2>/dev/null) || sz="24 80"
        rows=${sz% *}; cols=${sz#* }
        (( cols < 40 )) && cols=40
        if [[ $cols != "${_built_cols:-}" ]]; then
            _build_manifest
            (( ${#SEL_KEY[@]} )) && (( active >= ${#SEL_KEY[@]} )) && active=$(( ${#SEL_KEY[@]} - 1 ))
            (( active < 0 )) && active=0
        fi
        view=$(( rows - ${#HDR[@]} - 3 )); (( view < 1 )) && view=1
        local _mx=$(( ${#L[@]} - view )); (( _mx < 0 )) && _mx=0
        (( off > _mx )) && off=$_mx
        local n frame=$'\033[H\033[J'
        for (( n=0; n<${#HDR[@]}; n++ )); do
            frame+=$'\033['"$(( n + 1 ))"$';1H\033[2K'"${HDR[$n]}"
        done
        printf '%s' "$frame"
        _draw_body
        printf '\033[%d;1H\033[2K%b' "$rows" "${bold}[space] sel${reset}"
        printf '\033[%d;%dH%b' "$rows" $(( cols - 5 )) "${bold}[esc]${reset}"
        printf '\033[?25l'
    }

    _max_off() { local m=$(( ${#L[@]} - view )); (( m < 0 )) && m=0; printf '%s' "$m"; }

    # Moves by any number of rows and draws a single frame, so a burst of key
    # presses costs one repaint rather than one each.
    _scroll_by() {
        local n=$1 max prev=$off
        max=$(_max_off)
        off=$(( off + n ))
        (( off > max )) && off=$max
        (( off < 0 )) && off=0
        (( off == prev )) && return 0
        _draw_body
    }

    _scroll() { _scroll_by "$1"; }

    # The total only counts managers that are still selected, so turning one
    # off subtracts its packages immediately.
    _pkg_recount() {
        [[ -n ${TOTAL_HEAD:-} ]] || return 0
        local m live=0 w=24
        (( is_root )) || w=22
        for m in "${!PKG_COUNT[@]}"; do
            [[ -n ${SKIP_MGR[pkg:$m]:-} ]] && continue
            live=$(( live + PKG_COUNT[$m] ))
        done
        L[$TOTAL_HEAD]=$(printf '%-*s %s' "$w" "Total queued" \
                         "$live $(_plural "$live" package)")
        if (( TOTAL_HEAD >= off && TOTAL_HEAD < off + view )); then
            _line_at "$TOTAL_HEAD" $(( ${#HDR[@]} + 2 + TOTAL_HEAD - off ))
        fi
    }

    # Recomputes the source heading so the figure reflects what is still
    # selected the moment an entry is turned off.
    _src_recount() {
        [[ -n ${SRC_HEAD:-} ]] || return 0
        local i live=0 w=24
        (( is_root )) || w=22
        for (( i=0; i<${#REPOS[@]}; i++ )); do
            [[ -n ${SKIP_MGR[src:$i]:-} ]] || (( live++ ))
        done
        L[$SRC_HEAD]=$(printf '%s%-*s%s %s' "$bold" "$w" "BUILD FROM SOURCE" "$reset" \
                       "$live $(_plural "$live" item) queued")
        if (( SRC_HEAD >= off && SRC_HEAD < off + view )); then
            _line_at "$SRC_HEAD" $(( ${#HDR[@]} + 2 + SRC_HEAD - off ))
        fi
    }

    _row_of_active() {
        local r=${SEL_ROW[$active]}
        (( r < off || r >= off + view )) && return 0
        _line_at "$r" $(( ${#HDR[@]} + 2 + r - off ))
    }

    _repaint_pair() {
        local r frame="" scr
        for r in "${SEL_ROW[$_prev]}" "${SEL_ROW[$active]}"; do
            (( r >= off && r < off + view )) || continue
            scr=$(( ${#HDR[@]} + 2 + r - off ))
            _row_text "$r"
            frame+=$'\033['"$scr"$';1H\033[2K'"$ROWTXT"
        done
        frame+=$'\033[?25l'
        printf '%s' "$frame"
    }

    _ensure_visible() {
        local r=${SEL_ROW[$active]}
        (( r < off )) && { off=$r; _draw_all; return; }
        (( r >= off + view )) && { off=$(( r - view + 1 )); _draw_all; return; }
    }

    local key rest sgr c _prev=0 _k _extra _delta
    local _rv_stty; _rv_stty=$(stty -g 2>/dev/null)
    stty -echo 2>/dev/null
    printf '\033[?1000h\033[?1006h'
    view=$(( rows - ${#HDR[@]} - 3 )); (( view < 1 )) && view=1
    _draw_all
    while true; do
        (( _resized )) && { _resized=0; _draw_all; }
        IFS= read -t 0.05 -rsn1 key || continue
        case "$key" in
            ' ')
                (( is_root )) || continue
                (( ${#SEL_KEY[@]} )) || continue
                _k=${SEL_KEY[$active]}
                if [[ -n ${SKIP_MGR[$_k]:-} ]]; then
                    unset "SKIP_MGR[$_k]"
                    # selecting a queue requires its manager; selecting a
                    # manager says nothing about whether its queue is wanted
                    [[ $_k == pkg:* ]] && unset "SKIP_MGR[mgr:${_k#pkg:}]"
                else
                    SKIP_MGR[$_k]=1
                    # a queue cannot be installed without its manager
                    [[ $_k == mgr:* ]] && SKIP_MGR[pkg:${_k#mgr:}]=1
                fi
                [[ $_k == src:* ]] && _src_recount
                [[ $_k == pkg:* ]] && _pkg_recount
                _draw_body
                printf '\033[?25l' ;;
            $'\x1b')
                if IFS= read -rsn2 -t 0.001 rest 2>/dev/null; then
                    case "$rest" in
                        '[A')
                            (( is_root )) || continue
                            (( ${#SEL_KEY[@]} )) || continue
                            _prev=$active
                            active=$(( (active - 1 + ${#SEL_KEY[@]}) % ${#SEL_KEY[@]} ))
                            _ensure_visible
                            _repaint_pair ;;
                        '[B')
                            (( is_root )) || continue
                            (( ${#SEL_KEY[@]} )) || continue
                            _prev=$active
                            active=$(( (active + 1) % ${#SEL_KEY[@]} ))
                            _ensure_visible
                            _repaint_pair ;;
                        '[5') read -rsn1 -t 0.001 rest; _scroll_by $(( -view )) ;;
                        '[6') read -rsn1 -t 0.001 rest; _scroll_by "$view" ;;
                        '[<')
                            sgr=$rest
                            while IFS= read -rsn1 -t 0.001 c 2>/dev/null; do
                                sgr+=$c; [[ $c == [Mm] ]] && break
                            done
                            if [[ $sgr =~ \<64\; ]]; then _scroll_by -1
                            elif [[ $sgr =~ \<65\; ]]; then _scroll_by 1
                            fi ;;
                    esac
                else
                    break
                fi ;;
            $'\x7f'|$'\x08'|q|Q) break ;;
            k) _scroll_by -1 ;;
            j) _scroll_by 1 ;;
            g) off=0; _draw_all ;;
            G) off=$(_max_off); _draw_all ;;
        esac
    done
    printf '\033[?1006l\033[?1000l'
    [[ -n $_rv_stty ]] && stty "$_rv_stty" 2>/dev/null
    return 0
}

# ─────────────────────────── DISCOVERY

get_pkg_manager() {
    local mgr
    pkg_mgrs=(apt dnf yum pacman port pkg zypper xbps apk entropy dpkg ipkg opkg
              netpkg petget pkgsrc emerge openpkg guix brew slackpkg flatpak
              rpm-ostree snap rpm eopkg crew pkgtool nix paru trizen pikaur
              aurman yay pacaur aura pakku)
    available_pkg_managers=()
    for mgr in "${pkg_mgrs[@]}"; do
        command -v "$mgr" >/dev/null 2>&1 && available_pkg_managers+=("$mgr")
    done
    if [[ -x /nix/var/nix/profiles/default/bin/nix ]] &&
       [[ " ${available_pkg_managers[*]} " != *" nix "* ]]; then
        available_pkg_managers+=("nix")
    fi
    [[ -n ${output:-} ]] &&
        printf 'Detected package manager(s): %s\n' "${available_pkg_managers[*]:-none}" >> "$output"
}

_norm_arch() {
    local t=${1//[[:space:]]/}; t=${t,,}
    case $t in
        x86-64|x86_64|x64|amd64|intel64|em64t)            printf 'x86-64' ;;
        x86|x86-32|ia-32|i386|i486|i586|i686)             printf 'x86' ;;
        aarch64|arm64|armv8*|armv9*)                      printf 'AArch64' ;;
        arm|arm32|aarch32|armv7*|armv6*|armhf|armel)      printf 'ARM' ;;
        risc-v|riscv|riscv32|riscv64|rv32|rv64|rv128)     printf 'RISC-V' ;;
        powerpc|ppc|ppc64|ppc64le|ppc64el|power|powerisa) printf 'PowerPC' ;;
        mips|mips32|mips64|mipsel|mips64el)               printf 'MIPS' ;;
        *)                                                printf '%s' "$t" ;;
    esac
}

get_kernel() {
    IFS=" " read -ra uname <<< "$(uname -srm)"
    kernel_name="${uname[0]}"
    kernel_version="${uname[1]}"
    kernel_machine="${uname[2]}"
    [[ $kernel_name =~ (AIX|IRIX) ]] && {
        kernel="$kernel_name (unsupported kernel info)"
        return
    }
    if [[ $kernel_name == "Haiku" ]]; then
        kernel=$(uname -v)
        return
    fi
    if [[ "$kernel_name" == "Darwin" ]]; then
        export SYSTEM_VERSION_COMPAT=0
        IFS=$'\n' read -d "" -ra sw_vers <<< "$(awk -F'<|>' '/key|string/ {print $3}' \
                                "/System/Library/CoreServices/SystemVersion.plist")"
        for ((i=0; i < ${#sw_vers[@]}; i += 2)); do
            case ${sw_vers[i]} in
                ProductName)          darwin_name=${sw_vers[i+1]} ;;
                ProductVersion)       osx_version=${sw_vers[i+1]} ;;
                ProductBuildVersion)  osx_build=${sw_vers[i+1]}   ;;
            esac
        done
        kernel="$kernel_name $osx_version ($osx_build)"
    else
        kernel="$kernel_name $kernel_version"
    fi
}

get_os() {
    case $kernel_name in
        Darwin)   os=$darwin_name ;;
        SunOS)    os=Solaris ;;
        Haiku)    os=Haiku ;;
        MINIX)    os=MINIX ;;
        AIX)      os=AIX ;;
        IRIX*)    os=IRIX ;;
        FreeMiNT) os=FreeMiNT ;;
        Linux|GNU*)
            os=Linux ;;
        *BSD|DragonFly|Bitrig)
            os=BSD ;;
        *)
            type_effect1 "Unexpected OS detected: '$kernel_name', issues may occur. Consider adding support for your OS by contributing at https://mucator.net/" >&2
        ;;
    esac
}

get_shell() {
    shell="${SHELL##*/}"
}

get_display() {
    if [ -n "$WAYLAND_DISPLAY" ]; then
        display="Wayland"
    elif [ -n "$DISPLAY" ]; then
        display="X11"
    else
        display="None"
    fi
}

get_resolution() {
    case $os in
        "Mac OS X"|"macOS")
            if type -p screenresolution >/dev/null; then
                active_res="$(screenresolution get 2>&1 | awk '/Display/ {printf $6 "Hz, "}')"
                active_res="${active_res//x??@/ @ }"
            else
                active_res="$(system_profiler SPDisplaysDataType |\
                              awk '/Resolution:/ {printf $2"x"$4" @ "$6"Hz, "}')"
            fi
            if [[ -e "/Library/Preferences/com.apple.windowserver.plist" ]]; then
                scale_factor="$(PlistBuddy -c "Print DisplayAnyUserSets:0:0:Resolution" \
                                /Library/Preferences/com.apple.windowserver.plist)"
            else
                scale_factor=""
            fi
            [[ "$active_res" == *"@ Hz"* ]] && \
                active_res="${active_res//@ Hz}"
            [[ "${scale_factor%.*}" == 2 ]] && \
                active_res="${active_res// @/@2x @}"
            [[ "$active_res" == *"0Hz"* ]] && \
                active_res="${active_res// @ 0Hz}"
        ;;
        "Haiku")
            active_res="$(screenmode | awk -F ' |, ' 'END{printf $2 "x" $3 " @ " $6 $7}')"
            [[ "$refresh_rate" == "off" ]] && active_res="${active_res/ @*}"
        ;;
        *)
            if type -p xrandr >/dev/null && [[ $DISPLAY && -z $WAYLAND_DISPLAY ]]; then
                active_res="$(xrandr --nograb --current |\
                              awk 'match($0,/[0-9]*\.[0-9]*\*/) {
                                   printf $1 " @ " substr($0,RSTART,RLENGTH) "Hz, "}')"
                active_res="${active_res//\*}"
            elif type -p xwininfo >/dev/null && [[ $DISPLAY && -z $WAYLAND_DISPLAY ]]; then
                read -r w h \
                    <<< "$(xwininfo -root | awk -F':' '/Width|Height/ {printf $2}')"
                active_res="${w}x${h}"
            elif type -p xdpyinfo >/dev/null && [[ $DISPLAY && -z $WAYLAND_DISPLAY ]]; then
                active_res="$(xdpyinfo | awk '/dimensions:/ {printf $2}')"
            elif [[ -d /sys/class/drm ]]; then
                for dev in /sys/class/drm/*/modes; do
                    read -r single_resolution _ < "$dev"
                    [[ $single_resolution ]] && active_res="${single_resolution}, ${active_res}"
                done
            fi
        ;;
    esac
    active_res="${active_res%%,}"
    active_res="${active_res%%, }"
    active_res="${active_res//[[:space:]]/}"
    [[ -z "${active_res/x}" ]] && active_res=
    if [[ "$active_res" == *"@"* ]]; then
        refresh_rate="${active_res#*@}"
        refresh_rate="${refresh_rate#"${refresh_rate%%[![:space:]]*}"}"
        active_res="${active_res%%@*}"
    else
        refresh_rate=""
    fi
}

get_info() {
    get_kernel
    get_os
    get_shell
    get_display
}

# ─────────────────────────── CONFIRM INSTALL PATH

confirm_user() {
    if [[ $deploy == true ]]; then
        user_home=$(getent passwd "$(logname 2>/dev/null || echo root)" 2>/dev/null | cut -d: -f6)
        [[ -n $user_home && -d $user_home ]] || user_home=/root
        user=$(basename "$user_home")
        [[ $user_home == /root || $user_home == /var/root ]] && user=root
        return 0
    fi
    _RESTART_MAIN_MENU=0
    showed_warning=0
    declare -g num_rows=0
    prefix_inactive="[ ] "
    prefix_active="[*] "
    spacing_extra=1
    items_per_row=4
    SELECTED_HOME=""
    get_home_name() {
        local path="$1"
        case "$path" in
        "/root"|"/var/root") echo "root" ;;
        *) basename "$path" ;;
        esac
    }
    ESC=$(printf "\033")
    cursor_blink_on() { printf "$ESC[?25h"; }
    cursor_blink_off() { printf "$ESC[?25l"; }
    cursor_to() { printf "$ESC[$1;${2:-1}H"; }
    get_cursor_row() { IFS=';' read -sdR -p $'\E[6n' ROW COL; echo ${ROW#*[}; }
    enable_mouse() {
        printf "\e[?1000h"
        printf "\e[?1003h"
        printf "\e[?1006h"
        stty -echo
    }
    disable_mouse() {
        printf "\e[?1003l"
        printf "\e[?1000l"
        printf "\e[?1006l"
        stty echo
    }
    read_line() {
        local _varname=$1
        local _secret=${2:-0}
        local _input=""
        local _char
        while IFS= read -rsn1 _char; do
            if [[ -z "$_char" ]]; then
                break
            elif [[ "$_char" == $'\x1b' ]]; then
                _input="__ESC__"
                break
            elif [[ "$_char" == $'\x7f' || "$_char" == $'\b' ]]; then
                if [[ -n "$_input" ]]; then
                    _input="${_input%?}"
                    if (( _secret == 0 )); then
                        printf "\b \b"
                    fi
                fi
            else
                _input+="$_char"
                if (( _secret == 0 )); then
                    printf "%s" "$_char"
                fi
            fi
        done
        printf -v "$_varname" '%s' "$_input"
    }
    key_input() {
        local key _krc
        IFS= read -t 0.05 -rsn1 key 2>/dev/null >&2
        _krc=$?
        if (( _krc > 128 )); then echo tick; return; fi
        (( _krc != 0 )) && return
        if [[ $key = "" ]]; then echo enter; fi
        if [[ $key == $'\x7f' || $key == $'\x08' ]]; then echo esc; fi
        if [[ $key = $'\x1b' ]]; then
            read -rsn2 -t 0.001 key 2>/dev/null
            case "$key" in
            "[A") echo up ;;
            "[B") echo down ;;
            "[C") echo right ;;
            "[D") echo left ;;
            "[M")
                read -rsn3 mouse
                case "$mouse" in
                $'\x20'*) echo enter ;;
                *$'\x60'*) echo scroll_up ;;
                *$'\x61'*) echo scroll_down ;;
                *$'\x62'*) echo left ;;
                *$'\x63'*) echo right ;;
                esac ;;
            "[<")
                local sgr="$key"
                local c
                while IFS= read -rsn1 -t 0.001 c 2>/dev/null; do
                    sgr+="$c"
                    [[ "$c" =~ [Mm] ]] && break
                done
                if [[ "$sgr" =~ \<0\;[0-9]+\;[0-9]+M$ ]]; then echo enter
                elif [[ "$sgr" =~ \<64\;[0-9]+\;[0-9]+M$ ]]; then echo scroll_up
                elif [[ "$sgr" =~ \<65\;[0-9]+\;[0-9]+M$ ]]; then echo scroll_down
                elif [[ "$sgr" =~ \<66\;[0-9]+\;[0-9]+M$ ]]; then echo left
                elif [[ "$sgr" =~ \<67\;[0-9]+\;[0-9]+M$ ]]; then echo right
                fi ;;
            "") echo esc ;;
            esac
        elif [[ $key =~ ^[kjhlian]$ ]]; then
            case "$key" in
            k) echo up ;; j) echo down ;; h) echo left ;; l) echo right ;;
            i) echo info ;; a) echo all ;; n) echo new ;;
            esac
        fi
    }
    build_helpbar() {
        local cols=$(tput cols)
        if [[ $show_all_option == true ]]; then
            declare -g helpbar_left="\033[1m[n]\033[0m new  \033[1m[i]\033[0m info  \033[1m[a]\033[0m ${current_a_label}"
        else
            declare -g helpbar_left="\033[1m[n]\033[0m new  \033[1m[i]\033[0m info"
        fi
        local left_len=26
        [[ $current_a_label == "less" ]] && left_len=27
        local right_len=7
        declare -g helpbar_right="\033[1m[enter]\033[0m"
        declare -g helpbar_spaces=$((cols - left_len - right_len))
        ((helpbar_spaces < 1)) && helpbar_spaces=1
        declare -g help_bar
        help_bar=$(printf "%b%${helpbar_spaces}s%b" "$helpbar_left" "" "$helpbar_right")
    }
    create_new_user() {
        cursor_blink_on
        disable_mouse
        cursor_to "$(tput lines)" 1
        printf '\033[2K\r'
        local new_user new_password conf_password home_dir shell_path choice
        while true; do
            printf '\033[2K\r'
            type_effect1 "Username: " "$menu_delay"
            read_line new_user
            if [[ "$new_user" == "__ESC__" ]]; then cursor_blink_off; enable_mouse; return 1; fi
            if [[ ! "$new_user" =~ ^[a-zA-Z_][a-zA-Z0-9_-]{0,31}$ ]]; then
                printf '\033[2K\r'
                type_effect1 "Invalid username. Use letters, digits, underscores, or hyphens." "$menu_delay"
                sleep 3
                continue
            fi
            if [[ -z "$new_user" ]]; then continue; fi
            if id -u "$new_user" >/dev/null 2>&1; then
                printf '\033[2K\r'
                type_effect1 "User '$new_user' already exists." "$menu_delay"
                sleep 2
                continue
            fi
            break
        done
        while true; do
            printf '\033[2K\r'
            type_effect1 "Password: " "$menu_delay"
            read_line new_password 1
            if [[ "$new_password" == "__ESC__" ]]; then cursor_blink_off; enable_mouse; return 1; fi
            printf '\033[2K\r'
            type_effect1 "Confirm Password: " "$menu_delay"
            read_line conf_password 1
            if [[ "$conf_password" == "__ESC__" ]]; then cursor_blink_off; enable_mouse; return 1; fi
            if [[ "$new_password" == "$conf_password" && -n "$new_password" ]]; then
                break
            fi
            printf '\033[2K\r'
            type_effect1 "Passwords did not match. Try again." "$menu_delay"
            sleep 2
        done
        printf '\033[2K\r'
        type_effect1 "Home: /home/$new_user [Y/n] " "$menu_delay"
        while true; do
            read -n 1 -s choice
            case "$choice" in
                ""|Y|y)
                    home_dir="/home/$new_user"
                    break
                    ;;
                N|n)
                    while true; do
                        printf '\033[2K\r'
                        type_effect1 "Home path: " "$menu_delay"
                        read_line home_dir
                        if [[ "$home_dir" == "__ESC__" ]]; then cursor_blink_off; enable_mouse; return 1; fi
                        [[ -z "$home_dir" ]] && continue
                        if [[ ! "$home_dir" =~ ^/([a-zA-Z0-9_\.\-]+/)*[a-zA-Z0-9_\.\-]+$ ]]; then
                            printf '\033[2K\r'
                            type_effect1 "Invalid path entered. Please enter a valid absolute path." "$menu_delay"
                            sleep 3
                            continue
                        fi
                        if [[ -d "$home_dir" ]]; then
                            break
                        elif mkdir -p "$home_dir" 2>/dev/null; then
                            break
                        else
                            printf '\033[2K\r'
                            type_effect1 "Invalid path entered. Please enter a valid absolute path." "$menu_delay"
                            sleep 3
                            continue
                        fi
                    done
                    break
                    ;;
                *)
                    ;;
            esac
        done
        printf '\033[2K\r'
        type_effect1 "Shell: $SHELL [Y/n] " "$menu_delay"
        shell_path="$SHELL"
        while true; do
            read -n 1 -s choice
            case "$choice" in
                ""|Y|y)
                    shell_path="$SHELL"
                    break
                    ;;
                N|n)
                    while true; do
                        printf '\033[2K\r'
                        type_effect1 "Shell path: " "$menu_delay"
                        read_line shell_path
                        if [[ "$shell_path" == "__ESC__" ]]; then cursor_blink_off; enable_mouse; return 1; fi
                        [[ -z "$shell_path" ]] && continue
                        if [[ -f "$shell_path" ]]; then
                            break
                        else
                            printf '\033[2K\r'
                            type_effect1 "Could not locate '$shell_path'. Are you sure it exists?" "$menu_delay"
                            sleep 3
                            continue
                        fi
                    done
                    break
                    ;;
                *)
                    ;;
            esac
        done
        printf '\033[2K\r'
        type_effect1 "Creating $new_user..." "$menu_delay"
        # The password is handed to chpasswd on stdin only — it is never
        # written to disk and never appears in any command's arguments.
        if command -v useradd >/dev/null 2>&1; then
            useradd -m -d "$home_dir" -s "$shell_path" "$new_user" 2>/dev/null
            echo "$new_user:$new_password" | chpasswd 2>/dev/null
        elif command -v pw >/dev/null 2>&1; then
            pw useradd -n "$new_user" -d "$home_dir" -s "$shell_path" -m 2>/dev/null
            echo "$new_user:$new_password" | pw usermod -n "$new_user" -h 0 2>/dev/null
        else
            adduser --home "$home_dir" --shell "$shell_path" --disabled-password --gecos "" "$new_user" 2>/dev/null
            echo "$new_user:$new_password" | chpasswd 2>/dev/null
        fi
        cursor_blink_off
        enable_mouse
        return 0
    }
    user_menu() {
        cursor_blink_off
        local home_dirs=("$@")
        local terminal_width=$(tput cols)
        local -a normal_users=() normal_paths=()
        for path in "${home_dirs[@]}"; do
            normal_users+=( "$(get_home_name "$path")" )
            normal_paths+=( "$path" )
        done
        local -a all_users=() all_paths=()
        while IFS=: read -r user _ _ _ _ home _; do
            if [[ -n "$home" && "$home" != "/" &&
                  "$home" != "/var/empty" && "$home" != "/dev/null" &&
                  "$home" != "/nonexistent" && "$home" != "/bin/false" &&
                  "$home" != "/sbin/nologin" ]]; then
                all_users+=("$user")
                all_paths+=("$home")
            fi
        done < /etc/passwd
        local show_all_option=true
        (( ${#normal_users[@]} == ${#all_users[@]} )) && show_all_option=false
        local current_mode="normal"
        local current_a_label="all"
        local -a users paths show_info
        local original_count pad start_row top_pad columnGap active=0
        declare -g num_rows
        rebuild_current_data() {
            if [[ "$current_mode" == "normal" ]]; then
                users=("${normal_users[@]}")
                paths=("${normal_paths[@]}")
            else
                users=("${all_users[@]}")
                paths=("${all_paths[@]}")
            fi
            original_count=${#users[@]}
            local remainder=$(( original_count % items_per_row ))
            if (( remainder != 0 )); then
                local pads=$(( items_per_row - remainder ))
                for (( i=0; i<pads; i++ )); do users+=(""); paths+=(""); done
            fi
            local max_len=0
            for u in "${users[@]}" "${paths[@]}"; do
                (( ${#u} > max_len )) && max_len=${#u}
            done
            columnGap=$(( max_len + spacing_extra ))
            local terminal_width=$(tput cols)
            local max_row_width=0
            if (( original_count <= items_per_row )); then
                if (( original_count == 1 )); then
                    max_row_width=$(( ${#prefix_inactive} + ${#users[0]} ))
                else
                    max_row_width=$(( columnGap * (original_count - 1) ))
                    max_row_width=$(( max_row_width + ${#prefix_inactive} * original_count ))
                    max_row_width=$(( max_row_width + ${#users[original_count - 1]} ))
                fi
            else
                for (( start=0; start < ${#users[@]}; start += items_per_row )); do
                    local row_width=0
                    for (( i=0; i<items_per_row; i++ )); do
                        local idx=$(( start + i ))
                        local name="${users[idx]}"
                        (( row_width += ${#prefix_inactive} ))
                        (( row_width += ${#name} ))
                        if (( i < items_per_row - 1 )); then
                            if [[ -n "$name" ]]; then
                                (( row_width += columnGap - ${#name} ))
                            else
                                (( row_width += columnGap ))
                            fi
                        fi
                    done
                    (( row_width > max_row_width )) && max_row_width=$row_width
                done
            fi
            pad=$(( (terminal_width - max_row_width) / 2 ))
            (( pad < 0 )) && pad=0
            local terminal_height=$(tput lines)
            num_rows=$(( (${#users[@]} + items_per_row - 1) / items_per_row ))
            show_info=()
            for ((i=0; i<original_count; i++)); do show_info+=("false"); done
            (( active >= original_count )) && active=0
        }
        _um_layout_pick() {
            items_per_row=4
            rebuild_current_data
            if (( num_rows < 3 && pad >= 2 )); then
                _um_full=0
                return
            fi
            _um_full=1
            local _c9
            for _c9 in 3 2 1; do
                items_per_row=$_c9
                rebuild_current_data
                (( pad >= 2 )) && return
            done
        }
        local _um_full=0
        _um_layout_pick
        build_helpbar
        local _rz_centered=0
        local terminal_height=$(tput lines)
        if (( _um_full )); then
            _rz_centered=1
            clear
            top_pad=$(( (terminal_height - num_rows) / 2 ))
            (( top_pad < 2 )) && top_pad=2
            local menu_start_row=$(( top_pad - 2 ))
            for (( i=0; i<menu_start_row; i++ )); do echo; done
            printf "%*sSelect User:\n" "$pad" ""
            echo
            start_row=$(( menu_start_row + 3 ))
        else
            printf '\r\033[2K'
            start_row=$(get_cursor_row)
        fi
        local bold=$'\e[1m'
        local reset=$'\e[0m'
        first_print() {
            for (( row=0; row < num_rows; row++ )); do
                printf "%*s" "$pad" ""
                for (( col=0; col < items_per_row; col++ )); do
                    local idx=$(( row * items_per_row + col ))
                    local display_name="${users[idx]}"
                    [[ ${show_info[idx]:-false} == true && -n "${paths[idx]}" ]] && display_name="${paths[idx]}"
                    if [[ -n "$display_name" ]] && (( idx < original_count )); then
                        if (( idx == active )); then
                            type_effect1 "${prefix_active}${display_name}" "$menu_delay"
                        else
                            type_effect1 "${prefix_inactive}${display_name}" "$menu_delay"
                        fi
                        (( col < items_per_row - 1 && idx + 1 < original_count )) && \
                            printf "%*s" $(( columnGap - ${#display_name} )) ""
                    fi
                done
                echo
            done
        }
        first_print
        enable_mouse
        redraw_grid() {
            if (( num_rows >= 3 || ${_rz_centered:-0} )); then
                for (( row=0; row < num_rows; row++ )); do
                    cursor_to $(( start_row + row ))
                    printf '\033[2K'
                    printf "%*s" "$pad" ""
                    for (( col=0; col < items_per_row; col++ )); do
                        local idx=$(( row * items_per_row + col ))
                        local display_name="${users[idx]}"
                        [[ ${show_info[idx]:-false} == true && -n "${paths[idx]}" ]] && display_name="${paths[idx]}"
                        if [[ -n "$display_name" ]] && (( idx < original_count )); then
                            if (( idx == active )); then
                                printf "\b${bold}%s%s${reset} " "$prefix_active" "$display_name"
                            else
                                printf "%s%s" "$prefix_inactive" "$display_name"
                            fi
                            (( col < items_per_row - 1 && idx + 1 < original_count )) && \
                                printf "%*s" $(( columnGap - ${#display_name} )) ""
                        fi
                    done
                done
            else
                for (( row=0; row < num_rows; row++ )); do
                    cursor_to $(( start_row + row ))
                    printf '\033[2K'
                    printf "%*s" "$pad" ""
                    for (( col=0; col < items_per_row; col++ )); do
                        local idx=$(( row * items_per_row + col ))
                        local display_name="${users[idx]}"
                        [[ ${show_info[idx]:-false} == true && -n "${paths[idx]}" ]] && display_name="${paths[idx]}"
                        if [[ -n "$display_name" ]] && (( idx < original_count )); then
                            if (( idx == active )); then
                                printf "${bold}%s%s${reset}" "$prefix_active" "$display_name"
                            else
                                printf "%s%s" "$prefix_inactive" "$display_name"
                            fi
                            (( col < items_per_row - 1 && idx + 1 < original_count )) && \
                                printf "%*s" $(( columnGap - ${#display_name} )) ""
                        fi
                    done
                done
            fi
            cursor_to "$(tput lines)" 1
            if (( first_draw )); then
                printf '\033[2K\r'
                type_effect1 "$helpbar_left" "$menu_delay"
                printf "%${helpbar_spaces}s" ""
                type_effect1 "$helpbar_right" "$menu_delay"
                first_draw=0
            else
                printf "%b" "$help_bar"
            fi
        }
        _um_rerender() {
            local -a _keep_info=("${show_info[@]}")
            _um_layout_pick
            local _ki
            for (( _ki=0; _ki<original_count; _ki++ )); do
                show_info[_ki]="${_keep_info[_ki]:-false}"
            done
            build_helpbar
            if (( _um_full )); then
                clear
                local _th=$(tput lines)
                top_pad=$(( (_th - num_rows) / 2 ))
                (( top_pad < 2 )) && top_pad=2
                local _msr=$(( top_pad - 2 )) _i9
                for (( _i9=0; _i9<_msr; _i9++ )); do echo; done
                printf "%*sSelect User:\n" "$pad" ""
                echo
                start_row=$(( _msr + 3 ))
                _rz_centered=1
            else
                draw_ui backdrop "$num_rows"
                start_row=$ui_menu_row
                _rz_centered=0
            fi
        }
        first_draw=1
        redraw_grid
        while true; do
            case $(key_input) in
            tick)
                (( _resized )) && { _resized=0; _um_rerender; redraw_grid; }
                continue ;;
            enter)
                cursor_to $(( start_row + num_rows ))
                SELECTED_HOME="${paths[active]}"
                cursor_blink_on
                disable_mouse
                return
                ;;
            esc)
                _RESTART_MAIN_MENU=1
                return
                ;;
            up|scroll_up)
                {
                    local _was=$active
                    local col=$(( active % items_per_row ))
                    local row=$(( active / items_per_row ))
                    if (( row == 0 )); then
                        local prev_col=$(( (col - 1 + items_per_row) % items_per_row ))
                        local new_row=$(( (original_count - 1) / items_per_row ))
                        while (( new_row >= 0 )); do
                            local idx=$(( new_row * items_per_row + prev_col ))
                            if (( idx < original_count )); then active=$idx; break; fi
                            (( new_row-- ))
                        done
                    else
                        (( active -= items_per_row ))
                    fi
                    (( active == _was )) && active=$(( (_was - 1 + original_count) % original_count ))
                }
                ;;
            down|scroll_down)
                {
                    local _was=$active
                    local col=$(( active % items_per_row ))
                    local row=$(( active / items_per_row ))
                    if (( row == num_rows - 1 || active + items_per_row >= original_count )); then
                        local next_col=$(( (col + 1) % items_per_row ))
                        local new_row=0
                        while (( new_row < num_rows )); do
                            local idx=$(( new_row * items_per_row + next_col ))
                            if (( idx < original_count )); then active=$idx; break; fi
                            (( new_row++ ))
                        done
                    else
                        (( active += items_per_row ))
                    fi
                    (( active == _was )) && active=$(( (_was + 1) % original_count ))
                }
                ;;
            left)
                (( active-- ))
                if (( active < 0 )); then active=$(( original_count - 1 )); fi
                ;;
            right)
                (( active++ ))
                if (( active >= original_count )); then active=0; fi
                ;;
            info)
                if (( active < original_count && ${#paths[active]} > 0 )); then
                    show_info[active]=$([[ ${show_info[active]} == true ]] && echo false || echo true)
                fi
                ;;
            all)
                local old_num_rows=$num_rows
                local was_in_all=$([[ $current_mode == "all" ]] && echo true || echo false)
                current_mode=$([[ $current_mode == "normal" ]] && echo "all" || echo "normal")
                current_a_label=$([[ $current_mode == "normal" ]] && echo "all" || echo "less")
                _um_layout_pick
                build_helpbar
                if [[ $was_in_all == true && $old_num_rows -lt 3 ]] && (( ! _um_full && ! _rz_centered )); then
                    _rz_centered=0
                    cursor_to "$start_row" 1
                    printf '\033[2K\r'
                    printf '\033[1B\033[2K\r'
                    cursor_to "$start_row" 1
                else
                    local clear_rows=$(( old_num_rows > num_rows ? old_num_rows : num_rows ))
                    if (( old_num_rows >= 3 || _um_full || _rz_centered )); then
                        _rz_centered=1
                        clear
                        local terminal_height=$(tput lines)
                        top_pad=$(( (terminal_height - num_rows) / 2 ))
                        (( top_pad < 2 )) && top_pad=2
                        local menu_start_row=$(( top_pad - 2 ))
                        for (( i=0; i<menu_start_row; i++ )); do echo; done
                        printf "%*sSelect User:\n" "$pad" ""
                        echo
                        start_row=$(( menu_start_row + 3 ))
                    else
                        if (( clear_rows == 1 )); then
                            printf '\033[2K\r\033[1A\033[2K\r'
                        elif (( clear_rows == 2 )); then
                            printf '\033[2K\r\033[1A\033[2K\r\033[1A\033[2K\r'
                        fi
                    fi
                fi
                cursor_to "$(tput lines)" 1
                printf '\033[2K\r%b' "$help_bar"
                local _cl=$(( old_num_rows > num_rows ? old_num_rows : num_rows )) _ck
                for (( _ck=0; _ck<_cl; _ck++ )); do
                    cursor_to $(( start_row + _ck )) 1
                    printf '\033[2K'
                done
                cursor_to "$start_row" 1
                first_print
                cursor_to "$(tput lines)" 1
                continue
                ;;
            new)
                if create_new_user; then
                    local home_dirs=()
                    while IFS=: read -r _ _ uid _ _ homedir _; do
                        if [[ "$uid" == "0" ]]; then
                            [[ -d "$homedir" ]] && home_dirs+=("$homedir")
                            break
                        fi
                    done < /etc/passwd
                    for base in /home /Users /usr/home; do
                        [[ -d "$base" ]] || continue
                        for d in "$base"/*; do
                            [[ -d "$d" ]] && home_dirs+=("$d")
                        done
                    done
                    user_menu "${home_dirs[@]}"
                    return
                fi
                redraw_grid
                ;;
            esac
            redraw_grid
        done
    }
    root_warning() {
        cursor_blink_off
        clear
        local cols lines pad vpad
        local home_path="$1"
        cols=$(tput cols)
        lines=$(tput lines)
        pad=$(( (cols - 49) / 2 ))
        vpad=$(( (lines - 12) / 2 ))
        printf "%*s" "$vpad" "" | tr ' ' '\n'
        local bold=$(tput bold)
        local reset=$(tput sgr0)
        printf "%*s┌───────────────────────────────────────────────┐\n" "$pad" ""
        printf "%*s│               %sIMPORTANT NOTICE%s                │\n" "$pad" "" "$bold" "$reset"
        printf "%*s│                                               │\n" "$pad" ""
        if [[ "$home_path" == "/var/root" ]]; then
            printf "%*s│   Installing to '/var/root' will %sonly%s affect  │\n" "$pad" "" "$bold" "$reset"
        else
            printf "%*s│   Installing to '/root' will %sonly%s affect      │\n" "$pad" "" "$bold" "$reset"
        fi
        printf "%*s│   applications run as the root user.          │\n" "$pad" ""
        printf "%*s│                                               │\n" "$pad" ""
        printf "%*s│   • Normal user sessions remain unaffected.   │\n" "$pad" ""
        printf "%*s│   • Running a desktop as root is risky due    │\n" "$pad" ""
        printf "%*s│     to potential security vulnerabilities.    │\n" "$pad" ""
        printf "%*s│                                               │\n" "$pad" ""
        printf "%*s│                Proceed? [Y/n]                 │\n" "$pad" ""
        printf "%*s└───────────────────────────────────────────────┘\n" "$pad" ""
    }
    confirm_core() {
        local bold='\e[1m'
        local reset='\e[0m'
        local _rz=0 _rz_done=0
        user_home=$(getent passwd "$(logname 2>/dev/null)" 2>/dev/null | cut -d: -f6)
        [[ -n $user_home ]] || user_home=~
        while true; do
            local terminal_width=$(tput cols)
            local visible_text="Install to: ${user_home}/ [Y/n]"
            local pad=$(( (terminal_width - ${#visible_text}) / 2 ))
            if [[ ("$user_home" == "/root" || "$user_home" == "/var/root") ]] && [[ "$(logname 2>/dev/null)" != "root" || $showed_warning -eq 1 ]]; then
                root_warning "$user_home"
                showed_warning=1
            else
                local terminal_height=$(tput lines)
                if (( _rz )); then
                    _rz=0
                    _rz_done=1
                    draw_ui backdrop
                    printf "%*s" "$pad" ""
                    printf "Install to: ${bold}${user_home}/${reset} [Y/n] "
                elif (( num_rows >= 3 )); then
                    clear
                    local top_pad=$(( (terminal_height - 1) / 2 ))
                    (( top_pad < 0 )) && top_pad=0
                    for (( i=0; i<top_pad; i++ )); do echo; done
                else
                    if (( num_rows < 1 )); then
                        printf '\033[2K\r\033[1A\033[2K\r'
                    elif (( num_rows == 1 )); then
                        printf '\033[2K\r\033[1A\033[2K\r'
                    elif (( num_rows == 2 )); then
                        printf '\033[2K\r\033[1A\033[2K\r\033[1A\033[2K\r'
                    fi
                fi
                if (( ! _rz_done )); then
                    local saved_row=$(get_cursor_row)
                    cursor_to "$(tput lines)" 1; printf '\033[2K\r'; cursor_to "$saved_row" 1
                    printf "%*s" "$pad" ""
                    type_effect1 "Install to: ${bold}${user_home}/${reset} [Y/n] " "$menu_delay"
                fi
                _rz_done=0
            fi
            while true; do
                if ! read -t 0.05 -n 1 -s choice; then
                    (( _resized )) && { _resized=0; _rz=1; continue 2; }
                    continue
                fi
                case "$choice" in
                ""|Y|y)
                    user="$(basename "$user_home")"
                    if [[ "$(logname 2>/dev/null)" == "root" && $showed_warning -eq 0 ]]; then
                        showed_warning=1
                        break
                    fi
                    [[ "$user_home" == "/root" || "$user_home" == "/var/root" ]] && user="root"
                    return 0
                    ;;
                N|n)
                    if (( showed_warning )); then
                        if (( num_rows >= 3 )) || [[ "$(logname 2>/dev/null)" == "root" ]]; then
                            clear
                        else
                            if [[ "$user_home" == "/root" || "$user_home" == "/var/root" ]]; then
                                _RESTART_MAIN_MENU=1; return
                            fi
                        fi
                    fi
                    local home_dirs=()
                    while IFS=: read -r _ _ uid _ _ homedir _; do
                        if [[ "$uid" == "0" ]]; then
                            [[ -d "$homedir" ]] && home_dirs+=("$homedir")
                            break
                        fi
                    done < /etc/passwd
                    for base in /home /Users /usr/home; do
                        [[ -d "$base" ]] || continue
                        for d in "$base"/*; do
                            [[ -d "$d" ]] && home_dirs+=("$d")
                        done
                    done
                    user_menu "${home_dirs[@]}"
                    if (( _RESTART_MAIN_MENU )); then
                        cursor_blink_on; disable_mouse; num_rows=0; return
                    fi
                    user_home="$SELECTED_HOME"
                    showed_warning=1
                    break
                    ;;
                esac
            done
        done
    }
    confirm_core
    if (( _RESTART_MAIN_MENU )); then
        num_rows=0; main_menu
    fi
}

# ─────────────────────────── INIT

verify_root
get_resolution

if [[ $deploy == true ]]; then
    if (( ! is_root )); then
        if command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
            exec sudo -n bash "$(realpath "$0")" -d
        elif command -v doas >/dev/null 2>&1 && doas -n true 2>/dev/null; then
            exec doas -n bash "$(realpath "$0")" -d
        fi
        _e="$(date -u '+%Y-%m-%dT%H:%M:%SZ') Error: unattended deploy requires root privilege; passwordless escalation was not available."
        printf '%s\n' "$_e" >&2
        printf '%s\n' "$_e" >> "$log" 2>/dev/null
        exit 1
    fi
    confirm_user
    get_info
else
    stty sane 2>/dev/null
    printf '\033[?1000l\033[?1002l\033[?1003l\033[?1005l\033[?1006l\033[?1015l\033[?25h'
    trap 'restore_ui'           EXIT
    trap 'restore_ui; exit 130' INT
    trap 'restore_ui; exit 143' TERM
    trap 'restore_ui; exit 129' HUP
    trap 'restore_ui; exit 131' QUIT
    printf '\033[?1049h\033[H'
    mapfile -t ASCII_ART <<< "$ascii"
    ascii_h=${#ASCII_ART[@]}
    ascii_w=0
    for _l in "${ASCII_ART[@]}"; do
        (( ${#_l} > ascii_w )) && ascii_w=${#_l}
    done
    available_bytes=$(df --output=avail -B1 / 2>/dev/null | tail -n 1)
    available_bytes=${available_bytes//[!0-9]/}
    : "${available_bytes:=0}"
    arch_ok=1
    if [[ -n ${platform_arch:-} ]]; then
        _this_arch=$(_norm_arch "$(uname -m)")
        arch_ok=0
        IFS=',' read -ra _supported <<< "$platform_arch"
        for _sa in "${_supported[@]}"; do
            [[ $(_norm_arch "$_sa") == "$_this_arch" ]] && { arch_ok=1; break; }
        done
    fi
    res_line="Resolution: $resolution"
    [[ -n ${active_res:-} ]] && res_line+=" [Active: $active_res]"
    disk_label="Disk Space Requirement: "
    disk_value="${disk_requirement} minimum"
    main_menu
fi
# ─────────────────────────── START INSTALL [1]

if (( ! is_root )); then
    restore_ui
    type_effect1 'Error: installation requires root privilege.\n' "$menu_delay"
    exit 1
fi

if [[ -z "${user:-}" || -z "${user_home:-}" ]]; then
    restore_ui
    type_effect1 'Error: no installation location was resolved.\n' "$menu_delay"
    exit 1
fi

clear

_sz=$(stty size 2>/dev/null) && {
    terminal_height=${_sz% *}
    terminal_width=${_sz#* }
}
unset _sz

rm -f -- "$log" 2>/dev/null
if [[ $verbose == true ]]; then
    exec {_logfd}> >(tee -a "$log")
else
    exec {_logfd}>> "$log"
fi
output="/dev/fd/${_logfd}"

{
    printf '%s\n' "================================================================================"
    _lh_t=" INSTALLATION LOG - ${display_name}"
    _lh_p=$(( (80 - ${#_lh_t}) / 2 )); (( _lh_p < 0 )) && _lh_p=0
    printf '%*s%s\n' "$_lh_p" '' "$_lh_t"
    printf '%s\n' "================================================================================"
    printf ' %-15s %s\n' "Started"        "$(date -u '+%Y-%m-%dT%H:%M:%SZ') ($(date '+%Z'))"
    printf ' %-15s %s\n' "Host"           "$(hostname 2>/dev/null || uname -n)"
    printf ' %-15s %s\n' "Kernel"         "$kernel ($kernel_machine)"
    printf ' %-15s %s\n' "Platform"       "$platform${platform_arch:+ $platform_arch}"
    _m="interactive"; [[ $deploy == true ]] && _m="deploy"
    [[ $verbose == true ]] && _m+=" +verbose"
    printf ' %-15s %s\n' "Mode"           "$_m"
    printf ' %-15s %s\n' "Installer"      "$(realpath "$0" 2>/dev/null || printf '%s' "$0")"
    printf ' %-15s %s (uid %s)\n' "Invoked by" "$(logname 2>/dev/null || id -un)" "$(id -u)"
    printf ' %-15s %s (%s)\n' "Target"        "$user" "$user_home"
    printf ' %-15s %s (%s bytes)\n' "Disk required" "$disk_requirement" "$required_bytes"
    printf ' %-15s %s\n' "Upgrade policy" "${upgrade_policy:-auto}"
    printf ' %-15s %s\n' "Name resolution" "${translation:-auto}"
    [[ -n "${HDR_EXTRA:-}" ]] && printf '%s\n' "$HDR_EXTRA"
    printf ' %-15s %s\n' "Log file"       "$log"
    printf '\n' 
    # what the home filesystem holds now, to compare against at the end
    HOME_USED_BEFORE=$(df -k "$user_home" 2>/dev/null | awk 'NR==2{print $3}')
    printf ' DISK LAYOUT (pre-install)\n'
    { df -h --output=source,fstype,size,used,avail,pcent,target \
         -x tmpfs -x devtmpfs -x squashfs -x overlay 2>/dev/null || df -h; } | sed 's/^/ /'
    printf '%s\n\n' "================================================================================"
} > "$output"

type_effect() {
    printf '%b\n\n' "$1" | sed 's/\x1b\[[0-9;]*m//g' >> "$output"
    [[ $deploy == true ]] && return
    if [[ $no_anim == true ]]; then
        printf '%b\n' "$1"
        return
    fi
    local _t _i
    printf -v _t '%b' "$1"
    for (( _i=0; _i<${#_t}; _i++ )); do
        printf '%s' "${_t:_i:1}"
        sleep "$2"
    done
    echo
}

spin() {
    [[ "$verbose" == true ]] && return
    local delay=0.1
    local spinner='|/-\'
    local i=0
    local start_time=$(date +%s)
    local show_info_hint=false
    local show_log_line=false
    local last_rendered_line=""
    local hint_rendered=false
    local rows cols char
    local UI_ROW=${UI_ROW:-}
    local old_stty_settings
    old_stty_settings=$(stty -g < /dev/tty 2>/dev/null)
    exec {tty_fd}<> /dev/tty
    printf '\033[?25l' > /dev/tty
    drain_keyboard() {
        while read -rsn1 -t 0 -u "$tty_fd" 2>/dev/null; do :; done
    }
    _spin_cleanup() {
        [[ -n $old_stty_settings ]] && stty "$old_stty_settings" < /dev/tty 2>/dev/null
        printf '\033[%d;1H\033[2K' "${rows:-24}" > /dev/tty 2>/dev/null
        [[ -n ${UI_ROW:-} ]] && printf '\033[%d;1H' "$UI_ROW" > /dev/tty 2>/dev/null
        printf '\033[?25l' > /dev/tty 2>/dev/null
        exec {tty_fd}>&- 2>/dev/null
        exit
    }
    trap _spin_cleanup EXIT INT TERM
    while true; do
        # Read the size from the terminal itself. tput reports the size of
        # stdout, which is redirected during installs, and that is what put
        # the bar in the middle of the screen instead of the last row.
        read -r rows cols < <(stty size < /dev/tty 2>/dev/null)
        [[ -n $rows ]] || rows=24
        [[ -n $cols ]] || cols=80
        local now=$(date +%s)
        local elapsed=$((now - start_time))
        if (( elapsed >= 60 )) && [[ "$show_info_hint" == false ]]; then
            show_info_hint=true
            stty -echo -icanon min 0 time 0 <&$tty_fd 2>/dev/null
            drain_keyboard
        fi
        if [[ "$show_info_hint" == true ]] &&
           read -rsn1 -t 0.001 -u "$tty_fd" char 2>/dev/null; then
            [[ "$char" == $'\e' ]] && char="ESC"
            if [[ "$show_info_hint" == true ]]; then
                if [[ "$show_log_line" == false && "$char" == "i" ]]; then
                    show_log_line=true; last_rendered_line=""; hint_rendered=false
                    printf '\033[%d;1H\033[2K' "$rows" > /dev/tty
                elif [[ "$show_log_line" == true && "$char" == "ESC" ]]; then
                    show_log_line=false; last_rendered_line=""; hint_rendered=false
                    printf '\033[%d;1H\033[2K' "$rows" > /dev/tty
                fi
            fi
        fi
        printf '\033[%d;1H%s' "$rows" "${spinner:i++%${#spinner}:1}" > /dev/tty
        [[ -n ${UI_ROW:-} ]] && printf '\033[%d;1H' "$UI_ROW" > /dev/tty
        if [[ "$show_info_hint" == true && "$hint_rendered" == false ]]; then
            if [[ "$show_log_line" == true ]]; then
                printf '\033[%d;%dH[esc]' "$rows" $((cols-4)) > /dev/tty
            else
                printf '\033[%d;%dH[i]' "$rows" $((cols-2)) > /dev/tty
            fi
            hint_rendered=true
        fi
        if [[ "$show_log_line" == true && -f "$output" ]]; then
            local max_width=$((cols-8))
            local current_log_line
            current_log_line=$(
                tail -n 1 "$output" 2>/dev/null \
                | sed 's/^[[:space:]]*//; s/\x1b\[[0-9;]*m//g' \
                | tr -d '\n\r' \
                | cut -c1-"$max_width"
            )
            if [[ "$current_log_line" != "$last_rendered_line" ]]; then
                printf '\033[%d;3H%-*s' "$rows" "$max_width" "$current_log_line" > /dev/tty
                last_rendered_line="$current_log_line"
            fi
        fi
        sleep "$delay"
    done
}
load_ui() {
    [[ "$verbose" == true ]] && return
    # Record where the caller is so the bar can be cleared without relying on
    # terminal save and restore, which collides with the alternate buffer.
    UI_ROW=""
    if [[ -t 0 ]]; then
        local _st
        _st=$(stty -g 2>/dev/null)
        stty raw -echo 2>/dev/null
        printf '\033[6n'
        IFS='[;' read -r -d R -t 0.2 _ UI_ROW _ 2>/dev/null
        [[ -n $_st ]] && stty "$_st" 2>/dev/null
        [[ $UI_ROW =~ ^[0-9]+$ ]] || UI_ROW=""
    fi
    rm -f /tmp/spin_fifo_* 2>/dev/null || true
    spin &
    spinner_pid=$!
}

close_ui() {
    [[ "$verbose" == true ]] && { echo; return; }
    if [[ -n "$spinner_pid" ]]; then
        kill "$spinner_pid" 2>/dev/null
        wait "$spinner_pid" 2>/dev/null || true
        spinner_pid=""
        if [[ -n ${UI_ROW:-} ]]; then
            printf '\033[%d;1H\033[2K' $(( UI_ROW - 2 ))
        else
            printf "\033[2A\033[K"
        fi
        UI_ROW=""
        printf "\033[?25l"
    fi
}

declare -A pkg_install_cmds=(
    ["apt"]="env DEBIAN_FRONTEND=noninteractive apt-get install -y -f -o Dpkg::Options::=--force-confdef"
    ["dnf"]="dnf install -y"
    ["yum"]="yum install -y"
    ["pacman"]="pacman -S --needed --noconfirm"
    ["brew"]="brew install"
    ["port"]="port install"
    ["pkg"]="pkg install -y"
    ["zypper"]="zypper install -y"
    ["flatpak"]="flatpak install -y flathub"
    ["snap"]="snap install"
    ["rpm"]="dnf install -y"
    ["eopkg"]="eopkg install"
    ["crew"]="crew install"
    ["pkgtool"]="installpkg" 
    ["nix"]="$user_home/.cache/install_nix_packages.sh"
    ["guix"]="guix install"
    ["xbps"]="xbps-install -y"
    ["apk"]="apk add"
    ["equo"]="equo install"
    ["dpkg"]="dpkg -i"
    ["ipkg"]="ipkg install"
    ["opkg"]="opkg install"
    ["netpkg"]="netpkg install"
    ["petget"]="petget install"
    ["pkgsrc"]="cd /usr/pkgsrc/category/package && make install"
    ["emerge"]="emerge -uDN"
    ["rpm-ostree"]="rpm-ostree install"
    ["slackpkg"]="slackpkg install"
    ["openpkg"]="openpkg install"
    ["paru"]="sudo -u $user paru -S --noconfirm --needed --removemake --skipreview"
    ["trizen"]="sudo -u $user trizen -S --noconfirm --needed"
    ["pikaur"]="sudo -u $user pikaur -S --noconfirm --needed"
    ["aurman"]="sudo -u $user aurman -S --noconfirm --needed"
    ["yay"]="sudo -u $user yay -S --noconfirm --needed --removemake"
    ["pacaur"]="sudo -u $user pacaur -S --noconfirm --needed --removemake --skipreview"
    ["aura"]="sudo -u $user aura -S --noconfirm --needed"
    ["pakku"]="sudo -u $user pakku -S --noconfirm --needed"
)

install_package() {
    local package="$1"
    local installed=false
    local first_attempt=true
    echo -e "[0] \033[1m${package}\033[0m"
    for manager in "${available_pkg_managers[@]}"; do
        if $first_attempt; then
            type_effect "Attempting to install $package with $manager..." "$menu_delay"; echo
            first_attempt=false
        else
            [[ "$verbose" == false ]] && printf "\033[2A\033[K"
            type_effect "Attempting to install $package with $manager..." "$menu_delay"; echo
        fi
        load_ui
        if ${pkg_install_cmds[$manager]} "$package" </dev/null &>> "$output"; then
            close_ui; type_effect "\033[32mSuccessfully installed $package with $manager.\033[0m" "$menu_delay"; echo
            installed=true
            break
        else
            close_ui; type_effect "\033[31mFailed to install $package with $manager.\033[0m" "$menu_delay"; echo
        fi
    done
    if [[ "$installed" == false ]]; then
        [[ "$verbose" == false ]] && printf "\033[2A\033[K"
        type_effect "\033[31mFailed to install $package with all available package managers.\033[0m" "$menu_delay"; echo
        return 1
    fi
    return 0
}

clear; timer_start


# ─────────────────────────── CONFIGURATION FILES

_cfg_url='https://mucator.net/Exyn'

# A tilde is a reference to a home directory the configuration was written on.
# It is resolved here, textually, exactly where a shell would resolve it: only
# at the start of a word. A tilde anywhere else — a backup suffix, a path
# segment, an address — is left alone, and nothing but those two characters
# changes. Three processes handle any number of files.
_expand_home_refs() {
    [ -s /tmp/.install-placed.list ] || return 0
    [ -n "$user_home" ] || return 0
    _eh_esc=$(printf '%s' "$user_home" | sed 's/[&#\\]/\\&/g')
    # A command substitution cannot carry NUL bytes: bash drops them, and the
    # separated paths arrive as one string that matches no file. The list
    # stays in a file from end to end.
    _eh_hits=/tmp/.install-home-hits
    xargs -0 grep -lIZ -e '~/' < /tmp/.install-placed.list > "$_eh_hits" 2>/dev/null
    if [ -s "$_eh_hits" ]; then
        xargs -0 -r sed -i -E \
            "s#(^|[[:space:]\"'\`=:,;(\[{])~/#\\1${_eh_esc}/#g" < "$_eh_hits" 2>/dev/null
        printf 'Home paths made absolute in:\n' >> "$output" 2>/dev/null
        tr '\0' '\n' < "$_eh_hits" | sed 's/^/  /' >> "$output" 2>/dev/null
    else
        printf 'No home paths needed expanding\n' >> "$output" 2>/dev/null
    fi
    rm -f /tmp/.install-placed.list "$_eh_hits"
}

_place_selected() {
    # Places only what the manifest still lists. FILES is the master list and
    # the menus rebuild it as the user deselects, so whatever survives here is
    # exactly what was asked for. Nothing already on this disk is removed: a
    # path that is not listed is simply not written.
    _ps_root=$1
    _ps_placed=0; _ps_missing=0; _ps_fail=0; _ps_home=0; _ps_last_dir=
    : > /tmp/.install-placed.list
    [ -d "$_ps_root/HOME" ] && _ps_home=1

    for _ps_e in "${FILES[@]}"; do
        _ps_p=${_ps_e%%:*}
        [ -n "$_ps_p" ] || continue
        case "$_ps_p" in
            /*) _ps_src="$_ps_root$_ps_p"; _ps_dest="$_ps_p" ;;
            *)  if [ "$_ps_home" -eq 1 ]; then _ps_src="$_ps_root/HOME/$_ps_p"
                else _ps_src="$_ps_root/$_ps_p"; fi
                _ps_dest="$user_home/$_ps_p" ;;
        esac

        if [ ! -e "$_ps_src" ] && [ ! -L "$_ps_src" ]; then
            _ps_missing=$(( _ps_missing + 1 ))
            printf 'not in the payload: %s\n' "$_ps_p" >> "$output" 2>/dev/null
            continue
        fi

        _ps_dir=${_ps_dest%/*}
        [ "$_ps_dir" = "$_ps_dest" ] && _ps_dir=/
        if [ "$_ps_dir" != "$_ps_last_dir" ]; then
            mkdir -p "$_ps_dir" 2>/dev/null
            _ps_last_dir=$_ps_dir
        fi
        if [ -d "$_ps_src" ] && [ ! -L "$_ps_src" ]; then
            mkdir -p "$_ps_dest" 2>/dev/null
            cp -a "$_ps_src/." "$_ps_dest/" 2>/dev/null &&
                _ps_placed=$(( _ps_placed + 1 )) || _ps_fail=$(( _ps_fail + 1 ))
        else
            if cp -a "$_ps_src" "$_ps_dest" 2>/dev/null; then
                _ps_placed=$(( _ps_placed + 1 ))
                # A file that declares an interpreter is meant to be run. If
                # the payload lost that bit in transit, restore it here.
                printf '%s\0' "$_ps_dest" >> /tmp/.install-placed.list
                if [ ! -x "$_ps_dest" ] &&
                   [ "$(head -c 2 "$_ps_dest" 2>/dev/null)" = '#!' ]; then
                    chmod +x "$_ps_dest" 2>/dev/null &&
                        printf 'made executable: %s\n' "$_ps_dest" >> "$output" 2>/dev/null
                fi
            else
                _ps_fail=$(( _ps_fail + 1 ))
            fi
        fi
    done

    _expand_home_refs

    printf 'placed %s of %s recorded path(s)\n' "$_ps_placed" "${#FILES[@]}" >> "$output" 2>/dev/null
    [ "$_ps_missing" -gt 0 ] && printf '%s were not in the payload\n' "$_ps_missing" >> "$output" 2>/dev/null
    [ "$_ps_fail" -gt 0 ] && printf '%s could not be written\n' "$_ps_fail" >> "$output" 2>/dev/null
    [ "$_ps_fail" -eq 0 ]
}

install_files() {
    if ! command -v git >/dev/null 2>&1; then
        install_package git
        if ! command -v git >/dev/null 2>&1; then
            CONFIG_STATUS="Failed - git unavailable"
            type_effect "\033[31mGit is unavailable and could not be installed; configuration retrieval cannot proceed.\033[0m" "$menu_delay"; echo
            return 1
        fi
    fi

    type_effect "Retrieving system configuration files..." "$menu_delay"; echo
    load_ui

    local _cfg_tmp _cfg_rc=0
    _cfg_tmp=$(mktemp -d)

    git clone -q "$_cfg_url" "$_cfg_tmp" >/dev/null 2>&1 || _cfg_rc=1

    if (( _cfg_rc )); then
        rm -rf "$_cfg_tmp"
        close_ui
        CONFIG_STATUS="Failed - remote repository could not be cloned"
        if [ "${_muc_via_ak:-0}" = 1 ]; then
            type_effect "\033[31mThis access key is invalid or has expired.\033[0m" "$menu_delay"; echo
        else
            type_effect "\033[31mFailed to clone the remote configuration files repository.\033[0m" "$menu_delay"; echo
        fi
        return 1
    fi

    local _cfg_fail=0
    _place_selected "$_cfg_tmp" >/dev/null 2>&1 || _cfg_fail=1

    rm -rf "$_cfg_tmp"

    # Everything above ran as root, so files copied into the target home
    # would otherwise be owned by root and the user could not write to their
    # own configuration afterwards.
    if [[ -n ${user:-} && -d ${user_home:-} ]]; then
        _cfg_grp=$(id -gn "$user" 2>/dev/null || printf '%s' "$user")
        chown -R "$user":"$_cfg_grp" "$user_home" 2>/dev/null
    fi

    close_ui

    if (( _cfg_fail )); then
        CONFIG_STATUS="Partial - cloned, some files not placed"
        type_effect "\033[31mThe repository was retrieved, but one or more configuration files could not be installed to their destinations.\033[0m" "$menu_delay"; echo
        return 1
    fi

    CONFIG_STATUS="Retrieved from the remote repository"
    type_effect "\033[32mSuccessfully installed system configuration files.\033[0m" "$menu_delay"; echo
    return 0
}

# ─────────────────────────── PACKAGE PREPARATION

# Escalates only as far as the system requires: repair, refresh, then upgrade.
# A manager with no verified semantics is never given a mutating command.
prepare_pkgs() {
    local mgr=$1; shift
    local -a want=("$@")
    local _shown=0 _spin=0 _base family policy age last pending space

    _step() {
        if [[ -n ${spinner_pid:-} ]] || (( _spin )); then
            close_ui; _spin=0
        elif [[ ${verbose:-false} == false && $_shown == 1 ]]; then
            printf '\033[2A\033[K'
        fi
        type_effect "$1" "$menu_delay"; echo
        _shown=1
        if [[ ${2:-} == spin ]] && declare -F load_ui >/dev/null 2>&1; then
            load_ui; _spin=1
        fi
    }
    _endspin() {
        (( _spin )) || return 0
        close_ui; _spin=0
        [[ ${verbose:-false} == false ]] && _shown=0
    }
    _final() {
        if [[ -n ${spinner_pid:-} ]] || (( _spin )); then
            close_ui; _spin=0
        elif [[ ${verbose:-false} == false && $_shown == 1 ]]; then
            printf '\033[2A\033[K'
        fi
        type_effect "$1" "$menu_delay"; echo
        _shown=0
    }
    _note() { printf '%s\n' "$1" >> "$output"; }

    _base_mgr() {
        case "$1" in
            paru|yay|trizen|pikaur|aurman|pacaur|aura|pakku) echo pacman ;;
            dpkg)      echo apt ;;
            rpm)       echo dnf ;;
            *)         echo "$1" ;;
        esac
    }

    _family() {
        case "$1" in
            pacman|xbps|emerge|eopkg|equo)                      echo rolling ;;
            apt|dnf|yum|zypper|apk|pkg|slackpkg|opkg|ipkg|netpkg) echo point ;;
            brew|port|crew|flatpak|snap|nix|guix|rpm-ostree)    echo immutable ;;
            pkgsrc|petget|openpkg|pkgtool)                      echo unknown ;;
            *)                                                  echo unknown ;;
        esac
    }

    _index_file() {
        case "$1" in
            pacman)  ls -t /var/lib/pacman/sync/*.db 2>/dev/null | head -1 ;;
            apt)     echo /var/lib/apt/lists ;;
            dnf|yum) ls -td /var/cache/dnf /var/cache/yum 2>/dev/null | head -1 ;;
            zypper)  echo /var/cache/zypp/raw ;;
            apk)     echo /var/cache/apk ;;
            xbps)    ls -t /var/db/xbps/*repodata 2>/dev/null | head -1 ;;
            pkg)     echo /var/db/pkg/repo-FreeBSD.sqlite ;;
            eopkg)   echo /var/lib/eopkg/index ;;
        esac
    }

    _index_age() {   # whole days, -1 when unknown
        local f t now
        f=$(_index_file "$1")
        [[ -n $f && -e $f ]] || { echo -1; return; }
        now=$(date +%s)
        t=$(stat -c %Y "$f" 2>/dev/null || stat -f %m "$f" 2>/dev/null) || { echo -1; return; }
        echo $(( (now - t) / 86400 ))
    }

    _last_upgrade() {
        case "$1" in
            pacman) grep -a 'starting full system upgrade' /var/log/pacman.log 2>/dev/null |
                        tail -1 | sed -n 's/^\[\([^]]*\)\].*/\1/p' ;;
            apt)    grep -a -h '^Start-Date' /var/log/apt/history.log 2>/dev/null |
                        tail -1 | sed 's/^Start-Date: //' ;;
            dnf|yum) dnf history list 2>/dev/null | awk 'NR==3 {print $(NF-1), $NF}' ;;
        esac
    }

    _health() {
        local issues=""
        case "$1" in
            apt)
                if [[ -e /var/lib/dpkg/lock-frontend ]] &&
                   command -v fuser >/dev/null 2>&1 &&
                   fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; then
                    issues+="busy:another package operation is in progress"$'\n'
                fi
                if command -v dpkg >/dev/null 2>&1 && dpkg --audit 2>/dev/null | grep -q '[a-z]'; then
                    issues+="interrupted:dpkg reports partially configured packages"$'\n'
                fi ;;
            pacman)
                if [[ -e /var/lib/pacman/db.lck ]]; then
                    if command -v fuser >/dev/null 2>&1 && fuser /var/lib/pacman/db.lck >/dev/null 2>&1; then
                        issues+="busy:another pacman process holds the database"$'\n'
                    else
                        issues+="stale_lock:database lock left by an interrupted transaction"$'\n'
                    fi
                fi
                [[ -d /etc/pacman.d/gnupg/private-keys-v1.d ]] ||
                    issues+="keyring:package signing keyring is not initialised"$'\n' ;;
            dnf|yum)
                if [[ -e /var/lib/rpm/.rpm.lock ]] && command -v fuser >/dev/null 2>&1 &&
                   fuser /var/lib/rpm/.rpm.lock >/dev/null 2>&1; then
                    issues+="busy:another rpm transaction is in progress"$'\n'
                fi ;;
            zypper)
                [[ -e /var/run/zypp.pid ]] && issues+="busy:another zypper process is running"$'\n' ;;
        esac
        printf '%s' "$issues"
    }

    _repair() {
        local issues line kind detail waited=0 acted=0
        issues=$(_health "$1")
        [[ -n $issues ]] || return 0
        while IFS= read -r line; do
            [[ -n $line ]] || continue
            kind=${line%%:*}; detail=${line#*:}
            _note "Health: $detail"
            case "$kind" in
                busy)
                    _step "Waiting for another package operation to finish..." spin
                    while (( waited < 120 )); do
                        sleep 5; (( waited += 5 ))
                        [[ -n $(_health "$1") ]] || break
                    done
                    _endspin
                    _note "Waited ${waited}s for the concurrent operation" ;;
                stale_lock)
                    _step "Clearing an abandoned database lock..." 
                    rm -f /var/lib/pacman/db.lck && { acted=1; _note "Repair: removed stale lock"; } ;;
                interrupted)
                    _step "Completing an interrupted package transaction..." spin
                    dpkg --configure -a >> "$output" 2>&1 && { acted=1; _note "Repair: dpkg reconfigured"; }
                    _endspin ;;
                keyring)
                    _step "Initialising the package signing keyring..." spin
                    { pacman-key --init && pacman-key --populate; } >> "$output" 2>&1 &&
                        { acted=1; _note "Repair: keyring initialised"; }
                    _endspin ;;
            esac
        done <<< "$issues"
        return $(( ! acted ))
    }

    _refresh() {
        local rc=0
        case "$1" in
            apt)      apt-get update >> "$output" 2>&1 || rc=$? ;;
            dnf)      dnf makecache --refresh -y >> "$output" 2>&1 || rc=$? ;;
            yum)      yum makecache -y >> "$output" 2>&1 || rc=$? ;;
            pacman)   pacman -Sy --noconfirm >> "$output" 2>&1 || rc=$? ;;
            zypper)   zypper --non-interactive refresh >> "$output" 2>&1 || rc=$? ;;
            apk)      apk update >> "$output" 2>&1 || rc=$? ;;
            xbps)     xbps-install -S >> "$output" 2>&1 || rc=$? ;;
            pkg)      pkg update >> "$output" 2>&1 || rc=$? ;;
            eopkg)    eopkg update-repo >> "$output" 2>&1 || rc=$? ;;
            equo)     equo update >> "$output" 2>&1 || rc=$? ;;
            emerge)   emerge --sync --quiet >> "$output" 2>&1 || rc=$? ;;
            slackpkg) slackpkg -batch=on -default_answer=y update >> "$output" 2>&1 || rc=$? ;;
            opkg|ipkg) opkg update >> "$output" 2>&1 || rc=$? ;;
            brew)     brew update >> "$output" 2>&1 || rc=$? ;;
            port)     port selfupdate >> "$output" 2>&1 || rc=$? ;;
            flatpak)  flatpak update --appstream -y >> "$output" 2>&1 || rc=$? ;;
            snap)     rc=0 ;;   # snapd refreshes its own catalogue
            nix)      rc=0 ;;   # channels are the user's to manage
            *)        _note "No verified index refresh for $1; leaving it untouched"; return 0 ;;
        esac
        if (( rc )) && tail -60 "$log" 2>/dev/null |
             grep -qiE 'signature|keyring|GPG|NO_PUBKEY|not trusted|invalid or corrupted'; then
            _note "Index refresh failed signature validation; repairing trust store"
            _step "Repairing package signing keys..." spin
            case "$1" in
                pacman)
                    { pacman-key --init
                      pacman-key --populate
                      pacman -Sy --noconfirm archlinux-keyring
                      pacman -Sy --noconfirm; } >> "$output" 2>&1 && rc=0 ;;
                apt)
                    { apt-get install -y --reinstall ca-certificates
                      apt-get update; } >> "$output" 2>&1 && rc=0 ;;
                dnf|yum)
                    { rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-* 2>/dev/null
                      dnf makecache --refresh -y; } >> "$output" 2>&1 && rc=0 ;;
            esac
            _endspin
        fi
        return $rc
    }

    # The kernel and its out-of-tree modules are held back together: replacing
    # a running kernel removes the modules the live system is using.
    _kernel_group() {
        local p
        case "$1" in
            pacman)
                pacman -Qq 2>/dev/null | grep -Ex \
                    'linux|linux-lts|linux-zen|linux-hardened|linux-rt|linux-rt-lts|(linux[a-z-]*)-headers' 
                pacman -Qq 2>/dev/null | grep -E \
                    'nvidia|dkms|zfs|virtualbox-.*-modules|broadcom-wl|r8168|v4l2loopback|wireguard-'
                ;;
            dnf|yum)
                rpm -qa --qf '%{NAME}\n' 2>/dev/null | grep -Ex \
                    'kernel|kernel-core|kernel-modules|kernel-devel|akmod-nvidia|kmod-nvidia.*|dkms' ;;
            zypper)
                rpm -qa --qf '%{NAME}\n' 2>/dev/null | grep -Ex \
                    'kernel-default|kernel-default-devel|nvidia-.*|dkms' ;;
            apk) apk info 2>/dev/null | grep -Ex 'linux-lts|linux-virt|.*-dkms' ;;
        esac | sed '/^$/d' | sort -u
    }

    _pending_count() {
        case "$1" in
            pacman)  pacman -Qu 2>/dev/null | wc -l ;;
            apt)     apt-get -s upgrade 2>/dev/null | grep -c '^Inst ' ;;
            dnf|yum) dnf -q check-update 2>/dev/null | grep -cE '^[a-zA-Z0-9]' ;;
            zypper)  zypper --non-interactive list-updates 2>/dev/null | grep -c '^v ' ;;
            apk)     apk version -l '<' 2>/dev/null | tail -n +2 | grep -c . ;;
            xbps)    xbps-install -un 2>/dev/null | grep -c . ;;
            pkg)     pkg upgrade -n 2>/dev/null | grep -cE '^\s+[a-zA-Z0-9]' ;;
            *)       echo 0 ;;
        esac
    }

    _pending_touches_kernel() {
        local pending group g
        group=$(_kernel_group "$1")
        [[ -n $group ]] || return 1
        case "$1" in
            pacman)  pending=$(pacman -Qu 2>/dev/null | awk '{print $1}') ;;
            apt)     pending=$(apt-get -s upgrade 2>/dev/null | awk '/^Inst /{print $2}') ;;
            dnf|yum) pending=$(dnf -q check-update 2>/dev/null | awk '{print $1}' | sed 's/\.[^.]*$//') ;;
            *) return 1 ;;
        esac
        while IFS= read -r g; do
            [[ -n $g ]] && grep -qxF "$g" <<< "$pending" && return 0
        done <<< "$group"
        return 1
    }

    _upgrade_deferred() {
        local rc=0 group ignore="" g
        group=$(_kernel_group "$1")
        case "$1" in
            pacman)
                while IFS= read -r g; do [[ -n $g ]] && ignore+=" --ignore $g"; done <<< "$group"
                [[ -n $ignore ]] && _note "Holding back:${group//$'\n'/ }"
                pacman -Su --noconfirm $ignore >> "$output" 2>&1 || rc=$? ;;
            apt)
                env DEBIAN_FRONTEND=noninteractive apt-get upgrade -y \
                    -o Dpkg::Options::=--force-confdef \
                    -o Dpkg::Options::=--force-confold >> "$output" 2>&1 || rc=$? ;;
            dnf)
                dnf upgrade -y --exclude='kernel*' --exclude='*nvidia*' \
                    --exclude='dkms' >> "$output" 2>&1 || rc=$? ;;
            yum)
                yum update -y --exclude='kernel*' --exclude='*nvidia*' >> "$output" 2>&1 || rc=$? ;;
            zypper)
                zypper --non-interactive update >> "$output" 2>&1 || rc=$? ;;
            apk)
                apk upgrade >> "$output" 2>&1 || rc=$? ;;
            xbps)
                xbps-install -uy >> "$output" 2>&1 || rc=$? ;;
            pkg)
                pkg upgrade -y >> "$output" 2>&1 || rc=$? ;;
            eopkg)
                eopkg upgrade -y >> "$output" 2>&1 || rc=$? ;;
            *)
                _note "No verified upgrade path for $1; not attempting one"; return 1 ;;
        esac
        return $rc
    }

    _upgrade_full() {
        local rc=0
        case "$1" in
            pacman) pacman -Syu --noconfirm >> "$output" 2>&1 || rc=$? ;;
            apt)    env DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y \
                        -o Dpkg::Options::=--force-confdef \
                        -o Dpkg::Options::=--force-confold >> "$output" 2>&1 || rc=$? ;;
            dnf)    dnf upgrade -y --refresh >> "$output" 2>&1 || rc=$? ;;
            yum)    yum update -y >> "$output" 2>&1 || rc=$? ;;
            zypper) zypper --non-interactive update >> "$output" 2>&1 || rc=$? ;;
            apk)    apk upgrade --available >> "$output" 2>&1 || rc=$? ;;
            xbps)   xbps-install -Suy >> "$output" 2>&1 || rc=$? ;;
            pkg)    pkg upgrade -y >> "$output" 2>&1 || rc=$? ;;
            eopkg)  eopkg upgrade -y >> "$output" 2>&1 || rc=$? ;;
            equo)   equo upgrade >> "$output" 2>&1 || rc=$? ;;
            *)      _note "No verified full upgrade for $1; not attempting one"; return 1 ;;
        esac
        return $rc
    }

    _can_resolve() {
        local m=$1; shift
        (( $# )) || return 0
        case "$m" in
            pacman)  pacman -S --needed --noconfirm --print-format '%n' "$@" >/dev/null 2>&1 ;;
            apt)     apt-get install -s "$@" >/dev/null 2>&1 ;;
            dnf)     dnf -q --assumeno install "$@" >/dev/null 2>&1 ;;
            yum)     yum -q --assumeno install "$@" >/dev/null 2>&1 ;;
            zypper)  zypper --non-interactive --dry-run install "$@" >/dev/null 2>&1 ;;
            apk)     apk add --simulate "$@" >/dev/null 2>&1 ;;
            xbps)    xbps-install -n "$@" >/dev/null 2>&1 ;;
            pkg)     pkg install -n "$@" >/dev/null 2>&1 ;;
            brew)    brew info "$@" >/dev/null 2>&1 ;;
            eopkg)   eopkg info "$@" >/dev/null 2>&1 ;;
            *) return 0 ;;
        esac
    }

    _free_space() { df -Pm /var 2>/dev/null | awk 'NR==2 {print $4}'; }

    _on_battery() {
        local s
        for s in /sys/class/power_supply/*/online; do
            [[ -r $s ]] || continue
            [[ $(cat "$s" 2>/dev/null) == 0 ]] && return 0
            return 1
        done
        return 1
    }

    _base=$(_base_mgr "$mgr")
    # A helper that builds from source is not the index it sits on top of.
    local _is_helper=0
    [[ $mgr != "$_base" ]] && _is_helper=1
    family=$(_family "$_base")
    policy=${upgrade_policy:-auto}
    age=$(_index_age "$_base")
    last=$(_last_upgrade "$_base")

    {
        echo ""
        echo "─── Package preparation: $mgr${_base:+ (base: $_base)}"
        echo "    Family        : $family"
        echo "    Policy        : $policy"
        echo "    Index age     : $( (( age >= 0 )) && echo "${age} day(s)" || echo "not determinable" )"
        [[ -n $last ]] && echo "    Last upgrade  : $last"
        echo "    Requested     : ${#want[@]} package(s)"
    } >> "$output"

    _step "Checking the $mgr package manager..." spin
    _repair "$_base"

    if [[ $policy == never ]]; then
        _note "Decision: policy forbids modification; using the current index"
        _final "\033[32mThe ${mgr} package manager is ready.\033[0m"
        return 0
    fi

    if [[ $policy == always ]]; then
        _note "Decision: policy requests a full system upgrade"
        _step "Refreshing the package index..." spin
        _refresh "$_base"
        _step "Upgrading system packages..." spin
        if _upgrade_full "$_base"; then
            _final "\033[32mThe ${mgr} package manager is ready; system packages were upgraded.\033[0m"
        else
            _final "\033[33mThe ${mgr} upgrade reported errors; continuing with the installation.\033[0m"
        fi
        return 0
    fi

    if _can_resolve "$_base" "${want[@]}"; then
        _note "Decision: current index satisfies the request; no changes made"
        _final "\033[32mThe ${mgr} package manager is ready.\033[0m"
        return 0
    fi
    if (( _is_helper )); then
        # Its packages are built, not fetched from the base index, so their
        # absence there says nothing about whether the system is ready.
        _note "Decision: ${mgr} builds from source; the base index is not consulted"
        _final "\033[32mThe ${mgr} package manager is ready.\033[0m"
        return 0
    fi
    _note "Requested packages could not be resolved against the current index"

    if [[ $family == unknown || $family == immutable ]]; then
        _step "Refreshing the package index..." spin
        _refresh "$_base"
        _note "Decision: index refreshed; no upgrade attempted for a $family manager"
        _final "\033[32mThe ${mgr} package manager is ready.\033[0m"
        return 0
    fi

    if [[ $family == point ]]; then
        _step "Refreshing the package index..." spin
        _refresh "$_base"
        if _can_resolve "$_base" "${want[@]}"; then
            _note "Decision: refreshed index satisfies the request"
            _final "\033[32mThe ${mgr} package manager is ready.\033[0m"
            return 0
        fi
        _note "Still unresolved; upgrading installed packages without additions or removals"
        _step "Upgrading installed packages..." spin
        _upgrade_deferred "$_base"
        if _can_resolve "$_base" "${want[@]}"; then
            _note "Decision: resolved after upgrading installed packages"
            _final "Installed packages upgraded for ${mgr}."
        else
            _note "Decision: proceeding; packages will be attempted individually"
            _final "\033[32mThe ${mgr} package manager is ready.\033[0m"
        fi
        return 0
    fi

    _step "Refreshing the package index..." spin
    _refresh "$_base"

    pending=$(_pending_count "$_base")
    _note "Pending upgrade: ${pending} package(s)"

    space=$(_free_space)
    if [[ -n $space ]] && (( space < 2048 )); then
        _note "Free space: ${space} MiB — below the margin required for a system upgrade"
        _note "Decision: installing against the refreshed index without upgrading"
        _final "\033[32mThe ${mgr} package manager is ready.\033[0m"
        return 0
    fi

    if (( pending == 0 )); then
        _note "Decision: index refreshed; installed set already current"
        _final "\033[32mThe ${mgr} package manager is ready.\033[0m"
        return 0
    fi

    if _pending_touches_kernel "$_base"; then
        _note "Pending set includes the running kernel or modules bound to it"
        _on_battery && _note "System is running on battery power"
        _step "Upgrading userspace packages..." spin
        if _upgrade_deferred "$_base" && _can_resolve "$_base" "${want[@]}"; then
                KERNEL_UPDATE_DEFERRED=1
            _note "Decision: userspace upgraded; kernel group deferred, no reboot introduced"
            _final "\033[32mThe ${mgr} package manager is ready; the kernel was left as it is.\033[0m"
            return 0
        fi
        _endspin
        # The kernel and the modules bound to it stay as they are. Replacing
        # them on a machine that was working is how a system with proprietary
        # graphics ends up without a display, and no package is worth that.
        KERNEL_UPDATE_DEFERRED=1
        _note "Some requested packages may want the newer kernel group; it is left alone"
        _note "Decision: userspace upgraded; kernel group held back"
        _final "\033[32mThe ${mgr} package manager is ready; the kernel was left as it is.\033[0m"
        return 0
    fi

    _step "Upgrading userspace packages..." spin
    # deferred only: under auto the kernel group is never a fallback
    if _upgrade_deferred "$_base"; then
        _endspin
        _note "Decision: userspace upgraded to match the refreshed index"
        _final "\033[32mThe ${mgr} package manager is ready; system packages were upgraded.\033[0m"
    else
        _endspin
        _note "Decision: upgrade reported errors; continuing to install"
        _final "\033[33mThe ${mgr} upgrade reported errors; continuing with the installation.\033[0m"
    fi
    return 0
}

# ─────────────────────────── PREPARE

get_pkg_manager

if (( ${#available_pkg_managers[@]} )); then
    _pp_any=0
    for _pp_mgr in "${available_pkg_managers[@]}"; do
        _pp_arr="${_pp_mgr//-/_}_packages[@]"
        _pp_list=( "${!_pp_arr}" )
        (( ${#_pp_list[@]} )) || continue
        prepare_pkgs "$_pp_mgr" "${_pp_list[@]%%:*}"
        _pp_any=1
    done
    (( _pp_any )) || prepare_pkgs "${available_pkg_managers[0]}"
    unset _pp_mgr _pp_arr _pp_list _pp_any
fi
if [[ -z ${SKIP_MGR[mgr:sudo]:-} ]]; then
if ! command -v sudo &> /dev/null; then
    if [[ -f /etc/alpine-release ]]; then
        type_effect "Enabling community repositories..." "$menu_delay"; echo
        sed -i '/community/s/^#//' /etc/apk/repositories
        apk update &> /dev/null
        [[ "$verbose" == false ]] && printf "\033[2A\033[K"
    fi
    configure_sudo() {
        local path_added=false
        [[ "$verbose" == false ]] && printf "\033[2A\033[K"
        type_effect "Configuring sudo..." "$menu_delay"; echo
        if ! grep -q "/sbin" "/etc/profile"; then
            load_ui
            if echo "export PATH=\$PATH:/sbin" | tee -a /etc/profile > /dev/null; then
                close_ui
                type_effect "\033[32mSuccessfully added /sbin to the PATH.\033[0m" "$menu_delay"; echo
                path_added=true
            else
                close_ui
                type_effect "\033[31mFailed to add /sbin to the PATH.\033[0m" "$menu_delay"; echo
            fi
        fi
        if [[ "$path_added" == true ]]; then
            if ! source /etc/profile &> /dev/null; then
                [[ "$verbose" == false ]] && printf "\033[2A\033[K"
                type_effect "\033[31mFailed to refresh shell.\033[0m" "$menu_delay"; echo
            else
                [[ "$verbose" == false ]] && printf "\033[2A\033[K"
                type_effect "\033[32mSuccessfully refreshed shell.\033[0m" "$menu_delay"; echo
            fi
        fi
        [[ "$verbose" == false ]] && printf "\033[2A\033[K"
        type_effect "Adding $user to the sudoers file..." "$menu_delay"; echo
        load_ui
        if echo "$user ALL=(ALL) ALL" >> /etc/sudoers; then
            close_ui
            type_effect "\033[32mSuccessfully added $user to sudoers.\033[0m" "$menu_delay"; echo
        else
            close_ui
            type_effect "\033[31mFailed to add $user to sudoers.\033[0m" "$menu_delay"; echo
        fi
        [[ "$verbose" == false ]] && printf "\033[2A\033[K"
        type_effect "\033[32mSuccessfully installed and configured sudo.\033[0m" "$menu_delay"; echo
    }
    install_package "sudo" && configure_sudo
fi
fi

    own_cache() {
        if [ -d "$user_home/.cache" ]; then
            current_owner=$(stat -c "%U:%G" "$user_home/.cache")
            if [ "$current_owner" != "$user:$user" ]; then
                sudo chown -R $user:$user "$user_home/.cache"
            fi
        else
            mkdir -p "$user_home/.cache"
            sudo chown -R $user:$user "$user_home/.cache"
        fi
    }

    if command -v pacman &>/dev/null; then
        own_cache
        # Temporarily allows for AUR installation as root
        sudo_rule="$user ALL=(ALL) NOPASSWD: ALL"
        aur=true

        if ! sudo grep -qF "$sudo_rule" /etc/sudoers; then
            echo "$sudo_rule" | sudo tee -a /etc/sudoers >/dev/null
            rule_added=true
        else
            rule_added=false
        fi
    fi
if [[ -z ${SKIP_MGR[mgr:paru]:-} ]]; then

    aur_installers=(paru)

    install_aur_helpers() {
        for helper in "${aur_installers[@]}"; do
            if ! command -v "$helper" &> /dev/null; then
                [[ -d "$user_home/$helper" ]] && rm -rf "$user_home/$helper"
                echo -e "[0] \033[1m$helper\033[0m"
                type_effect "Attempting to install $helper. This will take some time..." "$menu_delay"; echo
                load_ui
                if ! pacman -S --needed base-devel git --noconfirm </dev/null &>> "$output"; then
                    close_ui
                    type_effect "\033[31mFailed to install dependencies with pacman.\033[0m" "$menu_delay"; echo
                    continue
                fi
                if ! git clone "https://aur.archlinux.org/$helper.git" "$user_home/$helper" </dev/null &>> "$output"; then
                    close_ui
                    type_effect "\033[31mFailed to clone $helper repository.\033[0m" "$menu_delay"; echo
                    continue
                fi
                sudo chown -R "$user:$user" "$user_home/$helper"
                own_cache
                cd "$user_home/$helper" || { close_ui; type_effect "\033[31mFailed to enter $helper directory.\033[0m" "$menu_delay"; echo; cd "$user_home" && rm -rf "$user_home/$helper"; continue; }
                if ! sudo -u "$user" makepkg -si --noconfirm </dev/null &>> "$output"; then
                    close_ui
                    type_effect "\033[31mFailed to build $helper.\033[0m" "$menu_delay"; echo
                    cd "$user_home" && rm -rf "$user_home/$helper"
                    continue
                fi
                close_ui
                type_effect "\033[32mSuccessfully installed $helper.\033[0m" "$menu_delay"; echo
                cd "$user_home" && rm -rf "$user_home/$helper"
                get_pkg_manager
            fi
        done
    }

    command -v pacman &>/dev/null && install_aur_helpers
    
fi

# ─────────────────────────── CONFIGURATION FILES

install_files || true

declare -A XLAT=()
declare -A XLAT_TRIED=()

_repo_ids() {
    case "$1" in
        pacman|yay|paru|trizen|pikaur|aurman|pacaur|aura|pakku) printf 'arch aur' ;;
        apt|dpkg)   printf 'debian ubuntu' ;;
        dnf|yum|rpm) printf 'fedora centos rhel' ;;
        zypper)     printf 'opensuse' ;;
        apk)        printf 'alpine' ;;
        xbps)       printf 'void' ;;
        pkg)        printf 'freebsd' ;;
        brew)       printf 'homebrew' ;;
        port)       printf 'macports' ;;
        nix)        printf 'nix' ;;
        guix)       printf 'gnuguix' ;;
        eopkg)      printf 'solus' ;;
        emerge)     printf 'gentoo' ;;
        slackpkg)   printf 'slackbuilds' ;;
        *)          printf '' ;;
    esac
}

_alias_table() {
    case "$2:$1" in
        apt:base-devel)            printf 'build-essential' ;;
        pacman:build-essential)    printf 'base-devel' ;;
        dnf:base-devel)            printf '@development-tools' ;;
        apt:qemu-base)             printf 'qemu-system' ;;
        apt:xorg-server)           printf 'xserver-xorg-core' ;;
        apt:xorg-xrandr|apt:xorg-xset|apt:xorg-xsetroot|apt:xorg-xgamma|apt:xorg-xrdb|apt:xorg-xmodmap)
                                   printf 'x11-xserver-utils' ;;
        apt:xorg-xev|apt:xorg-xprop|apt:xorg-xwininfo|apt:xorg-xdpyinfo|apt:xorg-xkill|apt:xorg-xlsclients)
                                   printf 'x11-utils' ;;
        apt:xorg-xinit)            printf 'xinit' ;;
        apt:xorg-fonts-misc)       printf 'xfonts-base' ;;
        apt:vulkan-intel|apt:vulkan-radeon|apt:vulkan-nouveau|apt:vulkan-swrast)
                                   printf 'mesa-vulkan-drivers' ;;
        apt:libva-intel-driver)    printf 'i965-va-driver' ;;
        apt:intel-media-driver)    printf 'intel-media-va-driver' ;;
        apt:gst-plugin-pipewire)   printf 'gstreamer1.0-pipewire' ;;
        apt:nginx-mainline)        printf 'nginx' ;;
        apt:gvim)                  printf 'vim-gtk3' ;;
        apt:hunspell-en_us)        printf 'hunspell-en-us' ;;
        apt:tesseract-data-eng)    printf 'tesseract-ocr-eng' ;;
        apt:zram-generator)        printf 'systemd-zram-generator' ;;
        apt:linux-firmware)        printf 'firmware-linux-free' ;;
        apt:python-pip)            printf 'python3-pip' ;;
        apt:python-beautifulsoup4) printf 'python3-bs4' ;;
        apt:firefox)               printf 'firefox-esr' ;;
        apt:networkmanager)        printf 'network-manager' ;;
        apt:bluez-utils)           printf 'bluez' ;;
        apt:github-cli)            printf 'gh' ;;
        apt:intel-ucode)           printf 'intel-microcode' ;;
        apt:openssh)               printf 'openssh-server' ;;
        apt:docker)                printf 'docker.io' ;;
        apt:fd)                    printf 'fd-find' ;;
        apt:ttf-dejavu)            printf 'fonts-dejavu' ;;
        apt:ttf-liberation)        printf 'fonts-liberation' ;;
        apt:noto-fonts)            printf 'fonts-noto' ;;
        apt:noto-fonts-emoji)      printf 'fonts-noto-color-emoji' ;;

        dnf:xorg-xrandr)           printf 'xrandr' ;;
        dnf:xorg-xev)              printf 'xorg-x11-utils' ;;
        dnf:vulkan-intel|dnf:vulkan-radeon) printf 'mesa-vulkan-drivers' ;;
        dnf:networkmanager)        printf 'NetworkManager' ;;
        dnf:python-pip)            printf 'python3-pip' ;;
        dnf:intel-ucode)           printf 'microcode_ctl' ;;
        dnf:firefox-esr)           printf 'firefox' ;;

        pacman:network-manager)    printf 'networkmanager' ;;
        pacman:firefox-esr)        printf 'firefox' ;;
        pacman:python3-pip)        printf 'python-pip' ;;
        pacman:x11-xserver-utils)  printf 'xorg-xrandr' ;;
        pacman:x11-utils)          printf 'xorg-xev' ;;
        pacman:mesa-vulkan-drivers) printf 'vulkan-intel' ;;
        pacman:build-essential)    printf 'base-devel' ;;
        pacman:openssh-server)     printf 'openssh' ;;
        pacman:docker.io)          printf 'docker' ;;
        pacman:fd-find)            printf 'fd' ;;
        pacman:pkg-config)         printf 'pkgconf' ;;
        *) printf '' ;;
    esac
}

_index_search() {
    local n=$1 mgr=$2 out=""
    case "$mgr" in
        apt|dpkg) out=$(apt-cache search --names-only "^${n}" 2>/dev/null | awk '{print $1}') ;;
        pacman|yay|paru|trizen|pikaur|aurman|pacaur|aura|pakku)
                  out=$(pacman -Ssq "^${n}" 2>/dev/null) ;;
        dnf|yum)  out=$(dnf -q repoquery --qf '%{name}' "${n}*" 2>/dev/null) ;;
        zypper)   out=$(zypper --non-interactive --quiet search --match-substrings "$n" 2>/dev/null |
                        awk -F'|' 'NR>2 {gsub(/ /,"",$2); print $2}') ;;
        apk)      out=$(apk search -q "$n" 2>/dev/null | sed 's/-[0-9].*//') ;;
        xbps)     out=$(xbps-query -Rs "$n" 2>/dev/null | awk '{print $2}' | sed 's/-[0-9][^-]*$//') ;;
        pkg)      out=$(pkg search -q "$n" 2>/dev/null | sed 's/-[0-9][^-]*$//') ;;
        brew)     out=$(brew search "$n" 2>/dev/null | grep -v '==>') ;;
        eopkg)    out=$(eopkg search "$n" 2>/dev/null | awk '{print $1}') ;;
        *) return 1 ;;
    esac
    [[ -n $out ]] || return 1
    local best="" c exact=0
    while IFS= read -r c || [[ -n $c ]]; do
        [[ -n $c ]] || continue
        [[ $c == "$n" ]] && { exact=1; continue; }
        # documentation, debug and source side packages are never the answer
        case "$c" in
            *-doc|*-docs|*-debug|*-dbg|*-dbgsym|*-src|*-source|*-tests) continue ;;
            *-demo|*-demos|*-examples|*-lang|*-i18n|*-common) continue ;;
        esac
        [[ $c == "$n"* || $n == "$c"* ]] || continue
        [[ -z $best || ${#c} -lt ${#best} ]] && best=$c
    done <<< "$out"
    # a package named exactly what was asked for needs no translation, and
    # must not lose to a longer neighbour such as gtk3-demos
    (( exact )) && return 2
    if [[ -n $best ]]; then REPO_RESULT=$best; return 0; fi
    return 1
}

_fetch() {
    local url=$1
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL --connect-timeout 5 --max-time 12 \
             -A "system-installer (package name resolution)" "$url" \
             </dev/null 2>/dev/null
    elif command -v wget >/dev/null 2>&1; then
        wget -qO- --timeout=12 --tries=1 \
             -U "system-installer (package name resolution)" "$url" \
             </dev/null 2>/dev/null
    else
        return 1
    fi
}

_RG_PROJECT='
BEGIN {
    n = split(ids, want, " ")
    pbase = pref; pver = ""
    if (match(pref, /_/)) { pbase = substr(pref, 1, RSTART - 1); pver = substr(pref, RSTART + 1) }
    pnum = vnum(pver)
}
{ buf = buf $0 }
function vnum(v,   t) { t = v; gsub(/[^0-9]/, "", t); return (t == "" ? -1 : t + 0) }
# Same distribution wins outright. Within it the exact release scores highest,
# then the closest older release, then newer ones, and rolling branches last.
# A sibling distribution is only a fallback, since its names often differ.
function score(repo,   j, base, suf, v, ok) {
    base = repo; suf = ""
    if (match(repo, /_/)) { base = substr(repo, 1, RSTART - 1); suf = substr(repo, RSTART + 1) }
    ok = 0
    for (j = 1; j <= n; j++) if (base == want[j]) ok = 1
    if (!ok) return 0
    if (pbase != "" && base == pbase) {
        if (suf == pver) return 100000
        v = vnum(suf)
        if (v >= 0 && pnum >= 0) {
            if (v <= pnum) return 90000 - (pnum - v)
            return 70000 - (v - pnum)
        }
        if (suf ~ /^testing/)     return 40000
        if (suf ~ /^backports/)   return 35000
        if (suf ~ /^(unstable|experimental|rolling)/) return 30000
        return 50000
    }
    v = vnum(suf)
    if (v >= 0) return 2000
    if (suf ~ /^(unstable|experimental|rolling)/) return 500
    return 1000
}
END {
    m = split(buf, objs, /\},[ \t]*\{/)
    best = 0; bestname = ""; bestrepo = ""; bestbin = 0
    for (i = 1; i <= m; i++) {
        o = objs[i]
        if (!match(o, /"repo"[ \t]*:[ \t]*"[^"]*"/)) continue
        repo = substr(o, RSTART, RLENGTH); sub(/.*"repo"[ \t]*:[ \t]*"/, "", repo); sub(/"$/, "", repo)
        sc = score(repo)
        if (sc == 0) continue
        bin = ""; src = ""
        if (match(o, /"binname"[ \t]*:[ \t]*"[^"]*"/)) {
            bin = substr(o, RSTART, RLENGTH); sub(/.*"binname"[ \t]*:[ \t]*"/, "", bin); sub(/"$/, "", bin)
        }
        if (match(o, /"srcname"[ \t]*:[ \t]*"[^"]*"/)) {
            src = substr(o, RSTART, RLENGTH); sub(/.*"srcname"[ \t]*:[ \t]*"/, "", src); sub(/"$/, "", src)
        }
        name = (bin != "" ? bin : src)
        hasbin = (bin != "" ? 1 : 0)
        if (name == "") continue
        # an entry that names the installable binary beats one that only
        # names the source package at the same release
        if (sc > best || (sc == best && hasbin && !bestbin)) {
            best = sc; bestname = name; bestrepo = repo; bestbin = hasbin
        }
    }
    if (bestname != "") print bestname
}'

_RG_SEARCH='
BEGIN { n = split(ids, want, " "); s = split(src, from, " ") }
{ buf = buf $0 }
END {
    np = split(buf, chunks, /\][ \t]*,[ \t]*"/)
    for (p = 1; p <= np; p++) {
        c = chunks[p]; hit = 0; target = ""; tbest = 0
        m = split(c, objs, /\},[ \t]*\{/)
        for (i = 1; i <= m; i++) {
            o = objs[i]
            if (!match(o, /"repo"[ \t]*:[ \t]*"[^"]*"/)) continue
            repo = substr(o, RSTART, RLENGTH); sub(/.*"repo"[ \t]*:[ \t]*"/, "", repo); sub(/"$/, "", repo)
            name = ""
            if (match(o, /"binname"[ \t]*:[ \t]*"[^"]*"/)) {
                name = substr(o, RSTART, RLENGTH); sub(/.*"binname"[ \t]*:[ \t]*"/, "", name); sub(/"$/, "", name)
            }
            if (name == "" && match(o, /"srcname"[ \t]*:[ \t]*"[^"]*"/)) {
                name = substr(o, RSTART, RLENGTH); sub(/.*"srcname"[ \t]*:[ \t]*"/, "", name); sub(/"$/, "", name)
            }
            if (name == "") continue
            for (j = 1; j <= s; j++)
                if ((repo == from[j] || index(repo, from[j] "_") == 1) && name == query) hit = 1
            sc = 0
            if (repo == pref) sc = 100
            else for (j = 1; j <= n; j++) {
                if (repo == want[j]) { sc = 60; break }
                if (index(repo, want[j] "_") == 1) {
                    suf = substr(repo, length(want[j]) + 2)
                    if (suf ~ /^[0-9]/) sc = 50
                    else if (suf ~ /^(unstable|experimental|rolling)/) sc = 10
                    else if (suf ~ /^(testing|backports)/) sc = 20
                    else sc = 30
                    break
                }
            }
            if (sc > tbest) { tbest = sc; target = name }
        }
        if (hit && target != "") { print target; exit }
    }
}'

_name_variants() {
    local n=${1,,}
    printf '%s\n' "$n"
    case "$n" in
        xf86-video-*) printf '%s\n' "xdrv:${n#xf86-video-}" "${n#xf86-video-}" ;;
        xf86-input-*) printf '%s\n' "xdrv:${n#xf86-input-}" "${n#xf86-input-}" ;;
        xorg-*)       printf '%s\n' "${n#xorg-}" ;;
        ttf-*|otf-*)  printf '%s\n' "fonts:${n#*-}" "${n#*-}" ;;
        python-*)     printf '%s\n' "python:${n#python-}" "${n#python-}" ;;
        perl-*)       printf '%s\n' "perl:${n#perl-}" ;;
        ruby-*)       printf '%s\n' "ruby:${n#ruby-}" ;;
        *-ucode)      printf '%s\n' "${n%-ucode}-microcode" ;;
        *-utils|*-tools) printf '%s\n' "${n%-*}" ;;
        *-git|*-bin)  printf '%s\n' "${n%-*}" ;;
    esac
}

_this_repo() {
    local id ver
    [[ -r /etc/os-release ]] || return
    id=$(. /etc/os-release 2>/dev/null; printf '%s' "${ID,,}")
    ver=$(. /etc/os-release 2>/dev/null; printf '%s' "${VERSION_ID:-}")
    [[ -n $id ]] || return
    case "$id" in
        debian) [[ -n $ver ]] && printf 'debian_%s' "${ver%%.*}" ;;
        ubuntu) [[ -n $ver ]] && printf 'ubuntu_%s' "${ver//./_}" ;;
        fedora) [[ -n $ver ]] && printf 'fedora_%s' "$ver" ;;
        alpine) [[ -n $ver ]] && printf 'alpine_%s' "$(printf '%s' "${ver%.*}" | tr . _)" ;;
        arch)   printf 'arch' ;;
        *)      [[ -n $ver ]] && printf '%s_%s' "$id" "${ver//./_}" || printf '%s' "$id" ;;
    esac
}

_remote_lookup() {
    local name=$1 mgr=$2 ids src body cand out
    [[ -n ${PREF_REPO+x} ]] || PREF_REPO=$(_this_repo)
    REPO_RESULT=""
    ids=$(_repo_ids "$mgr"); [[ -n $ids ]] || return 1
    src=$(_repo_ids "${SOURCE_MANAGER:-pacman}"); src=${src%% *}
    while IFS= read -r cand; do
        [[ -n $cand ]] || continue
        body=$(_fetch "https://repology.org/api/v1/project/${cand}") || continue
        [[ -n $body && $body != "[]" ]] || continue
        out=$(printf '%s' "$body" | awk -v ids="$ids" -v pref="$PREF_REPO" "$_RG_PROJECT")
        [[ -n $out ]] && { REPO_RESULT=$out; return 0; }
    done < <(_name_variants "$name")
    body=$(_fetch "https://repology.org/api/v1/projects/?search=${name}&inrepo=${src}") || return 1
    [[ -n $body && $body != "{}" ]] || return 1
    out=$(printf '%s' "$body" | awk -v ids="$ids" -v src="$src" -v query="$name" -v pref="$PREF_REPO" "$_RG_SEARCH")
    [[ -n $out ]] && { REPO_RESULT=$out; return 0; }
    return 1
}

resolve_names() {
    local mgr=$1; shift
    local -a pending=() remote=()
    local n r rc src_label
    XLAT=()
    [[ ${translation:-auto} == never ]] && return 1
    src_label=${SOURCE_MANAGER:-pacman}

    local -a fresh=()
    for n in "$@"; do
        [[ -n ${XLAT_TRIED[$mgr:$n]:-} ]] && continue
        XLAT_TRIED[$mgr:$n]=1
        fresh+=("$n")
    done
    (( ${#fresh[@]} )) || return 1
    set -- "${fresh[@]}"

    for n in "$@"; do
        r=$(_alias_table "$n" "$mgr")
        if [[ -n $r ]]; then
            XLAT[$n]=$r
            printf 'Mapped %s to %s from the built-in %s to %s table\n' \
                "$n" "$r" "$src_label" "$mgr" >> "$output"
        else
            pending+=("$n")
        fi
    done

    for n in "${pending[@]}"; do
        printf 'Searching the local %s index for %s\n' "$mgr" "$n" >> "$output"
        _index_search "$n" "$mgr"; rc=$?
        case $rc in
            0) XLAT[$n]=$REPO_RESULT
               printf 'Matched %s to %s in the local %s index\n' "$n" "$REPO_RESULT" "$mgr" >> "$output" ;;
            2) printf '%s is present in the local index and needs no translation\n' "$n" >> "$output" ;;
            *) remote+=("$n") ;;
        esac
    done

    (( ${#remote[@]} )) || { (( ${#XLAT[@]} )); return; }
    [[ ${translation:-auto} == auto ]] || { (( ${#XLAT[@]} )); return; }

    for n in "${remote[@]}"; do
        printf 'Translating %s from the %s namespace to the %s namespace...\n' \
            "$n" "$src_label" "$mgr" >> "$output"
        if _remote_lookup "$n" "$mgr"; then
            XLAT[$n]=$REPO_RESULT
            printf 'Translated %s to %s for %s\n' "$n" "$REPO_RESULT" "$mgr" >> "$output"
        else
            printf 'No %s equivalent published for %s\n' "$mgr" "$n" >> "$output"
        fi
    done

    for n in "${!XLAT[@]}"; do
        [[ ${XLAT[$n]} == "$n" ]] && unset 'XLAT[$n]'
    done
    (( ${#XLAT[@]} ))
}

skip_translation() {
    case "${1%%:*}" in
        linux|linux-lts|linux-zen|linux-hardened|linux-rt|linux-rt-lts) return 0 ;;
        *-headers|linux-headers) return 0 ;;
        *-ucode|linux-firmware|*-firmware) return 0 ;;
    esac
    return 1
}

ensure_fetch() {
    command -v curl >/dev/null 2>&1 && return 0
    command -v wget >/dev/null 2>&1 && return 0
    install_package curl >> "$output" 2>&1
    command -v curl >/dev/null 2>&1 && return 0
    install_package wget >> "$output" 2>&1
    command -v wget >/dev/null 2>&1
}

# Asks the manager which of the requested packages it cannot resolve, without
# installing anything. This runs before the first bulk attempt so the names are

failed=()
attempted_arrays=()
any_installs_attempted=false

if $aur; then
    own_cache
fi

fast_install() {
    local pkg_manager="$1"
    local array_prefix="$2"
    local array_name="$3"
    local check_output install_output remove_output install_rc
    local pkgs new missing
    local last_conflict repeat_count max_repeats success
    local init_pkg conflicting_package
    local -n current_pkg_array="$array_name"
    local skipped=()
    if [[ ! " ${available_pkg_managers[*]} " =~ " $pkg_manager " ]]; then
        return 1
    fi
    failed_pkg() {
        local pkg="$1"
        [[ -z "$pkg" ]] && return
        if ! printf "%s\n" "${failed[@]}" | grep -qxF "$pkg"; then
            failed+=("$pkg")
        fi
    }
    commence() {
        type_effect "Attempting a bulk package install via $pkg_manager..." "$menu_delay"; echo
        load_ui
    }
    install_msg() {
        if [[ "$array_prefix" == "$pkg_manager" ]]; then
            type_effect "Installing packages via ${pkg_manager}..." "$menu_delay"
        else
            type_effect "Installing ${array_prefix} packages via ${pkg_manager}..." "$menu_delay"
        fi
        echo
    }
    case "$pkg_manager" in
        apk)
			commence
            pkgs=("${current_pkg_array[@]%:*}")
            local iteration=1 max_iterations=5
            echo "Checking repository availability for ${#pkgs[@]} requested packages via apk..." >> "$output"
            while (( iteration <= max_iterations )); do
                echo "Simulating install: apk add --simulate ${pkgs[*]}" >> "$output"
                dry_run_output=$(
                    apk add --simulate "${pkgs[@]}" </dev/null 2>&1 | tee -a "$output"
                    exit "${PIPESTATUS[0]}"
                ); exit_code=$?
                if [[ $exit_code -ne 0 || "$dry_run_output" == *"ERROR:"* || "$dry_run_output" != *"OK"* ]]; then
                    all_bad_pkgs=$(awk '
                        /:$/ {p=$1; sub(/:$/,"",p)}
                        /breaks:/ || /conflicts:/ {print p}
                        /\(no such package\)/ {p=$1; sub(/:$/,"",p); print p}
                    ' <<<"$dry_run_output" | sed '/^$/d' | sort -u)
                    [[ -z "$all_bad_pkgs" ]] && break
                    echo "Problematic packages detected: $all_bad_pkgs" >> "$output"
                    new_pkgs=()
                    for p in "${pkgs[@]}"; do
                        p_base=${p%%[=-]*}; keep=true
                        for culprit in $all_bad_pkgs; do
                            [[ "$p_base" == "${culprit%%[=-]*}" ]] && { echo "Skipping package due to resolver issue: $p" >> "$output"; failed_pkg "$p"; keep=false; break; }
                        done
                        $keep && new_pkgs+=("$p")
                    done
                    pkgs=("${new_pkgs[@]}")
                    echo "Remaining install candidates: ${pkgs[*]}" >> "$output"
                    if (( ${#pkgs[@]} == 0 )); then
                        echo "All packages removed during dependency filtering. Bulk install aborted." >> "$output"
                        close_ui; type_effect "\033[31mCould not safely perform a bulk fast install.\033[0m" "$menu_delay"; echo; sleep 1.5
                        [[ "$verbose" == false ]] && printf "\033[2A\033[K"
                        type_effect "Initiating careful package installation..." "$menu_delay"; echo; return 1
                    fi
                    ((iteration++)); continue
                else
                    echo "Dependency simulation completed successfully." >> "$output"; break
                fi
            done
            if (( iteration > max_iterations )); then
                echo "Maximum dependency resolution attempts reached ($max_iterations). Aborting bulk mode." >> "$output"
                close_ui; return 1
            fi
            if (( ${#pkgs[@]} > 0 )); then
                close_ui; install_msg
                echo "Install command: apk add --no-cache ${pkgs[*]}" >> "$output"
                load_ui; apk add --no-cache "${pkgs[@]}" </dev/null 2>&1 | tee -a "$output"
                close_ui; type_effect "\033[32mSuccessfully installed apk packages.\033[0m" "$menu_delay"; echo
                echo "Bulk installation completed successfully via apk." >> "$output"; return 0
            fi
            ;;
        apt)
			commence
            pkgs=("${current_pkg_array[@]%:*}")
            echo "Checking repository availability for ${#pkgs[@]} requested packages via apt..." >> "$output"
            while :; do
                echo "Simulating install: apt-get install --dry-run ${pkgs[*]}" >> "$output"
                dry_run_output=$(
                    apt-get install -y --dry-run "${pkgs[@]}" </dev/null 2>&1 | tee -a "$output"
                    exit "${PIPESTATUS[0]}"
                )
                missing_pkgs=$(grep -oP "Unable to locate package \K[^ ]+" <<<"$dry_run_output")
                no_cand_pkgs=$(grep -E "has no installation candidate|is not available" <<<"$dry_run_output" | awk -F"'" '/no installation candidate/ {print $2} /is not available/ {print $2}')
                conflict_pkgs=$(grep -oP "Conflicts: \K[^ ]+" <<<"$dry_run_output" | cut -d: -f1)
                all_culprits=$(printf "%s\n%s\n%s\n" "$missing_pkgs" "$no_cand_pkgs" "$conflict_pkgs" | sed '/^$/d' | sort -u)
                [[ -z "$all_culprits" ]] && { echo "Dependency simulation completed successfully." >> "$output"; break; }
                echo "Problematic packages detected: $all_culprits" >> "$output"
                for culprit in $all_culprits; do
                    echo "Skipping package due to resolver issue: $culprit" >> "$output"
                    failed_pkg "$culprit"
                    new_pkgs=(); for p in "${pkgs[@]}"; do [[ "$p" != "$culprit" ]] && new_pkgs+=("$p"); done
                    pkgs=("${new_pkgs[@]}")
                done
                echo "Remaining install candidates: ${pkgs[*]}" >> "$output"
                if (( ${#pkgs[@]} == 0 )); then
                    echo "All packages removed during dependency filtering. Bulk install aborted." >> "$output"
                    close_ui; type_effect "\033[31mCould not safely perform a bulk fast install.\033[0m" "$menu_delay"; echo; sleep 1.5
                    [[ "$verbose" == false ]] && printf "\033[2A\033[K"
                    type_effect "Initiating careful package installation..." "$menu_delay"; echo; return 1
                fi
            done
            if (( ${#pkgs[@]} > 0 )); then
                close_ui; install_msg; load_ui
                echo "Install command: apt-get install --no-install-recommends ${pkgs[*]}" >> "$output"
                DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "${pkgs[@]}" </dev/null >> "$output" 2>&1
				close_ui; type_effect "\033[32mSuccessfully installed apt packages.\033[0m" "$menu_delay"; echo
                echo "Bulk installation completed successfully via apt." >> "$output"; return 0
            fi
            ;;
        brew)
			commence
            pkgs=("${current_pkg_array[@]%:*}")
            brew_cmd="HOMEBREW_NO_AUTO_UPDATE=1 brew install"
            echo "Checking repository availability for ${#pkgs[@]} requested packages via Homebrew..." >> "$output"
            echo "Simulating install: $brew_cmd --dry-run ${pkgs[*]}" >> "$output"
            dry_run_output=$(
                sudo -u "$user" bash -c "$brew_cmd --dry-run ${pkgs[*]}" </dev/null 2>&1 | tee -a "$output"
                exit "${PIPESTATUS[0]}"
            ); dry_rc=$?
            if (( dry_rc != 0 )); then
                echo "Homebrew dry-run reported issues. Bulk install cannot proceed safely." >> "$output"
                close_ui; type_effect "\033[31mCould not perform a bulk install with Homebrew.\033[0m" "$menu_delay"; echo; sleep 1.2
                [[ "$verbose" == false ]] && printf "\033[2A\033[K"
                type_effect "Performing careful package installation..." "$menu_delay"; echo; return 1
            fi
            echo "Dependency simulation completed successfully." >> "$output"
            close_ui; install_msg; load_ui
            echo "Install command: $brew_cmd ${pkgs[*]}" >> "$output"
            install_output=$(
                sudo -u "$user" bash -c "$brew_cmd ${pkgs[*]}" </dev/null 2>&1 | tee -a "$output"
                exit "${PIPESTATUS[0]}"
            ); install_rc=$?
            if (( install_rc == 0 )); then
                close_ui; type_effect "\033[32mSuccessfully installed brew packages.\033[0m" "$menu_delay"; echo
                echo "Bulk installation completed successfully via Homebrew." >> "$output"; return 0
            else
                close_ui; type_effect "\033[31mBulk install failed unexpectedly.\033[0m" "$menu_delay"; echo
                echo "Homebrew bulk install returned non-zero exit status ($install_rc)." >> "$output"; return 1
            fi
            ;;
      dnf|yum)
			commence
            pkgs=("${current_pkg_array[@]%:*}")
            echo "Querying repositories: $pkg_manager list --available ${pkgs[*]}" >> "$output"
            available_output=$(
                $pkg_manager list --available "${pkgs[@]}" </dev/null 2>&1 | tee -a "$output"
                exit "${PIPESTATUS[0]}"
            )
            new_pkgs=()
            for p in "${pkgs[@]}"; do
                if grep -q "^$p\." <<<"$available_output"; then
                    echo "Confirmed available: $p" >> "$output"
                    new_pkgs+=("$p")
                else
                    echo "Package not available in repositories: $p — skipping." >> "$output"
                    failed_pkg "$p"
                fi
            done
            pkgs=("${new_pkgs[@]}")
            if [ ${#pkgs[@]} -gt 0 ]; then
                echo "Proceeding with bulk install. ${#pkgs[@]} package(s) passed availability check." >> "$output"
                echo "Install command: $pkg_manager install -y --skip-broken --setopt=install_weak_deps=False ${pkgs[*]}" >> "$output"
                close_ui; install_msg; load_ui
                install_output=$(
                    DEBIAN_FRONTEND=noninteractive $pkg_manager install -y --skip-broken --setopt=install_weak_deps=False "${pkgs[@]}" </dev/null 2>&1 | tee -a "$output"
                    exit "${PIPESTATUS[0]}"
                ); install_rc=$?
                close_ui
                if [ $install_rc -eq 0 ]; then
                    type_effect "\033[32mSuccessfully installed $pkg_manager packages.\033[0m" "$menu_delay"; echo
                    echo "Bulk installation completed successfully via $pkg_manager." >> "$output"
                    return 0
                else
                    type_effect "\033[31mBulk install failed unexpectedly.\033[0m" "$menu_delay"; echo
                    echo "$pkg_manager install returned non-zero exit status ($install_rc)." >> "$output"
                    return 1
                fi
            else
                echo "All requested packages were filtered out during availability check. Bulk install aborted." >> "$output"
                close_ui; type_effect "\033[31mCould not safely perform a bulk fast install.\033[0m" "$menu_delay"; echo; sleep 1.5
                [[ "$verbose" == false ]] && printf "\033[2A\033[K"
                type_effect "Initiating careful package installation..." "$menu_delay"; echo
                return 1
            fi
            ;;
        flatpak)
            commence
            pkgs=("${current_pkg_array[@]%%:*}")
            echo "Checking flathub availability for ${#pkgs[@]} requested packages via flatpak..." >> "$output"
            new_pkgs=()
            for p in "${pkgs[@]}"; do
                if flatpak remote-info flathub "$p" >/dev/null 2>&1; then
                    echo "Confirmed available: $p" >> "$output"
                    new_pkgs+=("$p")
                else
                    echo "Flatpak not available in flathub: $p — skipping." >> "$output"
                    failed_pkg "$p"
                fi
            done
            pkgs=("${new_pkgs[@]}")
            if (( ${#pkgs[@]} == 0 )); then
                echo "All requested flatpaks were filtered out during availability check. Bulk install completed (nothing to install)." >> "$output"
                close_ui; type_effect "\033[32mSuccessfully installed flatpak packages.\033[0m" "$menu_delay"; echo
                echo "Bulk installation completed successfully via flatpak." >> "$output"
                return 0
            fi
            close_ui; install_msg; load_ui
            echo "Final bulk install: flatpak install --noninteractive flathub ${pkgs[*]} -y" >> "$output"
            install_output=$(
                flatpak install --noninteractive flathub "${pkgs[@]}" -y </dev/null 2>&1 | tee -a "$output"
                exit "${PIPESTATUS[0]}"
            )
            install_rc=$?
            close_ui
            if (( install_rc == 0 )); then
                type_effect "\033[32mSuccessfully installed flatpak packages.\033[0m" "$menu_delay"; echo
                echo "Bulk installation completed successfully via flatpak." >> "$output"; return 0
            else
                type_effect "\033[31mFlatpak bulk install failed unexpectedly.\033[0m" "$menu_delay"; echo
                echo "flatpak install returned non-zero exit status ($install_rc)." >> "$output"; return 1
            fi
            ;;
        pacman)
            commence
            local -A seen
            pkgs=()
            for p in "${current_pkg_array[@]%:*}"; do
                [[ ${seen[$p]} ]] && continue
                seen[$p]=1
                pkgs+=("$p")
            done
            while :; do
                check_cmd="pacman -Sp --needed ${pkgs[*]}"
                check_output=$(eval "$check_cmd" </dev/null 2>&1)
                missing=($(grep -oP 'target not found: \K\S+' <<<"$check_output" | sort -u))
                (( ${#missing[@]} )) || break
                for m in "${missing[@]}"; do
                    skipped+=("$m")
                    echo "Target not found: '$m' - skipping..." >> "$output"
                done
                new=()
                for p in "${pkgs[@]}"; do
                    [[ " ${missing[*]} " != *" $p "* ]] && new+=("$p")
                done
                pkgs=("${new[@]}")
            done
            if (( ${#pkgs[@]} == 0 )); then
                echo "All requested pacman packages were filtered out during availability check. Bulk install completed (nothing to install)." >> "$output"
                close_ui; type_effect "\033[32mSuccessfully installed pacman packages.\033[0m" "$menu_delay"; echo
                echo "Bulk installation completed successfully via pacman." >> "$output"; return 0
            fi
            close_ui; install_msg; load_ui
            handle_conflict() {
                local line="$1"
                conflict_part=$(sed 's/^:: \(.*\) are in conflict.*/\1/' <<<"$line")
                pkgA_part=$(cut -d' ' -f1 <<<"$conflict_part")
                init_pkg="${pkgA_part%%-[0-9]*}"
                conflicting_package=$(grep -oP 'Remove \K[^? ]+' <<<"$line")
            }
            last_conflict=""
            repeat_count=0
            max_repeats=3
            success=false
            while :; do
                install_cmd="pacman -S --noconfirm --needed --overwrite '*' ${pkgs[*]}"
                install_output=$(
                    eval "$install_cmd" </dev/null 2>&1 | tee -a "$output"
                    exit "${PIPESTATUS[0]}"
                )
                install_rc=$?
                conflict_line=$(grep "are in conflict" <<<"$install_output" | head -n1)
                dep_break=$(grep -m1 "breaks dependency" <<<"$install_output")
                if [[ -z "$conflict_line" && -z "$dep_break" ]]; then
                    success=true
                    break
                fi
                if [[ -n "$conflict_line" ]]; then
                    handle_conflict "$conflict_line"
                    echo "Conflict detected: '$init_pkg' conflicts with '$conflicting_package'. Removing conflicting package to continue..." >> "$output"
                elif [[ -n "$dep_break" ]]; then
                    init_pkg=$(grep -oP '^:: installing \K[^\s(]+' <<<"$dep_break")
                    conflicting_package="$init_pkg"
                    echo "Dependency break detected for '$init_pkg'. Attempting resolution..." >> "$output"
                fi
                current_conflict="${init_pkg}:${conflicting_package}"
                if [[ "$current_conflict" == "$last_conflict" ]]; then
                    ((repeat_count++))
                else
                    repeat_count=1
                    last_conflict="$current_conflict"
                fi
                if (( repeat_count >= max_repeats )); then
                    if [[ " ${pkgs[*]} " == *" $init_pkg "* ]]; then
                        skipped+=("$init_pkg")
                    fi
                    echo "Could not resolve repeated conflict/dependency for '$init_pkg'. Skipping package..." >> "$output"
                    success=false
                    break
                fi
                remove_output=$(
                    pacman -R --noconfirm "$conflicting_package" </dev/null 2>&1 | tee -a "$output"
                    exit "${PIPESTATUS[0]}"
                )
                if grep -q "breaks dependency" <<<"$remove_output"; then
                    if [[ " ${pkgs[*]} " == *" $init_pkg "* ]]; then
                        skipped+=("$init_pkg")
                    fi
                    echo "Removing '$conflicting_package' would break dependencies. Skipping '$init_pkg' instead..." >> "$output"
                    new=()
                    for p in "${pkgs[@]}"; do
                        [[ "$p" != "$init_pkg" ]] && new+=("$p")
                    done
                    pkgs=("${new[@]}")
                    continue
                fi
            done
            close_ui
            if $success; then
                type_effect "\033[32mSuccessfully installed pacman packages.\033[0m" "$menu_delay"; echo
                echo "Bulk installation completed successfully via pacman." >> "$output"
                for s in "${skipped[@]}"; do
                    failed_pkg "$s"
                done
                return 0
            else
                type_effect "\033[31mCould not safely perform a bulk fast install.\033[0m" "$menu_delay"; echo; sleep 1.5
                echo "Bulk fast install failed due to unresolved issues. Falling back to careful mode..." >> "$output"
                [[ "$verbose" == false ]] && printf "\033[2A\033[K]"
                type_effect "Initiating careful package installation..." "$menu_delay"; echo
                return 1
            fi
            ;;
        paru)
			commence
            install_prefix="sudo -u $user "
            install_flags="-S --noconfirm --needed --removemake --skipreview"
            local -A seen; pkgs=()
            for p in "${current_pkg_array[@]%:*}"; do [[ ${seen[$p]} ]] && continue; seen[$p]=1; pkgs+=("$p"); done
            echo "paru: preparing bulk AUR install for ${#pkgs[@]} unique targets." >> "$output"
            success=false
            max_attempts=40
            attempt=0
            skipped=()
            while (( attempt < max_attempts )); do
                ((attempt++))
                install_cmd="${install_prefix}paru $install_flags ${pkgs[*]}"
                echo "paru: attempt $attempt → $install_cmd" >> "$output"
                install_output=$(eval "$install_cmd" </dev/null 2>/dev/null | tee -a "$output")
                install_rc=${PIPESTATUS[0]}
                handled_error=false
                if grep -q "error: could not find all required packages:" <<<"$install_output"; then
                    handled_error=true
					echo "paru: missing package targets detected." >> "$output"
                    missing_targets=($(grep -oP '^\s+\K\S+(?=\s+\(target\))' <<<"$install_output"))
                    missing_wanted=($(grep -oP '^\s+\S+\s+\(wanted by: \K\S+(?=\))' <<<"$install_output"))
                    to_skip=($(printf '%s\n' "${missing_targets[@]}" "${missing_wanted[@]}" | sort -u))
                    if (( ${#to_skip[@]} > 0 )); then
                        echo "paru: removing unavailable packages: ${to_skip[*]}" >> "$output"
                        for t in "${to_skip[@]}"; do
                            failed_pkg "$t"
                            skipped+=("$t")
                        done
                        new=()
                        for p in "${pkgs[@]}"; do
                            skip=false
                            for ts in "${to_skip[@]}"; do [[ "$p" == "$ts" ]] && skip=true && break; done
                            ! $skip && new+=("$p")
                        done
                        pkgs=("${new[@]}")
                    fi
                fi
                conflict_line=$(grep -i "are in conflict" <<<"$install_output" | head -n1)
                if [[ -n "$conflict_line" ]]; then
                    handled_error=true
                    pkg1=$(sed -E 's/^:: ([^ ]+) and ([^ ]+) are in conflict.*$/\1/' <<<"$conflict_line")
                    pkg2=$(sed -E 's/^:: ([^ ]+) and ([^ ]+) are in conflict.*$/\2/' <<<"$conflict_line")
                    base1="${pkg1%%-[0-9]*}"
                    base2="${pkg2%%-[0-9]*}"
                    echo "paru: conflict detected → $pkg1 vs $pkg2" >> "$output"
                    local -a to_remove=()
                    [[ " ${pkgs[*]} " == *" $base1 "* ]] && to_remove+=("$base1")
                    [[ " ${pkgs[*]} " == *" $base2 "* ]] && to_remove+=("$base2")
                    if (( ${#to_remove[@]} > 0 )); then
                        echo "paru: removing conflicting request(s): ${to_remove[*]}" >> "$output"
                        for r in "${to_remove[@]}"; do failed_pkg "$r"; done
                        new=()
                        for p in "${pkgs[@]}"; do
                            keep=true
                            for r in "${to_remove[@]}"; do [[ "$p" == "$r" ]] && keep=false && break; done
                            $keep && new+=("$p")
                        done
                        pkgs=("${new[@]}")
                    fi
                fi
                if grep -qi "Conflicts found:" <<<"$install_output"; then
                    handled_error=true
                    conflicting_pkg=$(awk '/Conflicts found:/ { while (getline > 0) { gsub(/^[ \t]+/, ""); if (length($0) > 0) { sub(/:.*/, "", $0); print $0; exit; } } }' <<<"$install_output" | head -n1 | xargs)

                    if [[ -n "$conflicting_pkg" && " ${pkgs[*]} " == *" $conflicting_pkg "* ]]; then
                        echo "paru: provider conflict detected → removing $conflicting_pkg" >> "$output"
                        failed_pkg "$conflicting_pkg"
                        new=()
                        for p in "${pkgs[@]}"; do [[ "$p" != "$conflicting_pkg" ]] && new+=("$p"); done
                        pkgs=("${new[@]}")
                    fi
                fi
                if ! $handled_error; then
                    [[ $install_rc -eq 0 ]] && success=true && break
                    echo "paru: command exited with RC=$install_rc without resolvable error. stopping." >> "$output"
                    break
                fi
                echo "paru: remaining install candidates → ${pkgs[*]}" >> "$output"
            done
            close_ui
            if $success && (( ${#pkgs[@]} > 0 )); then
                install_msg; load_ui
                final_install_cmd="${install_prefix}paru $install_flags --overwrite '*' ${pkgs[*]}"
                echo "Executing final bulk install: $final_install_cmd" >> "$output"
                eval "$final_install_cmd" </dev/null >> "$output" 2>&1
                close_ui; type_effect "\033[32mSuccessfully installed $pkg_manager packages.\033[0m" "$menu_delay"; echo
                echo "Bulk installation completed successfully." >> "$output"
                return 0
            else
                for p in "${pkgs[@]}"; do failed_pkg "$p"; done
                echo "paru: bulk mode failed after $attempt attempt(s). falling back to careful installer." >> "$output"
                type_effect "\033[31mCould not safely perform a bulk fast install.\033[0m" "$menu_delay"; echo; sleep 1.5
                [[ "$verbose" == false ]] && printf "\033[2A\033[K"
                type_effect "Initiating careful package installation..." "$menu_delay"; echo
                return 1
            fi
            ;;
          pkg)
			commence
            pkgs=("${current_pkg_array[@]%:*}")
            echo "Preparing bulk install for ${#pkgs[@]} requested packages." >> "$output"
            while true; do
                dry_run_output=$(
                    pkg install -ny "${pkgs[@]}" </dev/null 2>&1 | tee -a "$output"
                    exit "${PIPESTATUS[0]}"
                )
                culprits=$(grep "matching '" <<<"$dry_run_output" | sed "s/.*matching '\([^']*\)'.*/\1/")
                [[ -z "$culprits" ]] && break
                echo "Resolver detected missing packages: $culprits" >> "$output"
                for culprit in $culprits; do
                    failed_pkg "$culprit"
                    new_pkgs=()
                    for p in "${pkgs[@]}"; do [[ "$p" != "$culprit" ]] && new_pkgs+=("$p"); done
                    pkgs=("${new_pkgs[@]}")
                done
                echo "Remaining install candidates: ${pkgs[*]}" >> "$output"
                if [[ ${#pkgs[@]} -eq 0 ]]; then
                    close_ui; type_effect "\033[31mCould not safely perform a bulk fast install.\033[0m" "$menu_delay"; echo; sleep 1.5
                    echo "All packages removed during dependency filtering. bulk mode aborted." >> "$output"
                    [[ "$verbose" == false ]] && printf "\033[2A\033[K"
                    type_effect "Initiating careful package installation..." "$menu_delay"; echo
                    return 1
                fi
            done
            if [[ ${#pkgs[@]} -gt 0 ]]; then
                close_ui; install_msg; load_ui
                echo "Executing final install for: ${pkgs[*]}" >> "$output"
                pkg install -y "${pkgs[@]}" </dev/null 2>&1 | tee -a "$output"
                close_ui; type_effect "\033[32mSuccessfully installed pkg packages.\033[0m" "$menu_delay"; echo
                echo "pkg: bulk installation completed successfully." >> "$output"
                return 0
            fi
            ;;
        snap)
            commence
            pkgs=("${current_pkg_array[@]%:*}")
            echo "Querying snap store availability for ${#pkgs[@]} requested packages via snap..." >> "$output"
            new_pkgs=()
            for p in "${pkgs[@]}"; do
                if snap info "$p" >/dev/null 2>&1; then
                    echo "Confirmed available: $p" >> "$output"
                    new_pkgs+=("$p")
                else
                    echo "Snap not available in store: $p — skipping." >> "$output"
                    failed_pkg "$p"
                fi
            done
            pkgs=("${new_pkgs[@]}")
            if (( ${#pkgs[@]} == 0 )); then
                echo "All requested snaps were filtered out during availability check. Bulk install completed (nothing to install)." >> "$output"
                close_ui
                type_effect "\033[32mSuccessfully installed snap packages.\033[0m" "$menu_delay"; echo
                echo "Bulk installation completed successfully via snap." >> "$output"
                return 0
            fi
            close_ui; install_msg; load_ui
            while :; do
                echo "Final bulk install: snap install ${pkgs[*]}" >> "$output"
                install_output=$(
                    snap install "${pkgs[@]}" </dev/null 2>&1 | tee -a "$output"
                    exit "${PIPESTATUS[0]}"
                )
                install_rc=$?
                if (( install_rc == 0 )); then
                    close_ui; type_effect "\033[32mSuccessfully installed snap packages.\033[0m" "$menu_delay"; echo
                    echo "Bulk installation completed successfully via snap." >> "$output"; return 0
                fi
                classic_snaps=($(grep -oP 'snap "\K[^"]+' <<<"$install_output" | sort -u))
                if (( ${#classic_snaps[@]} > 0 )); then
                    echo "Classic confinement detected for: ${classic_snaps[*]} — skipping (bulk cannot mix --classic safely)" >> "$output"
                    for culprit in "${classic_snaps[@]}"; do
                        failed_pkg "$culprit"
                        new_pkgs=(); for p in "${pkgs[@]}"; do [[ "$p" != "$culprit" ]] && new_pkgs+=("$p"); done
                        pkgs=("${new_pkgs[@]}")
                    done
                    echo "Remaining install candidates: ${pkgs[*]}" >> "$output"
                    if (( ${#pkgs[@]} == 0 )); then
                        close_ui; type_effect "\033[31mCould not safely perform a bulk fast install.\033[0m" "$menu_delay"; echo; sleep 1.5
                        [[ "$verbose" == false ]] && printf "\033[2A\033[K]"
                        type_effect "Initiating careful package installation..." "$menu_delay"; echo; return 1
                    fi
                    continue
                fi
                close_ui; type_effect "\033[31mCould not perform a bulk install with snap.\033[0m" "$menu_delay"; echo; sleep 1.2
                [[ "$verbose" == false ]] && printf "\033[2A\033[K]"
                type_effect "Performing careful package installation..." "$menu_delay"; echo; return 1
            done
            ;;
        yay)
			commence
            install_prefix="sudo -u $user "
            install_flags="-S --noconfirm --needed --removemake"
            local -A seen; pkgs=()
            for p in "${current_pkg_array[@]%:*}"; do [[ ${seen[$p]} ]] && continue; seen[$p]=1; pkgs+=("$p"); done
            echo "yay: starting AUR resolution for ${#pkgs[@]} requested packages." >> "$output"
            success=false
            max_attempts=40
            attempt=0
            while (( attempt < max_attempts )); do
                ((attempt++))
                install_cmd="${install_prefix}yay $install_flags ${pkgs[*]}"
                echo "yay: attempt $attempt → $install_cmd" >> "$output"
                install_output=$(
                    eval "$install_cmd" </dev/null 2>&1 | tee -a "$output"
                    exit "${PIPESTATUS[0]}"
                )
                install_rc=$?
                handled_error=false
                if grep -q "error: could not find all required packages:" <<<"$install_output"; then
                    handled_error=true
                    missing_targets=($(grep -oP '^\s+\K\S+(?=\s+\(target\))' <<<"$install_output"))
                    missing_wanted=($(grep -oP '^\s+\S+\s+\(wanted by: \K\S+(?=\))' <<<"$install_output"))
                    to_skip=($(printf '%s\n' "${missing_targets[@]}" "${missing_wanted[@]}" | sort -u))
                    if (( ${#to_skip[@]} > 0 )); then
                        echo "yay: missing packages detected → ${to_skip[*]}" >> "$output"
                        for t in "${to_skip[@]}"; do skipped+=("$t"); done
                        new=()
                        for p in "${pkgs[@]}"; do
                            skip=false
                            for ts in "${to_skip[@]}"; do [[ "$p" == "$ts" ]] && skip=true && break; done
                            ! $skip && new+=("$p")
                        done
                        pkgs=("${new[@]}")
                        echo "yay: remaining install candidates → ${pkgs[*]}" >> "$output"
                    fi
                fi
                conflict_line=$(grep -i "are in conflict" <<<"$install_output" | head -n1)
                if [[ -n "$conflict_line" ]]; then
                    handled_error=true
                    pkg1=$(sed -E 's/^:: ([^ ]+) and ([^ ]+) are in conflict.*$/\1/' <<<"$conflict_line")
                    pkg2=$(sed -E 's/^:: ([^ ]+) and ([^ ]+) are in conflict.*$/\2/' <<<"$conflict_line")
                    base1="${pkg1%%-[0-9]*}"
                    base2="${pkg2%%-[0-9]*}"
                    echo "yay: conflict detected → $pkg1 vs $pkg2" >> "$output"
                    local -a to_remove=()
                    [[ " ${pkgs[*]} " == *" $base1 "* ]] && to_remove+=("$base1")
                    [[ " ${pkgs[*]} " == *" $base2 "* ]] && to_remove+=("$base2")
                    if (( ${#to_remove[@]} > 0 )); then
                        echo "yay: removing conflicting targets → ${to_remove[*]}" >> "$output"
                        for r in "${to_remove[@]}"; do failed_pkg "$r"; done

                        new=()
                        for p in "${pkgs[@]}"; do
                            keep=true
                            for r in "${to_remove[@]}"; do [[ "$p" == "$r" ]] && keep=false && break; done
                            $keep && new+=("$p")
                        done
                        pkgs=("${new[@]}")
                    fi
                fi
                if grep -qi "Conflicts found:" <<<"$install_output"; then
                    handled_error=true
                    conflicting_pkg=$(awk '
                        /Conflicts found:/ {
                            while (getline > 0) {
                                gsub(/^[ \t]+/, "")
                                if (length($0) > 0) { sub(/:.*/, "", $0); print $0; exit }
                            }
                        }' <<<"$install_output" | head -n1 | xargs)

                    if [[ -n "$conflicting_pkg" && " ${pkgs[*]} " == *" $conflicting_pkg "* ]]; then
                        echo "yay: provider conflict detected → removing $conflicting_pkg" >> "$output"
                        failed_pkg "$conflicting_pkg"

                        new=()
                        for p in "${pkgs[@]}"; do [[ "$p" != "$conflicting_pkg" ]] && new+=("$p"); done
                        pkgs=("${new[@]}")
                    fi
                fi
                if ! $handled_error; then
                    [[ $install_rc -eq 0 ]] && success=true
                    break
                fi
            done
            (( attempt >= max_attempts )) && success=false
            installed=$(pacman -Qq </dev/null 2>/dev/null || echo "")
            for p in "${pkgs[@]}"; do
                grep -Fx "$p" <<<"$installed" >/dev/null || failed_pkg "$p"
            done
            close_ui
            if $success && (( ${#pkgs[@]} > 0 )); then
				install_msg; load_ui
                final_install_cmd="${install_prefix}yay $install_flags --overwrite '*' ${pkgs[@]}"
                echo "yay: executing final bulk install → $final_install_cmd" >> "$output"
                eval "$final_install_cmd" </dev/null 2>&1 | tee -a "$output"
                for s in "${skipped[@]}"; do failed_pkg "$s"; done
                echo "Bulk installation completed successfully." >> "$output"
                return 0
            else
                close_ui; type_effect "\033[31mCould not safely perform a bulk fast install.\033[0m" "$menu_delay"; echo; sleep 1.5
                echo "Bulk mode failed after $attempt attempt(s). falling back to careful installer." >> "$output"
                [[ "$verbose" == false ]] && printf "\033[2A\033[K"
                type_effect "Initiating careful package installation..." "$menu_delay"; echo
                return 1
            fi
            ;;
          *)
            return 1 
			;;
    esac
}

manage_conflicts() {
    local manager=$1
    local pkg=$2
    local install_output=""
    local conflicting_package=""
    local conflict_pattern=""
    local extract_regex=""
    local remove_cmd=""
    case "$manager" in
        pacman)
            conflict_pattern="are in conflict"
            extract_regex='Remove \K[^?]+'
            remove_cmd="pacman -R --noconfirm"
            ;;
        homebrew|brew)
            conflict_pattern="conflicting"
            extract_regex='because \K[^ ]+'
            remove_cmd="brew uninstall"
            ;;
        port)
            conflict_pattern="conflicts with"
            extract_regex='conflicts with \K[^ ]+'
            remove_cmd="port uninstall"
            ;;
        pkg)
            conflict_pattern="already installed"
            extract_regex='already installed: \K[^ ]+'
            remove_cmd="pkg remove"
            ;;
        entropy)
            conflict_pattern="Conflict detected"
            extract_regex='Conflict detected: \K[^ ]+'
            remove_cmd="equo remove"
            ;;
        dpkg)
            conflict_pattern="is installed"
            extract_regex='\berror: \K[^ ]+'
            remove_cmd="dpkg --remove"
            ;;
        ipkg|opkg)
            conflict_pattern="Conflicts with"
            extract_regex='Conflicts with \K[^ ]+'
            remove_cmd="opkg remove"
            ;;
        netpkg)
            conflict_pattern="conflict detected"
            extract_regex='conflicts with: \K[^ ]+'
            remove_cmd="netpkg remove"
            ;;
        petget)
            conflict_pattern="conflicts with"
            extract_regex='conflicts with \K[^ ]+'
            remove_cmd="petget remove"
            ;;
        pkgsrc)
            conflict_pattern="Conflict detected"
            extract_regex='Conflict with: \K[^ ]+'
            remove_cmd="pkgsrc remove"
            ;;
        portage)
            conflict_pattern="conflicts with"
            extract_regex='conflicts with: \K[^ ]+'
            remove_cmd="emerge --unmerge"
            ;;
        slackpkg)
            conflict_pattern="conflicting package"
            extract_regex='conflicting package: \K[^ ]+'
            remove_cmd="slackpkg remove"
            ;;
        openpkg)
            conflict_pattern="conflict"
            extract_regex='conflict with: \K[^ ]+'
            remove_cmd="openpkg remove"
            ;;
    esac
    install_output=$(${pkg_install_cmds[$manager]} "$pkg" </dev/null 2>&1)
    if [[ -n "$conflict_pattern" ]] && echo "$install_output" | grep -q "$conflict_pattern"; then
        close_ui; type_effect "Handling package conflict..." "$menu_delay"; echo; load_ui
        conflicting_package=$(echo "$install_output" | grep -oP "$extract_regex")
        if $remove_cmd "$conflicting_package" &>> "$output"; then
            close_ui; type_effect "Attempting to install $pkg after removing conflicts..." "$menu_delay"; echo; load_ui
            if ${pkg_install_cmds[$manager]} "$pkg" &>> "$output"; then
                return 0
            fi
        fi
    fi
    return 1
}

install() {
    local array_name=$1
    local preferred_manager=$2
    local package_list=("${!3}")
    package_count=${#package_list[@]}
    if ! command -v "$preferred_manager" &>/dev/null && { [ "$preferred_manager" != "nix" ] || [ ! -f "/nix/var/nix/profiles/default/bin/nix" ]; }; then
        preferred_manager_exists=false
        attempted_arrays+=("$array_name") 
    else
        attempted_arrays+=("$array_name")
        preferred_manager_exists=true
    fi 
    if [ "$preferred_manager_exists" == true ]; then
        if [[ $package_count -eq 1 ]]; then
            type_effect "Installing 1 package with $preferred_manager... This may take a moment." "$menu_delay"
        else
            type_effect "Installing $package_count packages with $preferred_manager... This will take some time." "$menu_delay"
        fi
    else
        if [[ $package_count -eq 1 ]]; then
            type_effect "Installing 1 package... This may take a moment." "$menu_delay"
        else
            type_effect "Installing $package_count packages... This will take some time." "$menu_delay"
        fi
    fi
    echo; any_installs_attempted=true; local pkg_counter=1
    for pkg in "${package_list[@]}"; do
        [[ "$pkg" == TotalSize* ]] && continue
        pkg_name="${pkg%%:*}"; repo=""
        [[ "$preferred_manager" == "flatpak" ]] && IFS=":" read -r pkg_name repo _ <<< "$pkg"
        [[ "$verbose" == false ]] && { tput cuu 1; tput el; echo; }
        echo -e "[$pkg_counter] \033[1m$pkg_name\033[0m"
        installed=false; failed_with_preferred=false
        if [[ "$preferred_manager" == "nix" && -x /nix/var/nix/profiles/default/bin/nix ]] || command -v "$preferred_manager" &>/dev/null; then
            type_effect "Attempting to install $pkg_name with $preferred_manager..." "$menu_delay"; echo
            load_ui
            if ( [[ "$preferred_manager" == "yay" ]] && yay -Si "$pkg_name" &>/dev/null && ${pkg_install_cmds[$preferred_manager]} "$pkg_name" </dev/null &>> "$output" ) ||
               ( [[ "$preferred_manager" != "yay" && "$preferred_manager" != "flatpak" ]] && ${pkg_install_cmds[$preferred_manager]} "$pkg_name" </dev/null &>> "$output" ) ||
               ( [[ "$preferred_manager" == "flatpak" ]] && flatpak install --system -y "$repo" "$pkg_name" </dev/null &>> "$output" ); then
                close_ui; type_effect "\033[32mSuccessfully installed $pkg_name with $preferred_manager.\033[0m" "$menu_delay"; echo
                installed=true
            else
                if manage_conflicts "$preferred_manager" "$pkg_name"; then
                    close_ui; type_effect "\033[32mSuccessfully installed $pkg_name with $preferred_manager.\033[0m" "$menu_delay"; echo
                    installed=true
                else
                    close_ui; type_effect "\033[31mFailed to install $pkg_name with $preferred_manager. Trying fallbacks.\033[0m" "$menu_delay"; echo
                    failed_with_preferred=true
                fi
            fi
        fi
        if [[ $installed == false ]]; then
            first_attempt=true
            for fallback_manager in "${available_pkg_managers[@]}"; do
                [[ $fallback_manager == "$preferred_manager" ]] && continue
                [[ "$verbose" == false && $failed_with_preferred == true ]] && { printf "\033[2A\033[K"; failed_with_preferred=false; }

                if $first_attempt; then
                    type_effect "Attempting to install $pkg_name with $fallback_manager..." "$menu_delay"; echo
                    first_attempt=false
                else
                    [[ "$verbose" == false ]] && printf "\033[2A\033[K"
                    type_effect "Attempting to install $pkg_name with $fallback_manager..." "$menu_delay"; echo
                fi
                load_ui
                if ( [[ "$fallback_manager" == "yay" ]] && yay -Si "$pkg_name" &>/dev/null && ${pkg_install_cmds[$fallback_manager]} "$pkg_name" </dev/null &>> "$output" ) ||
                   ( [[ "$fallback_manager" != "yay" ]] && ${pkg_install_cmds[$fallback_manager]} "$pkg_name" </dev/null &>> "$output" ); then
                    close_ui; type_effect "\033[32mSuccessfully installed $pkg_name with $fallback_manager.\033[0m" "$menu_delay"; echo
                    installed=true; break
                else
                    if manage_conflicts "$fallback_manager" "$pkg_name"; then
                        close_ui; type_effect "\033[32mSuccessfully installed $pkg_name with $fallback_manager.\033[0m" "$menu_delay"; echo
                        installed=true; break
                    else
                        close_ui; type_effect "\033[31mFailed to install $pkg_name with $fallback_manager.\033[0m" "$menu_delay"; echo
                    fi
                fi
            done
        fi
        if [[ $installed == false ]]; then
            [[ "$verbose" == false ]] && printf "\033[2A\033[K"
            type_effect "\033[31mFailed to install $pkg_name.\033[0m" "$menu_delay"; echo
            failed+=("$pkg_name")
        fi
        ((pkg_counter++))
    done
}

get_installed() {
    case $1 in
        apt) installed_pkgs=$(apt-mark showmanual) ;;
        dnf) installed_pkgs=$(dnf list installed 2>/dev/null | awk '/@commandline/ {print $1}') ;;
        yum) installed_pkgs=$(yum list installed 2>/dev/null | awk '/@commandline/ {print $1}') ;;
        pacman) installed_pkgs=$(pacman -Qq) ;;
        brew) installed_pkgs=$(brew list --formula) ;;
        port) installed_pkgs=$(port installed requested | awk '/(active)/ {print $1}') ;;
        zypper) installed_pkgs=$(zypper se --installed-only | awk '{print $3}') ;;
        flatpak) installed_pkgs=$(flatpak list --app --columns=application 2>/dev/null | sort -u) ;;
        snap) if systemctl is-active --quiet snapd; then installed_pkgs=$(snap list 2>/dev/null | awk 'NR>1 {print $1}'); fi ;;
        paru) installed_pkgs=$(pacman -Qq) ;;
        trizen) installed_pkgs=$(pacman -Qq) ;;
        pikaur) installed_pkgs=$(pacman -Qq) ;;
        yay) installed_pkgs=$(pacman -Qq) ;;
        aurman) installed_pkgs=$(pacman -Qq) ;;
        pacaur) installed_pkgs=$(pacman -Qq) ;;
        aura) installed_pkgs=$(pacman -Qq) ;;
        pakku) installed_pkgs=$(pacman -Qq) ;;
	    rpm) installed_pkgs=$(rpm -qa) ;;
 	    eopkg) installed_pkgs=$(eopkg list-installed | awk '{print $1}') ;;
	    crew) installed_pkgs=$(crew list) ;;
	    pkgtool) installed_pkgs=$(ls /var/log/packages) ;;
        # nix) installed_pkgs=$(nix-env -q | sed 's/-.*//') ;;
        guix) installed_pkgs=$(guix package --list-installed) ;;
        xbps) installed_pkgs=$(xbps-query -l) ;;
        apk) installed_pkgs=$(apk info) ;;
        entropy) installed_pkgs=$(equo query installed) ;;
        dpkg) installed_pkgs=$(dpkg-query -f '${binary:Package}\n' -W) ;;
        ipkg) installed_pkgs=$(ipkg list_installed) ;;
        opkg) installed_pkgs=$(opkg list-installed) ;;
        netpkg) installed_pkgs=$(netpkg -q) ;;
        petget) installed_pkgs=$(petget list_installed) ;;
        pkgsrc) installed_pkgs=$(pkg_info) ;;
        portage) installed_pkgs=$(equery list -1) ;;
        rpm-ostree) installed_pkgs=$(rpm-ostree db list | awk '/^  name: / {print $2}') ;;
        slackpkg) installed_pkgs=$(slackpkg search) ;;
        openpkg) installed_pkgs=$(openpkg query --installed) ;;
    esac
}

_line() {
    if [[ -n ${spinner_pid:-} ]] || (( ${_rc_spin:-0} )); then
        close_ui; _rc_spin=0
    elif [[ ${verbose:-false} == false && ${_rc_open:-0} == 1 ]]; then
        printf '\033[2A\033[K'
    fi
    type_effect "$1" "$menu_delay"; echo
    _rc_open=1
    if [[ ${2:-} == spin ]] && declare -F load_ui >/dev/null 2>&1; then
        load_ui; _rc_spin=1
    fi
}

_done_line() {
    if [[ -n ${spinner_pid:-} ]] || (( ${_rc_spin:-0} )); then
        close_ui; _rc_spin=0
    elif [[ ${verbose:-false} == false && ${_rc_open:-0} == 1 ]]; then
        printf '\033[2A\033[K'
    fi
    type_effect "$1" "$menu_delay"; echo
    _rc_open=0
}


probe_rejects() {
    local mgr=$1; shift
    local sim
    (( $# )) || return 1
    case "$mgr" in
        pacman|yay|paru|trizen|pikaur|aurman|pacaur|aura|pakku)
            sim=$(pacman -S --needed --noconfirm --print-format '%n' "$@" 2>&1 >/dev/null)
            sed -n "s/.*target not found: \([^ ]*\).*/\1/p" <<< "$sim" ;;
        apt|dpkg)
            sim=$(env DEBIAN_FRONTEND=noninteractive apt-get install -s -y "$@" 2>&1 >/dev/null)
            sed -n "s/^E: Unable to locate package \(.*\)/\1/p;
                    s/^E: Package '\([^']*\)' has no installation candidate/\1/p" <<< "$sim" ;;
        dnf|yum)
            sim=$(dnf -q --assumeno install "$@" 2>&1 >/dev/null)
            sed -n 's/^No match for argument: \(.*\)/\1/p' <<< "$sim" ;;
        zypper)
            sim=$(zypper --non-interactive --dry-run install "$@" 2>&1 >/dev/null)
            sed -n "s/^Package '\([^']*\)' not found.*/\1/p" <<< "$sim" ;;
        apk)
            sim=$(apk add --simulate "$@" 2>&1 >/dev/null)
            sed -n 's/^  \([^ ]*\) (no such package).*/\1/p' <<< "$sim" ;;
        *) return 1 ;;
    esac | sed 's/[<>=].*//' | sed '/^$/d' | sort -u
}

pre_resolve() {
    local mgr=$1 array_name=$2 origin=$3
    local -n _pr="$array_name"
    local -a problematic=() keep=() eligible=() out=()
    local p base resolved=0 dropped=0

    [[ ${translation:-auto} == never ]] && return 0
    [[ -n $origin && $origin != "$mgr" ]] || return 0
    (( ${#_pr[@]} )) || return 0

    local -a names=()
    for p in "${_pr[@]}"; do names+=("${p%%:*}"); done

    _line "Attempting a bulk install with ${mgr}..."
    mapfile -t problematic < <(probe_rejects "$mgr" "${names[@]}")
    if (( ${#problematic[@]} == 0 )); then
        [[ ${verbose:-false} == false && ${_rc_open:-0} == 1 ]] && printf '\033[2A\033[K'
        _rc_open=0
        return 0
    fi

    # Every problematic package leaves the set. Only the ones that come back
    # with a different name are put in again; the rest are recorded as
    # unavailable and are never looked up again this run.
    for p in "${_pr[@]}"; do
        base=${p%%:*}
        if printf '%s\n' "${problematic[@]}" | grep -qxF "$base"; then
            skip_translation "$base" || eligible+=("$base")
        else
            keep+=("$p")
        fi
    done
    _pr=("${keep[@]}")

    if (( ${#eligible[@]} == 0 )); then
        for p in "${problematic[@]}"; do
            printf '%s\n' "${failed[@]}" | grep -qxF "$p" || failed+=("$p")
        done
        [[ ${verbose:-false} == false && ${_rc_open:-0} == 1 ]] && printf '\033[2A\033[K'
        _rc_open=0
        return 0
    fi

    printf 'Unresolved by %s: %s\n' "$mgr" "${eligible[*]}" >> "$output"
    _line "Resolving package names..." spin
    ensure_fetch >/dev/null 2>&1
    resolve_names "$mgr" "${eligible[@]}"

    for p in "${problematic[@]}"; do
        if [[ -n ${XLAT[$p]:-} && ${XLAT[$p]} != "$p" ]]; then
            _pr+=("${XLAT[$p]}"); (( resolved++ ))
        else
            printf '%s\n' "${failed[@]}" | grep -qxF "$p" || { failed+=("$p"); (( dropped++ )); }
        fi
    done

    if (( resolved )); then
        _line "\033[32mSuccessfully resolved ${resolved} package name(s).\033[0m"
    else
        _line "\033[31mNo package names could be resolved.\033[0m"
    fi
    printf 'Resolution for %s: %d renamed, %d unavailable\n' "$mgr" "$resolved" "$dropped" >> "$output"
    sleep 0.6
    if [[ -n ${spinner_pid:-} ]] || (( ${_rc_spin:-0} )); then close_ui; _rc_spin=0
    elif [[ ${verbose:-false} == false ]]; then printf '\033[2A\033[K'; fi
    _rc_open=0
    return 0
}


# The width of the left column is fixed once, from the longest name in the
# left half of the package list, so every grid below it lines up.
GRID_COL=0
_grid_width() {
    local -n _gw="$1"
    local half=$(( (${#_gw[@]} + 1) / 2 )) i longest=""
    for (( i=0; i<half; i++ )); do
        (( ${#_gw[i]} > ${#longest} )) && longest=${_gw[i]}
    done
    printf '%s' $(( ${#longest} + 4 ))
}

failed_grid() {
    local -n _fg="${1:-failed}"
    local -a padding_array=()
    local pkg longest_name="" max_length base_padding=4 current_length total_padding
    local num_failed half_failed i pkg_index second_pkg_index line
    num_failed=${#_fg[@]}
    (( num_failed )) || return 0
    half_failed=$(( (num_failed + 1) / 2 ))
    for pkg in "${_fg[@]}"; do
        (( ${#pkg} > ${#longest_name} )) && longest_name="$pkg"
    done
    max_length=${#longest_name}
    # a width set by an earlier grid wins, so the columns agree down the page
    (( GRID_COL > 0 )) && max_length=$(( GRID_COL - base_padding ))
    for pkg in "${_fg[@]}"; do
        current_length=${#pkg}
        total_padding=$(( base_padding + (max_length - current_length) ))
        padding_array+=("$pkg$(printf '%*s' "$total_padding" '')")
    done
    for (( i=0; i<half_failed; i++ )); do
        pkg_index=$((i + 1))
        if (( pkg_index >= 10 && pkg_index < 100 )); then
            line="[$pkg_index] \033[31m${padding_array[i]}\033[0m"
        else
            line=" [$pkg_index] \033[31m${padding_array[i]}\033[0m"
        fi
        if (( i + half_failed < num_failed )); then
            second_pkg_index=$((i + 1 + half_failed))
            line+=" [$second_pkg_index] \033[31m${padding_array[i + half_failed]}\033[0m"
        fi
        printf '%b\n' "$line"
    done
}

# Get list of all currently installed packages across all managers
# The manifest scans this already. Where it has, the result is reused rather
# than rebuilt: the query is the slowest part of both.
if (( ${PKG_SCAN_DONE:-0} )) && (( ${#all_installed[@]} )); then
    printf 'Using the package list gathered for the manifest\n' >> "$output" 2>/dev/null
else
    for available_manager in "${available_pkg_managers[@]}"; do
        get_installed "$available_manager"
        if [[ -n $installed_pkgs ]]; then
            all_installed+=($installed_pkgs)
        fi
    done
    PKG_SCAN_DONE=1
fi

all_installed=($(printf "%s\n" "${all_installed[@]}" | sort -u))

# Initialize tracking variables before the loop
total=0
any_installs_attempted=false

(( ${#PLANNED_COMPONENTS[@]} )) || true
require_network "download packages"

for array_name in $(compgen -A variable | grep '_packages$'); do
    if [[ -n ${SKIP_MGR[pkg:${array_name%_packages}]:-} ]]; then
        printf 'Skipped by request: %s\n' "${array_name%_packages}" >> "$output"
        continue
    fi
    preferred_manager="${array_name%%_*}"

    # Build filtered array of packages that are not already installed
    eval "
        filtered_array=()
        for pkg in \"\${$array_name[@]}\"; do
            base_pkg=\"\${pkg%%:*}\"
            [[ \"\$base_pkg\" == TotalSize ]] && continue
            skip_translation \"\$base_pkg\" && [[ \"\$preferred_manager\" != \"\$bulk_manager\" ]] && continue
            if ! printf \"%s\n\" \"\${all_installed[@]}\" | grep -qxF \"\$base_pkg\"; then
                filtered_array+=(\"\$pkg\")
            fi
        done
    "
    eval "$array_name=(\"\${filtered_array[@]}\")"
    eval "package_count=\${#$array_name[@]}"
    [[ $package_count -eq 0 ]] && continue
    any_installs_attempted=true
    total=$((total + package_count))
    bulk_manager="$preferred_manager"
    if ! printf '%s\n' "${available_pkg_managers[@]}" | grep -qxF "$preferred_manager"; then
        if [[ ${#available_pkg_managers[@]} -gt 0 ]]; then
            bulk_manager="${available_pkg_managers[0]}"
        else
            bulk_manager=""
        fi
    fi
    if [[ -n "$bulk_manager" ]]; then
        pre_resolve "$bulk_manager" "$array_name" "$preferred_manager"
        fast_install "$bulk_manager" "$preferred_manager" "$array_name" && continue
    fi
    install "$array_name" "$preferred_manager" "${array_name}[@]"
done

if [[ ${#failed[@]} -gt 0 ]]; then
    second_pass_list=("${failed[@]}")
    failed=() 
    type_effect "Revisiting failed packages..." "$menu_delay"; echo
    install "Final_Retry" "all" "second_pass_list[@]"
fi

# Calculate results based on the total gathered during the loop
num_failed=${#failed[@]}
num_successful=$((total - num_failed))

# Calculate success rate (avoid division by zero and negative results)
if (( total > 0 )); then
    # Sanity check: success shouldn't be negative
    (( num_successful < 0 )) && num_successful=0
    success_rate=$((num_successful * 100 / total))
else
    success_rate=100
fi

if [ "$any_installs_attempted" = true ]; then
    type_effect "Package installation success: $success_rate%" "$menu_delay"
    echo
fi

# ─────────────────────────── SERVICES

SVC_ENABLED_LIST=()
SVC_FAILED_LIST=()
SVC_FAIL_DETAIL=()
SVC_STATUS=()
SVC_INIT=""
SVC_READY=0

install_services() {
    (( ${#SERVICES[@]} )) || return 0
    [[ -n ${SKIP_MGR[svc:all]:-} ]] && {
        printf 'Services skipped by request\n' >> "$output"
        return 0
    }

    local entry path size desc execs rest unit name first_exec init
    local total=0 ready=0 created=0 already=0 failed=0 reloaded=0 _svc_cmd="" _svc_gap="" _svc_out=""
    local started=0 deferred=0
    local -a failed_services=()
    SVC_ENABLED_LIST=(); SVC_FAILED_LIST=(); SVC_FAIL_DETAIL=(); SVC_STATUS=(); SVC_READY=0

    _svc_note() { printf '%s\n' "$1" >> "$output"; }

    # The target decides how services are managed, not the machine the
    # configuration came from: a systemd capture may well land on runit.
    _svc_detect() {
        if command -v systemctl >/dev/null 2>&1 && [[ -d /run/systemd/system ]]; then
            printf 'systemd'
        elif command -v rc-update >/dev/null 2>&1; then
            printf 'openrc'
        elif command -v sv >/dev/null 2>&1 && [[ -d /etc/sv || -d /etc/runit ]]; then
            printf 'runit'
        elif command -v dinitctl >/dev/null 2>&1; then
            printf 'dinit'
        elif command -v s6-rc >/dev/null 2>&1; then
            printf 's6'
        elif command -v sysrc >/dev/null 2>&1; then
            printf 'bsd'
        elif command -v update-rc.d >/dev/null 2>&1 || command -v chkconfig >/dev/null 2>&1; then
            printf 'sysv'
        elif command -v systemctl >/dev/null 2>&1; then
            printf 'systemd'
        else
            printf 'none'
        fi
    }

    # The plain service name, whatever shape the source recorded it in.
    # The unit name exactly as systemd knows it. Only a bare name gets the
    # .service suffix; a socket, timer or target already states its type.
    _svc_name() {
        local b=${1##*/}
        printf '%s' "$b"
    }

    _svc_unit() {
        case "$1" in
            *.service|*.socket|*.timer|*.target|*.mount|*.path|*.slice|*.scope|*.automount)
                printf '%s' "$1" ;;
            *)  printf '%s.service' "$1" ;;
        esac
    }

    # The plain name for managers that do not use unit suffixes at all.
    _svc_plain() {
        local b=$1
        b=${b%.service}; b=${b%.socket}; b=${b%.timer}; b=${b%.target}
        b=${b%.mount}; b=${b%.path}; b=${b%.slice}; b=${b%.scope}
        printf '%s' "$b"
    }

    _svc_runit_dir() {
        local d
        for d in /var/service /run/runit/service /etc/runit/runsvdir/default /service; do
            [[ -d $d ]] && { printf '%s' "$d"; return 0; }
        done
        return 1
    }

    _svc_present() {
        local n=$1 p=$2
        case "$init" in
            systemd)
                [[ -e $p ]] && return 0
                systemctl list-unit-files --no-legend "$(_svc_unit "$n")" 2>/dev/null | grep -q . && return 0
                systemctl cat "$(_svc_unit "$n")" >/dev/null 2>&1 ;;
            openrc|sysv) [[ -x /etc/init.d/$n ]] ;;
            runit)       [[ -d /etc/sv/$n ]] ;;
            dinit)       [[ -e /etc/dinit.d/$n ]] ;;
            s6)          [[ -d /etc/s6/sv/$n || -d /etc/s6-rc/source/$n ]] ;;
            bsd)         [[ -x /etc/rc.d/$n || -x /usr/local/etc/rc.d/$n ]] ;;
            *)           return 1 ;;
        esac
    }

    _svc_enabled() {
        local n=$1 state
        case "$init" in
            systemd)
                state=$(systemctl is-enabled "$(_svc_unit "$n")" 2>/dev/null)
                case "$state" in
                    enabled|enabled-runtime|static|alias|indirect|generated) return 0 ;;
                    *) return 1 ;;
                esac ;;
            openrc) rc-update show 2>/dev/null | grep -qE "^[[:space:]]*${n}[[:space:]]" ;;
            runit)  local d; d=$(_svc_runit_dir) || return 1; [[ -e $d/$n ]] ;;
            dinit)  dinitctl list 2>/dev/null | grep -q "$n" ;;
            s6)     s6-rc -a list 2>/dev/null | grep -qx "$n" ;;
            bsd)    [[ $(sysrc -n "${n}_enable" 2>/dev/null) == [Yy][Ee][Ss] ]] ;;
            sysv)   ls /etc/rc[2-5].d/S??"$n" >/dev/null 2>&1 ;;
            *)      return 1 ;;
        esac
    }

    # Only a service the source kept in its own administrative directory is
    # ever written, and only when the program it runs exists here.
    # Everything the recorded command line refers to that this system does
    # not have. A unit usually fails to enable because its program, or the
    # socket or helper it calls, was never installed here.
    _svc_missing_parts() {
        local list=$1 part out=""
        for part in ${list//:/ }; do
            [[ $part == /* ]] || continue
            [[ -e $part ]] && continue
            out+="${out:+, }${part}"
        done
        printf '%s' "$out"
    }

    _svc_can_create() {
        local p=$1 x=$2
        [[ -n $x && -e ${x%% *} ]] || return 1
        case "$init" in
            systemd) [[ $p == /etc/systemd/system/* ]] ;;
            runit)   return 0 ;;
            openrc)  return 0 ;;
            *)       return 1 ;;
        esac
    }

    _svc_create() {
        local n=$1 p=$2 d=$3 x=$4 rd
        case "$init" in
            systemd)
                mkdir -p "${p%/*}" 2>/dev/null || return 1
                {
                    printf '[Unit]\n'
                    printf 'Description=%s\n\n' "${d:-Managed service}"
                    printf '[Service]\nType=simple\n'
                    printf 'ExecStart=%s\n' "$x"
                    printf 'Restart=on-failure\n\n'
                    printf '[Install]\nWantedBy=multi-user.target\n'
                } > "$p" 2>/dev/null || return 1
                chmod 0644 "$p" 2>/dev/null ;;
            runit)
                mkdir -p "/etc/sv/$n" 2>/dev/null || return 1
                {
                    printf '#!/bin/sh\n'
                    printf 'exec 2>&1\n'
                    printf 'exec %s\n' "$x"
                } > "/etc/sv/$n/run" 2>/dev/null || return 1
                chmod 0755 "/etc/sv/$n/run" 2>/dev/null ;;
            openrc)
                {
                    printf '#!/sbin/openrc-run\n'
                    printf 'description="%s"\n' "${d:-Managed service}"
                    printf 'command="%s"\n' "${x%% *}"
                    [[ $x == *' '* ]] && printf 'command_args="%s"\n' "${x#* }"
                    printf 'command_background=true\n'
                    printf 'pidfile="/run/%s.pid"\n' "$n"
                    printf 'depend() {\n    need net\n}\n'
                } > "/etc/init.d/$n" 2>/dev/null || return 1
                chmod 0755 "/etc/init.d/$n" 2>/dev/null ;;
            *) return 1 ;;
        esac
        return 0
    }

    _svc_enable() {
        local n=$1 rd
        case "$init" in
            systemd)
                _svc_out=$(systemctl enable "$(_svc_unit "$n")" 2>&1) ||
                _svc_out=$(systemctl enable --force "$(_svc_unit "$n")" 2>&1)
                printf '%s\n' "$_svc_out" >> "$output" ;;
            openrc) rc-update add "$(_svc_plain "$n")" default >> "$output" 2>&1 ;;
            runit)
                rd=$(_svc_runit_dir) || return 1
                ln -sf "/etc/sv/$(_svc_plain "$n")" "$rd/$(_svc_plain "$n")" >> "$output" 2>&1 ;;
            dinit)  dinitctl enable "$n" >> "$output" 2>&1 ;;
            s6)     s6-rc-bundle-update add default "$n" >> "$output" 2>&1 ;;
            bsd)    sysrc "${n}_enable=YES" >> "$output" 2>&1 ;;
            sysv)
                if command -v update-rc.d >/dev/null 2>&1; then
                    update-rc.d "$n" defaults >> "$output" 2>&1
                else
                    chkconfig "$n" on >> "$output" 2>&1
                fi ;;
            *) return 1 ;;
        esac
    }

    _svc_start() {
        local n=$1
        case "$init" in
            systemd) systemctl start "$(_svc_unit "$n")" >> "$output" 2>&1 ;;
            openrc)  rc-service "$(_svc_plain "$n")" start >> "$output" 2>&1 ;;
            runit)   sv up "$n" >> "$output" 2>&1 ;;
            dinit)   dinitctl start "$n" >> "$output" 2>&1 ;;
            s6)      s6-rc -u change "$n" >> "$output" 2>&1 ;;
            bsd|sysv) service "$n" start >> "$output" 2>&1 ;;
            *) return 1 ;;
        esac
    }

    _svc_active() {
        local n=$1
        case "$init" in
            systemd) systemctl is-active --quiet "$(_svc_unit "$n")" 2>/dev/null ;;
            openrc)  rc-service "$n" status >/dev/null 2>&1 ;;
            runit)   sv status "$n" 2>/dev/null | grep -q '^run' ;;
            *) return 1 ;;
        esac
    }

    _svc_unmask() {
        [[ $init == systemd ]] || return 0
        [[ $(systemctl is-enabled "$(_svc_unit "$1")" 2>/dev/null) == masked ]] || return 0
        systemctl unmask "$(_svc_unit "$1")" >> "$output" 2>&1
        _svc_note "unmasked $1"
    }

    _svc_is_dm() {
        case "$(_svc_plain "$1")" in
            gdm|gdm3|sddm|lightdm|lxdm|ly|greetd|xdm|slim|nodm|emptty|\
            cosmic-greeter|display-manager|entrance|lxqt-sddm|wdm) return 0 ;;
            *) return 1 ;;
        esac
    }

    # Only one service may own the display. If this system already has a
    # different one, it is stood down so the recorded choice takes effect.
    _svc_clear_dm() {
        local want=$1 current
        [[ $init == systemd ]] || return 0
        current=$(basename "$(readlink -f /etc/systemd/system/display-manager.service 2>/dev/null)" 2>/dev/null)
        [[ -n $current ]] || return 0
        [[ $(_svc_plain "$current") != "$(_svc_plain "$want")" ]] || return 0
        systemctl disable "$current" >> "$output" 2>&1
        _svc_note "stood down $current so $want can take the display"
    }

    # Activating these mid-install would take the machine away from the
    # installer, so they are configured now and come up on the next boot.
    _svc_defer_start() {
        _svc_is_dm "$1" && return 0
        # anything that takes the console, the session or the network away
        # from a running installation waits for the next boot
        case "$(_svc_plain "$1")" in
            graphical|graphical.target|multi-user|plymouth-quit|plymouth-quit-wait|\
            plymouth-start|plymouth-read-write|systemd-vconsole-setup|\
            getty@*|serial-getty@*|console-getty|autovt@*) return 0 ;;
        esac
        case "$(_svc_plain "$1")" in
            NetworkManager|systemd-networkd|wpa_supplicant|iwd|dhcpcd|connman|\
            netctl*|*-wait-online|systemd-logind|dbus|dbus-daemon|plymouth*|\
            systemd-resolved|networking|network) return 0 ;;
            *) return 1 ;;
        esac
    }

    init=$(_svc_detect)
    type_effect "Enabling services..." "$menu_delay"; echo
    load_ui

    if [[ $init == none ]]; then
        close_ui
        _svc_note 'no supported service manager was found; nothing was enabled'
        type_effect "\033[33mNo service manager was found; services were not enabled.\033[0m" "$menu_delay"; echo
        return 0
    fi
    SVC_INIT=$init
    _svc_note "service manager on this system: $init"

    for entry in "${SERVICES[@]}"; do
        path=${entry%%:*};  rest=${entry#*:}
        size=${rest%%:*};   rest=${rest#*:}
        desc=${rest%%:*}
        execs=""
        [[ $rest == *:* ]] && execs=${rest#*:}
        first_exec=${execs%%:*}
        name=$(_svc_name "$path")
        [[ -n $name ]] || continue
        (( total++ ))

        if _svc_enabled "$name"; then
            (( already++ )); (( ready++ ))
            SVC_ENABLED_LIST+=("$name"); SVC_STATUS+=("$name|already enabled|")
            _svc_note "$name is already enabled"
            continue
        fi

        if ! _svc_present "$name" "$path"; then
            if _svc_can_create "$path" "${execs//:/ }"; then
                if _svc_create "$name" "$path" "$desc" "${execs//:/ }"; then
                    (( created++ )); reloaded=1
                    _svc_note "wrote a $init service for $name from the recorded description"
                else
                    (( failed++ )); failed_services+=("$name"); SVC_FAILED_LIST+=("$name")
                    SVC_FAIL_DETAIL+=("$name: tried to write a $init definition at $path but the file could not be created")
                    SVC_STATUS+=("$name|not enabled|Could not write a $init definition at $path.")
                    _svc_note "could not write a service definition for $name"
                    continue
                fi
            else
                (( failed++ )); failed_services+=("$name"); SVC_FAILED_LIST+=("$name")
                if [[ -n $first_exec && ! -e $first_exec ]]; then
                    _svc_gap=$(_svc_missing_parts "$execs")
                    SVC_FAIL_DETAIL+=("$name: not installed here; missing ${_svc_gap:-$first_exec}")
                    SVC_STATUS+=("$name|not enabled|Not present on this system, and it cannot be written because ${_svc_gap:-$first_exec} ${_svc_gap:+are}${_svc_gap:-is} not installed.")
                    _svc_note "$name is absent and $first_exec is not on this system"
                else
                    _svc_gap=$(_svc_missing_parts "$execs")
                    SVC_FAIL_DETAIL+=("$name: unit absent; supplied by a package not installed here")
                    if [[ -n $_svc_gap ]]; then
                        SVC_STATUS+=("$name|not enabled|Its unit is not on this system. Missing: ${_svc_gap}.")
                    else
                        SVC_STATUS+=("$name|not enabled|Its unit is supplied by a package that is not installed here.")
                    fi
                    _svc_note "$name is absent; it belongs to a package that is not installed here"
                fi
                continue
            fi
        fi

        (( reloaded )) && {
            [[ $init == systemd ]] && systemctl daemon-reload >> "$output" 2>&1
            reloaded=0
        }

        _svc_unmask "$name"
        _svc_is_dm "$name" && _svc_clear_dm "$name"
        case "$init" in
            systemd) _svc_cmd="systemctl enable $(_svc_unit "$name")" ;;
            openrc)  _svc_cmd="rc-update add $name default" ;;
            runit)   _svc_cmd="a link into the service directory" ;;
            dinit)   _svc_cmd="dinitctl enable $name" ;;
            s6)      _svc_cmd="s6-rc-bundle-update add default $name" ;;
            bsd)     _svc_cmd="sysrc ${name}_enable=YES" ;;
            sysv)    _svc_cmd="update-rc.d $name defaults" ;;
            *)       _svc_cmd="the service manager" ;;
        esac
        _svc_enable "$name"

        if _svc_enabled "$name"; then
            (( ready++ ))
            if _svc_defer_start "$name"; then
                (( deferred++ )); REBOOT_REQUIRED=1
                SVC_ENABLED_LIST+=("$name")
                SVC_STATUS+=("$name|enabled, starts at next boot|Held back from starting now: it would take the display or the network from this installer.")
                _svc_note "enabled $name (starts at next boot)"
            elif _svc_active "$name"; then
                SVC_ENABLED_LIST+=("$name"); SVC_STATUS+=("$name|enabled, already running|")
                _svc_note "enabled $name (already running)"
            elif _svc_start "$name"; then
                (( started++ ))
                SVC_ENABLED_LIST+=("$name"); SVC_STATUS+=("$name|enabled and started|")
                _svc_note "enabled and started $name"
            else
                (( deferred++ )); REBOOT_REQUIRED=1
                SVC_ENABLED_LIST+=("$name")
                SVC_STATUS+=("$name|enabled, will start at boot|Enabled, but starting it now returned an error.")
                _svc_note "enabled $name; it did not start now and will be tried at boot"
            fi
        else
            (( failed++ )); failed_services+=("$name"); SVC_FAILED_LIST+=("$name")
            _svc_gap=$(_svc_missing_parts "$execs")
            SVC_FAIL_DETAIL+=("$name: ran $_svc_cmd; still reported disabled")
            if [[ -n $_svc_gap ]]; then
                SVC_STATUS+=("$name|not enabled|Requires ${_svc_gap}, which ${_svc_gap//, / and } is not installed on this system.")
            elif [[ -n $_svc_out ]]; then
                SVC_STATUS+=("$name|not enabled|${_svc_out%%$'\n'*}")
            else
                SVC_STATUS+=("$name|not enabled|The service manager declined to enable it and gave no reason.")
            fi
            _svc_note "could not enable $name"
        fi
    done

    close_ui
    if (( failed == 0 )); then
        type_effect "\033[32mEnabled $ready of $total service(s).\033[0m" "$menu_delay"; echo
    else
        type_effect "\033[33mEnabled $ready of $total service(s); $failed could not be enabled.\033[0m" "$menu_delay"; echo
    fi
    (( created ))  && _svc_note "created $created service definition(s)"
    (( already ))  && _svc_note "$already were already enabled"
    (( started ))  && _svc_note "started $started now"
    (( deferred )) && _svc_note "$deferred take effect after a restart"
    SVC_READY=$ready
    (( failed ))   && _svc_note "not enabled: ${failed_services[*]}"
    return 0
}

install_services

# ─────────────────────────── SOURCE BUILD

failed_builds=()

source_build() {
    (( ${#REPOS[@]} )) || return 0


    local entry name work rc n=0 step i url keep_dir _t _sb_first=1 failed_step
    local -a steps
    local ACQ_KIND ACQ_URL ACQ_DIR ACQ_FILE ACQ_CMD ACQ_NONE=0
    local -A _sb_tried=()
    local SB_ERR; SB_ERR=$(mktemp)
    local -A _dep_seen=()
    local -a DEP_TOKENS=()

    _sb_note() { printf '%s\n' "$1" >> "$output"; }

    # Entries are colon separated, but a command may contain "https://" or an
    # scp-style "git@host:path". Both are protected before the split.
    _sb_split() {
        local raw=$1 m
        raw=${raw//:\/\//$'\001'}
        # an scp-style remote such as git@github.com:user/repo.git also
        # carries a colon that is not a separator
        while [[ $raw =~ ([A-Za-z0-9_.-]+@[A-Za-z0-9_.-]+): ]]; do
            m=${BASH_REMATCH[0]}
            raw=${raw/"$m"/"${m%:}"$'\002'}
        done
        IFS=':' read -ra steps <<< "$raw"
        for i in "${!steps[@]}"; do
            steps[i]=${steps[i]//$'\001'/://}
            steps[i]=${steps[i]//$'\002'/:}
            steps[i]=${steps[i]#"${steps[i]%%[![:space:]]*}"}
            steps[i]=${steps[i]%"${steps[i]##*[![:space:]]}"}
        done
    }

    # A bare host/path is a common shorthand; an ssh remote needs keys this
    # machine will not have, so it is rewritten to its https equivalent.
    _sb_norm_url() {
        local u=$1
        if [[ $u == git@*:* ]]; then
            u=${u#git@}
            u="https://${u/://}"
        elif [[ $u == ssh://git@* ]]; then
            u="https://${u#ssh://git@}"
        elif [[ $u != *://* && $u == *.*/* ]]; then
            u="https://$u"
        fi
        printf '%s' "$u"
    }

    _sb_name() {
        local u=$1 b seg
        b=${u%%\?*}; b=${b%/}; b=${b##*/}; b=${b%.git}
        b=${b%.tar.gz}; b=${b%.tar.xz}; b=${b%.tar.bz2}; b=${b%.tar.zst}
        b=${b%.tgz}; b=${b%.zip}; b=${b%.tar}
        if [[ $b =~ ^v?[0-9] ]]; then
            local path=${u#*://}; path=${path#*/}
            for seg in ${path//\// }; do
                case "$seg" in
                    archive|refs|tags|releases|download|"") continue ;;
                    v?[0-9]*|[0-9]*) continue ;;
                    *) b=${seg%.git} ;;
                esac
            done
        fi
        b=${b%.git}
        printf '%s' "${b:-source}"
    }

    # Reads the acquisition command and works out what it will actually do:
    # which tool, which address, whether a directory or output name was given.
    _sb_plan() {
        local cmd=$1 tok prev="" seen=0
        ACQ_KIND=""; ACQ_URL=""; ACQ_DIR=""; ACQ_FILE=""; ACQ_CMD=$cmd
        case "$cmd" in
            git\ clone*|git\ -C*clone*) ACQ_KIND=git ;;
            curl*)  ACQ_KIND=curl ;;
            wget*)  ACQ_KIND=wget ;;
            svn\ checkout*|svn\ co*) ACQ_KIND=svn ;;
            hg\ clone*) ACQ_KIND=hg ;;
            *://*)  ACQ_KIND=bare ;;
            *)      ACQ_KIND=other ;;
        esac
        for tok in $cmd; do
            case "$tok" in
                -*) prev=$tok; continue ;;
            esac
            if [[ $prev == -o || $prev == -O || $prev == --output ]]; then
                ACQ_FILE=$tok; prev=""; continue
            fi
            if [[ $tok == *://* || $tok == git@*:* || $tok == *.*/* ]]; then
                [[ -z $ACQ_URL ]] && ACQ_URL=$(_sb_norm_url "$tok")
                seen=1; prev=""; continue
            fi
            # a plain word after the address is the destination directory
            if (( seen )) && [[ $ACQ_KIND == git || $ACQ_KIND == svn || $ACQ_KIND == hg ]]; then
                case "$tok" in clone|checkout|co|git|svn|hg) ;; *) ACQ_DIR=$tok ;; esac
            fi
            prev=""
        done
        [[ -n $ACQ_URL ]] || return 1

        case "$ACQ_KIND" in
            git)
                [[ -n $ACQ_DIR ]] || { ACQ_DIR=${ACQ_URL##*/}; ACQ_DIR=${ACQ_DIR%.git}; }
                ACQ_CMD="git clone"
                [[ $cmd == *--recursive* || $cmd == *--recurse-submodules* ]] &&
                    ACQ_CMD+=" --recurse-submodules"
                [[ $cmd =~ (--depth[[:space:]]+[0-9]+) ]] && ACQ_CMD+=" ${BASH_REMATCH[1]}"
                [[ $cmd =~ (-b|--branch)[[:space:]]+([^[:space:]]+) ]] &&
                    ACQ_CMD+=" --branch ${BASH_REMATCH[2]}"
                ACQ_CMD+=" '$ACQ_URL' '$ACQ_DIR'" ;;
            curl)
                # curl without -O or -o writes the archive to stdout, which
                # silently produces nothing to build
                [[ -n $ACQ_FILE ]] || ACQ_FILE=${ACQ_URL##*/}
                ACQ_FILE=${ACQ_FILE%%\?*}
                ACQ_CMD="curl -fsSL --retry 2 -o '$ACQ_FILE' '$ACQ_URL'" ;;
            wget)
                [[ -n $ACQ_FILE ]] || ACQ_FILE=${ACQ_URL##*/}
                ACQ_FILE=${ACQ_FILE%%\?*}
                ACQ_CMD="wget -q -O '$ACQ_FILE' '$ACQ_URL'" ;;
            bare)
                ACQ_FILE=${ACQ_URL##*/}; ACQ_FILE=${ACQ_FILE%%\?*}
                if [[ $ACQ_URL == *.git ]]; then
                    ACQ_KIND=git
                    ACQ_DIR=${ACQ_FILE%.git}
                    ACQ_CMD="git clone '$ACQ_URL' '$ACQ_DIR'"
                else
                    ACQ_KIND=curl
                    ACQ_CMD="curl -fsSL --retry 2 -o '$ACQ_FILE' '$ACQ_URL'"
                fi ;;
        esac
        return 0
    }

    # ~/ and $HOME in a recorded command refer to the account the command was
    # written on. The installer runs as root, so both are replaced with the
    # target user's home before anything executes.
    _sb_expand_home() {
        local c=$1
        c=${c//\$HOME/$user_home}
        c=${c//\$\{HOME\}/$user_home}
        c=${c//\~\//$user_home/}
        [[ $c == *' ~' ]] && c="${c% ~} $user_home"
        [[ $c == '~' ]] && c=$user_home
        printf '%s' "$c"
    }

    _sb_strip_priv() {
        local c=$1
        # strip the escalation tool and any of its own options
        while [[ $c == sudo\ * || $c == doas\ * || $c == /usr/bin/sudo\ * ]]; do
            c=${c#/usr/bin/}
            c=${c#sudo }; c=${c#doas }
            while [[ $c == -* ]]; do
                [[ $c == -u\ * ]] && { c=${c#-u }; c=${c#* }; continue; }
                c=${c#* }
            done
        done
        printf '%s' "$c"
    }

    # Commands recorded from an interactive session often stop and wait for
    # an answer, which an unattended run can never give.
    _sb_fix_flags() {
        local c=$1
        case "$c" in
            *make\ menuconfig*|*make\ config*|*make\ xconfig*|*make\ nconfig*)
                printf '%s' "SKIP:interactive configuration step"; return ;;
        esac
        [[ $c == apt*install* && $c != *-y* ]] && c="${c/install/install -y}"
        [[ $c == apt-get*install* && $c != *-y* ]] && c="${c/install/install -y}"
        [[ $c == dnf*install* && $c != *-y* ]] && c="${c/install/install -y}"
        [[ $c == pacman*-S* && $c != *--noconfirm* ]] && c="$c --noconfirm"
        [[ $c == pip*install* && $c != *--break-system-packages* ]] &&
            c="$c --break-system-packages"
        [[ $c == npm*install* && $c != *--yes* ]] && c="$c --no-fund --no-audit"
        c=${c/ -i / }
        c=${c/ --interactive/}
        printf '%s' "$c"
    }

    # makepkg refuses outright; the node and rust tools leave root-owned
    # caches in the user's home when run with privilege
    _sb_needs_user() {
        case "$1" in
            makepkg*|*" makepkg "*|yay*|paru*|trizen*|pikaur*) return 0 ;;
            npm\ *|yarn\ *|pnpm\ *) return 0 ;;
            cargo\ install*) return 0 ;;
            *) return 1 ;;
        esac
    }

    # The tool a step needs may not be on this machine at all
    # Which tool a step needs. Nothing is installed here: prerequisites are
    # resolved before the spinner starts, because install_package prints its
    # own lines and drives its own spinner.
    _sb_tools_for() {
        case "$1" in
            make*|*/configure*|*autogen*) printf 'make gcc pkg-config' ;;
            cmake*)   printf 'cmake' ;;
            meson*)   printf 'meson' ;;
            ninja*)   printf 'ninja' ;;
            cargo*)   printf 'cargo' ;;
            go\ *)    printf 'go' ;;
            npm*)     printf 'npm' ;;
            python*setup.py*|pip*) printf 'python3' ;;
        esac
    }

    _sb_ensure_tool() {
        local t=$1
        # a tool is only ever attempted once per run, however many steps ask
        [[ -n ${_sb_tried[$t]:-} ]] && return 0
        _sb_tried[$t]=1
        command -v "$t" >/dev/null 2>&1 && return 0
        case "$t" in
            gcc) install_package base-devel || install_package build-essential ;;
            *)   install_package "$t" ;;
        esac
        return 0
    }

    # Reads a failed step's output and names what the compiler could not find.
    _sb_missing() {
        sed -n -e 's/.*fatal error: \([^:]*\): No such file or directory.*/hdr:\1/p' \
               -e "s/.*fatal error: '\([^']*\)' file not found.*/hdr:\1/p" \
               -e 's/.*error: \([A-Za-z0-9_/.+-]*\.h\): No such file.*/hdr:\1/p' \
               -e "s/.*Package '\([^']*\)' not found.*/pc:\1/p" \
               -e "s/.*No package '\([^']*\)' found.*/pc:\1/p" \
               -e 's/.*Package \([A-Za-z0-9_.+-]*\) was not found in the pkg-config search path.*/pc:\1/p' \
               -e 's/.*Package requirements (\([A-Za-z0-9_.+-]*\)[^)]*) were not met.*/pc:\1/p' \
               -e 's/.*Dependency "\([^"]*\)" not found.*/pc:\1/p' \
               -e 's/.*Could NOT find \([A-Za-z0-9_+-]*\).*/pc:\1/p' \
               -e 's/.*configure: error: "\{0,1\}\([A-Za-z0-9_.+-]*\) not found"\{0,1\}.*/pc:\1/p' \
               -e 's/.*configure: error: \([A-Za-z0-9_.+-]*\) is required.*/pc:\1/p' \
               -e 's/.*checking for \([A-Za-z0-9_.+-]*\)\.\.\. no.*configure: error.*/pc:\1/p' \
               -e 's/.*cannot find -l\([A-Za-z0-9_.+-]*\).*/lib:\1/p' \
               -e 's/^\([a-zA-Z0-9_.+-]*\): command not found.*/cmd:\1/p' \
               -e 's/.*: \([a-zA-Z0-9_.+-]*\): not found.*/cmd:\1/p' \
               -e 's/.*\([a-zA-Z0-9_.+-]*\): command not found.*/cmd:\1/p' \
               -e 's/.*: \([a-zA-Z0-9_.+-]*\): command not found.*/cmd:\1/p' \
               "$1" 2>/dev/null | sed "s/'//g" | sort -u
    }

    # Candidate package names for a missing dependency. Development headers
    # are named differently on every distribution, so several spellings are
    # offered and the first that installs wins.
    # The library behind a missing header or module, in its plain form.
    _sb_base_for() {
        local t=$1
        local kind=${t%%:*}
        local name=${t#*:}
        case "$kind" in
            hdr)
                case "$name" in
                    X11/Xft/*|*/Xft*)          printf 'libxft' ;;
                    X11/extensions/Xrandr*)    printf 'libxrandr' ;;
                    X11/extensions/Xinerama*)  printf 'libxinerama' ;;
                    X11/extensions/*)          printf 'libxext' ;;
                    X11/*)                     printf 'libx11' ;;
                    ft2build.h|freetype*/*)    printf 'freetype2' ;;
                    fontconfig/*)              printf 'fontconfig' ;;
                    zlib.h)                    printf 'zlib' ;;
                    openssl/*)                 printf 'openssl' ;;
                    curl/*)                    printf 'curl' ;;
                    ncurses*|curses.h)         printf 'ncurses' ;;
                    pango/*)                   printf 'pango' ;;
                    cairo*)                    printf 'cairo' ;;
                    gtk*/*)                    printf 'gtk3' ;;
                    wayland*)                  printf 'wayland' ;;
                    glib.h|glib/*|glib-object.h) printf 'glib2' ;;
                    *) name=${name%%/*}; name=${name%.h}; name=${name%.hpp}
                       printf '%s' "$name" ;;
                esac ;;
            pc|lib)
                [[ $kind == lib ]] && name=lib${name}
                # a module name is rarely the library's own name
                case "${name,,}" in
                    xft|libxft)             printf 'libxft' ;;
                    x11|libx11)             printf 'libx11' ;;
                    xinerama|libxinerama)   printf 'libxinerama' ;;
                    xrandr|libxrandr)       printf 'libxrandr' ;;
                    xext|libxext)           printf 'libxext' ;;
                    xrender|libxrender)     printf 'libxrender' ;;
                    xcb|libxcb)             printf 'libxcb' ;;
                    curses|ncurses|ncursesw|tinfo|termcap|libncurses*|libtinfo)
                                            printf 'ncurses' ;;
                    ssl|crypto|libssl|libcrypto|openssl) printf 'openssl' ;;
                    z|libz|zlib)            printf 'zlib' ;;
                    event|libevent|libevent_core) printf 'libevent' ;;
                    pcre2*|libpcre2*)       printf 'pcre2' ;;
                    sqlite3|libsqlite3)     printf 'sqlite' ;;
                    gtk+-3.0|gtk3)          printf 'gtk3' ;;
                    gtk+-2.0)               printf 'gtk2' ;;
                    freetype2|libfreetype)  printf 'freetype2' ;;
                    fontconfig|libfontconfig) printf 'fontconfig' ;;
                    jpeg|libjpeg)           printf 'libjpeg-turbo' ;;
                    png|libpng)             printf 'libpng' ;;
                    gl|libgl|opengl)        printf 'mesa' ;;
                    udev|libudev)           printf 'systemd' ;;
                    glib-2.0|glib|libglib*|gio-2.0|gobject-2.0) printf 'glib2' ;;
                    *)                      printf '%s' "${name,,}" ;;
                esac ;;
            cmd) printf '%s' "$name" ;;
        esac
    }

    # Distributions spell development files differently. The form this system
    # uses is tried first, so the common case installs on the first attempt.
    # The package that provides a build tool. These are programs, so the
    # development spellings below never apply to them.
    _sb_tool_pkg() {
        case "$1" in
            autoreconf|autoconf|autoheader|autom4te) printf 'autoconf' ;;
            automake|aclocal)      printf 'automake' ;;
            libtool|libtoolize)    printf 'libtool' ;;
            cmake)                 printf 'cmake' ;;
            ninja)                 printf 'ninja-build ninja' ;;
            meson)                 printf 'meson' ;;
            pkg-config|pkgconf)    printf 'pkg-config pkgconf' ;;
            msgfmt|xgettext)       printf 'gettext' ;;
            makeinfo)              printf 'texinfo' ;;
            gperf)                 printf 'gperf' ;;
            bison|yacc)            printf 'bison' ;;
            flex|lex)              printf 'flex' ;;
            gcc|cc|c99)            printf 'gcc build-essential base-devel' ;;
            g++|c++)               printf 'g++ gcc' ;;
            rustc|cargo)           printf 'rust cargo' ;;
            go)                    printf 'golang go' ;;
            python3|python)        printf 'python3 python' ;;
            unzip)                 printf 'unzip' ;;
            *)                     printf '%s' "$1" ;;
        esac
    }

    _sb_pkg_for() {
        local base
        # a missing program is installed by name, not as a header package
        if [[ $1 == cmd:* ]]; then
            _sb_tool_pkg "${1#cmd:}"
            return 0
        fi
        base=$(_sb_base_for "$1")
        [[ -n $base ]] || return 0
        local stem=${base#lib}
        local trimmed=$base
        # gcr-3, webkit2gtk-4.1 and friends carry an API version that the
        # package name usually leaves out
        [[ $base =~ ^(.*[a-zA-Z])-[0-9][0-9.]*$ ]] && trimmed=${BASH_REMATCH[1]}
        local out
        case "${available_pkg_managers[0]:-}" in
            pacman|yay|paru|trizen|pikaur|aurman|pacaur|aura|pakku)
                out="$base $trimmed $stem" ;;
            apt|dpkg)
                out="$base-dev lib$stem-dev $trimmed-dev $base" ;;
            dnf|yum|zypper)
                out="$base-devel lib$stem-devel $trimmed-devel $base" ;;
            apk)
                out="$base-dev $trimmed-dev $base" ;;
            *)
                out="$base $trimmed $base-dev $base-devel" ;;
        esac
        # the same spelling twice is two identical failures
        printf '%s' "$out" | tr ' ' '\n' | awk 'NF && !seen[$0]++' | tr '\n' ' '
    }

    # Installs whatever a failed step said was missing. Returns 0 when at
    # least one package went in, so the step is worth retrying.
    # Works out what is missing and asks the resolver about the whole set.
    # Returns 0 when there is something new to install.
    # A build step that calls git in a directory the payload delivered will
    # find no repository there: the metadata is deliberately not carried.
    # Creating an empty one satisfies the call without changing the sources.
    _sb_fix_repo() {
        grep -q 'not a git repository' "$SB_ERR" 2>/dev/null || return 1
        command -v git >/dev/null 2>&1 || return 1
        [[ -e .git ]] && return 1
        git init -q . >> "$output" 2>&1 || return 1
        git -c user.name=installer -c user.email=installer@localhost \
            add -A -f >> "$output" 2>&1
        git -c user.name=installer -c user.email=installer@localhost \
            commit -qm "payload" >> "$output" 2>&1
        _sb_note "created a repository in ${PWD} for a build step that expects one"
        return 0
    }

    _sb_plan_deps() {
        local errfile=$1 token base
        local -a tokens=() bases=()
        DEP_TOKENS=()
        mapfile -t tokens < <(_sb_missing "$errfile")
        for token in "${tokens[@]}"; do
            [[ -n ${_dep_seen[$token]:-} ]] && continue
            _dep_seen[$token]=1
            DEP_TOKENS+=("$token")
            _sb_note "missing: $token"
            base=$(_sb_base_for "$token")
            [[ -n $base ]] && bases+=("$base")
        done
        (( ${#DEP_TOKENS[@]} )) || return 1
        if (( ${#bases[@]} )) && declare -F resolve_names >/dev/null 2>&1; then
            resolve_names "${available_pkg_managers[0]:-}" "${bases[@]}" >/dev/null 2>&1
        fi
        return 0
    }

    # Installs what _sb_plan_deps found. Nothing is computed here, so the
    # screen is handed straight to install_package.
    _sb_install_deps() {
        local token cand base placed got=1
        for token in "${DEP_TOKENS[@]}"; do
            placed=0
            base=$(_sb_base_for "$token")
            for cand in $(_sb_pkg_for "$token"); do
                if command -v "$cand" >/dev/null 2>&1; then placed=1; got=0; break; fi
                if install_package "$cand"; then
                    _sb_note "supplied $token with $cand"
                    placed=1; got=0
                    break
                fi
            done
            if (( ! placed )) && [[ -n ${XLAT[$base]:-} ]]; then
                if install_package "${XLAT[$base]}"; then
                    _sb_note "supplied $token with ${XLAT[$base]} (resolved)"
                    got=0
                else
                    _sb_note "could not supply $token"
                fi
            elif (( ! placed )); then
                _sb_note "could not supply $token"
            fi
        done
        return $got
    }

    _sb_supply() {
        local errfile=$1 token cand got=1 placed base mgr
        local -a tokens=() bases=() fresh=()
        mgr=${available_pkg_managers[0]:-}

        mapfile -t tokens < <(_sb_missing "$errfile")
        # a dependency already attempted is not attempted again, which is what
        # makes it safe to keep asking the compiler what else it needs
        for token in "${tokens[@]}"; do
            [[ -n ${_dep_seen[$token]:-} ]] && continue
            _dep_seen[$token]=1
            fresh+=("$token")
        done
        tokens=("${fresh[@]}")
        (( ${#tokens[@]} )) || return 1
        for token in "${tokens[@]}"; do
            base=$(_sb_base_for "$token")
            [[ -n $base ]] && bases+=("$base")
            _sb_note "missing: $token"
        done

        # ask the resolver about the whole set at once, the same way the
        # package stage does, so a name this system does not use is corrected
        # before anything is attempted
        if (( ${#bases[@]} )) && declare -F resolve_names >/dev/null 2>&1; then
            resolve_names "$mgr" "${bases[@]}" >/dev/null 2>&1
        fi

        for token in "${tokens[@]}"; do
            placed=0
            base=$(_sb_base_for "$token")
            for cand in $(_sb_pkg_for "$token"); do
                if command -v "$cand" >/dev/null 2>&1; then placed=1; got=0; break; fi
                if install_package "$cand"; then
                    _sb_note "supplied $token with $cand"
                    placed=1; got=0
                    break
                fi
            done
            if (( ! placed )) && [[ -n ${XLAT[$base]:-} ]]; then
                if install_package "${XLAT[$base]}"; then
                    _sb_note "supplied $token with ${XLAT[$base]} (resolved)"
                    got=0
                else
                    _sb_note "could not supply $token"
                fi
            elif (( ! placed )); then
                _sb_note "could not supply $token"
            fi
        done
        return $got
    }

    _sb_run() {
        local c=$1 rc=0
        : > "$SB_ERR"
        if _sb_needs_user "$c" && [[ -n ${user:-} && $(id -un) != "$user" ]]; then
            _sb_note "+ (as $user) $c"
            chown -R "$user" . 2>/dev/null
            sudo -u "$user" env HOME="$user_home" bash -c "$c" > "$SB_ERR" 2>&1 || rc=$?
        else
            _sb_note "+ $c"
            bash -c "$c" > "$SB_ERR" 2>&1 || rc=$?
        fi
        cat "$SB_ERR" >> "$output" 2>/dev/null
        return $rc
    }

    _sb_unpack() {
        local f found="" ok
        shopt -s nullglob
        for f in *.tar.gz *.tgz *.tar.xz *.tar.bz2 *.tar.zst *.tar *.zip; do
            [[ -f $f ]] || continue
            found=$f; ok=1
            case "$f" in
                *.zip)
                    if command -v unzip >/dev/null 2>&1; then
                        _sb_run "unzip -q -o '$f'" || ok=0
                    elif command -v bsdtar >/dev/null 2>&1; then
                        _sb_run "bsdtar -xf '$f'" || ok=0
                    elif command -v python3 >/dev/null 2>&1; then
                        _sb_run "python3 -m zipfile -e '$f' ." || ok=0
                    else
                        _sb_note "no tool available to unpack '$f'"; ok=0
                    fi ;;
                *)  _sb_run "tar -xf '$f'" || ok=0 ;;
            esac
            # an archive that could not be unpacked is left where it is, so
            # the failure is visible rather than hidden behind a missing file
            (( ok )) && rm -f "$f"
        done
        shopt -u nullglob
        [[ -n $found ]]
    }

    _sb_descend() {
        local d count
        count=$(find . -maxdepth 1 -mindepth 1 -type d ! -name '.*' 2>/dev/null | wc -l)
        if (( count == 1 )); then
            d=$(find . -maxdepth 1 -mindepth 1 -type d ! -name '.*' 2>/dev/null)
            cd "$d" 2>/dev/null && _sb_note "working in ${PWD}"
        fi
    }

    # A tree may need a configure pass the recorded commands never mention
    _sb_bootstrap() {
        local first=$1
        [[ $first == make* ]] || return 0
        [[ -f Makefile || -f makefile || -f GNUmakefile ]] && return 0
        if [[ -x ./autogen.sh ]]; then
            _sb_run "./autogen.sh" && _sb_note "ran autogen.sh (no Makefile was present)"
        fi
        if [[ ! -f Makefile && -x ./configure ]]; then
            _sb_run "./configure" && _sb_note "ran ./configure (no Makefile was present)"
        fi
        [[ -f Makefile || -f makefile || -f GNUmakefile ]]
    }

    require_network "retrieve sources"
    _sb_note ""
    _sb_note "─── Source builds: ${#REPOS[@]} package(s)"

    local _idx=-1
    for entry in "${REPOS[@]}"; do
        _idx=$(( _idx + 1 ))
        # an entry turned off in the manifest is not built
        if [[ -n ${SKIP_MGR[src:$_idx]:-} ]]; then
            _sb_note "skipped by request: $entry"
            continue
        fi
        _sb_split "$entry"
        (( ${#steps[@]} )) || continue
        (( n++ ))

        # nothing may be on screen from the previous entry when this one
        # announces itself
        [[ -n ${spinner_pid:-} ]] && close_ui

        # An entry does not have to fetch anything. Where the first step is
        # not an acquisition the whole entry is a sequence of commands, run
        # in order from the user's home directory.
        # Whether the first step fetches anything is decided here rather than
        # by the parser, which will read almost any bare word as a hostname.
        ACQ_NONE=0
        _t=$(_sb_expand_home "$(_sb_strip_priv "${steps[0]}")")
        case "${_t%% *}" in
            git|curl|wget|fetch|svn|hg|rsync|scp|ftp) ;;
            *) [[ $_t == *://* ]] || ACQ_NONE=1 ;;
        esac
        if (( ACQ_NONE )) || ! _sb_plan "$_t"; then
            ACQ_NONE=1
            ACQ_CMD=""; ACQ_DIR=""; ACQ_FILE=""; ACQ_KIND=none
            ACQ_URL=""
            name=$(_sb_name "${steps[0]}")
            [[ -n $name ]] || name="step ${n}"
        else
            name=$(_sb_name "$ACQ_URL")
        fi

        # anything that prints or spins on its own runs before the title, so
        # an entry never announces itself and then interrupts with a package
        # install of its own
        case "$ACQ_KIND" in
            none) : ;;
            git)  _sb_ensure_tool git ;;
            curl) _sb_ensure_tool curl ;;
            wget) _sb_ensure_tool wget ;;
        esac
        [[ ${ACQ_FILE:-} == *.zip ]] && _sb_ensure_tool unzip
        for (( i=1; i<${#steps[@]}; i++ )); do
            for _t in $(_sb_tools_for "$(_sb_strip_priv "${steps[i]}")"); do
                _sb_ensure_tool "$_t"
            done
        done

        printf '[%d] \033[1m%s\033[0m\n' "$n" "$name"
        [[ -n ${spinner_pid:-} ]] && close_ui
        if (( ACQ_NONE )); then
            type_effect "Preparing $name..." "$menu_delay"; echo
        else
            type_effect "Retrieving $name..." "$menu_delay"; echo
        fi
        load_ui

        work=$(mktemp -d) || { close_ui; continue; }
        # A sequence of plain commands runs from the user's home, which is what
        # a relative path in it refers to. Anything fetched gets its own tree.
        if (( ACQ_NONE )); then
            pushd "$user_home" >/dev/null 2>&1 || { close_ui; continue; }
        else
            pushd "$work" >/dev/null 2>&1 || { close_ui; continue; }
        fi
        _sb_note ""
        _sb_note "─── [$n] $name  (${ACQ_KIND})"
        _sb_note "parsed ${#steps[@]} step(s) from: $entry"
        for (( i=0; i<${#steps[@]}; i++ )); do
            _sb_note "  step[$i]: ${steps[i]}"
        done

        # A destination the user named is theirs: it is used where it is and
        # left in place afterwards. Anything we create ourselves lives in the
        # temporary tree and is removed when the build finishes.
        keep_dir=""
        if [[ $ACQ_KIND == git && $ACQ_DIR == /* ]]; then
            keep_dir=$ACQ_DIR
            if [[ -d $ACQ_DIR/.git ]]; then
                _sb_note "reusing the existing checkout at $ACQ_DIR"
                ACQ_CMD="git -C '$ACQ_DIR' pull --ff-only"
            elif [[ -e $ACQ_DIR && -n $(ls -A "$ACQ_DIR" 2>/dev/null) ]]; then
                _sb_note "$ACQ_DIR exists and is not a checkout; building in a temporary tree"
                ACQ_DIR=${ACQ_URL##*/}; ACQ_DIR=${ACQ_DIR%.git}
                ACQ_CMD="git clone '$ACQ_URL' '$ACQ_DIR'"
                keep_dir=""
            fi
        fi

        rc=0
        _sb_run "$ACQ_CMD" || rc=$?
        if (( rc )); then
            popd >/dev/null 2>&1; rm -rf "$work"
            _sb_note "removed the temporary build tree"
            close_ui
            failed_builds+=("$name")
            [[ -n ${spinner_pid:-} ]] && close_ui
            type_effect "\033[31mCould not retrieve $name.\033[0m" "$menu_delay"; echo; echo
            continue
        fi

        _sb_unpack
        if [[ -n $ACQ_DIR && -d $ACQ_DIR ]]; then
            cd "$ACQ_DIR" && _sb_note "working in ${PWD}"
        else
            _sb_descend
        fi

        # close_ui returns to the task line and clears it, so a message must
        # always follow. Without one the line is left blank while the build
        # runs, and load_ui then records a row two lines above the one every
        # later close_ui expects to return to.
        close_ui
        type_effect "Building $name..." "$menu_delay"; echo
        load_ui

        local ran=0 failed_step="" _ar="" _plan_rc=0
        _sb_note "build directory: ${PWD}"
        _sb_note "directory contains: $(ls -A 2>/dev/null | head -8 | tr '\n' ' ')"
        # with nothing fetched, the first step is a command like any other
        _sb_first=1; (( ACQ_NONE )) && _sb_first=0
        for (( i=_sb_first; i<${#steps[@]}; i++ )); do
            step=$(_sb_expand_home "$(_sb_strip_priv "${steps[i]}")")
            [[ -n $step ]] || continue
            if [[ $step == cd\ * ]]; then
                local d=${step#cd }; d=${d%/}
                if [[ -d $d ]]; then cd "$d" && _sb_note "working in ${PWD}"
                else _sb_note "skipped '$step': no such directory from ${PWD}"; fi
                continue
            fi
            # the archive was already unpacked before the build steps ran, so
            # a recorded extraction has nothing left to open
            case "$step" in
                tar\ *|unzip\ *|bsdtar\ *)
                    _ar=$(printf '%s\n' $step | grep -E '[.](tar([.][a-z0-9]+)?|tgz|zip)$' | head -1)
                    if [[ -n $_ar && ! -f $_ar ]]; then
                        _sb_note "skipped '$step': $_ar is already unpacked"
                        continue
                    fi ;;
            esac
            step=$(_sb_fix_flags "$step")
            if [[ $step == SKIP:* ]]; then
                _sb_note "skipped: ${step#SKIP:}"
                continue
            fi
            # a recorded configure pass may not exist in a release tarball
            # that already ships a Makefile: running it would fail for a step
            # the tree does not need
            if [[ $step == ./* ]]; then
                local _script=${step%% *}
                # archives frequently lose the executable bit
                if [[ -f $_script && ! -x $_script ]]; then
                    chmod +x "$_script" 2>/dev/null &&
                        _sb_note "made ${_script} executable"
                fi
                if [[ ! -x $_script ]]; then
                    if [[ -f Makefile || -f makefile || -f GNUmakefile ]]; then
                        _sb_note "skipped '$step': not present, and a Makefile already exists"
                        continue
                    fi
                    _sb_note "skipped '$step': not present in this tree"
                    continue
                fi
            fi
            (( ran )) || _sb_bootstrap "$step"
            ran=1
            # $? after a negation is the negation's status, not the command's
            _sb_run "$step"
            rc=$?
            # A compiler stops at the first header it cannot find, so the
            # next one only appears after the first is supplied. Keep going
            # while each round supplies something new.
            local _round=0
            while (( rc != 0 && _round < 6 )); do
                close_ui
                # say what is happening before the work starts, then turn the
                # bar back on: reading the error output and resolving names
                # can take a moment and the line must not sit still
                [[ -n ${spinner_pid:-} ]] && close_ui
                type_effect "Examining why $name failed..." "$menu_delay"; echo
                load_ui
                if _sb_fix_repo; then
                    _plan_rc=0
                    _sb_note "retrying with a repository in place"
                else
                    _sb_plan_deps "$SB_ERR"
                    _plan_rc=$?
                fi
                # the bar is stopped before anything touches the screen
                close_ui
                if (( _plan_rc != 0 )); then
                    _sb_note "nothing further can be supplied"
                    # close_ui has already returned the cursor to the notice
                    # line and cleared it; moving again would climb past the
                    # title, which is what pushed the result out of place
                    break
                fi
                # close_ui leaves the cursor on the notice line. That one line
                # is cleared and the next message takes its place: the title
                # above it is still on screen and does not need reprinting.
                [[ ${verbose:-false} == false ]] && printf '\033[2K\r'
                if (( ${#DEP_TOKENS[@]} )); then
                    type_effect "Installing build dependencies for $name..." "$menu_delay"; echo
                    _sb_install_deps || { _sb_note "no dependency could be installed"; break; }
                    [[ ${verbose:-false} == false ]] && printf '\033[2K\r\033[1A\033[2K\r'
                fi
                (( _round++ ))
                [[ -n ${spinner_pid:-} ]] && close_ui
                type_effect "Building $name..." "$menu_delay"; echo
                load_ui
                _sb_run "$step"
                rc=$?
            done

            if (( rc != 0 )); then
                failed_step=$step
                _sb_note "step failed with status $rc: $step"
                break
            fi
        done

        popd >/dev/null 2>&1
        rm -rf "$work"
        if [[ -n $keep_dir ]]; then
            _sb_note "left in place at $keep_dir (a destination you specified)"
        else
            _sb_note "removed the temporary build tree"
        fi
        close_ui
        if (( rc == 0 )) && (( ran )); then
            [[ -n ${spinner_pid:-} ]] && close_ui
            type_effect "\033[32mBuilt and installed $name.\033[0m" "$menu_delay"; echo
        elif (( rc == 0 )); then
            [[ -n ${spinner_pid:-} ]] && close_ui
            type_effect "\033[33mRetrieved $name, but no build step was recorded.\033[0m" "$menu_delay"; echo
            failed_builds+=("$name")
        else
            [[ -n ${spinner_pid:-} ]] && close_ui
            type_effect "\033[33mRetrieved $name, but ${failed_step:-the build step} failed.\033[0m" "$menu_delay"; echo
            failed_builds+=("$name")
        fi
    done

    rm -f "$SB_ERR"
    (( ${#failed_builds[@]} )) && _sb_note "Source builds not completed: ${failed_builds[*]}"

    # a package that was fetched but would not build has not been installed,
    # so it counts against the figure the end screen reports
    local _t=$(( ${total:-0} + ${ext_attempted:-0} + ${#REPOS[@]} ))
    local _f=$(( ${num_failed:-0} + ${#failed_extensions[@]} + ${#failed_builds[@]} ))
    if (( _t > 0 )); then
        local _ok=$(( _t - _f )); (( _ok < 0 )) && _ok=0
        success_rate=$(( _ok * 100 / _t ))
    else
        success_rate=100
    fi
    return 0
}

source_build

# ─────────────────────────── LOGIN SHELL

SHELL_STATUS=""
SHELL_DETAIL=""

configure_shell() {
    # a name captured from $SHELL can carry stray whitespace
    source_shell=${source_shell//[[:space:]]/}
    [[ -n ${source_shell:-} ]] || return 0
    [[ -n ${SKIP_MGR[shell:set]:-} ]] && {
        printf 'login shell left unchanged by request\n' >> "$output"
        return 0
    }
    # the account being configured, not the account that launched this
    local now=""
    now=$(getent passwd "$user" 2>/dev/null | cut -d: -f7)
    [[ -z $now ]] && now=$(awk -F: -v u="$user" '$1==u{print $7}' /etc/passwd 2>/dev/null)
    now=${now##*/}
    [[ -z $now ]] && { declare -F get_shell >/dev/null 2>&1 && get_shell; now=${shell:-}; }
    now=${now//[[:space:]]/}
    [[ $now == "$source_shell" ]] && {
        printf 'login shell already %s\n' "$source_shell" >> "$output"
        return 0
    }

    [[ -n ${spinner_pid:-} ]] && close_ui
    type_effect "Setting the login shell to ${source_shell}..." "$menu_delay"; echo
    load_ui

    # The shell has to exist before an account can be pointed at it.
    local path
    path=$(command -v "$source_shell" 2>/dev/null)
    if [[ -z $path ]]; then
        [[ -n ${spinner_pid:-} ]] && close_ui
        install_package "$source_shell"
        path=$(command -v "$source_shell" 2>/dev/null)
        type_effect "Setting the login shell to ${source_shell}..." "$menu_delay"; echo
        load_ui
    fi
    if [[ -z $path ]]; then
        [[ -n ${spinner_pid:-} ]] && close_ui
        SHELL_STATUS="not changed"
        SHELL_DETAIL="${source_shell} is not installed on this system and could not be installed."
        printf '%s\n' "$SHELL_DETAIL" >> "$output"
        type_effect "\033[33mThe login shell was left as ${now}.\033[0m" "$menu_delay"; echo
        return 0
    fi

    # chsh refuses a shell that is not listed as a valid one.
    if [[ -w /etc/shells || ! -e /etc/shells ]] &&
       ! grep -qxF "$path" /etc/shells 2>/dev/null; then
        printf '%s\n' "$path" >> /etc/shells 2>/dev/null &&
            printf 'listed %s in /etc/shells\n' "$path" >> "$output"
    fi

    local ok=0
    chsh -s "$path" "$user" >> "$output" 2>&1 && ok=1
    (( ok )) || { usermod -s "$path" "$user" >> "$output" 2>&1 && ok=1; }

    # what the account actually says now, rather than what the tool returned
    local current
    current=$(getent passwd "$user" 2>/dev/null | cut -d: -f7)
    [[ -z $current ]] && current=$(awk -F: -v u="$user" '$1==u{print $7}' /etc/passwd 2>/dev/null)

    [[ -n ${spinner_pid:-} ]] && close_ui
    if [[ $current == "$path" ]]; then
        SHELL_STATUS="changed"
        SHELL_DETAIL="${user} now logs in with ${path}, replacing ${now}. It takes effect at the next sign-in."
        REBOOT_REQUIRED=1
        printf '%s\n' "$SHELL_DETAIL" >> "$output"
        type_effect "\033[32mLogin shell set to ${source_shell}.\033[0m" "$menu_delay"; echo
    else
        SHELL_STATUS="not changed"
        SHELL_DETAIL="chsh and usermod both ran, but ${user} still logs in with ${current:-an unknown shell}."
        printf '%s\n' "$SHELL_DETAIL" >> "$output"
        type_effect "\033[33mThe login shell could not be changed.\033[0m" "$menu_delay"; echo
    fi
    return 0
}

configure_shell

# ─────────────────────────── DISPLAY SERVER

X11_ACTIONS=()
X11_RETARGETED=()
X11_FIXED=0
X11_NO_ACCEL=0

configure_display() {
    local _fixed=0 _notes=0
    X11_ACTIONS=()

    _x_note() { printf '%s\n' "$1" >> "$output"; }
    _x_act()  { X11_ACTIONS+=("$1"); _x_note "$1"; (( _fixed++ )); }

    # Replaces the task line with a new one. The bar is stopped first, always:
    # install_package prints and spins on its own, and two of them at once is
    # what scatters text across the screen.
    # Replaces the task line with the next one. close_ui returns the cursor to
    # that line, so this only holds while nothing else has written since.
    _x_step() {
        if [[ -n ${spinner_pid:-} ]]; then
            close_ui
        fi
        [[ -n ${spinner_pid:-} ]] && close_ui
        type_effect "$1" "$menu_delay"; echo
        load_ui
    }

    # install_package owns the screen while it runs and leaves the cursor
    # several lines further down. The bar is therefore stopped before it and
    # is NOT restarted afterwards: the next step prints on a fresh line and
    # starts its own, which is the only way the arithmetic stays true.
    _x_install() {
        [[ -n ${spinner_pid:-} ]] && close_ui
        spinner_pid=""
        install_package "$1"
    }

    # The configuration was written against one output name and one screen
    # size. Both are recorded in the payload and both are wrong here. Rather
    # than guessing which programs care, every file this installer placed is
    # searched for those two tokens: the manifest already names them, so the
    # search is bounded and exact.
    _x_retarget() {
        local from_out=$1 to_out=$2 from_res=$3 to_res=$4
        [[ -n $to_out || -n $to_res ]] || return 0
        local entry path full files=0 touched sz

        for entry in "${FILES[@]}"; do
            path=${entry%%:*}
            [[ -n $path ]] || continue
            case "$path" in
                /*) full=$path ;;
                *)  full=$user_home/$path ;;
            esac
            [[ -f $full ]] || continue
            sz=$(stat -c %s "$full" 2>/dev/null || echo 0)
            (( sz > 2000000 )) && continue
            grep -Iq . "$full" 2>/dev/null || continue

            touched=0
            if [[ -n $from_out && -n $to_out && $from_out != "$to_out" ]] &&
               grep -qF "$from_out" "$full" 2>/dev/null; then
                sed -i "s/${from_out}/${to_out}/g" "$full" 2>/dev/null && touched=1
            fi
            if [[ -n $from_res && -n $to_res && $from_res != "$to_res" ]] &&
               grep -qF "$from_res" "$full" 2>/dev/null; then
                sed -i "s/${from_res}/${to_res}/g" "$full" 2>/dev/null && touched=1
            fi
            if (( touched )); then
                chown "$user" "$full" 2>/dev/null
                files=$(( files + 1 ))
                X11_RETARGETED+=("$full")
                _x_note "retargeted ${full}"
            fi
        done

        (( files )) && _x_act "updated ${files} file(s) that named the source machine's display"
        return 0
    }

    # A handful of settings mean "ask the graphics card to do this". On a
    # virtual card with no acceleration they do not fail loudly; they leave
    # the screen holding its first frame. These are matched by setting name,
    # not by application, so any program using the same keys is covered.
    _x_soften() {
        local entry path full files=0 sz tmpf
        tmpf=$(mktemp) || return 0
        for entry in "${FILES[@]}"; do
            path=${entry%%:*}
            [[ -n $path ]] || continue
            case "$path" in
                /*) full=$path ;;
                *)  full=$user_home/$path ;;
            esac
            [[ -f $full ]] || continue
            sz=$(stat -c %s "$full" 2>/dev/null || echo 0)
            (( sz > 512000 )) && continue
            grep -Iq . "$full" 2>/dev/null || continue
            grep -Eqi '^[[:space:]]*(vsync|use-damage|backend)[[:space:]]*[:=]' \
                 "$full" 2>/dev/null || continue

            cp -a "$full" "$tmpf" 2>/dev/null || continue
            # waiting on a refresh signal the host never sends
            sed -i -E 's/^([[:space:]]*vsync[[:space:]]*[:=][[:space:]]*)"?(true|opengl[a-z-]*|drm)"?([[:space:]]*;?)$/\1false\3/I' "$tmpf" 2>/dev/null
            # repainting only what changed, from a buffer that reports it wrongly
            sed -i -E 's/^([[:space:]]*use-damage[[:space:]]*[:=][[:space:]]*)"?true"?([[:space:]]*;?)$/\1false\2/I' "$tmpf" 2>/dev/null
            # asking the card to composite when nothing is behind it
            sed -i -E 's/^([[:space:]]*backend[[:space:]]*[:=][[:space:]]*)"?(glx|egl)"?([[:space:]]*;?)$/\1"xrender"\3/I' "$tmpf" 2>/dev/null

            # only a file that actually differs is written back
            if ! cmp -s "$full" "$tmpf"; then
                cat "$tmpf" > "$full" 2>/dev/null && {
                    chown "$user" "$full" 2>/dev/null
                    files=$(( files + 1 ))
                    _x_note "softened GPU-dependent settings in ${full}"
                }
            fi
        done
        rm -f "$tmpf"
        (( files )) && _x_act "adjusted ${files} file(s) that expected a graphics card this machine does not have"
        return 0
    }

    # The compositor is the one program guaranteed to stall a virtual display,
    # because every setting it has assumes a card that reports honestly. Its
    # configuration is found through the manifest rather than by guessing at
    # paths, and only live assignments are touched: a commented line is a
    # note the operator wrote, not a setting.
    _x_compositor() {
        local entry path full cfg=""
        for entry in "${FILES[@]}"; do
            path=${entry%%:*}
            case "$path" in
                *picom*|*compton*) ;;
                *) continue ;;
            esac
            case "$path" in
                /*) full=$path ;;
                *)  full=$user_home/$path ;;
            esac
            [[ -f $full ]] || continue
            case "${full##*/}" in
                picom.conf|compton.conf) cfg=$full; break ;;
                *.conf) [[ -n $cfg ]] || cfg=$full ;;
            esac
        done
        [[ -n $cfg ]] || { _x_note "no compositor configuration in this payload"; return 0; }
        _x_note "compositor configuration: $cfg"

        # key  desired-value
        local -a want=(
            'backend|"xrender"'
            'vsync|false'
            'use-damage|false'
            'unredir-if-possible|false'
        )
        local pair key val line term added=0 changed=0 tmpf
        tmpf=$(mktemp) || return 0
        cp -a "$cfg" "$tmpf" 2>/dev/null || return 0

        for pair in "${want[@]}"; do
            key=${pair%%|*}; val=${pair#*|}

            if grep -Eq "^[[:space:]]*${key}[[:space:]]*[:=]" "$tmpf" 2>/dev/null; then
                # a live assignment: keep the file's own terminator
                term=""
                grep -Eq "^[[:space:]]*${key}[[:space:]]*[:=].*;[[:space:]]*$" "$tmpf" 2>/dev/null && term=";"
                sed -i -E "s|^([[:space:]]*${key}[[:space:]]*[:=][[:space:]]*).*$|\1${val}${term}|" \
                       "$tmpf" 2>/dev/null && changed=1

            elif grep -Eq "^[[:space:]]*#+[[:space:]]*${key}[[:space:]]*[:=]" "$tmpf" 2>/dev/null; then
                # present, but commented out: the setting already has a home in
                # this file, so it is enabled where it stands rather than
                # restated somewhere else
                term=""
                grep -Eq "^[[:space:]]*#+[[:space:]]*${key}[[:space:]]*[:=].*;[[:space:]]*$" "$tmpf" 2>/dev/null && term=";"
                sed -i -E "0,/^[[:space:]]*#+[[:space:]]*${key}[[:space:]]*[:=]/s||${key} = |" \
                       "$tmpf" 2>/dev/null
                sed -i -E "s|^(${key} = ).*$|\1${val}${term}|" "$tmpf" 2>/dev/null && changed=1
                _x_note "enabled the existing ${key} setting"

            else
                # nowhere in the file: stated at the top, each on its own with
                # a blank line beneath it
                if (( ! added )); then
                    sed -i "1i # Added by the installer for reliable display under virtualisation." "$tmpf" 2>/dev/null
                    sed -i "2i\\ " "$tmpf" 2>/dev/null
                    added=1
                fi
                sed -i "2i ${key} = ${val};" "$tmpf" 2>/dev/null
                sed -i "3i\\ " "$tmpf" 2>/dev/null
                changed=1
                _x_note "added the ${key} setting, which this file did not carry"
            fi
        done

        if (( changed )) && ! cmp -s "$cfg" "$tmpf"; then
            [[ -e ${cfg}.original ]] || cp -a "$cfg" "${cfg}.original" 2>/dev/null
            cat "$tmpf" > "$cfg" 2>/dev/null && chown "$user" "$cfg" 2>/dev/null
            _x_act "set the compositor to render without relying on the graphics card"
        fi
        rm -f "$tmpf"
        return 0
    }

    # ── what graphics hardware is actually here ────────────────────────────
    # The configuration came from another machine. Its driver choice is a
    # statement about that machine's hardware, not this one's.
    _x_gpu() {
        local line
        if command -v lspci >/dev/null 2>&1; then
            line=$(lspci -nn 2>/dev/null | grep -iE 'vga|3d|display' | head -1)
        fi
        case "${line,,}" in
            *vmware*|*"svga ii"*)      printf 'vmware' ;;
            *virtualbox*|*innotek*)    printf 'vbox' ;;
            *qxl*|*"red hat"*)         printf 'qxl' ;;
            *virtio*)                  printf 'virtio' ;;
            *nvidia*)                  printf 'nvidia' ;;
            *"advanced micro"*|*amd*|*ati*|*radeon*) printf 'amd' ;;
            *intel*)                   printf 'intel' ;;
            *)                         printf 'generic' ;;
        esac
    }

    # Kernel mode setting decides whether X can run without root rights.
    _x_has_kms() {
        [[ -d /sys/class/drm ]] || return 1
        compgen -G '/sys/class/drm/card[0-9]*' >/dev/null 2>&1
    }

    # Legacy drivers that predate kernel mode setting. Where the kernel
    # already drives the card, these are worse than nothing: the server
    # prefers them by name, they then reach for raw VGA I/O, and a rootless
    # server is refused that access.
    _x_is_legacy() {
        case "$1" in
            vmware|vesa|fbdev|cirrus|mach64|r128|savage|sis|trident|tdfx|\
            neomagic|i128|apm|ark|chips|glint|i740|s3virge|siliconmotion) return 0 ;;
            *) return 1 ;;
        esac
    }

    # What to install when the kernel is not driving the card.
    # Whether this machine already carries a driver for the card it has.
    _x_have_driver() {
        local d m
        case "$1" in
            amd)    d="amdgpu radeon ati" ;;
            intel)  d="intel i915" ;;
            nvidia) d="nouveau nvidia" ;;
            vmware) d="vmware" ;;
            vbox)   d="vboxvideo" ;;
            qxl)    d="qxl" ;;
            virtio) d="modesetting" ;;
            *)      return 1 ;;
        esac
        for m in $d; do
            [[ -e /usr/lib/xorg/modules/drivers/${m}_drv.so ||
               -e /usr/lib64/xorg/modules/drivers/${m}_drv.so ]] && return 0
        done
        return 1
    }

    _x_driver_pkgs() {
        case "$1" in
            vmware) printf 'xf86-video-vmware xserver-xorg-video-vmware' ;;
            vbox)   printf 'virtualbox-guest-utils' ;;
            qxl)    printf 'xf86-video-qxl xserver-xorg-video-qxl' ;;
            nvidia) printf 'xf86-video-nouveau xserver-xorg-video-nouveau' ;;
            amd)    printf 'xf86-video-amdgpu xserver-xorg-video-amdgpu' ;;
            *)      printf '' ;;
        esac
    }

    [[ -n ${spinner_pid:-} ]] && close_ui

    type_effect "Preparing the display server..." "$menu_delay"; echo
    load_ui

    local _gpu; _gpu=$(_x_gpu)
    _x_note "graphics hardware: $_gpu"

    # ── 1. the server, the launcher and the pieces startx needs ────────────
    # A configuration can carry a window manager without carrying the server
    # that hosts it.
    local _need _p
    for _need in Xorg startx xauth xrdb; do
        command -v "$_need" >/dev/null 2>&1 && continue
        case "$_need" in
            Xorg)   for _p in xorg-server xserver-xorg; do _x_install "$_p" && break; done ;;
            startx) for _p in xorg-xinit xinit; do _x_install "$_p" && break; done ;;
            xauth)  for _p in xorg-xauth xauth; do _x_install "$_p" && break; done ;;
            xrdb)   for _p in xorg-xrdb x11-xserver-utils; do _x_install "$_p" && break; done ;;
        esac
        command -v "$_need" >/dev/null 2>&1 && _x_act "installed the package providing $_need"
    done

    _x_step "Selecting a graphics driver..."
    # ── 2. which driver should serve this card ────────────────────────────
    # With kernel mode setting the built-in modesetting driver is the right
    # answer and needs no root rights. The server, left to itself, ranks a
    # vendor legacy driver above it purely by name, so the choice is stated
    # rather than left to autoconfiguration.
    local _drv _mods=/usr/lib/xorg/modules/drivers
    [[ -d $_mods ]] || _mods=/usr/lib64/xorg/modules/drivers
    # Only where the server would otherwise pick a legacy driver. On hardware
    # whose in-tree driver is current — amdgpu, nouveau, intel — that driver
    # is the better answer, and overriding it is known to break console
    # switching: the vendor driver restores the text mode on VT change and
    # modesetting on some older cards does not.
    local _force_ms=0
    case "$_gpu" in
        vmware|vbox|qxl|virtio|generic) _force_ms=1 ;;
    esac
    local _lgi
    for _lgi in "$_mods"/*_drv.so; do
        [[ -e $_lgi ]] || continue
        _lgi=${_lgi##*/}; _lgi=${_lgi%_drv.so}
        _x_is_legacy "$_lgi" && _force_ms=1
    done

    if _x_has_kms && (( _force_ms )); then
        if [[ -e $_mods/modesetting_drv.so ]]; then
            if [[ ! -e /etc/X11/xorg.conf.d/20-modesetting.conf ]]; then
                mkdir -p /etc/X11/xorg.conf.d 2>/dev/null
                {
                    printf 'Section "Device"\n'
                    printf '    Identifier "Kernel modesetting"\n'
                    printf '    Driver "modesetting"\n'
                    printf 'EndSection\n'
                } > /etc/X11/xorg.conf.d/20-modesetting.conf 2>/dev/null &&
                    _x_act "told the server to use the kernel modesetting driver"
            fi
        else
            _x_install xf86-video-modesetting ||
            _x_install xserver-xorg-core || true
        fi
        # a legacy driver present on disk will still be ranked first, and its
        # only effect here is to crash the server
        local _lg
        for _lg in "$_mods"/*_drv.so; do
            [[ -e $_lg ]] || continue
            _lg=${_lg##*/}; _lg=${_lg%_drv.so}
            _x_is_legacy "$_lg" || continue
            _x_note "the legacy $_lg driver is installed and outranks modesetting"
        done
    else
        # the module, not the package name: a driver already on disk needs
        # nothing done, whichever distribution's package delivered it
        if _x_have_driver "$_gpu"; then
            _x_note "a driver for $_gpu hardware is already installed"
        else
            for _drv in $(_x_driver_pkgs "$_gpu"); do
                _x_install "$_drv" &&
                    { _x_act "Installed the $_gpu graphics driver ($_drv)"; break; }
            done
        fi
    fi
    command -v glxinfo >/dev/null 2>&1 || _x_install mesa-utils || true

    # ── 2b. a guest under a hypervisor ────────────────────────────────────
    # A virtual machine presents a card the host emulates. Two things then
    # decide whether the picture ever updates: the guest tools that carry
    # frames to the host, and whether any renderer exists at all. Without
    # them the first frame is drawn and nothing after it, which reads as a
    # frozen screen even though every program is still running.
    # Whether a guest-tools package is already on this system. The package
    # name and the programs it installs rarely match, so the programs are
    # what gets looked for.
    _x_have_tools() {
        case "$1" in
            open-vm-tools)
                command -v vmtoolsd >/dev/null 2>&1 ||
                [[ -x /usr/bin/vmtoolsd || -x /usr/sbin/vmtoolsd ]] ;;
            virtualbox-guest-utils)
                command -v VBoxClient >/dev/null 2>&1 ||
                command -v VBoxService >/dev/null 2>&1 ;;
            qemu-guest-agent)
                command -v qemu-ga >/dev/null 2>&1 ;;
            spice-vdagent)
                command -v spice-vdagent >/dev/null 2>&1 ;;
            *)  command -v "$1" >/dev/null 2>&1 ;;
        esac
    }

    _x_virtual() {
        local hv=""
        if command -v systemd-detect-virt >/dev/null 2>&1; then
            hv=$(systemd-detect-virt 2>/dev/null)
        fi
        [[ $hv == none || -z $hv ]] && case "$_gpu" in
            vmware) hv=vmware ;; vbox) hv=oracle ;; qxl|virtio) hv=kvm ;;
            *) return 0 ;;
        esac
        _x_note "running as a guest under $hv"

        local _tools=""
        case "$hv" in
            vmware)          _tools="open-vm-tools" ;;
            oracle)          _tools="virtualbox-guest-utils" ;;
            kvm|qemu)        _tools="qemu-guest-agent spice-vdagent" ;;
            microsoft|hyperv) _tools="hyperv" ;;
            *)               _tools="" ;;
        esac
        local _t
        if [[ -z ${SKIP_MGR[vm:tools]:-} ]]; then
            for _t in $_tools; do
                _x_have_tools "$_t" && { _x_note "$_t is already present"; continue; }
                _x_install "$_t" && _x_act "installed $_t, the guest tools for $hv"
            done
        else
            _x_note "guest tools skipped by request"
        fi

        # A renderer of some kind has to exist. Where the host offers no
        # acceleration, the software one is what keeps the screen moving.
        local _has_gl=0
        [[ -e /dev/dri/renderD128 ]] && _has_gl=1
        if command -v glxinfo >/dev/null 2>&1 &&
           glxinfo 2>/dev/null | grep -q 'direct rendering: Yes'; then
            _has_gl=1
        fi
        if (( ! _has_gl )); then
            _x_note "the host offers no accelerated rendering to this guest"
            _x_install mesa || _x_install libgl1-mesa-dri || true
            # glamor asks the card to draw. With nothing behind it the server
            # paints once and then appears to stop, so it is turned off.
            # only meaningful where modesetting is the driver in use; with a
            # legacy driver the option belongs to nothing
            if ! _x_has_kms; then
                _x_note "no kernel mode setting device, so acceleration is left as the driver sets it"
                X11_NO_ACCEL=1
                return 0
            fi
            # the same Identifier twice would leave the server with two
            # conflicting Device sections, so the existing one is amended
            mkdir -p /etc/X11/xorg.conf.d 2>/dev/null
            if [[ -e /etc/X11/xorg.conf.d/20-modesetting.conf ]]; then
                grep -q 'AccelMethod' /etc/X11/xorg.conf.d/20-modesetting.conf 2>/dev/null ||
                    sed -i 's|^EndSection|    Option "AccelMethod" "none"\nEndSection|' \
                        /etc/X11/xorg.conf.d/20-modesetting.conf 2>/dev/null &&
                        _x_act "turned off hardware acceleration, which this guest cannot provide"
            else
                {
                    printf 'Section "Device"\n'
                    printf '    Identifier "Kernel modesetting"\n'
                    printf '    Driver "modesetting"\n'
                    printf '    Option "AccelMethod" "none"\n'
                    printf 'EndSection\n'
                } > /etc/X11/xorg.conf.d/20-modesetting.conf 2>/dev/null &&
                    _x_act "turned off hardware acceleration, which this guest cannot provide"
            fi
            X11_NO_ACCEL=1
        fi

        if [[ -z ${SKIP_MGR[vm:tweak]:-} ]]; then
            _x_compositor
            _x_soften
        else
            _x_note "display settings left untouched by request"
        fi

        # The tools only carry frames while they are running.
        [[ -n ${SKIP_MGR[vm:tools]:-} ]] && return 0
        case "$hv" in
            vmware)
                command -v systemctl >/dev/null 2>&1 &&
                systemctl enable --now vmtoolsd >> "$output" 2>&1 &&
                    _x_act "started the VMware guest service" ;;
            oracle)
                command -v systemctl >/dev/null 2>&1 &&
                systemctl enable --now vboxservice >> "$output" 2>&1 &&
                    _x_act "started the VirtualBox guest service" ;;
            kvm|qemu)
                command -v systemctl >/dev/null 2>&1 &&
                systemctl enable --now spice-vdagentd >> "$output" 2>&1 &&
                    _x_act "started the SPICE guest agent" ;;
        esac
        return 0
    }
    _x_virtual

    _x_step "Checking the display configuration..."
    # ── 3. configuration fragments that name absent hardware ──────────────
    # A copied xorg.conf naming a driver this machine does not have is the
    # most common reason the server exits before it starts. X autodetects
    # perfectly well without one, so an unusable fragment is set aside
    # rather than deleted.
    _x_check_conf() {
        local f=$1 drv mod ok=1
        [[ -r $f ]] || return 0
        while read -r drv; do
            [[ -n $drv ]] || continue
            mod=/usr/lib/xorg/modules/drivers/${drv}_drv.so
            [[ -e $mod || -e /usr/lib64/xorg/modules/drivers/${drv}_drv.so ]] && continue
            ok=0
            _x_note "$f names the $drv driver, which is not installed here"
        done < <(sed -n 's/^[[:space:]]*[Dd]river[[:space:]]*"\([^"]*\)".*/\1/p' "$f" 2>/dev/null)
        (( ok )) && return 0
        mv "$f" "${f}.unused" 2>/dev/null &&
            _x_act "set aside ${f##*/}: it names a driver this machine does not have"
    }

    _x_check_conf /etc/X11/xorg.conf
    local _frag
    for _frag in /etc/X11/xorg.conf.d/*.conf; do
        [[ -e $_frag ]] || continue
        _x_check_conf "$_frag"
    done

    # ── 4. permission to touch the hardware ───────────────────────────────
    # Without kernel mode setting the server has to reach the card directly,
    # which a plain user may not do. This is the "failed to enable I/O ports
    # access" refusal.
    local _wrap=/etc/X11/Xwrapper.config
    if [[ ! -f $_wrap ]] || ! grep -q '^allowed_users' "$_wrap" 2>/dev/null; then
        mkdir -p /etc/X11 2>/dev/null
        {
            printf 'allowed_users=anybody\n'
            if _x_has_kms; then printf 'needs_root_rights=auto\n'
                           else printf 'needs_root_rights=yes\n'; fi
        } > "$_wrap" 2>/dev/null &&
            _x_act "allowed the console user to start the server"
    fi

    # ── 5. the groups a seat is granted through ───────────────────────────
    local _g
    for _g in video input; do
        getent group "$_g" >/dev/null 2>&1 || continue
        id -nG "$user" 2>/dev/null | tr ' ' '\n' | grep -qx "$_g" && continue
        usermod -aG "$_g" "$user" >/dev/null 2>&1 &&
            _x_act "added $user to the $_g group"
    done

    # ── 6. the authority file startx complains about ──────────────────────
    if [[ ! -e $user_home/.Xauthority ]]; then
        install -o "$user" -m 600 /dev/null "$user_home/.Xauthority" 2>/dev/null &&
            _x_act "created the X authority file"
    fi
    chown "$user" "$user_home/.Xauthority" 2>/dev/null

    _x_step "Aligning the configuration with this display..."
    # ── 7. the session the configuration expects to launch ────────────────
    local _rc=$user_home/.xinitrc _target
    if [[ -e $_rc ]]; then
        [[ -x $_rc ]] || { chmod +x "$_rc" 2>/dev/null && _x_act "made .xinitrc executable"; }
        chown "$user" "$_rc" 2>/dev/null
        # what it launches is the operator's business; the packages were
        # installed from the manifest, not guessed from this file
        _target=$(sed -n 's/^[[:space:]]*exec[[:space:]]\{1,\}\([^[:space:]]*\).*/\1/p' \
                  "$_rc" 2>/dev/null | tail -1)
        [[ -n $_target ]] && ! command -v "${_target##*/}" >/dev/null 2>&1 &&
            _x_note ".xinitrc launches ${_target##*/}, which is not on this system"
    fi


    # what this machine actually presents
    local _have_out _first_out _cur_res
    if command -v xrandr >/dev/null 2>&1; then
        _have_out=$(xrandr --listmonitors 2>/dev/null | sed -n 's/^ *[0-9]*: *[+*]*\([^ ]*\).*/\1/p')
        _cur_res=$(xrandr 2>/dev/null | sed -n 's/.*current \([0-9]\{1,\} x [0-9]\{1,\}\).*/\1/p' | tr -d ' ')
    fi
    [[ -z $_have_out && -d /sys/class/drm ]] &&
        _have_out=$(ls -1 /sys/class/drm 2>/dev/null | sed -n 's/^card[0-9]*-//p')
    _first_out=$(printf '%s\n' $_have_out | head -1)
    [[ -z $_cur_res && -r /sys/class/graphics/fb0/virtual_size ]] &&
        _cur_res=$(tr ',' 'x' < /sys/class/graphics/fb0/virtual_size 2>/dev/null)

    _x_retarget "${source_output:-}" "$_first_out" "${resolution:-}" "$_cur_res"

    # ── 8. the seat manager rootless X depends on ─────────────────────────
    if command -v systemctl >/dev/null 2>&1; then
        systemctl is-enabled systemd-logind >/dev/null 2>&1 ||
            systemctl enable systemd-logind >> "$output" 2>&1 || true
    elif command -v rc-update >/dev/null 2>&1; then
        rc-update show 2>/dev/null | grep -q elogind ||
            { rc-update add elogind default >> "$output" 2>&1 &&
              _x_act "enabled elogind, which grants the seat"; }
    fi

    _x_step "Verifying the display server..."
    # ── 9. read any record of a previous attempt ──────────────────────────
    # A server that has already failed here leaves the reason on disk. These
    # are signatures, not one machine's story: each says something specific
    # about what to change.
    _x_read_log() {
        local lg=$1
        [[ -r $lg ]] || return 1
        local _drv_crash=""

        # A driver without kernel mode setting reaching for VGA I/O on a
        # rootless server: it is refused, then dereferences the result.
        if grep -q 'xf86EnableIO: failed to enable I/O ports' "$lg" 2>/dev/null; then
            _drv_crash=$(sed -n 's;.*/xorg/modules/drivers/\([a-z0-9]*\)_drv\.so.*;\1;p' \
                         "$lg" 2>/dev/null | head -1)
            if [[ -n $_drv_crash ]] && _x_is_legacy "$_drv_crash"; then
                _x_note "a previous attempt crashed inside the $_drv_crash driver"
                if _x_has_kms && [[ -e $_mods/modesetting_drv.so ]]; then
                    mkdir -p /etc/X11/xorg.conf.d 2>/dev/null
                    {
                        printf 'Section "Device"\n'
                        printf '    Identifier "Kernel modesetting"\n'
                        printf '    Driver "modesetting"\n'
                        printf 'EndSection\n'
                    } > /etc/X11/xorg.conf.d/20-modesetting.conf 2>/dev/null &&
                        _x_act "replaced the $_drv_crash driver with kernel modesetting, which crashed the last attempt"
                else
                    grep -q '^needs_root_rights=yes' /etc/X11/Xwrapper.config 2>/dev/null ||
                        { printf 'needs_root_rights=yes\n' >> /etc/X11/Xwrapper.config 2>/dev/null &&
                          _x_act "granted the server the hardware access its driver requires"; }
                fi
            fi
        fi

        # No usable output at all.
        if grep -q '(EE) no screens found' "$lg" 2>/dev/null; then
            _x_note "a previous attempt found no usable screen"
            _x_has_kms || _x_note "this machine reports no kernel mode setting device"
        fi

        # A configured module that is not installed.
        local _miss
        while read -r _miss; do
            [[ -n $_miss ]] || continue
            _x_note "a previous attempt could not load the $_miss module"
            _x_is_legacy "$_miss" && continue
            _x_install "xf86-video-${_miss}" &&
                _x_act "installed the missing $_miss driver"
        done < <(sed -n 's/.*(EE) Failed to load module "\([^"]*\)".*/\1/p' "$lg" 2>/dev/null | sort -u)

        # The seat was refused.
        if grep -q 'systemd-logind: failed to take control' "$lg" 2>/dev/null; then
            _x_note "a previous attempt was refused control of the seat"
            grep -q '^needs_root_rights' /etc/X11/Xwrapper.config 2>/dev/null ||
                { printf 'needs_root_rights=yes\n' >> /etc/X11/Xwrapper.config 2>/dev/null &&
                  _x_act "granted the server the rights the seat manager withheld"; }
        fi

        # Fonts the server could not find; harmless but noisy, and cheap to fix.
        if grep -q "'fonts.dir' not found" "$lg" 2>/dev/null; then
            command -v mkfontdir >/dev/null 2>&1 ||
                _x_install xorg-mkfontscale || true
            local _fd
            for _fd in /usr/share/fonts/misc /usr/share/fonts/TTF; do
                [[ -d $_fd ]] || continue
                command -v mkfontscale >/dev/null 2>&1 && mkfontscale "$_fd" 2>/dev/null
                command -v mkfontdir  >/dev/null 2>&1 && mkfontdir  "$_fd" 2>/dev/null
            done
        fi
        return 0
    }

    # On a machine that has never run the server there is nothing to read, so
    # one is made. The server is asked to probe the hardware and exit: it is
    # given its own display number, told not to switch the console away, and
    # bounded by a timeout. Whatever it writes is then read like any other log.
    _x_probe() {
        command -v Xorg >/dev/null 2>&1 || return 1
        # the server writes to the console itself, so nothing of ours may be
        # drawing while it runs, and the cursor stays hidden throughout
        [[ -n ${spinner_pid:-} ]] && close_ui
        printf '\033[?25l'
        local plog=/tmp/.install-xprobe.log vt
        rm -f "$plog"
        vt=$(fgconsole 2>/dev/null || printf '')
        timeout 20 Xorg :99 -novtswitch -sharevts -noreset -logfile "$plog" \
            -config /dev/null >/dev/null 2>&1 &
        local pid=$!
        sleep 4
        kill "$pid" 2>/dev/null
        wait "$pid" 2>/dev/null || true
        # put the console back exactly as it was
        [[ -n $vt ]] && command -v chvt >/dev/null 2>&1 && chvt "$vt" 2>/dev/null
        stty sane 2>/dev/null
        printf '\033[?25l'
        [[ -s $plog ]] || return 1
        _x_note "probed the display server; its log is at $plog"
        X_PROBE_LOG=$plog
        return 0
    }

    local _lg _found=0 X_PROBE_LOG=""
    for _lg in "$user_home/.local/share/xorg/Xorg.0.log" /var/log/Xorg.0.log \
               "$user_home/.local/share/xorg/Xorg.1.log"; do
        [[ -r $_lg ]] || continue
        _x_read_log "$_lg"; _found=1
        break
    done
    if (( ! _found )) && [[ ${X11_PROBE:-true} == true ]]; then
        X_PROBE_LOG=""
        _x_probe && [[ -n $X_PROBE_LOG ]] && _x_read_log "$X_PROBE_LOG"
    fi

    # Nothing below this line may print until the bar is down. close_ui is
    # a no-op when none is running, so this is safe on every path out.
    [[ -n ${spinner_pid:-} ]] && close_ui
    spinner_pid=""
    printf '\033[?25l'
    [[ -n ${spinner_pid:-} ]] && close_ui
    type_effect "\033[32mDisplay server is ready.\033[0m" "$menu_delay"; echo
    X11_FIXED=$_fixed
    return 0
}

configure_display

# ─────────────────────────── END
_fmt_bytes() {
    local b=${1:-0} u=0 w f
    local -a units=(B KiB MiB GiB TiB PiB)
    [[ $b =~ ^[0-9]+$ ]] || { printf 'unknown'; return; }
    w=$b; f=0
    while (( w >= 1024 && u < 5 )); do f=$(( (w % 1024) * 10 / 1024 )); w=$(( w / 1024 )); (( u++ )); done
    if (( u > 0 && w < 10 && f > 0 )); then printf '%d.%d %s' "$w" "$f" "${units[$u]}"
    else printf '%d %s' "$w" "${units[$u]}"; fi
}

draw_end_ui() {
    local mode="static"
    [[ ${1:-} == animated ]] && mode="animated"
    local sz line pad i menu_h total top=0
    put() {
        local p=$(( (terminal_width - $1) / 2 ))
        (( p < 0 )) && p=0
        printf '%*s' "$p" ''
        if [[ $mode == animated ]]; then type_effect1 "$2" "$delay"; else printf '%b' "$2"; fi
    }
    # statistics are for reading, so they are written straight out; only the
    # heading, the restart notice and the menu are typed
    put_plain() {
        local p=$(( (terminal_width - $1) / 2 ))
        (( p < 0 )) && p=0
        printf '%*s%b' "$p" '' "$2"
    }
    clear
    sz=$(stty size 2>/dev/null) || sz="24 80"
    terminal_height=${sz% *}
    terminal_width=${sz#* }
    menu_h=2
    (( ${REBOOT_REQUIRED:-0} )) && menu_h=4
    total=$(( ascii_h + 1 + 1 + 1 + 4 + 1 + menu_h ))
    (( terminal_height > total )) && top=$(( (terminal_height - total) / 2 ))
    for (( i=0; i<top; i++ )); do echo; done
    pad=$(( (terminal_width - ascii_w) / 2 ))
    (( pad < 0 )) && pad=0
    for line in "${ASCII_ART[@]}"; do
        printf '%*s%s\n' "$pad" '' "$line"
    done
    echo
    local _hdr="INSTALLATION COMPLETE"
    put_plain ${#_hdr} "${bold}${_hdr}${reset}"; echo
    echo
    local _du _used _size _pct
    read -r _size _used _pct < <(df -B1 / 2>/dev/null | awk 'NR==2 {print $2, $3, $5}')
    _du="Disk Usage: $(_fmt_bytes "${_used:-0}") of $(_fmt_bytes "${_size:-0}") (${_pct:-0%})"
    local _l
    for _l in "Packages Installed: ${success_rate:-100}%" \
              "Elapsed Time: ${duration:-unknown}" \
              "$_du" \
              "Log: ${log}"; do
        put_plain ${#_l} "$_l"; echo
    done
    echo
    if (( ${REBOOT_REQUIRED:-0} )); then
        local _rb="A system restart is required to complete this installation."
        put ${#_rb} "${bold}${_rb}${reset}"; echo
        echo
    fi
    local l1="1. Summary        3. Reboot System"
    local l2="2. View Log       4. Exit to Shell"
    put ${#l1} "${bold}${l1}${reset}"; echo
    put ${#l2} "${bold}${l2}${reset}"
    printf '\033[?25l'
}

end_summary() {
    local -a lines=()
    local off=0 view rows cols key rest max n
    lines+=("${bold}INSTALLATION SUMMARY${reset}" "")
    lines+=("$(printf '  %-22s %s' 'System' "$display_name")")
    lines+=("$(printf '  %-22s %s' 'Target' "${user:-unknown} (${user_home:-unknown})")")
    lines+=("$(printf '  %-22s %s' 'Elapsed' "${duration:-unknown}")")
    lines+=("$(printf '  %-22s %s' 'Packages installed' "${success_rate:-100}%")")
    (( ${#failed[@]} )) && lines+=("$(printf '  %-22s %s' 'Packages unavailable' "${#failed[@]}")")
    (( ${#failed_extensions[@]} )) && lines+=("$(printf '  %-22s %s' 'Extensions unavailable' "${#failed_extensions[@]}")")
    (( ${EXT_TOTAL:-0} )) && lines+=("$(printf '  %-22s %s' 'Extensions enabled' "${EXT_ENABLED:-0} of ${EXT_TOTAL:-0}")")
    (( ${#failed_builds[@]} )) && lines+=("$(printf '  %-22s %s' 'Source builds failed' "${#failed_builds[@]}")")
    (( ${#SERVICES[@]} )) && lines+=("$(printf '  %-22s %s' 'Services enabled' "${SVC_READY:-0} of ${#SERVICES[@]}")")
    if [[ -n ${CONFIG_STATUS:-} ]]; then
        if [[ $CONFIG_STATUS == Failed* || $CONFIG_STATUS == Partial* ]]; then
            lines+=("$(printf '  %-22s \033[31m%s\033[0m' 'Configuration files' "$CONFIG_STATUS")")
        else
            lines+=("$(printf '  %-22s \033[32m%s\033[0m' 'Configuration files' "$CONFIG_STATUS")")
        fi
    fi
    (( ${KERNEL_UPDATE_DEFERRED:-0} )) && lines+=("$(printf '  %-22s %s' 'Kernel update' 'deferred')")
    (( ${REBOOT_REQUIRED:-0} )) && lines+=("$(printf '  %-22s %s' 'Restart' 'required')")
    lines+=("$(printf '  %-22s %s' 'Log' "$log")")
    if (( ${#failed[@]} )); then
        GRID_COL=$(_grid_width failed)
        lines+=("" "${bold}PACKAGES NOT INSTALLED${reset}" "")
        while IFS= read -r n; do lines+=("$n"); done < <(failed_grid failed)
    fi
    if (( ${#failed_extensions[@]} )); then
        lines+=("" "${bold}EXTENSIONS NOT INSTALLED${reset}" "")
        while IFS= read -r n; do lines+=("$n"); done < <(failed_grid failed_extensions)
    fi
    if (( ${#failed_builds[@]} )); then
        lines+=("" "${bold}SOURCE BUILDS NOT COMPLETED${reset}" "")
        while IFS= read -r n; do lines+=("$n"); done < <(failed_grid failed_builds)
    fi
    _sum_wrap() {
        local cont=$1 text=$2 w=$3 line="" word
        (( w < 30 )) && w=30
        # the first wrapped line carries the tree character, the rest align
        # under the text it introduces
        local lead=$cont
        (( ${_sum_first:-0} )) && lead="└─ "
        for word in $text; do
            if [[ -z $line ]]; then line=$word
            elif (( ${#line} + 1 + ${#word} > w )); then
                lines+=("${lead}${line}"); lead=$cont; line=$word
            else line+=" $word"; fi
        done
        [[ -n $line ]] && lines+=("${lead}${line}")
        _sum_first=0
    }

    local _sz3 _wid=70
    _sz3=$(stty size 2>/dev/null) && _wid=$(( ${_sz3#* } - 10 ))

    # df -k is the one form Linux, the BSDs and macOS all agree on
    local _hu_after _hu_delta _hf_after
    _hu_after=$(df -k "$user_home" 2>/dev/null | awk 'NR==2{print $3}')
    _hf_after=$(df -k "$user_home" 2>/dev/null | awk 'NR==2{print $4}')
    if [[ -n ${HOME_USED_BEFORE:-} && -n $_hu_after ]]; then
        _hu_delta=$(( (_hu_after - HOME_USED_BEFORE) * 1024 ))
        lines+=("" "${bold}DISK${reset}" "")
        lines+=("$(printf '  %-22s %s' 'Home before' "$(_fmt_bytes $(( HOME_USED_BEFORE * 1024 )))")")
        lines+=("$(printf '  %-22s %s' 'Home after' "$(_fmt_bytes $(( _hu_after * 1024 )))")")
        if (( _hu_delta >= 0 )); then
            lines+=("$(printf '  %-22s \033[32m+%s\033[0m' 'Added' "$(_fmt_bytes "$_hu_delta")")")
        else
            lines+=("$(printf '  %-22s %s' 'Reclaimed' "$(_fmt_bytes $(( -_hu_delta )))")")
        fi
        [[ -n $_hf_after ]] &&
            lines+=("$(printf '  %-22s %s' 'Free now' "$(_fmt_bytes $(( _hf_after * 1024 )))")")
    fi
    (( _wid < 34 )) && _wid=34

    if [[ -n ${SHELL_STATUS:-} ]]; then
        local _sc="\033[32m"
        [[ $SHELL_STATUS == "not changed" ]] && _sc="\033[31m"
        lines+=("" "${bold}LOGIN SHELL${reset}" "")
        lines+=("$(printf '  %-22s %b%s\033[0m' "${source_shell:-shell}" "$_sc" "$SHELL_STATUS")")
        [[ -n ${SHELL_DETAIL:-} ]] && { _sum_first=1; _sum_wrap "     " "$SHELL_DETAIL" "$_wid"; }
    fi

    if (( ${#X11_ACTIONS[@]} )); then
        lines+=("" "${bold}DISPLAY SERVER${reset}" "")
        local _xa
        for _xa in "${X11_ACTIONS[@]}"; do
            # a sentence, not a fragment
            lines+=("  ${_xa^}")
        done
        if (( ${#X11_RETARGETED[@]} )); then
            lines+=("")
            local _xf
            for _xf in "${X11_RETARGETED[@]}"; do
                lines+=("     ${_xf}")
            done
        fi
    fi

    if (( ${#SVC_STATUS[@]} )); then
        local _sz2 _wid=70
        _sz2=$(stty size 2>/dev/null) && _wid=$(( ${_sz2#* } - 10 ))
        (( _wid < 34 )) && _wid=34
        lines+=("" "${bold}SYSTEM SERVICES${reset}${SVC_INIT:+  (${SVC_INIT})}" "")
        local _e _n _st _why _colour
        for _e in "${SVC_STATUS[@]}"; do
            _n=${_e%%|*}; _e=${_e#*|}
            _st=${_e%%|*}; _why=${_e#*|}
            case "$_st" in
                "not enabled") _colour="\033[31m" ;;
                enabled,*)     _colour="\033[33m" ;;
                *)             _colour="\033[32m" ;;
            esac
            lines+=("$(printf '%-26s %b%s\033[0m' "$_n" "$_colour" "$_st")")
            if [[ -n $_why ]]; then
                _sum_first=1
                _sum_wrap "   " "$_why" "$_wid"
            fi
        done
    fi

    _draw_summary() {
        local animate=${1:-0}
        local sz; sz=$(stty size 2>/dev/null) || sz="24 80"
        rows=${sz% *}; cols=${sz#* }
        view=$(( rows - 2 )); (( view < 1 )) && view=1
        max=$(( ${#lines[@]} - view )); (( max < 0 )) && max=0
        (( off > max )) && off=$max
        (( off < 0 )) && off=0
        printf '\033[H\033[J'
        local k
        for (( k=0; k<view; k++ )); do
            printf '\033[%d;1H\033[2K' $(( k + 1 ))
            if (( animate )) && [[ ${no_anim:-false} != true ]]; then
                type_effect1 "${lines[$(( off + k ))]:-}" 0.0015
            else
                printf '%b' "${lines[$(( off + k ))]:-}"
            fi
        done
        printf '\033[%d;1H\033[2K%b' "$rows" "${bold}[esc]${reset}"
        printf '\033[?25l'
    }
    _draw_summary 1
    while true; do
        (( _resized )) && { _resized=0; _draw_summary; }
        IFS= read -t 0.05 -rsn1 key || continue
        case "$key" in
            $'\x1b')
                if IFS= read -rsn2 -t 0.001 rest 2>/dev/null; then
                    case "$rest" in
                        '[A') (( off > 0 )) && { (( off-- )); _draw_summary; } ;;
                        '[B') (( off < max )) && { (( off++ )); _draw_summary; } ;;
                    esac
                else
                    break
                fi ;;
            $'\x7f'|$'\x08'|q|Q) break ;;
            k) (( off > 0 )) && { (( off-- )); _draw_summary; } ;;
            j) (( off < max )) && { (( off++ )); _draw_summary; } ;;
        esac
    done
}

end_menu() {
    # Whatever ran last, the end screen is drawn on a terminal nothing else
    # is writing to. A stage that returned with its progress bar alive would
    # otherwise draw over this one line by line.
    [[ -n ${spinner_pid:-} ]] && close_ui
    spinner_pid=""
    printf '\033[?25l'
    is_finished=true
    timer_end
    [[ ${deploy:-false} == true ]] && return 0
    menu_active=1
    _resized=0
    draw_end_ui animated
    local key _vl_stty=""
    while true; do
        (( _resized )) && { _resized=0; draw_end_ui static; }
        read -t 0.05 -rn 1 -s key || continue
        case $key in
            1) menu_active=0; end_summary; menu_active=1; draw_end_ui static; _resized=0 ;;
            2)
                # The installer holds the alternate screen. A pager wants one
                # too, and the two cannot nest: it ends up drawing over the
                # end screen and leaving fragments behind on exit. Stepping
                # back to the normal screen first gives the pager a buffer of
                # its own, with the end screen untouched underneath.
                menu_active=0
                _vl_stty=$(stty -g 2>/dev/null)
                printf '\033[?1049l\033[?25h'
                stty sane 2>/dev/null
                if command -v less >/dev/null 2>&1; then
                    LESS= less -R -i -M -- "$log"
                elif command -v more >/dev/null 2>&1; then
                    more -- "$log"
                else
                    cat -- "$log"
                    printf '\nEnd of log. Press any key to return.'
                    read -rsn 1
                fi
                [[ -n ${_vl_stty:-} ]] && stty "$_vl_stty" 2>/dev/null
                printf '\033[?1049h\033[?25l'
                menu_active=1; draw_end_ui static; _resized=0 ;;
            3)
                restore_ui
                command -v systemctl >/dev/null 2>&1 && exec systemctl reboot
                command -v reboot >/dev/null 2>&1 && exec reboot
                exec telinit 6 ;;
            4|q|Q|$'\e'|$'\x03') exit 0 ;;
        esac
    done
}

if [ "$rule_added" = true ]; then
    sed -i "/$sudo_rule/d" /etc/sudoers
fi

end_menu
