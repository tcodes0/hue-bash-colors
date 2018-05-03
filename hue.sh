#! /usr/bin/env bash
# Vadd 256 support.
# 
# 
# 
# 
# 
# 
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
#                 SUB ROUTINES
#- - - - - - - - - - - - - - - - - - - - - - - - -

#start of a color sequence
s="\e["
#clear colors
end="${s}0m"

print-all-combinations(){
  for bg in {40..47} {100..107} 49 ; do
    for fg in {30..37} {90..97} 39 ; do
      for fm in 0 1 2 3 4 5 7 ; do
        printf "${s}${fm};${bg};${fg}m \"\\${s}${fm};${bg};${fg}m\" ${s}0m"
      done
      printf "\n"
    done
  done
}

_256(){
  # arg 1: 256 color code number.
  # output: color code with no start or end
  echo -n "38;05;${1}"
}

print-256-colors(){
  for color in {0..255}; do 
    echo -ne "${s}$(_256 $color)m $(printf %03d $color)"
    if [ $((${color} % 16)) == 15 ]; then 
      printf "\n"
    fi
  done
  echo -ne "$end"
}

print-ansi-colors(){
  # Original: https://github.com/stark/Color-Scripts/blob/master/color-scripts/colorview
  # Modified by Aaron Griffin
  # and further by Kazuo Teramoto
  # Color-scripts by Stark
  # Today is may/2018

  FGNAMES=('black ' 'red' 'green' 'yellow' 'purple ' 'pink' 'teal ' 'white ')
  BGNAMES=('DFT' 'BLK' 'RED' 'GRN' 'YEL' 'BLU' 'MAG' 'CYN' 'WHT')

  # echo "     ┌──────────────────────────────────────────────────────────────────────────┐"
  for b in {0..8}; do
    ((b>0)) && bg=$((b+39))

    echo -en "\033[0m ${BGNAMES[b]}    "
    
    for f in {0..7}; do
      echo -en "\033[${bg};$((f+30))m  ${FGNAMES[f]}"
    done
    
    echo -en "\033[0m"
    echo -en "\033[0m\n\033[0m        "
    
    for f in {0..7}; do
      echo -en "\033[${bg};1;$((f+30))m  ${FGNAMES[f]}"
    done

    echo -en "\033[0m"
    echo -e "\033[0m"

    ((b<8)) &&
    echo -e " "
  done
  # echo "     └──────────────────────────────────────────────────────────────────────────┘"
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
          buffer+=$(printf "${s}${fm};${bg};${fg}m \"\\${s}${fm};${bg};${fg}m\" ${s}0m")
        else
          buffer+=$(printf "${s}${fm};${bg};${fg}m \"\\${s}${fm};${bg};${fg}m\" ${s}0m")
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

#- - - - - - - - - - - - - - - - - - - - - - - - -
#                      MAIN
#- - - - - - - - - - - - - - - - - - - - - - - - -
parse-options "$@"

#this var stores user selected colors
sequence="$s"

if [ "$h" -o "$help" -o "$#" == 0 ]; then
  echo -e "${s}4;35mHUE.SH ${s}34;1mHELPS ${s}0;4;33mTO MAKE ${s}1;32mTHE TERMINAL ${s}0;4;36mPRETTIER!$end
  \n♦︎ $ hue.sh --pink --bold foobar\
  \n  < ${s}35;1;49mfoobar$end
  \n♦ $ hue.sh --red --underline --swap Hello!\
  \n  < ${s}7;4;31mHello!$end
  \n♦ ${s}4mANSI colors:$end
  ${s}7;30m 30 $end${s}1;30m 30 $end--black           ${s}7;34m 34 $end${s}1;34m 34 $end--purple
  ${s}7;31m 31 $end${s}1;31m 31 $end--red             ${s}7;35m 35 $end${s}1;35m 35 $end--pink
  ${s}7;32m 32 $end${s}1;32m 32 $end--green           ${s}7;36m 36 $end${s}1;36m 36 $end--teal
  ${s}7;33m 33 $end${s}1;33m 33 $end--yellow          ${s}7;37m 37 $end${s}1;37m 37 $end--grey
  ${s}7;39m 39 $end${s}1;39m 39 $end--default
  ${s}7;90m 90 $end${s}1;90m 90 $end--light-black     ${s}7;94m 94 $end${s}1;94m 94 $end--light-purple
  ${s}7;91m 91 $end${s}1;91m 91 $end--light-red       ${s}7;95m 95 $end${s}1;95m 95 $end--light-pink
  ${s}7;92m 92 $end${s}1;92m 92 $end--light-green     ${s}7;96m 96 $end${s}1;96m 96 $end--light-teal
  ${s}7;93m 93 $end${s}1;93m 93 $end--light-yellow    ${s}7;97m 97 $end${s}1;97m 97 $end--light-grey
  \n♦ ${s}4mstyles${s}90;49m*$end
  ${s}1m--bold$end            ${s}4m--underline$end
  ${s}2m--dim$end             ${s}5m--blink$end
  ${s}7m--swap$end${s}90;49m+$end           ${s}3m--italic${s}90;49m#$end
  \n  ${s}90;49m* You can combine them!$end
  ${s}90;49m# Terminal font must support italic$end
  ${s}90;49m+ Swap works swaping foreground and background color!$end
  \n♦ ${s}4mbackgrounds$end
  ${s}107;30m--bg=default$end      ${s}40m--bg=black$end
  ${s}100m--bg=light-black$end  ${s}46;30m--bg=${s}3m...any ANSI color!$end
  \n♦ ${s}4mmore options:$end
  --code          output color code only
  --pallete       show all possibilities
  --ansi          show ANSI color preview
  --more-colors   show 256 color preview
  --candy         pretty
  "
  exit
fi

case "true" in
  "$more_colors") print-256-colors && exit ;;
  "$pallete") print-all-combinations && exit ;;
  "$ansi") print-ansi-colors && exit ;;
  "$candy") candy && exit ;;
esac

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
    echo -e "${s}1;33;m WARNING: $color is out of bounds for 256 color codes.
          Use a number between 0 and 255.$end"
  else
    sequence+="$(_256 $color);"
  fi
fi

if [ $black ]; then  sequence+="30;"
elif [ $red ]; then  sequence+="31;"
elif [ $green ]; then  sequence+="32;"
elif [ $yellow ]; then  sequence+="33;"
elif [ $purple ]; then  sequence+="34;"
elif [ $pink ]; then  sequence+="35;"
elif [ $teal ]; then  sequence+="36;"
elif [ "$gray" -o "$grey" ]; then  sequence+="37;"
elif [ $default ]; then  sequence+="39;"
elif [ $light_black ]; then  sequence+="90;"
elif [ $light_red ]; then  sequence+="91;"
elif [ $light_green ]; then  sequence+="92;"
elif [ $light_yellow ]; then  sequence+="93;"
elif [ $light_purple ]; then  sequence+="94;"
elif [ $light_pink ]; then  sequence+="95;"
elif [ $light_teal ]; then  sequence+="96;"
elif [ "$light_gray" -o "$light_grey" ]; then  sequence+="97;"
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
  gray | grey)  sequence+="47;" ;;
  default)  sequence+="49;" ;;
  light_black)  sequence+="100;" ;;
  light_red)  sequence+="101;" ;;
  light_green)  sequence+="102;" ;;
  light_yellow)  sequence+="103;" ;;
  light_purple)  sequence+="104;" ;;
  light_pink)  sequence+="105;" ;;
  light_teal)  sequence+="106;" ;;
  light_gray | light_grey)  sequence+="107;" ;;
  *)  sequence+="49;" ;;
esac

#trim last character (;) to close sequence
sequence=${sequence:0:-1}"m"

if [ "$code" ]; then
  #print sequence as-is. Add 'printf \"' so user can copy paste output
  echo -n "printf \"$sequence"
  if [ "$(get-arguments)" ]; then
    # print all arguments, if any
    printf "$(get-arguments)"
  fi
  #close \", suggest a newline and a printf to clear formatting, justobesafe
  echo -n "\" && printf \"$end\" && printf \"\n\""
else
  #interpret sequence to produce colored output
  printf "$sequence$(get-arguments)"
fi

# clear formatting
printf "$end\n"
