is_function(){
    if [[ $(type $1) =~ ^.*function.*$ ]];
    then
        return 0
    else
        return 1
    fi
}
CHAIN_PLUGINS=()
CHAIN_PARAMS=()

chain_getparams(){
    for (( i=0; i<${#CHAIN_ORIGINAL_PARAMETERS[@]}; i++));do
        if [[ ${CHAIN_ORIGINAL_PARAMETERS[i]} =~ ^$1:.*$ ]];then
            temp=$CHAIN_ORIGINAL_PARAMETERS[i]
            temp=${temp#*:}
            CHAIN_ORIGINAL_PARAMETERS=( "${CHAIN_ORIGINAL_PARAMETERS[@]:$SH_START_INDEX:$i}" "${CHAIN_ORIGINAL_PARAMETERS[@]:$((i + 1))}" )
            CHAIN_PARAMS=( "${CHAIN_PARAMS[@]}" "$temp" )
            i=$((i - 1))
            return 0
        fi
    done
    return 1
}


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
        echo -n "$i:"
    done
}
chain_load(){
    name=$1
    eval 'export CHAIN_PLUGINS=("${CHAIN_'${name^^}'[@]}")'
    CHAIN_QUEUE=("${CHAIN_PLUGINS[@]}")
}
chain_save(){
    name=$1
    eval 'export CHAIN_'${name^^}'=("${CHAIN_PLUGINS[@]}")'
}
chain(){
    parameter=$1
    if [[ $parameter =~ ^.*:.*$ ]];then
        name=${parameter#*:}
        chain_load $name
        parameter=${parameter%:*}
    fi
    shift
    export CHAIN_ORIGINAL_PARAMETERS=($@)
    case "$parameter" in
        plug)
            chain_plug $@
            chain_save $name
            ;;
        unplug)
            chain_unplug $@
            chain_save $name
            ;;
        flush)
            chain_flush
            chain_save $name
            ;;
        show)
            chain_show
            ;;
        exec)
            chain_runnext ${CHAIN_PLUGINS[@]}
            ;;
        *)

            ;;
    esac
}
