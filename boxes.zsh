#!/bin/zsh
autoload -Uz colors
colors


_define_box_style_simple () {
  style=(
    le,top "╔"
    le,mid "║"
    le,bot "╚"
    lp,top "═"
    lp,bot "═"
    sp,top "╤"
    sp,mid "│"
    sp,bot "╧"
    rp,top "═"
    rp,bot "═"
    re,top "╗"
    re,mid "║"
    re,bot "╝"
  )
}

_define_box_style_fancy () {
  style=(
    le,top "▗█"
    le,mid "▐█"
    le,bot "▝█"
    lp,top "█"
    lp,bot "█"
    sp,top "██"
    sp,mid "█▌"
    sp,bot "██"
    rp,top "▀"
    rp,bot "▄"
    re,top "▜█▖"
    re,mid " █▌"
    re,bot "▟█▘"
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

  local _set_colors () {
    print -rn -- "$box_fg$box_bg"
  }

  local _reset_colors () {
    print -rn -- "$reset_color"
  }

  local _draw_lr_edge () {
    print -rn -- "$style[$1]"
  }

  local _draw_lr_panel_tb () {
    repeat $(($1+($2*2))); do print -rn "$style[$3]"; done
  }

  local _draw_le_top () { _draw_lr_edge le,top }
  local _draw_le_mid () { _draw_lr_edge le,mid }
  local _draw_le_bot () { _draw_lr_edge le,bot }

  local _draw_re_top () { _draw_lr_edge re,top }
  local _draw_re_mid () { _draw_lr_edge re,mid }
  local _draw_re_bot () { _draw_lr_edge re,bot }

  local _draw_sp_top () { _draw_lr_edge sp,top }
  local _draw_sp_mid () { _draw_lr_edge sp,mid }
  local _draw_sp_bot () { _draw_lr_edge sp,bot }

  local _draw_lp_top () { _draw_lr_panel_tb $max_lp_width 0 lp,top }
  local _draw_lp_mid () { print -rn -- "$1" }
  local _draw_lp_bot () { _draw_lr_panel_tb $max_lp_width 0 lp,bot }

  local _draw_rp_top () { _draw_lr_panel_tb $max_rp_width $line_spacing rp,top }
  local _draw_rp_mid () { print -rn -- "$1" }
  local _draw_rp_bot () { _draw_lr_panel_tb $max_rp_width $line_spacing rp,bot }

  local _draw_header () {
    _set_colors
    _draw_le_top
    _draw_lp_top
    _draw_sp_top
    _draw_rp_top
    _draw_re_top
    _reset_colors
    print
  }

  local _draw_footer () {
    _set_colors
    _draw_le_bot 
    _draw_lp_bot
    _draw_sp_bot
    _draw_rp_bot
    _draw_re_bot
    _reset_colors
    print
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
    _fit $max_rp_width $line_spacing "$1"
  }

  _fit_icon() {
    _fit $max_lp_width 0 "$1"
  }

  local _draw_line () {
    _set_colors
    _draw_le_mid
    _draw_lp_mid "$1"
    _draw_sp_mid
    _draw_rp_mid "$2"
    _draw_re_mid
    _reset_colors
    print
  }


  local -x max_lp_width=$(_max_width "${icons[@]}")
  local -x max_rp_width=$(_max_width "${lines[@]}")

  _draw_header
  for ((i=1; i<=${#lines}; i++)); do
    _draw_line "${icons[i]}" "${lines[i]}"
  done
  _draw_footer

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
echo

_define_box_style_fancy 
box=("${(@f)$(_make_infobox -icons "" "host °zqf°" "" "user::zqf")}")
_draw_box "${box[@]}"
echo

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
