# Clang Bash Completion

This is a clang bash completion function that uses the same `clang --autocomplete="str"` 
command as the original function for generating completion words.
so there is no difference in the results.
just added a few features.

For example, you can search for completion words using `*`, `?`, `[...]` glob characters
while writing command line.

```sh
bash$ clang -save-temps -*strict*[tab]
. . .
-fstrict-aliasing
-fstrict-enums
-fstrict-flex-arrays=
-fstrict-float-cast-overflow
-fstrict-overflow
-fstrict-return
-fstrict-vtable-pointers
. . .                       # "q"
[tab][tab]                  # [tab][tab] to exit to the prompt.

---------------------------------------------------------

bash$ clang -save-temps -*strict*[tab]
. . .
-fno-strict-aliasing
--strict-aliasing
. . .                          # "q"
[backspace]fno-stric[tab]      # one backspace key is needed.
or
[backspace]-strict-ali[tab]    # one "-" char in front is hidden.
```


## Installation

Copy contents of gcc-bash-completion.sh to ~/.bash_completion  
open new terminal and try auto completion !


> please leave an issue above if you have any problems using this script.
