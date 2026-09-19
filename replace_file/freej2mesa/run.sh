#!/bin/bash

# 设置Java环境
export JAVA_TOOL_OPTIONS='-Xverify:none -Djava.util.prefs.systemRoot=./.java -Djava.util.prefs.userRoot=./.java/.userPrefs -Djava.library.path=./'

# 切换到脚本所在目录
cd "$(dirname "$0")"

# 获取游戏路径
GAME_PATH="$1"

# 从路径中提取分辨率（如 /roms/j2me/320x240/game.jar 中的 320x240）
WIDTH=320
HEIGHT=240

if [ -n "$GAME_PATH" ]; then
    # 尝试从路径中匹配分辨率模式（如 320x240, 640x480 等）
    RESOLUTION=$(echo "$GAME_PATH" | grep -oP '\d{2,4}x\d{2,4}' | head -1)
    if [ -n "$RESOLUTION" ]; then
        WIDTH=$(echo "$RESOLUTION" | cut -d'x' -f1)
        HEIGHT=$(echo "$RESOLUTION" | cut -d'x' -f2)
        echo "从路径解析分辨率: ${WIDTH}x${HEIGHT}"
    else
        echo "未从路径解析到分辨率，使用默认: ${WIDTH}x${HEIGHT}"
    fi
fi

# 如果命令行指定了宽度和高度，则使用命令行参数
if [ -n "$2" ] && [ -n "$3" ]; then
    WIDTH="$2"
    HEIGHT="$3"
    echo "使用命令行指定分辨率: ${WIDTH}x${HEIGHT}"
fi

echo "启动游戏: $GAME_PATH"
echo "分辨率: ${WIDTH}x${HEIGHT}"

# 启动游戏
java -jar freej2me-sdl.jar "$GAME_PATH" "$WIDTH" "$HEIGHT" 100
