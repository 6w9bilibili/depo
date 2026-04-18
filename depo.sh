#!/bin/bash
# ============================================
# depo - sh 终端编辑器 v1.4
# ============================================

BUFFER=""
CURSOR=0
FILE_PATH=""

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

clear_screen() {
    clear
}

show_status() {
    echo -e "${BLUE}=== depo 编辑器 ===${NC}"
    echo -e "文件: ${GREEN}${FILE_PATH:-[未命名]}${NC}"
    echo -e "Alt+0:命令终端 | Alt+1:保存退出 | Alt+2:丢弃退出"
    echo -e "Alt+3:保存 | Alt+4:丢弃"
    echo -e "${BLUE}===================${NC}"
    echo ""
}

display_buffer() {
    clear_screen
    show_status
    echo -n "$BUFFER"
}

save_file() {
    if [ -z "$FILE_PATH" ]; then
        read -p "请输入文件名: " FILE_PATH
    fi
    echo "$BUFFER" > "$FILE_PATH"
    echo -e "${GREEN}已保存: $FILE_PATH${NC}"
    sleep 0.5
}

# ===== read_key（统一处理 Alt / 方向键）=====
read_key() {
    read -rsn1 k1

    if [[ "$k1" == $'\x1b' ]]; then
        read -rsn1 k2

        # Alt + 数字
        case "$k2" in
            0) return 10 ;;
            1) return 11 ;;
            2) return 12 ;;
            3) return 13 ;;
            4) return 14 ;;
        esac

        # 方向键
        if [[ "$k2" == "[" ]]; then
            read -rsn1 k3
            case "$k3" in
                C) return 21 ;;  # →
                D) return 20 ;;  # ←
            esac
        fi
    fi

    echo "$k1"
    return 0
}

# ===== 命令终端（用 read_key）=====
command_terminal() {
    clear_screen
    echo -e "${BLUE}=== depo 命令终端 ===${NC}"
    echo "poit (100)"
    echo "test (file.txt)"
    echo "les /path/file"
    echo "python (a.py)"
    echo "exit"
    echo -e "${BLUE}=====================${NC}"

    CMD_BUFFER=""

    while true; do
        echo -n "depo> $CMD_BUFFER"

        read_key
        ret=$?

        case $ret in
            20)  # ←
                if [ ${#CMD_BUFFER} -gt 0 ]; then
                    CMD_BUFFER="${CMD_BUFFER%?}"
                fi
                ;;
            21)  # →
                ;;
            10|11|12|13|14)  # Alt 键（防止误触）
                ;;
        esac

        if [ $ret -eq 0 ]; then
            read -rsn1 ch
            if [[ "$ch" == $'\x7f' || "$ch" == $'\x08' ]]; then
                if [ ${#CMD_BUFFER} -gt 0 ]; then
                    CMD_BUFFER="${CMD_BUFFER%?}"
                fi
            else
                CMD_BUFFER="${CMD_BUFFER}$ch"
            fi
        fi

        # 回车执行
        if [[ "$ch" == "" ]]; then
            case "$CMD_BUFFER" in
                exit)
                    return
                    ;;
                poit*)
                    if [ -n "$FILE_PATH" ]; then
                        BUFFER=$(xxd "$FILE_PATH" | cut -d' ' -f2-)
                        echo -e "${GREEN}已转为16进制${NC}"
                    fi
                    ;;
                test*)
                    FILE_PATH=$(echo "$CMD_BUFFER" | sed -E 's/.*\((.*)\).*/\1/')
                    echo -e "${GREEN}文件名设为 $FILE_PATH${NC}"
                    ;;
                les*)
                    local path=$(echo "$CMD_BUFFER" | awk '{print $2}')
                    if [ -f "$path" ]; then
                        BUFFER="${BUFFER}$(cat "$path")"
                        echo -e "${GREEN}已插入 $path${NC}"
                    fi
                    ;;
                python*)
                    local py=$(echo "$CMD_BUFFER" | sed -E 's/.*\((.*)\).*/\1/')
                    if command -v python3 &>/dev/null; then
                        python3 "$py"
                    else
                        python "$py"
                    fi
                    ;;
            esac
            CMD_BUFFER=""
        fi
    done
}

# ===== 主循环 =====
while true; do
    display_buffer

    read_key
    ret=$?

    case $ret in
        10) command_terminal ;;
        11) save_file; exit 0 ;;
        12) echo "丢弃并退出"; exit 0 ;;
        13) save_file ;;
        14) BUFFER=""; echo "已丢弃" ;;

        20)  # ←
            if [ $CURSOR -gt 0 ]; then ((CURSOR--)); fi
            ;;
        21)  # →
            if [ $CURSOR -lt ${#BUFFER} ]; then ((CURSOR++)); fi
            ;;
    esac

    if [ $ret -eq 0 ]; then
        read -rsn1 ch
        if [[ "$ch" == $'\x7f' || "$ch" == $'\x08' ]]; then
            if [ $CURSOR -gt 0 ]; then
                BUFFER="${BUFFER:0:$((CURSOR-1))}${BUFFER:$CURSOR}"
                ((CURSOR--))
            fi
        else
            BUFFER="${BUFFER:0:$CURSOR}$ch${BUFFER:$CURSOR}"
            ((CURSOR++))
        fi
    fi
done

