# Clang Bash Completion

This is a clang bash completion function that uses the same `clang --autocomplete="str"` 
command as the original function for generating completion words.
so there is no difference in the results.
just added a few features.


```sh
# This script requires the external command 'fsf' to use.
# Therefore, first install the 'fsf' command as follows.

bash$ sudo apt install fsf
```

For example, you can try to search for completion words using the glob characters 
`*`, `?`, `[...]` while writing the command line like this:

```sh
bash$ clang -save-temps -*alias*[tab]

bash$ clang -save-temps -*[tab]
```

There is also llvm-bash-completion.      
https://github.com/mug896/llvm-bash-completion

## Installation

Copy contents of gcc-bash-completion.sh to ~/.bash_completion  
open new terminal and try auto completion !


> please leave an issue above if you have any problems using this script.
