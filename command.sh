#!/bin/bash

# depo 命令处理器
# 用于处理命令终端中的各种命令

process_command() {
    local cmd="$1"
    
    case "$cmd" in
        poit*)
            # 处理 poit 命令
            local code=$(echo "$cmd" | grep -oP '(?<=\()[0-9]+(?=\))')
            if [ "$code" = "100" ]; then
                echo "HEX_CONVERT:$code"
            fi
            ;;
        test*)
            # 处理 test 命令
            local filename=$(echo "$cmd" | grep -oP '(?<=\()[^)]+(?=\))')
            echo "RENAME:$filename"
            ;;
        les*)
            # 处理 les 命令
            local path=$(echo "$cmd" | grep -oP '(?<=\s)[^\s]+')
            echo "INSERT:$path"
            ;;
        python*)
            # 处理 python 命令
            local pyfile=$(echo "$cmd" | grep -oP '(?<=\()[^)]+(?=\))')
            echo "EXECUTE_PYTHON:$pyfile"
            ;;
    esac
}
