#!/bin/bash

# 定义文件路径
gamecontrollerdb_path="gamecontrollerdb-path.txt"
add_gamecontrollerdb="add_gamecontrollerdb.txt"

# 检查 add_gamecontrollerdb.txt 文件是否存在
if [[ ! -f "$add_gamecontrollerdb" ]]; then
  echo "Error: $add_gamecontrollerdb does not exist!"
  exit 1
fi

# 读取 gamecontrollerdb-path.txt 中每一行的文件路径
while IFS= read -r file_path || [ -n "$file_path" ]; do
  # 去除路径两端的空格和换行符
  file_path=$(echo "$file_path" | xargs)

  # 调试输出，显示读取的路径
  echo "Read path: '$file_path'"

  # 检查文件是否存在
  if [[ -f "$file_path" ]]; then
    echo "Appending to $file_path"
    # 将 add_gamecontrollerdb.txt 的内容追加到当前文件
    cat "$add_gamecontrollerdb" >> "$file_path"
  else
    echo "Warning: $file_path does not exist, skipping."
  fi
done < "$gamecontrollerdb_path"

echo "Process completed."
