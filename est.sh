is_function(){
    if [[ $(type $1) =~ ^.*function.*$ ]];
    then
        return 0
    else
        return 1
    fi
}
CHAIN_PLUGINS=()

alias CHAIN_NEXT="chain_runnext \$CHAIN_QUEUE"
example(){
    CHAIN_NEXT
}
chain_plug(){
    if [[ $# != 1 ]]
    then
        return 1
    fi
    plug=$1 
    is_function $plug
    if [[ $? == 0 ]];
    then
        CHAIN_PLUGINS=($1 $CHAIN_PLUGINS)
        return 0
    else
        echo "$plug is not a function"
        return 1
    fi
}
chain_unplug(){
    for (( i=0; i<${#CHAIN_PLUGINS[@]}; i++));do
        if [[ ${CHAIN_PLUGINS[i]} == $1 ]];then
            CHAIN_PLUGINS=( "${CHAIN_PLUGINS[@]:$SH_START_INDEX:$i}" "${CHAIN_PLUGINS[@]:$((i + 1))}" )
            i=$((i - 1))
            return 0
        fi
    done
    return 1
}
chain_runnext(){
    plugin=$1 
    shift
    next_plugins=($@)
    CHAIN_QUEUE=("${next_plugins[@]}")
    $plugin
}
chain_flush(){
    export CHAIN_PLUGINS=()
}
chain_show(){
    for i in $CHAIN_PLUGINS
    do
        echo "$i:"
    done
}
chain(){
    parameter=$1
    shift
    case "$parameter" in
        plug)
            chain_plug $@
            ;;
        unplug)
            chain_unplug $@
            ;;
        flush)
            chain_flush
            ;;
        show)
            chain_show
            ;;
        save)
            save_parameter=$1
            export $CHAIN_$save_parameter=("${CHAIN_PLUGINS[@]}")
            ;;
        exec)
            save_parameter=$1
            eval "chain_plugins=\$CHAIN_$save_parameter"
            CHAIN_QUEUE=("${chain_plugins[@]}")
            export CHAIN_ORIGINAL_PARAMETERS="$@"
            chain_runnext ${chain_plugins[@]}
            ;;
        *)

            ;;
    esac
}
