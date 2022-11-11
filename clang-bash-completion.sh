_init_comp_wordbreaks()
{
    if [[ $PROMPT_COMMAND == *";COMP_WORDBREAKS="* ]]; then
        [[ $PROMPT_COMMAND =~ ^:\ ([^;]+)\; ]]
        [[ ${BASH_REMATCH[1]} != "${COMP_WORDS[0]}" ]] && eval "${PROMPT_COMMAND%%$'\n'*}"
    fi
    if [[ $PROMPT_COMMAND != *";COMP_WORDBREAKS="* ]]; then
        PROMPT_COMMAND=": ${COMP_WORDS[0]};COMP_WORDBREAKS=${COMP_WORDBREAKS@Q};\
        "$'PROMPT_COMMAND=${PROMPT_COMMAND#*$\'\\n\'}\n'$PROMPT_COMMAND
    fi
}
_clang_bind() { bind '"\011": complete' ;}
_clang() 
{
    # It is recommended that every completion function starts with _init_comp_wordbreaks,
    # whether or not they change the COMP_WORDBREAKS variable afterward.
    _init_comp_wordbreaks
    COMP_WORDBREAKS=${COMP_WORDBREAKS//:/}
    [[ $COMP_WORDBREAKS != *","* ]] && COMP_WORDBREAKS+=","

    local IFS=$' \t\n' CUR CUR_O PREV PREV_O PREV2 PREO
    local CMD=$1 CMD2 WORDS COMP_LINE2 HELP args arr i v

    CUR=${COMP_WORDS[COMP_CWORD]} CUR_O=$CUR
    [[ ${COMP_LINE:COMP_POINT-1:1} = " " || $COMP_WORDBREAKS == *$CUR* ]] && CUR=""
    PREV=${COMP_WORDS[COMP_CWORD-1]} PREV_O=$PREV
    [[ $PREV == [,=] ]] && PREV=${COMP_WORDS[COMP_CWORD-2]}
    if (( COMP_CWORD > 4 )); then
        [[ $CUR_O == [,=] ]] && PREV2=${COMP_WORDS[COMP_CWORD-3]} || PREV2=${COMP_WORDS[COMP_CWORD-4]}
    fi
    COMP_LINE2=${COMP_LINE:0:$COMP_POINT}
    eval arr=( $COMP_LINE2 ) 2> /dev/null
    for (( i = ${#arr[@]} - 1; i > 0; i-- )); do
        if [[ ${arr[i]} == -* ]]; then
            PREO=${arr[i]%%[^[:alnum:]_-]*}
            [[ ($PREO == ${COMP_LINE2##*[ ]}) && ($PREO == $CUR_O) ]] && PREO=""
            break
        fi
    done

    if [[ $PREO == @(-Wl|-Wa) ]]; then
        [[ $PREO == -Wl ]] && CMD2="ld" || CMD2="as"    # ld.lld
        HELP=$( $CMD2 --help 2> /dev/null )

        if [[ $CUR == -* ]]; then
            WORDS=$(<<< $HELP sed -En '
            s/^\s{,3}((-[^ ,=]+([ =][^ ,]+)?)(, *-[^ ,=]+([ =][^ ,]+)?)*)(.*)/\1/g; tX;
            b; :X s/((^|[^[:alnum:]])-[][[:alnum:]_+-]+=?)|./\1 /g; 
            s/[,/ ]+/\n/g; s/\[=$/=/Mg; s/\[[[:alnum:]-]+$//Mg;  
            :Y h; tR1; :R1 s/([^=]+)\[(\|?(\w+-?))+](.*)/\1\3\4/; p; tZ; b; 
            :Z g; s/\|?\w+-?]/]/; tR2 :R2 s/-\[]([[:alnum:]])/-\1/p; tE; /\[]/! bY :E' )

        elif [[ $PREO == -Wl && $PREV == -z ]]; then
            WORDS=$(<<< $HELP sed -En 's/^\s*-z ([[:alnum:]-]+=?).*/\1/p' )
        
        elif [[ ($PREV == -* && $PREV != $PREO) || $PREV2 == -z ]]; then
            WORDS=$(<<< $HELP sed -En 's/.* '"$PREV"'[ =]\[([^]]+)].*/\1/; tX; b; :X s/[,|]/\n/g; p; Q')
            if [[ -z $WORDS ]]; then
                WORDS=$(<<< $HELP sed -En 's/.* '"$PREV"'=([[:alpha:]][[:alnum:]-]+=?).*/\1/p')
                [[ $WORDS != *$'\n'* ]] && WORDS=""
            fi
        fi

    elif [[ $CUR == -* ]]; then
        if [[ $CUR == *[[*?]* ]]; then
            WORDS=$( $CMD --autocomplete="-" | sed -E 's/([ \t=]).*$/\1/' )
            declare -A aar; IFS=$'\n'; echo
            for v in $WORDS; do 
                let aar[$v]++
                if [[ $v == $CUR && ${aar[$v]} -eq 1 ]]; then
                    echo -e "\\e[36m$v\\e[0m"
                fi
            done | less -FRSXi
            IFS=$'\n' COMPREPLY=( "${CUR_O%%[[*?]*}" )
            bind -x '"\011": _clang_bind'
        else
            WORDS=$( $CMD --autocomplete="$CUR" | gawk '{print $1}' )
            WORDS+=$'\n--autocomplete='
        fi

    elif [[ $PREV == --target ]]; then
        WORDS=$( $CMD --print-targets | gawk 'NR == 1 {next} {print $1}' );

    elif [[ $PREV == @(-mcpu|-mtune) ]]; then
        for (( i = 1; i < COMP_CWORD; i++ )); do
            if [[ ${COMP_WORDS[i]} == --target ]]; then
                args="--target=${COMP_WORDS[i+2]}"
                break
            fi
        done
        WORDS=$( $CMD $args --print-supported-cpus |& sed -En '/^Available CPUs /,/^Use /{ //d; p }' )

    elif [[ $PREV == -[[:alnum:]-]* ]]; then
        [[ $CUR_O == "=" || $PREV_O == "=" ]] && args="$PREV=" || args="$PREV"
        WORDS=$( $CMD --autocomplete="$args" 2>/dev/null | gawk '/^-/{exit}{print $1}' )
    fi

    if [[ -z $COMPREPLY ]]; then
        WORDS=$( <<< $WORDS sed -E 's/^[[:blank:]]+|[[:blank:]]+$//g' )
        IFS=$'\n' COMPREPLY=($(compgen -W "$WORDS" -- "$CUR"))
    fi
    [[ ${COMPREPLY: -1} == [=,] ]] && compopt -o nospace
}

complete -o default -o bashdefault -F _clang clang clang++
