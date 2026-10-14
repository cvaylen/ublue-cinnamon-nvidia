#!/bin/bash
set -euo pipefail

THEMES=$1
HERE=$(dirname "$(readlink -f "$0")")

declare -A LIGHT=(
    [FG]='#5c616c'
    [CONTENT_BG]='#ffffff'
    [CONTENT_SELECTED_BG]='#F5F6F7'
    [FG_DIM]='rgba(92, 97, 108, 0.7)'
    [FG_INSENSITIVE]='rgba(92, 97, 108, 0.55)'
    [ENTRY_BG]='#ffffff'
    [ENTRY_BORDER]='#cfd6e6'
    [ENTRY_INSENSITIVE_BG]='#fbfbfb'
    [ENTRY_INSENSITIVE_BORDER]='#e0e4ee'
    [SIDEBAR_FG]='#5c616c'
    [SIDEBAR_FG_INSENSITIVE]='rgba(92, 97, 108, 0.55)'
    [SIDEBAR_BG]='#F5F6F7'
    [SIDEBAR_BORDER]='#dcdfe3'
    [SIDEBAR_HOVER_BG]='#ffffff'
    [SIDEBAR_ENTRY_BG]='#ffffff'
    [SYSTEM_BUTTON_BG]='#ffffff'
    [DIALOG_BG]='#f5f6f7'
    [DIALOG_BORDER]='#cfd6e6'
    [BUTTON_BG]='#fbfbfc'
    [BUTTON_BORDER]='#cfd6e6'
    [BUTTON_HOVER_BG]='#ffffff'
    [ASSETS]='light-assets'
)

declare -A DARK=(
    [FG]='#D3DAE3'
    [CONTENT_BG]='#383c4a'
    [CONTENT_SELECTED_BG]='#505666'
    [FG_DIM]='rgba(211, 218, 227, 0.7)'
    [FG_INSENSITIVE]='rgba(211, 218, 227, 0.45)'
    [ENTRY_BG]='#404552'
    [ENTRY_BORDER]='#2b2e39'
    [ENTRY_INSENSITIVE_BG]='#3c414e'
    [ENTRY_INSENSITIVE_BORDER]='#313440'
    [SIDEBAR_FG]='#D3DAE3'
    [SIDEBAR_FG_INSENSITIVE]='rgba(211, 218, 227, 0.45)'
    [SIDEBAR_BG]='#2f343f'
    [SIDEBAR_BORDER]='#2b2e39'
    [SIDEBAR_HOVER_BG]='#505666'
    [SIDEBAR_ENTRY_BG]='#404552'
    [SYSTEM_BUTTON_BG]='#404552'
    [DIALOG_BG]='#323644'
    [DIALOG_BORDER]='#2b2e39'
    [BUTTON_BG]='#444a58'
    [BUTTON_BORDER]='#2b2e39'
    [BUTTON_HOVER_BG]='#505666'
    [ASSETS]='dark-assets'
)

declare -A DARKER
for k in "${!LIGHT[@]}"; do DARKER[$k]=${LIGHT[$k]}; done
for k in SIDEBAR_FG SIDEBAR_FG_INSENSITIVE SIDEBAR_BG SIDEBAR_BORDER SIDEBAR_HOVER_BG SIDEBAR_ENTRY_BG SYSTEM_BUTTON_BG; do DARKER[$k]=${DARK[$k]}; done

render() {
    local -n palette=$2
    local css=$THEMES/$3/cinnamon/cinnamon.css
    local script=()
    for k in "${!palette[@]}"; do script+=(-e "s/@${k}@/${palette[$k]}/g"); done
    sed "${script[@]}" "$HERE/$1.css.in" >> "$css"
    if grep -q '@[A-Z_]*@' "$css"; then
        echo "unreplaced placeholder in $css" >&2
        exit 1
    fi
}

cp -a "$THEMES/Arc-Dark/cinnamon" "$THEMES/Arc-Darker/cinnamon"
cp -a "$THEMES/Arc-Dark-solid/cinnamon" "$THEMES/Arc-Darker-solid/cinnamon"

for template in appmenu dialogs calendar-events panel; do
    render $template LIGHT Arc
    render $template LIGHT Arc-solid
    render $template DARK Arc-Dark
    render $template DARK Arc-Dark-solid
    render $template DARK Arc-Darker
    render $template DARK Arc-Darker-solid
done
render cinnamenu DARKER Arc-Darker
render cinnamenu DARKER Arc-Darker-solid
render calendar DARKER Arc-Darker
render calendar DARKER Arc-Darker-solid
