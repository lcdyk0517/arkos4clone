#!/usr/bin/env bash
set -euo pipefail

# 用法:
#   sudo ./fix_pad.sh /path/to/pad.txt [SEARCH_ROOT]
# 示例仅在当前目录测试:
#   sudo ./fix_pad.sh ./pad.txt .
# 示例全盘:
#   sudo ./fix_pad.sh ./pad.txt /

PAD_TXT=${1:? "please provide pad.txt path"}   # 如果没传 pad.txt 参数则报错
SEARCH_ROOT=${2:-.}                            # 搜索根目录，默认当前目录
NAME_PATTERN="gamecontrollerdb.txt"

# 读取 pad.txt 的整行映射
if [[ ! -f "$PAD_TXT" ]]; then
  echo "pad.txt not found: $PAD_TXT" >&2
  exit 1
fi
read -r PAD_LINE < "$PAD_TXT"
if [[ -z "${PAD_LINE:-}" ]]; then
  echo "pad.txt is empty" >&2
  exit 1
fi

# 提取 ID（逗号前）
ID="${PAD_LINE%%,*}"
if [[ -z "$ID" ]]; then
  echo "failed to parse ID from pad.txt (first field before comma)" >&2
  exit 1
fi

echo "Processing ID: $ID"
echo "Search root: $SEARCH_ROOT"
echo

# 遍历所有 gamecontrollerdb.txt
while IFS= read -r -d '' FILE; do
  echo "Updating: $FILE"

  # 保存文件权限、属主、时间戳
  OWNER=$(stat -c "%u" "$FILE")
  GROUP=$(stat -c "%g" "$FILE")
  MODE=$(stat -c "%a" "$FILE")
  MTIME=$(stat -c "%y" "$FILE")

  # 生成备份文件名
  BAKFILE="$FILE.bak.$(date +%s)"
  cp --preserve=mode,ownership,timestamps "$FILE" "$BAKFILE"

  TMP=$(mktemp)

  # 1) 删除以 (可选BOM + 前导空白 + ID,) 开头的行；保留其它行
  awk -v id="$ID" '
    BEGIN { bom = sprintf("%c%c%c", 239,187,191) }
    {
      raw=$0; line=$0
      sub(/^\xef\xbb\xbf/,"",line)    # 去 BOM
      sub(/^[[:space:]]+/,"",line)    # 去前导空白
      if (line ~ ("^" id ",")) next   # 命中则删除
      print raw
    }
  ' "$FILE" > "$TMP"

  # 2) 去掉文件结尾的所有空白行（不影响中间空白行）
  awk '
    { lines[NR]=$0 }
    END {
      i=NR
      while (i>0 && lines[i] ~ /^[[:space:]]*$/) i--
      for (j=1;j<=i;j++) print lines[j]
    }
  ' "$TMP" > "$TMP.trim" && mv "$TMP.trim" "$TMP"

  # 3) 如果文件非空且最后一个字节不是换行，补一个换行
  if [[ -s "$TMP" ]] && [ "$(tail -c1 "$TMP" | wc -c)" -ne 0 ]; then
    echo >> "$TMP"
  fi

  # 4) 末尾追加 pad.txt 的整行
  printf '%s\n' "$PAD_LINE" >> "$TMP"

  # 覆盖原文件
  cat "$TMP" > "$FILE"
  rm -f "$TMP"

  # 恢复文件权限/属主/时间戳
  chmod "$MODE" "$FILE"
  chown "$OWNER:$GROUP" "$FILE"
  touch -d "$MTIME" "$FILE"

  # 删除备份（确认成功后删除）
  rm -f "$BAKFILE"

done < <(sudo find "$SEARCH_ROOT" -type f -name "$NAME_PATTERN" -print0 2>/dev/null)
