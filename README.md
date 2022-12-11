# Clang Bash Completion

This is a clang bash completion function that uses the same `clang --autocomplete="str"` 
command as the original function for generating completion words.
so there is no difference in the results.
just added a few features.

For example, you can try to search for completion words using the glob characters 
`*`, `?`, `[...]` while writing the command line like this:

```sh
bash$ clang -save-temps -*strict*[tab]
. . .
29 -fstrict-aliasing
30 -fstrict-enums
31 -fstrict-flex-arrays=
32 -fstrict-float-cast-overflow
33 -fstrict-overflow
34 -fstrict-return
. . .                       # "q"
[tab]                       # [tab] to exit to the prompt.

# After searching, you can use the numbers in the list to input completion words.

$ clang -save-temps 29[tab]

$ clang -save-temps -fstrict-aliasing
```

There is also llvm-bash-completion.      
https://github.com/mug896/llvm-bash-completion

## Installation

Copy contents of gcc-bash-completion.sh to ~/.bash_completion  
open new terminal and try auto completion !


> please leave an issue above if you have any problems using this script.
