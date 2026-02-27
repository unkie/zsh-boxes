#!/bin/zsh
autoload -Uz colors
colors


_define_box_style_simple () {
  style=(
    le,top "╔"
    le,bot "╚"
    re,top "╗"
    re,bot "╝"
    sp,top "╤"
    sp,mid "│"
    sp,bot "╧"
    le,mid "║"
    rp,top "═"
    rp,bot "═"
    re,mid "║"
  )
}

_define_box_style_fancy () {
  style=(
    le,top "▗█"
    le,bot "▝█"
    re,top "▜█▖"
    re,bot "▟█▘"
    sp,top "██"
    sp,mid "█▌"
    sp,bot "██"
    le,mid "▐█"
    rp,top "▀"
    rp,bot "▄"
    re,mid " █▌"
  )
  # other style
  #re,top "▜█"
  #re,bot "▟█"
}


# Draw a box into a array of lines
#
# Usage:
#   _make_infobox [options]… [line]...
#   _make_infobox [options]… --icons [icon] [line] ...
#
# options:
#   -fg <col>: The foreground color
#   -bg <col>: The background color
#   -icons: The 
_make_infobox() {

  # array of lines and icon
  local -a lines
  local -a icons

  # no icons by default
  local -x use_icons=0

  # no colors by default
  local -x box_fg
  local -x box_bg

  # default spacing on the left and right of each line.
  local -x line_spacing=1

  # read options
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -fg) box_fg="$2"; shift 2 ;;
      -bg) box_bg="$2"; shift 2 ;;
      -line-spacing) line_spacing="$2"; shift 2 ;;
      -icons) use_icons=1; shift;;
      *) break ;;
    esac
  done
  # read lines
  if ((use_icons)); then
    while (($#>=2)); do
      icons+=("$1"); shift;
      lines+=("$1"); shift;
    done
  else
    while [[ $# -gt 0 ]]; do
      icons+=("")
      lines+=("$1"); shift;
    done
  fi

  local _set_colors
  _set_colors() {
    print -rn -- "$box_fg$box_bg"
  }

  local _reset_colors
  _reset_colors() {
    print -rn -- "$reset_color"
  }

  _draw_corner () {
    print -rn -- "$style[$1]"
  }

  _draw_horizontal_edge () {
    local row=$1
    local total_width="$(( box_max_width + ($line_spacing * 2) ))"
    repeat $total_width; do print -rn "$style[rp,$row]"; done
  }

  _draw_vertical_edge () {
    local col=$1
    print -rn -- "$style[$col,mid]"
  }

  _draw_top_left () { _draw_corner le,top }
  _draw_top_right () { _draw_corner re,top; print }
  _draw_bot_left () { _draw_corner le,bot }
  _draw_bot_right () { _draw_corner re,bot; print }

  _draw_bot_edge () { _draw_horizontal_edge bot }
  _draw_top_edge () { _draw_horizontal_edge top }
  _draw_left_edge () { _draw_vertical_edge le }
  _draw_right_edge () { _draw_vertical_edge re }

  local _header
  _header() {
    _set_colors
    _draw_top_left 
    print -rn -- "$style[sp,top]"
    _draw_top_edge
    _draw_top_right
    _reset_colors
  }

  local _footer
  _footer() {
    _set_colors
    _draw_bot_left 
    print -rn -- "$style[sp,bot]"
    _draw_bot_edge
    _draw_bot_right
    _reset_colors
  }

  local _max_width() {
    local max_width=0
    emulate -L zsh
    zmodload zsh/regex

    local s=$1
    local re=$'\x1b\\[[0-9;?]*[ -/]*[@-~]'   # ANSI CSI sequences

    while [[ $s =~ $re ]]; do
      s=${s[1,$((MBEGIN-1))]}${s[$((MEND+1)),-1]}
    done

    print -r -- ${#s}
  }

  local _fit
  _fit() {
    local max_width="$1"
    local spacing="$2"
    local s="$3"
    local n=$(_max_width $s)
    print -n -- "${(l:$spacing:: :)}"
    if (( n > $max_width )); then
      print -rn -- "${s[1,max_width]}"
    else
      print -rn -- "${s}$(printf '%*s' $((max_width-n)) '')"
    fi
    print -r -- "${(l:$spacing:: :)}"
  }

  _fit_line() {
    _fit $max_line_width $line_spacing "$1"
  }

  _fit_icon() {
    _fit $max_icon_width 0 "$1"
  }

  local _line
  _line() {
    if ((use_icon)); then
    fi
    line=$(_fit_line "$1")
    icon=$(_fit_icon "$2")
    _set_colors
    _draw_left_edge
    print -rn -- "$icon"
    print -rn -- "$style[sp,mid]"
    print -rn -- "$line"
    _draw_right_edge
    _reset_colors
    print
  }


  local -x max_line_width=$(_max_width "${lines[@]}")
  local -x max_icon_width=$(_max_width "${icons[@]}")
  local -x box_max_width
  if ((use_icons)); then
    box_max_width=$(( max_line_width + max_icon_width ))
  else
    box_max_width=$max_line_width
  fi

  _header $box_max_width
  for ((i=1; i<=${#lines}; i++)); do
    _line "${lines[i]}" "${icons[i]}"
  done
  _footer $box_max_width

}


boxdraw() {
  emulate -L zsh
  setopt localoptions noshwordsplit

  local W=23
  local ICONW=1
  local PAD=1

  local title="" icon1="" line1="" icon2="" line2=""
  local -a lines

  # Simple mode: positional lines
  if [[ $# -gt 0 && $1 != --* ]]; then
    lines=("$@")
  else
    # Flag mode
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --width)    W="$2"; shift 2 ;;
        --title)    title="$2"; shift 2 ;;
        --icon1)    icon1="$2"; shift 2 ;;
        --line1)    line1="$2"; shift 2 ;;
        --icon2)    icon2="$2"; shift 2 ;;
        --line2)    line2="$2"; shift 2 ;;
        --) shift; break ;;
        *) lines+=("$1"); shift ;;
      esac
    done
    [[ -n $line1 ]] && lines+=("$line1")
    [[ -n $line2 ]] && lines+=("$line2")
  fi

  local _wcwidth
  _wcwidth() {
    print -rC1 -- "$@" | wc -L
  }

  local w
  W=$(print -rC1 -- "${lines[@]}" | wc -L)

  local _fit
  _fit() {
    local s="$1"
    local n=$(_wcwidth "$s")
    if (( n > W )); then
      print -r -- "${s[1,W]}"
    else
      print -r -- "${s}$(printf '%*s' $((W-n+1)) '')"
    fi
  }

  _rev() { print "\e[7m$1\e[27m"; }


  local top="▗████$(printf '▀%.0s' {1..$((W+ICONW+PAD))})▜█"
  local bot="▝████$(printf '▄%.0s' {1..$((W+ICONW+PAD))})▟█"

  print -r -- "  $fg[magenta]$top"

  # If you want a fixed 2-line layout like your example, use icon1/icon2.
  if [[ -n $icon1 || -n $icon2 ]]; then
    local t1="$(_fit "${lines[1]:-$title}")"
    local t2="$(_fit "${lines[2]}")"

    # icon block looks like: ██▌  (so: █ + icon + █▌)
    print -r -- "  ▐█$(_rev "${icon1:-}")█▌ $(print -r -- "$fg[blue]$t1$fg[magenta]") █▌"
    print -r -- "  ▐█$(_rev "${icon2:-}")█▌ $(print -r -- "$fg[blue]$t2$fg[magenta]") █▌"
  else
    # Generic: no icon column, just text lines
    local L
    for L in "${lines[@]}"; do
      print -r -- "  ▐███▌ $(_fit "$L") █▌"
    done
  fi

  print -r -- "  $bot$reset_color"
}
# ▬▰▱▭
# boxdraw "host °zqf°" "space: ▰▰▰▰▰▱▱▱▱ 6/10 GiB"
# echo
boxdraw --title "host °zqf°" --icon1 "" --line1 "host °zqf°" --icon2 "" --line2 "user::zqf"
echo

_draw_box() {
  for x in "$@"; do
    print -r -- "$x"
  done
}

_move_cursor() {
  print "\e[$1;$2H"
}

_draw_box_at() {
  local row=$1 col=$2; shift 2
  local i=0
  for l in "$@"; do
    print -r -- "$(_move_cursor $((row+i)) $col)$l"
    ((i++))
  done
}


local -a box

#box=("${(@f)$(_make_infobox "i1" "l1" "i2" "l2.")}")
#_draw_box "${box[@]}"

local -Ax style

_define_box_style_simple
box=("${(@f)$(_make_infobox -icons "" "host °zqf°" "" "user::zqf")}")
_draw_box "${box[@]}"

_define_box_style_fancy 
box=("${(@f)$(_make_infobox -icons "" "host °zqf°" "" "user::zqf")}")
_draw_box "${box[@]}"

txt=("${(@f)$(~/Downloads/hyprtxt/hyprtxt 'zsh-boxes')}")
box=("${(@f)$(_make_infobox -line-spacing 3 "${txt[@]}")}")
_draw_box "${box[@]}"
echo

# box=("${(@f)$(_make_infobox -fg "$fg[yellow]" -bg $bg[magenta] -line-spacing 3 xxx)}")
# _draw_box "${box[@]}"
# _draw_box_at 8 17 "${box[@]}"
#
# box=("${(@f)$(_make_infobox -fg "$fg[yellow]" -line-spacing 3 "${fg[blue]}blue")}")
# _draw_box_at 8 40 "${box[@]}"
