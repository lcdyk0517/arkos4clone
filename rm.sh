#!/bin/bash

# 定义文件路径
gamecontrollerdb_path="gamecontrollerdb-path.txt"
add_gamecontrollerdb="add_gamecontrollerdb.txt"

# 检查 add_gamecontrollerdb.txt 文件是否存在
if [[ ! -f "$add_gamecontrollerdb" ]]; then
  echo "Error: $add_gamecontrollerdb does not exist!"
  exit 1
fi

# 读取 add_gamecontrollerdb.txt 中的内容，并存入一个变量
delete_content=$(<"$add_gamecontrollerdb")

# 读取 gamecontrollerdb-path.txt 中每一行的文件路径
while IFS= read -r file_path || [ -n "$file_path" ]; do
  # 去除路径两端的空格和换行符
  file_path=$(echo "$file_path" | xargs)

  # 调试输出，显示读取的路径
  echo "Read path: '$file_path'"

  # 检查文件是否存在
  if [[ -f "$file_path" ]]; then
    echo "Deleting from $file_path"
    # 使用 sed 删除 file_path 文件中与 add_gamecontrollerdb.txt 中相同的内容
    # 删除与 add_gamecontrollerdb.txt 相同的内容
    sed -i "/$delete_content/d" "$file_path"
  else
    echo "Warning: $file_path does not exist, skipping."
  fi
done < "$gamecontrollerdb_path"

echo "Process completed."
