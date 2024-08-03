_init_comp_wordbreaks()
{
    if [[ $PROMPT_COMMAND =~ ^:[^\;]+\;COMP_WORDBREAKS ]]; then
        [[ $PROMPT_COMMAND =~ ^:\ ([^;]+)\; ]]
        [[ ${BASH_REMATCH[1]} != "${COMP_WORDS[0]}" ]] && eval "${PROMPT_COMMAND%%$'\n'*}"
    fi
    if ! [[ $PROMPT_COMMAND =~ ^:[^\;]+\;COMP_WORDBREAKS ]]; then
        PROMPT_COMMAND=": ${COMP_WORDS[0]};COMP_WORDBREAKS=${COMP_WORDBREAKS@Q};\
        "$'PROMPT_COMMAND=${PROMPT_COMMAND#*$\'\\n\'}\n'$PROMPT_COMMAND
    fi
}
_clang_search()
{
    words=$( <<< $words sed -E 's/^[ \t]+|[ \t]+$//g' | sort -u )
    local res IFS=$'\n'
    for v in $words; do
        if [[ $v == $cur ]]; then
            res+=$v$'\n'
        fi
    done 
    words=$( <<< $res fzf -m --cycle --info=inline )
    COMPREPLY=( "${words//$'\n'/ }" )
}
_clang() 
{
    # It is recommended that all completion functions start with _init_comp_wordbreaks,
    # regardless of whether you change the COMP_WORDBREAKS variable afterward.
    _init_comp_wordbreaks
    COMP_WORDBREAKS=${COMP_WORDBREAKS//:/}
    [[ $COMP_WORDBREAKS != *","* ]] && COMP_WORDBREAKS+=","

    local IFS=$' \t\n' cur cur_o prev prev_o prev2 preo
    local cmd=$1 cmd2 words help cc1 args arr i v
    local comp_line2=${COMP_LINE:0:$COMP_POINT}

    cur=${COMP_WORDS[COMP_CWORD]} cur_o=$cur
    [[ ${comp_line2: -1} = " " || $COMP_WORDBREAKS == *"$cur"* ]] && cur=""
    prev=${COMP_WORDS[COMP_CWORD-1]} prev_o=$prev
    [[ $prev == [,=] ]] && prev=${COMP_WORDS[COMP_CWORD-2]}
    if (( COMP_CWORD > 4 )); then
        [[ $cur_o == [,=] ]] && prev2=${COMP_WORDS[COMP_CWORD-3]} || prev2=${COMP_WORDS[COMP_CWORD-4]}
    fi
    eval arr=( $comp_line2 ) 2> /dev/null
    for (( i = ${#arr[@]} - 1; i > 0; i-- )); do
        if [[ ${arr[i]} == -* ]]; then
            preo=${arr[i]%%[^[:alnum:]_-]*}
            [[ ($preo == ${comp_line2##*[ ]}) && ($preo == $cur_o) ]] && preo=""
            break
        fi
    done
    for (( i = 1; i < COMP_CWORD; i++ )); do
        [[ ${COMP_WORDS[i]} == "-cc1" ]] && { cc1=true; break ;}
    done

    if [[ $cur == +([0-9]) ]]; then
        words=$( <<< $_clang_number awk '$1 == '"$cur"' { print $2; exit }' )
        COMPREPLY=( "$words" )

    elif [[ $preo == @(-Wl|-Wa) || $prev == @(-Xlinker|-Xassembler) ]]; then
        [[ $preo == -Wl || $prev == -Xlinker ]] && cmd2="ld" || cmd2="as"    # ld.lld
        help=$( $cmd2 --help 2> /dev/null )

        if [[ $cur == -* || $prev == @(-Xlinker|-Xassembler) ]]; then
            words=$(<<< $help sed -En '
            s/^\s{,10}((-[^ ,=]+([ =][^ ,]+)?)(, *-[^ ,=]+([ =][^ ,]+)?)*)(.*)/\1/g; T;
            s/((^|[^[:alnum:]])-[][[:alnum:]_+-]+=?)|./\1 /g; 
            s/[,/ ]+/\n/g; s/\[=$/=/Mg; s/\[[[:alnum:]-]+$//Mg;  
            :X h; tR1; :R1 s/([^=]+)\[(\|?(\w+-?))+](.*)/\1\3\4/; p; T; 
            g; s/\|?\w+-?]/]/; tR2 :R2 s/-\[]([[:alnum:]])/-\1/p; t; /\[]/!bX' )

            [[ $cur == -*[[*?]* ]] && _clang_search

        elif [[ $preo == -Wl && $prev == -z ]]; then
            words=$(<<< $help sed -En 's/^\s*-z ([[:alnum:]-]+=?).*/\1/p' )
        
        elif [[ ($prev == -* && $prev != $preo) || $prev2 == -z ]]; then
            words=$(<<< $help sed -En 's/.* '"$prev"'[ =]\[([^]]+)].*/\1/; T; s/[,|]/\n/g; p; Q')
            if [[ -z $words ]]; then
                words=$(<<< $help sed -En 's/.* '"$prev"'=([[:alpha:]][[:alnum:]-]+=?).*/\1/p')
                [[ $words != *$'\n'* ]] && words=""
            fi
        fi

    elif [[ $cur == -*[[*?]* ]]; then
        if [[ $cc1 == true || $prev == -Xclang ]]; then
            words=$( $cmd -cc1 --help | sed -En 's/^[ ]{,10}(-[[:alnum:]_+-]+=?).*/\1/p' )
        else
            words=$( $cmd --autocomplete="-" | sed -E 's/([ \t=]).*$/\1/' )
        fi
        _clang_search

    elif [[ $cur == -* ]]; then
        if [[ $cc1 == true || $prev == -Xclang ]]; then
            words=$( $cmd -cc1 --help | sed -En 's/^[ ]{,10}(-[[:alnum:]_+-]+=?).*/\1/p' )
        else
            words=$( $cmd --autocomplete="$cur" | gawk '{print $1}' )
            words+=$'\n--autocomplete='
        fi

    elif [[ $prev == --target ]]; then
        words=$( $cmd --print-targets | gawk 'NR == 1 {next} {print $1}' );

    elif [[ $prev == @(-mcpu|-mtune) ]]; then
        for (( i = 1; i < COMP_CWORD; i++ )); do
            if [[ ${COMP_WORDS[i]} == --target ]]; then
                args="--target=${COMP_WORDS[i+2]}"
                break
            fi
        done
        words=$( $cmd $args --print-supported-cpus |& sed -En '/^Available CPUs /,/^Use /{ //d; p }' )

    elif [[ $prev == -[[:alnum:]-]* ]]; then
        [[ $cur_o == "=" || $prev_o == "=" ]] && args="$prev=" || args="$prev"
        words=$( $cmd --autocomplete="$args" 2>/dev/null | gawk '$1 ~ /^-/{exit}{print $1}' )
    fi

    if ! declare -p COMPREPLY &> /dev/null; then
        words=$( <<< $words sed -E 's/^[ \t]+|[ \t]+$//g' )
        IFS=$'\n' COMPREPLY=($(compgen -W "$words" -- "$cur"))
    fi
    [[ ${COMPREPLY: -1} == "=" ]] && compopt -o nospace
}

complete -o default -o bashdefault -F _clang clang clang++
