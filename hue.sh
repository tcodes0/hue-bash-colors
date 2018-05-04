#! /usr/bin/env bash
#- - - - - - - - - - - - - - - - - - - - - - - - -
#                 HELPER FUNCTIONS
#- - - - - - - - - - - - - - - - - - - - - - - - -

#exits with a message
bailout() {
	local message=$@
	if [[ "$#" == "0" ]]; then
		message="error"
	fi
	echo -ne "\e[1;31m❌\040 $message\e[0m"
	if [[ ! "$-" =~ i ]]; then
		#shell is not interactive, so kill it.
		exit 1
	fi
}

parse-options() {
  #input   - $@ or string containing shorts (-s), longs (--longs), and arguments
  #returns - arrays with parsed data and opts set as vars
  #exports a var for each option. (-s => $s, --foo => $foo, --long-opt => $long_opt)
  #"-" are translated into "_"
  #"--" signals the end of options
  #shorts take no arguments, to give args to an option use a --long=arg

  if [[ "$#" == 0 ]]; then
    return
  fi

  # Opts we may have inherited from a parent function also using parse-options. Unset to void collisions.
  if [ "$allOptions" ]; then
    for opt in ${allOptions[@]}; do
      unset $opt
    done
  fi

  local argn long short noMoreOptions

  #echo to split quoted args, repeat until no args left
  for arg in $(echo "$@"); do
    argn=$(($argn + 1))

    # if flag set
    if [[ "$noMoreOptions" ]]; then
      #end of options seen, just push remaining args
      arguments+=($arg)
      continue
    fi

    # if end of options is seen
    if [[ "$arg" =~ ^--$ ]]; then
      # set flag to stop parsing
      noMoreOptions="true"
      continue
    fi

    # if long
    if [[ "$arg" =~ ^--[[:alnum:]] ]]; then
      #start on char 2, skip leading --
      long=${arg:2}
      # substitute any - with _
      long=${long/-/_}
      # if opt has an =, it means it has an arg
      if [[ "$arg" =~ ^--[[:alnum:]][[:alnum:]]+= ]]; then
        # split opt from arg. Ann=choco makes export ann=choco
        export ${long%=*}="${long#*=}"
        longsWithArgs+=(${long%=*})
      else
        #no arg, just push
        longs+=($long)
      fi
      continue
    fi

    # if short
    if [[ "$arg" =~ ^-[[:alnum:]] ]]; then
      local i=1 #start on 1, skip leading -
      # since shorts can be chained (-gpH), look at one char at a time
      while [ $i != ${#arg} ]; do
        short=${arg:$i:1}
        shorts+=($short)
        i=$((i + 1))
      done
      continue
    fi

    # not a long or short, push as an arg
    arguments+=($arg)
  done

  # give opts with no arguments value "true"
  for short in ${shorts[@]}; do
    export $short="true"
  done

  for long in ${longs[@]}; do
    export $long="true"
  done

  export allOptions="$(get-shorts)$(get-longs)"
}

#part of parse-options
get-shorts() {
  if [ "$shorts" ]; then
    for short in ${shorts[@]}; do
      echo -ne "$short "
    done
  fi
}

#part of parse-options
get-longs() {
  if [ "$longs" ]; then
    for long in ${longs[@]}; do
      echo -ne "$long "
    done
  fi
  if [ "$longsWithArgs" ]; then
    for long in ${longsWithArgs[@]}; do
      echo -ne "${long}* "
    done
  fi
}

#part of parse-options
get-arguments() {
  for arg in ${arguments[@]}; do
    echo -ne "$arg "
  done
}
#- - - - - - - - - - - - - - - - - - - - - - - - -
#                      MAIN
#- - - - - - - - - - - - - - - - - - - - - - - - -
parse-options "$@"

#start of a color sequence
_s="\033["
#clear colors
__="${_s}0m"
#256color start sequence
_x="38;05;"

print-all-combinations(){
  for bg in {40..47} {100..107} 49 ; do
    for fg in {30..37} {90..97} 39 ; do
      for fm in 0 1 2 3 4 5 7 ; do
        printf "${_s}${fm};${bg};${fg}m \"\\${_s}${fm};${bg};${fg}m\" ${_s}0m"
      done
      printf "\n"
    done
  done
}

_256(){
  # arg 1: 256 color code $number.
  # output: 38;05;$number
  echo -n "${_x}${1}"
}

print-256-colors(){
  local bg
  for color in {0..255}; do 
    echo -ne "${_s}$(_256 $color)m $(printf %03d $color)${__}"
    echo -ne "${_s}7;$(_256 $color)m $(printf %03d $color)${__}"
    if [ $((${color} % 12)) == 3 ]; then 
      printf "\n"
    fi
  done
  echo -ne "${__}"
}

print-ansi-colors(){
  # Original: https://github.com/stark/Color-Scripts/blob/master/color-scripts/colorview
  # Modified by Aaron Griffin
  # and further by Kazuo Teramoto
  # Color-scripts by Stark

  local FGNAMES=('black ' 'red' 'green' 'yellow' 'purple ' 'pink' 'teal ' 'white ' 'no 8' 'default ')
  local BGNAMES=('default' 'black  ' 'red    ' 'green  ' 'yellow ' 'purple ' 'pink   ' 'teal   ' 'white  ')
  #controls distance between columns
  local gutter="   "

  echo -e "\n${_s}7;49m* Bg * ${__}$gutter${_s}7;49m  ****************   Normal and bold foreground   ****************  ${__}"
  for b in {0..8}; do
    ((b>0)) && bg=$((b+39))

    #Left blank
    echo -en "${__}${_s}7;39;49m       ${__}$gutter"
    
    #Normal color row
    for f in {0..7} 9; do
      echo -en "${_s}${bg};$((f+30))m  ${FGNAMES[f]}"
    done
    echo -en "${__}"

    #Left Background color name
    echo -en "${__}\n${_s}7;39;49m${BGNAMES[b]}${__}$gutter"
    
    #Bold color row
    for f in {0..7} 9; do
      echo -en "${_s}${bg};1;$((f+30))m  ${FGNAMES[f]}"
    done
    echo -en "${__}\n"

    #Spacer
    ((b<8)) && echo -e "${_s}7;m       ${__}"
  done
}

candy(){
  echo "┌────────────────────────────────────────────────────────────┐"
  echo "├      Normal backgroud              Light background        ┤"
  echo "├    Normal          Bold           Normal          Bold     ┤"
  echo "└────────────────────────────────────────────────────────────┘"
  j=1
  for fg in 30 90 31 91 32 92 33 93 34 94 35 95 36 96 37 97 39; do
    for bg in 40 100 41 101 42 102 43 103 44 104 45 105 46 106 47 107; do
      for fm in 0 1; do
        if [ "$fm" == 0 ]; then
          if [ "$bg" == 49 ]; then
            buffer+="\n\n"
          fi
          buffer+=$(printf "${_s}${fm};${bg};${fg}m \"\\${_s}${fm};${bg};${fg}m\" ${_s}0m")
        else
          buffer+=$(printf "${_s}${fm};${bg};${fg}m \"\\${_s}${fm};${bg};${fg}m\" ${_s}0m")
        fi

        if [ "$((j % 4))" == 0 ]; then
          echo $buffer
          unset buffer
        fi

        j=$((j+1))
      done
    done
  done
}

#this var stores user selected colors
sequence="${_s}"

if [ "$h" -o "$help" -o "$#" == 0 ]; then
  echo -e "\
  \n${_s}4;${_x}160m♦ HUE.SH ${_s}1;${_x}161mHELPS ${_s}0;4;${_x}162mTO MAKE ${_s}1;${_x}163mTHE TERMINAL ${_s}0;4;${_x}164mPRETTIER!${__}\
  \n${_s}4;${_x}220m♦ HUE.SH ${_s}1;${_x}221mHELPS ${_s}0;4;${_x}222mTO MAKE ${_s}1;${_x}223mTHE TERMINAL ${_s}0;4;${_x}224mPRETTIER!${__}\
  \n${_s}4;${_x}70m♦ HUE.SH ${_s}1;${_x}71mHELPS ${_s}0;4;${_x}72mTO MAKE ${_s}1;${_x}73mTHE TERMINAL ${_s}0;4;${_x}74mPRETTIER!${__}\
  \n${_s}4;${_x}20m♦ HUE.SH ${_s}1;${_x}21mHELPS ${_s}0;4;${_x}22mTO MAKE ${_s}1;${_x}23mTHE TERMINAL ${_s}0;4;${_x}24mPRETTIER!${__}
  \n♦︎ $ hue.sh --pink --bold hue.sh works like an echo on steroids for colors\
  \n  < ${_s}35;1;49mhue.sh works like an echo on steroids for colors${__}
  \n♦ $ hue.sh --red --underline --swap --bg=teal Hello!\
  \n  < ${_s}4;7;31;46mHello!${__}
  \n♦ ${_s}4mANSI colors:${__}
  ${_s}7;30m 30 ${__}${_s}1;30m 30 ${__}--black        ${_s}7;34m 34 ${__}${_s}1;34m 34 ${__}--purple
  ${_s}7;31m 31 ${__}${_s}1;31m 31 ${__}--red          ${_s}7;35m 35 ${__}${_s}1;35m 35 ${__}--pink
  ${_s}7;32m 32 ${__}${_s}1;32m 32 ${__}--green        ${_s}7;36m 36 ${__}${_s}1;36m 36 ${__}--teal
  ${_s}7;33m 33 ${__}${_s}1;33m 33 ${__}--yellow       ${_s}7;37m 37 ${__}${_s}1;37m 37 ${__}--white
  ${_s}7;39m 39 ${__}${_s}1;39m 39 ${__}--default
  ${_s}7;90m 90 ${__}${_s}1;90m 90 ${__}--light-black  ${_s}7;94m 94 ${__}${_s}1;94m 94 ${__}--light-purple
  ${_s}7;91m 91 ${__}${_s}1;91m 91 ${__}--light-red    ${_s}7;95m 95 ${__}${_s}1;95m 95 ${__}--light-pink
  ${_s}7;92m 92 ${__}${_s}1;92m 92 ${__}--light-green  ${_s}7;96m 96 ${__}${_s}1;96m 96 ${__}--light-teal
  ${_s}7;93m 93 ${__}${_s}1;93m 93 ${__}--light-yellow ${_s}7;97m 97 ${__}${_s}1;97m 97 ${__}--light-white
  \n♦ ${_s}4m256color:${__}${_s}2;49m#${__}
  ${_s}7;${_x}86m 86 ${__}${_s}${_x}86;49m 86 ${__}--color=86     ${_s}7;${_x}204m 204 ${__}${_s}${_x}204;49m 204 ${__}--color=204
  ${_s}7;${_x}53m 53 ${__}${_s}${_x}53;49m 53 ${__}--color=53     ${_s}7;${_x}220m 220 ${__}${_s}${_x}220;49m 220 ${__}--color=220
  \n♦ ${_s}4mstyles${_s}2;49m*${__}
  ${_s}1;7;99m 01 ${__} ${_s}1m--bold${__}            ${_s}7;99m ${_s}4m04${_s}24m ${__} ${_s}4m--underline${__}
  ${_s}2;7;99m 02 ${__} ${_s}2m--dim${__}             ${_s}5;7;99m 05 ${__} ${_s}5m--blink${__}${_s}2;49m#${__}
  ${_s}3;7;99m 03 ${__} ${_s}3m--italic.${_s}2;49m#${__}        ${_s}7;99m 07 ${__} ${_s}7m--swap${__}${_s}2;49m+${__}
  \n  ${_s}2;49m* You can combine them!${__}
  ${_s}2;49m# Depends on terminal emulator support.${__}
  ${_s}2;49m+ Swap works swaping foreground and background color.${__}
  \n♦ ${_s}4mbackgrounds${__}
  ${_s}107;30m--bg=default${__}           ${_s}46m--bg=teal${__}
  ${_s}100m--bg=light-black${__}       --bg=${_s}3m...any ANSI color!${__}
  ${_s}7;38;05;150;49m--color=150 --swap${__}     ${_s}7;38;05;20;49m--color=20 --swap${__}
  \n♦ ${_s}4mmore options:${__}
  --code                 output color code only
  --pallete              view all possible ANSI combinations
  --view=ansi            view ANSI color preview
  --view=256             view 256color preview
  --newline, -n          don't print a newline"
#  --candy                🍫 🌈
#  "
  exit
fi

case "true" in
  "$pallete") print-all-combinations && exit ;;
  "$candy") candy && exit ;;
esac

if 
  [ "$view" == "ansi" -o "$view" == "ANSI" ]; then print-ansi-colors && exit; elif
  [ "$view" == "256" ]; then print-256-colors && exit 
fi

# styles
# only (bold or default) or only (bold) prints yellow. Implementation quirk.
if [ $bold ]; then  sequence+="1;"; fi
if [ $dim ]; then  sequence+="2;"; fi
if [ $italic ]; then  sequence+="3;"; fi
if [ $underline ]; then  sequence+="4;"; fi
if [ $blink ]; then  sequence+="5;"; fi
if [ $swap ]; then  sequence+="7;"; fi

# foregrounds
if [[ "$color" =~ [[:digit:]] ]]; then
  if [[ "$color" =~ _ ]] || [ "$color" -gt 255 ]; then
    echo -e "${_s}1;33;m WARNING: $color is out of bounds for 256 color codes.
          Use a number between 0 and 255.${__}"
  else
    sequence+="$(_256 $color);"
  fi
elif [ $black ]; then  sequence+="30;"
elif [ $red ]; then  sequence+="31;"
elif [ $green ]; then  sequence+="32;"
elif [ $yellow ]; then  sequence+="33;"
elif [ $purple ]; then  sequence+="34;"
elif [ $pink ]; then  sequence+="35;"
elif [ $teal ]; then  sequence+="36;"
elif [ "$white" ]; then  sequence+="37;"
elif [ $default ]; then  sequence+="39;"
elif [ $light_black ]; then  sequence+="90;"
elif [ $light_red ]; then  sequence+="91;"
elif [ $light_green ]; then  sequence+="92;"
elif [ $light_yellow ]; then  sequence+="93;"
elif [ $light_purple ]; then  sequence+="94;"
elif [ $light_pink ]; then  sequence+="95;"
elif [ $light_teal ]; then  sequence+="96;"
elif [ "$light_white" ]; then  sequence+="97;"
fi

# backgrounds
case $bg in
  black)  sequence+="40;" ;;
  red)  sequence+="41;" ;;
  green)  sequence+="42;" ;;
  yellow)  sequence+="43;" ;;
  purple)  sequence+="44;" ;;
  pink)  sequence+="45;" ;;
  teal)  sequence+="46;" ;;
  white)  sequence+="47;" ;;
  default)  sequence+="49;" ;;
  light_black)  sequence+="100;" ;;
  light_red)  sequence+="101;" ;;
  light_green)  sequence+="102;" ;;
  light_yellow)  sequence+="103;" ;;
  light_purple)  sequence+="104;" ;;
  light_pink)  sequence+="105;" ;;
  light_teal)  sequence+="106;" ;;
  light_white)  sequence+="107;" ;;
  *)  sequence+="" ;;
esac

#trim last character (;) to close sequence with m
sequence=${sequence:0:-1}"m"

if [ "$code" ]; then
  #print sequence as-is. Add 'printf \"' so user can copy paste output
  echo -n "printf \"$sequence"
  if [ "$(get-arguments)" ]; then
    # print all arguments, if any
    printf -- "$(get-arguments)"
  fi
  #close \" clear formatting
  echo -n "${__}\""
  # echo -n "\" && printf \"${__}\" && printf \"\n\""
else
  #interpret sequence to produce colored output
  printf "$sequence$(get-arguments)"
fi

# clear formatting
printf "${__}"

#print a newline
if ! [ "$n" -o "$newline" ]; then
  printf "\n"
fi
