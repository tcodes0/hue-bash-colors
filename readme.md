# Hue

![help.png](https://user-images.githubusercontent.com/15015324/39720286-36d27e48-5212-11e8-9c53-9cbbe19fef5a.png)
## Use Hue like echo

**To view the above message use -h or --help:**

    $ hue.sh -h

**Classic ANSI colors have switches with their names:**

    $ hue.sh --teal will show in teal

**They all have a *light-* variant:**

    $ hue.sh --light-teal will show in light teal

--default will probably be a light tone on a dark background terminal, and a black tone in a white themed one.
--white will always show white, just like --black will show black.
Don't ask me what light-white means, though

When using --bold the color becomes the light- version automatically.

**256color is available using **--hue=**_color\_code_:**

    $ hue.sh --hue=79 a blend of teal and green perhaps?
    $ hue.sh --hue=53 reminds me of grapes

**Add styles using switches too:**

    $ hue.sh --bold Important text.
    $ hue.sh --underline remember this.

View the complete list of styles and ANSI color switches using `$ hue.sh -h`

**Add backgrounds using **--bg=**_ANSI\_color_:**

    $ hue.sh --bg=pink a pink box with text

**256color backgrounds need the --swap switch:**

    $ hue.sh --hue=172 --swap will show in a dark orange background

**256color background with ANSI text color:**

    $ hue.sh --hue=172 --swap --bg=teal same as above, with teal text

--swap exchanges foreground and background color, try it!


**To view all 256color codes use:**

    $ hue.sh --view=256

![256.png](https://user-images.githubusercontent.com/15015324/39611277-ff7aa6ec-4f2c-11e8-90c2-5b86acdeae23.png)

**To view all ANSI colors:**

    $ hue.sh --view=ansi

![ansi.png](https://user-images.githubusercontent.com/15015324/39611278-ff9eeb9c-4f2c-11e8-8ac9-59724624c0a0.png)


## Other things it does

**Output internal code, for your reuse:**

    $ hue.sh --hue=99 --swap --underline --code
    < printf "\033[4;7;38;05;99m\033[0m"

**Suppress newline printing:**

    $ hue.sh -n
    $ hue.sh --newline

**Classic ANSI color dump:**

    $ hue.sh --palette

All combinations of ANSI colors, backgrounds and styles. _Warning: long output!_

**The help message is there to help:**

    $ hue.sh -h


## Installation

Download or clone the repo, then put hue.sh in your `$HOME/bin/` directory (or whatever directory you use for bash scripts)


## A note from me

I wrote this for my own use to make coloring the terminal easier (to do, remember and read).
I like the --code switch specially.

#### _Make the shell work for you!_