#! /usr/bin/env bash
#- - - - - - - - - - - - - - - - - - - - - - - - -
#                 HELPER FUNCTIONS
#- - - - - - - - - - - - - - - - - - - - - - - - -
#pretty echo.
precho() {
  echo -e "\e[1m♦︎ $@\e[0m"
}

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
sequence="\e["

if [ "$h" -o "$help" -o "$#" == 0 ]; then
  echo -e "\e[1;36m♦︎ $ hue.sh --yellow --bold foobar\
  \n  < \e[33;1;49mfoobar\e[1;36m\
  \n  $ hue.sh --red --underline --box Hello!\
  \n  < \e[7;4;31mHello!\e[0m
  \n  \e[4;35mhue.sh \e[34;1mhelps \e[0;4;33mto make \e[1;32mthe terminal \e[0;4;36mprettier!\e[0m
  \n  \e[4mcolors:\e[0m
  --black           --red
  --purple          --pink
  --green           --teal
  --yellow          --grey
  --white
  --light-black     --light-purple
  --light-red       --light-pink
  --light-green     --light-teal
  --light-yellow    --light-grey
  \n  \e[4mstyles\e[37;49m*\e[0m
  --bold            --underline
  --dim             --blink
  --box             --italic\e[4;37;49m#\e[0m
  \n  \e[4;37;49m* You can combine them! (some combos don't work)\e[0m
  \e[4;37;49m# Terminal font must support italic\e[0m
  \n  \e[4mbackgrounds\e[4;37;49m*\e[0m:
  --bg=white        --bg=black
  --bg=light-black  --bg=\e[3m...any color!\e[0m
  \n  \e[4;37;49m* --box and --bg= override eachother!\e[0m
  \n  need \e[4minspiration\e[0m?
  --show-all
  \n  want to output \e[4mescape sequences\e[0m to use in code?
  --code"
  exit
fi

# styles
# only (bold or white) and (bold) prints yellow. Implementation quirk.
if [ $bold ]; then
  sequence=$sequence"1;"
fi
if [ $dim ]; then
  sequence=$sequence"2;"
fi
if [ $italic ]; then
  sequence=$sequence"3;"
fi
if [ $underline ]; then
  sequence=$sequence"4;"
fi
if [ $blink ]; then
  sequence=$sequence"5;"
fi
if [ $box ]; then
  sequence=$sequence"7;"
fi

# foregrounds
if [ $black ]; then
  sequence=$sequence"30;"
elif [ $red ]; then
  sequence=$sequence"31;"
elif [ $green ]; then
  sequence=$sequence"32;"
elif [ $yellow ]; then
  sequence=$sequence"33;"
elif [ $purple ]; then
  sequence=$sequence"34;"
elif [ $pink ]; then
  sequence=$sequence"35;"
elif [ $teal ]; then
  sequence=$sequence"36;"
elif [ "$gray" -o "$grey" ]; then
  sequence=$sequence"37;"
elif [ $white ]; then
  sequence=$sequence"39;"
elif [ $light_black ]; then
  sequence=$sequence"90;"
elif [ $light_red ]; then
  sequence=$sequence"91;"
elif [ $light_green ]; then
  sequence=$sequence"92;"
elif [ $light_yellow ]; then
  sequence=$sequence"93;"
elif [ $light_purple ]; then
  sequence=$sequence"94;"
elif [ $light_pink ]; then
  sequence=$sequence"95;"
elif [ $light_teal ]; then
  sequence=$sequence"96;"
elif [ "$light_gray" -o "$light_grey" ]; then
  sequence=$sequence"97;"
fi

# backgrounds
case $bg in
  black)
    sequence=$sequence"40;"
  ;;
  red)
    sequence=$sequence"41;"
  ;;
  green)
    sequence=$sequence"42;"
  ;;
  yellow)
    sequence=$sequence"43;"
  ;;
  purple)
    sequence=$sequence"44;"
  ;;
  pink)
    sequence=$sequence"45;"
  ;;
  teal)
    sequence=$sequence"46;"
  ;;
  gray | grey)
    sequence=$sequence"47;"
  ;;
  white)
    sequence=$sequence"49;"
  ;;
  light_black)
    sequence=$sequence"100;"
  ;;
  light_red)
    sequence=$sequence"101;"
  ;;
  light_green)
    sequence=$sequence"102;"
  ;;
  light_yellow)
    sequence=$sequence"103;"
  ;;
  light_purple)
    sequence=$sequence"104;"
  ;;
  light_pink)
    sequence=$sequence"105;"
  ;;
  light_teal)
    sequence=$sequence"106;"
  ;;
  light_gray | light_grey)
    sequence=$sequence"107;"
  ;;
  *)
    sequence=$sequence"49;"
  ;;
esac

#trim last character (a ;) to close sequence
sequence=${sequence:0:-1}"m"

if [ "$code" ]; then
  #print sequence as-is. Add 'printf \"' so user can copy paste output
  echo -n "printf \"$sequence"
  if [ "$(get-arguments)" ]; then
    # print all arguments, if any
    printf "$(get-arguments)"
  fi
  #close \", suggest a newline and a printf to clear formatting justobesafe
  echo -n "\" && printf \"\e[0m\" && printf \"\n\""
else
  #interpret sequence to produce colored output
  printf "$sequence$(get-arguments)"
fi

# clear formatting
printf "\e[0m\n"
