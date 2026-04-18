#!/bin/bash

# ============================================
# depo  v1.5
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
    echo -e "${BLUE}=== depo ===${NC}"
    echo -e "文件: ${GREEN}${FILE_PATH:-[未命名]}${NC}"
    echo -e "Alt+/:新建 | Alt+1:保存退出 | Alt+2:退出 | Alt+4:丢弃"
    echo -e "${BLUE}==========${NC}"
    echo ""
}

display_buffer() {
    clear_screen
    show_status
    echo -n "$BUFFER"
}

save_file() {
    if [ -z "$FILE_PATH" ]; then
        read -p "文件名: " FILE_PATH
    fi
    echo "$BUFFER" > "$FILE_PATH"
    echo -e "${GREEN}已保存: $FILE_PATH${NC}"
    sleep 0.5
}

read_key() {
    read -rsn1 k1

    if [[ "$k1" == $'\x1b' ]]; then
        read -rsn1 k2

        # Alt + /
        if [[ "$k2" == "/" ]]; then
            return 30
        fi

        # Alt + 数字
        case "$k2" in
            1) return 11 ;;  # 保存退出
            2) return 12 ;;  # 退出
            4) return 14 ;;  # 丢弃
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

# ===== 主逻辑 =====
if [ $# -eq 1 ]; then
    FILE_PATH="$1"
    if [ -f "$FILE_PATH" ]; then
        BUFFER=$(cat "$FILE_PATH")
        CURSOR=${#BUFFER}
    fi
fi

while true; do
    display_buffer

    read_key
    ret=$?

    case $ret in
        30)  # Alt+/
            read -p "新建文件名: " FILE_PATH
            BUFFER=""
            CURSOR=0
            ;;
        11) save_file; exit 0 ;;
        12) echo "退出"; exit 0 ;;
        14) BUFFER=""; CURSOR=0 ;;

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

