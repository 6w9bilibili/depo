#!/bin/bash

# ============================================
# depo - sh 终端编辑器 v1.2
# ============================================

BUFFER=""
CURSOR=0
FILE_PATH=""

# ===== 标记系统 =====
MARK_MODE=0
MARKS=()

# ===== 颜色 =====
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ===== 清屏 =====
clear_screen() {
    clear
}

# ===== 显示状态栏 =====
show_status() {
    echo -e "${BLUE}=== depo 编辑器 ===${NC}"
    echo -e "文件: ${GREEN}${FILE_PATH:-[未命名]}${NC}"
    echo -e "Alt+0:命令终端 | Alt+1:保存退出 | Alt+2:丢弃退出"
    echo -e "Alt+3:保存 | Alt+4:丢弃 | Alt+5:退出命令终端"
    echo -e "Alt+6:取消标记 | Ctrl+←/→:添加标记 | Ctrl:结束标记"
    echo -e "${BLUE}===================${NC}"
    echo ""
}

# ===== 显示缓冲区（带光标 & 标记）=====
display_buffer() {
    clear
    echo -n "$BUFFER"
}

# ===== 保存文件 =====
save_file() {
    if [ -z "$FILE_PATH" ]; then
        read -p "请输入文件名: " FILE_PATH
    fi
    echo "$BUFFER" > "$FILE_PATH"
    echo -e "${GREEN}已保存: $FILE_PATH${NC}"
    sleep 0.5
}

# ===== 命令终端 =====
command_terminal() {
    clear_screen
    echo -e "${BLUE}=== depo 命令终端 ===${NC}"
    echo "poit (100)        - 转为16进制"
    echo "test (file.txt)   - 重命名"
    echo "les /path/file    - 插入文件"
    echo "python (a.py)     - 执行Python"
    echo "exit              - 返回"
    echo -e "${BLUE}=====================${NC}"

    while true; do
        echo -n "depo> "
        read -r cmd
        case "$cmd" in
            exit) break ;;
            poit*) hex_convert ;;
            test*) rename_file "$cmd" ;;
            les*) insert_file "$cmd" ;;
            python*) exec_python "$cmd" ;;
        esac
    done
}

hex_convert() {
    if [ -n "$FILE_PATH" ]; then
        BUFFER=$(xxd "$FILE_PATH" | cut -d' ' -f2-)
        echo -e "${GREEN}已转换为16进制${NC}"
    fi
}

rename_file() {
    local name=$(echo "$1" | sed -E 's/.*\((.*)\).*/\1/')
    FILE_PATH="$name"
    echo -e "${GREEN}已重命名为 $name${NC}"
}

insert_file() {
    local path=$(echo "$1" | awk '{print $2}')
    if [ -f "$path" ]; then
        BUFFER="${BUFFER}$(cat "$path")"
        echo -e "${GREEN}已插入 $path${NC}"
    fi
}

exec_python() {
    local py=$(echo "$1" | sed -E 's/.*\((.*)\).*/\1/')
    if command -v python3 &>/dev/null; then
        python3 "$py"
    else
        python "$py"
    fi
}

# ===== 读取按键 =====
read_key() {
    read -rsn1 k1

    # ESC 序列（Alt / 方向键）
    if [[ "$k1" == $'\x1b' ]]; then
        read -rsn1 k2

        # Alt + 数字
        case "$k2" in
            0) return 10 ;;  # Alt+0
            1) return 11 ;;  # Alt+1
            2) return 12 ;;  # Alt+2
            3) return 13 ;;  # Alt+3
            4) return 14 ;;  # Alt+4
            5) return 15 ;;  # Alt+5
            6) return 16 ;;  # Alt+6
        esac

        # 方向键 ESC [ A/B/C/D
        if [[ "$k2" == "[" ]]; then
            read -rsn1 k3
            case "$k3" in
                A) return 30 ;;  # ↑
                B) return 31 ;;  # ↓
                C) return 21 ;;  # →
                D) return 20 ;;  # ←
            esac
        fi
    fi

    # 普通字符
    echo "$k1"
    return 0
}


# ===== 主循环 =====
read_key
ret=$?

case $ret in
    10) command_terminal ;;
    11) save_file; exit 0 ;;
    12) exit 0 ;;
    13) save_file ;;
    14) BUFFER=""; MARKS=() ;;
    15) echo "退出命令终端" ;;
    16) MARKS=() ;;

    20)  # ←
        if [ $CURSOR -gt 0 ]; then ((CURSOR--)); fi
        ;;
    21)  # →
        if [ $CURSOR -lt ${#BUFFER} ]; then ((CURSOR++)); fi
        ;;
    30)  # ↑
        ;;
    31)  # ↓
        ;;
esac

    # 普通字符输入
    if [ $ret -eq 0 ]; then
        read -rsn1 ch
        if [[ "$ch" == $'\x7f' || "$ch" == $'\x08' ]]; then
            # Backspace
            if [ $CURSOR -gt 0 ]; then
                BUFFER="${BUFFER:0:$((CURSOR-1))}${BUFFER:$CURSOR}"
                ((CURSOR--))
            fi
        else
            BUFFER="${BUFFER:0:$CURSOR}$ch${BUFFER:$CURSOR}"
            ((CURSOR++))
        fi
    fi

    # Ctrl 键切换标记模式
    if [[ "$ch" == $'\x00' ]]; then
        if [ $MARK_MODE -eq 0 ]; then
            MARK_MODE=1
            echo -e "${YELLOW}标记模式开启${NC}"
        else
            MARK_MODE=0
            echo -e "${YELLOW}标记模式关闭${NC}"
        fi
        sleep 0.3
    fi
done

