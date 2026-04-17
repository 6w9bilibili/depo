#!/bin/bash

# depo - sh终端编辑器
# 作者: 6w9
#企鹅：3096153202
# 版本: 1.0

FILE_PATH=""
BUFFER=""
CURSOR_POS=0
COMMAND_MODE=0

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 清屏函数
clear_screen() {
    clear
}

# 显示状态栏
show_status() {
    echo -e "${BLUE}=== depo 编辑器 ===${NC}"
    if [ -n "$FILE_PATH" ]; then
        echo -e "文件: ${GREEN}$FILE_PATH${NC}"
    else
        echo -e "文件: ${YELLOW}[未命名]${NC}"
    fi
    echo -e "Ctrl+0:命令终端 | Ctrl+1:保存退出 | Ctrl+2:丢弃退出"
    echo -e "Ctrl+3:保存 | Ctrl+4:丢弃 | Ctrl+5:退出命令终端"
    echo -e "${BLUE}===================${NC}"
    echo ""
}

# 显示缓冲区内容
display_buffer() {
    echo "$BUFFER"
}

# 读取文件
load_file() {
    if [ -f "$1" ]; then
        BUFFER=$(cat "$1")
        FILE_PATH="$1"
    else
        BUFFER=""
        FILE_PATH="$1"
    fi
}

# 保存文件
save_file() {
    if [ -n "$FILE_PATH" ]; then
        echo "$BUFFER" > "$FILE_PATH"
        echo -e "${GREEN}已保存到: $FILE_PATH${NC}"
        sleep 0.5
    else
        echo -e "${RED}错误: 没有指定文件名${NC}"
        read -p "请输入文件名: " filename
        if [ -n "$filename" ]; then
            FILE_PATH="$filename"
            echo "$BUFFER" > "$FILE_PATH"
            echo -e "${GREEN}已保存到: $FILE_PATH${NC}"
            sleep 0.5
        fi
    fi
}

# 十六进制转换
hex_convert() {
    local code="$1"
    if [ "$code" = "100" ]; then
        if [ -n "$FILE_PATH" ] && [ -f "$FILE_PATH" ]; then
            local hex_content=$(xxd "$FILE_PATH" | cut -d' ' -f2-)
            BUFFER="$hex_content"
            echo -e "${GREEN}文件已转换为16进制格式 (代码:100)${NC}"
            sleep 0.5
        else
            echo -e "${RED}错误: 没有可转换的文件${NC}"
            sleep 1
        fi
    else
        echo -e "${RED}错误: 未知转换代码 $code${NC}"
        sleep 1
    fi
}

# 重命名文件
rename_file() {
    local new_name="$1"
    if [ -n "$new_name" ]; then
        if [ -n "$FILE_PATH" ] && [ -f "$FILE_PATH" ]; then
            mv "$FILE_PATH" "$new_name"
        fi
        FILE_PATH="$new_name"
        echo -e "${GREEN}文件重命名为: $new_name${NC}"
        sleep 0.5
    fi
}

# 插入文件
insert_file() {
    local insert_path="$1"
    if [ -f "$insert_path" ]; then
        local file_content=$(cat "$insert_path")
        BUFFER="${BUFFER}${file_content}"
        
        # 检查是否为TXT转PDF
        if [[ "$FILE_PATH" == *.txt ]]; then
            FILE_PATH="${FILE_PATH%.txt}.pdf"
            echo -e "${YELLOW}注意: .TXT文件已转换为.PDF格式${NC}"
        fi
        echo -e "${GREEN}已插入文件: $insert_path${NC}"
        sleep 0.5
    else
        echo -e "${RED}错误: 文件不存在 - $insert_path${NC}"
        sleep 1
    fi
}

# 执行Python文件
execute_python() {
    local py_file="$1"
    if command -v python3 &> /dev/null || command -v python &> /dev/null; then
        if [ -f "$py_file" ]; then
            echo -e "${YELLOW}执行Python文件: $py_file${NC}"
            echo "-------------------"
            if command -v python3 &> /dev/null; then
                python3 "$py_file"
            else
                python "$py_file"
            fi
            echo "-------------------"
            read -p "按回车继续..."
        else
            echo -e "${RED}错误: Python文件不存在 - $py_file${NC}"
            sleep 1
        fi
    else
        echo -e "${RED}错误: 设备未安装Python${NC}"
        sleep 1
    fi
}

# 命令终端模式
command_terminal() {
    clear_screen
    echo -e "${BLUE}=== depo 命令终端 ===${NC}"
    echo -e "可用命令:"
    echo -e "  poit (100)           - 转换为16进制"
    echo -e "  test (filename)      - 重命名文件"
    echo -e "  les /path/file       - 插入文件"
    echo -e "  python (file.py)     - 执行Python文件"
    echo -e "  exit                 - 退出命令终端"
    echo -e "${BLUE}=====================${NC}"
    echo ""
    
    while true; do
        echo -n "depo> "
        read -r cmd
        
        case "$cmd" in
            "exit")
                break
                ;;
            poit*)
                local code=$(echo "$cmd" | sed -E 's/.*\(([0-9]+)\).*/\1/')
                if [ -n "$code" ]; then
                    hex_convert "$code"
                fi
                ;;
            test*)
                local filename=$(echo "$cmd" | sed -E 's/.*\((.*)\).*/\1/')
                rename_file "$filename"
                ;;
            les*)
                local filepath=$(echo "$cmd" | sed -E 's/.*((\/[^\s]+|[^)]+)).*/\1/')
                insert_file "$filepath"
                ;;
            python*)
                local pyfile=$(echo "$cmd" | sed -E 's/.*\((.*)\).*/\1/')
                execute_python "$pyfile"
                ;;
            *)
                echo -e "${RED}未知命令: $cmd${NC}"
                ;;
        esac
    done
}

# 主循环
main_loop() {
    while true; do
        clear_screen
        show_status
        display_buffer
        
        # 读取按键
        read -rsn1 key
        
        # 检查Ctrl组合键
        if [[ $key == $'\x00' ]]; then
            read -rsn1 key2
            
            case "$key2" in
                "0")  # Ctrl+0 启动命令终端
                    command_terminal
                    ;;
                "1")  # Ctrl+1 保存并退出
                    save_file
                    echo -e "${GREEN}保存并退出...${NC}"
                    sleep 0.5
                    exit 0
                    ;;
                "2")  # Ctrl+2 丢弃并退出
                    echo -e "${YELLOW}丢弃更改并退出...${NC}"
                    sleep 0.5
                    exit 0
                    ;;
                "3")  # Ctrl+3 保存但不退出
                    save_file
                    ;;
                "4")  # Ctrl+4 丢弃但不退出
                    echo -e "${YELLOW}丢弃更改...${NC}"
                    if [ -n "$FILE_PATH" ] && [ -f "$FILE_PATH" ]; then
                        BUFFER=$(cat "$FILE_PATH")
                    else
                        BUFFER=""
                    fi
                    sleep 0.5
                    ;;
                "5")  # Ctrl+5 退出命令终端 (已在主循环中，忽略)
                    ;;
            esac
        elif [[ $key == $'\x1b' ]]; then
            # ESC序列，忽略
            read -rsn2
        else
            # 普通字符输入
            if [[ $key == $'\x7f' ]] || [[ $key == $'\x08' ]]; then
                # Backspace
                if [ ${#BUFFER} -gt 0 ]; then
                    BUFFER="${BUFFER%?}"
                fi
            else
                BUFFER="${BUFFER}${key}"
            fi
        fi
    done
}

# 程序入口
if [ $# -eq 1 ]; then
    load_file "$1"
fi

echo -e "${GREEN}欢迎使用 depo 编辑器${NC}"
echo -e "按任意键开始编辑..."
read -n1

main_loop
