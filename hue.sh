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

if [ "$h" -o "$help" -o "$#" == 0 ]; then
  echo -e "\e[1;36m♦︎ $ hue.sh --yellow --bold foobar\
  \n  < \e[33;1;49mfoobar\e[1;36m\
  \n  $ hue.sh --red --underline --box Hello!\
  \n  < \e[7;4;31mHello!\e[0m
  \n  \e[4;35mhue.sh \e[34mhelps \e[33mto make \e[32mthe terminal \e[36mprettier!\e[0m
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
  \n  \e[4mstyles\e[0;1;4;32m*\e[0m
  --bold            --underline
  --dim             --blink
  --box             --italic\e[1;4;32m#\e[0m
  \n  \e[1;4;32m* You can combine them! (some combos don't work)\e[0m
  \e[1;4;32m# Terminal font must support italic\e[0m
  \n  \e[4mbackgrounds\e[0;1;4;33m*\e[0m:
  --bg=white        --bg=black
  --bg=light-black  --bg=\e[3m...any color!\e[0m
  \n  \e[1;4;33m* --box and --bg= override eachother!\e[0m
  \n  need \e[4minspiration\e[0m?
  --show-all
  \n  want to output \e[4mescape sequences\e[0m only?
  --code"
  exit
fi

# styles
# only (bold or white) and (bold) prints yellow. Implementation quirk.
if [ $bold ]; then
  printf "\e[1m"
fi
if [ $dim ]; then
  printf "\e[2m"
fi
if [ $italic ]; then
  printf "\e[3m"
fi
if [ $underline ]; then
  printf "\e[4m"
fi
if [ $blink ]; then
  printf "\e[5m"
fi
if [ $box ]; then
  printf "\e[7m"
fi

# foregrounds
if [ $black ]; then
  printf "\e[30m"
elif [ $red ]; then
  printf "\e[31m"
elif [ $green ]; then
  printf "\e[32m"
elif [ $yellow ]; then
  printf "\e[33m"
elif [ $purple ]; then
  printf "\e[34m"
elif [ $pink ]; then
  printf "\e[35m"
elif [ $teal ]; then
  printf "\e[36m"
elif [ "$gray" -o "$grey" ]; then
  printf "\e[37m"
elif [ $white ]; then
  printf "\e[39m"
elif [ $light_black ]; then
  printf "\e[90m"
elif [ $light_red ]; then
  printf "\e[91m"
elif [ $light_green ]; then
  printf "\e[92m"
elif [ $light_yellow ]; then
  printf "\e[93m"
elif [ $light_purple ]; then
  printf "\e[94m"
elif [ $light_pink ]; then
  printf "\e[95m"
elif [ $light_teal ]; then
  printf "\e[96m"
elif [ "$light_gray" -o "$light_grey" ]; then
  printf "\e[97m"
fi

# backgrounds
case $bg in
  black)
    printf "\e[40m"
  ;;
  red)
    printf "\e[41m"
  ;;
  green)
    printf "\e[42m"
  ;;
  yellow)
    printf "\e[43m"
  ;;
  purple)
    printf "\e[44m"
  ;;
  pink)
    printf "\e[45m"
  ;;
  teal)
    printf "\e[46m"
  ;;
  gray | grey)
    printf "\e[47m"
  ;;
  white)
    printf "\e[49m"
  ;;
  light_black)
    printf "\e[100m"
  ;;
  light_red)
    printf "\e[101m"
  ;;
  light_green)
    printf "\e[102m"
  ;;
  light_yellow)
    printf "\e[103m"
  ;;
  light_purple)
    printf "\e[104m"
  ;;
  light_pink)
    printf "\e[105m"
  ;;
  light_teal)
    printf "\e[106m"
  ;;
  light_gray | light_grey)
    printf "\e[107m"
  ;;
  *)
    printf "\e[49m"
  ;;
esac

# print all arguments
printf "$(get-arguments)"
# end formatting
printf "\e[0m\n"
