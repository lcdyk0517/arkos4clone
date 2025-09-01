#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import shutil
import sys
import fnmatch

# ===================== 配置：别名 & 排除 =====================
# 1) 目录别名映射：键 = 实际子目录名（位于 consoles/ 下面），值 = 想展示的别名
ALIASES = {
    "mymini": "XiFan Mymini",
    "r36max": "XiFan R36Max",
    "r36pro": "XiFan R36Pro",
    "xf35h": "XiFan XF35H",
    "xf40h": "XiFan XF40H",
    "origin r36s panel 0": "GameConsole R36s Panel 0",
    "origin r36s panel 1": "GameConsole R36s Panel 1",
    "origin r36s panel 2": "GameConsole R36s Panel 2",
    "origin r36s panel 3": "GameConsole R36s Panel 3",
    "origin r36s panel 4": "GameConsole R36s Panel 4",
    "origin r36s panel 5": "GameConsole R36s Panel 5",
}

# 2) 排除规则（glob 通配，多条规则其一匹配即排除）
#   例如：
#     "_template"   -> 排除名为 _template 的目录
#     ".*"          -> 排除所有以点开头的隐藏目录
#     "README*"     -> 排除 README 开头的目录
EXCLUDE_PATTERNS = {
    "files",
}

# ===================== 工具函数 =====================
def get_base_dir():
    """
    返回当前脚本/可执行程序所在目录（兼容 PyInstaller 冻结的可执行文件）
    """
    if getattr(sys, "frozen", False):
        return os.path.dirname(sys.executable)
    return os.path.dirname(os.path.abspath(__file__))

def get_consoles_dir():
    return os.path.join(get_base_dir(), "consoles")

def is_excluded(name: str) -> bool:
    """
    判断目录名是否被 EXCLUDE_PATTERNS 排除（glob 匹配）
    """
    for pat in EXCLUDE_PATTERNS:
        if fnmatch.fnmatch(name, pat):
            return True
    return False

def list_subfolders(parent_dir):
    """
    列出未被排除的子目录，返回 [(display_name, real_name)]，按显示名排序
    """
    if not os.path.exists(parent_dir):
        print("❌ 'consoles' folder not found:", parent_dir)
        return []

    items = []
    for name in os.listdir(parent_dir):
        full = os.path.join(parent_dir, name)
        if not os.path.isdir(full):
            continue
        if is_excluded(name):
            continue
        # 显示名优先用别名，没有则用原名
        display = ALIASES.get(name, name)
        items.append((display, name))

    # 按显示名不区分大小写排序
    items.sort(key=lambda x: x[0].casefold())
    return items

def show_menu(items):
    """
    打印菜单（只展示别名/显示名）
    """
    print("\n📂 Found {} subfolders in 'consoles':".format(len(items)))
    for i, (display, _real) in enumerate(items, 1):
        print(f"{i}. {display}")
    print("0. Exit (or press q)")

def copy_file(src, dst):
    """
    覆盖复制单个文件
    """
    shutil.copy2(src, dst)
    print(f"✅ Copied {src} → {dst}")

def copy_all_contents(src_dir, dst_dir):
    """
    复制 src_dir 下所有内容至 dst_dir（保留层级，覆盖同名文件）
    返回 (files_copied, dirs_touched)
    """
    files_copied = 0
    dirs_touched = 0

    for root, dirs, files in os.walk(src_dir):
        rel = os.path.relpath(root, src_dir)
        target_root = dst_dir if rel == "." else os.path.join(dst_dir, rel)

        if not os.path.exists(target_root):
            os.makedirs(target_root, exist_ok=True)
            dirs_touched += 1

        for f in files:
            src_path = os.path.join(root, f)
            dst_path = os.path.join(target_root, f)
            shutil.copy2(src_path, dst_path)  # overwrite
            files_copied += 1

    return files_copied, dirs_touched

def choose_folder_and_copy(items, consoles_dir):
    """
    交互选择，并复制选中目录的全部内容到“脚本所在目录”
    """
    if not items:
        print("(No subfolders to choose from.)")
        return

    while True:
        choice = input("\nEnter a number to choose a folder (0 to exit): ").strip().lower()
        if choice in {"0", "q"}:
            print("Exited.")
            return
        if not choice.isdigit():
            print("⚠️ Please enter a valid number.")
            continue

        idx = int(choice)
        if 1 <= idx <= len(items):
            display, real = items[idx - 1]
            src_dir = os.path.join(consoles_dir, real)
            dst_dir = get_base_dir()

            print(f"\n✅ You chose: {display}  (folder: {real})")
            print(f"Source: {src_dir}")
            print(f"Destination (script/exe directory): {dst_dir}")

            print("📂 Copying selected folder (files will be overwritten)...")
            files_copied, dirs_touched = copy_all_contents(src_dir, dst_dir)
            print(f"\n✨ Done! Files copied: {files_copied}, directories created/merged: {dirs_touched}.")
            return
        else:
            print("⚠️ Number out of range, try again.")

def main():
    consoles_dir = get_consoles_dir()
    items = list_subfolders(consoles_dir)   # [(display_name, real_name)]
    show_menu(items)
    choose_folder_and_copy(items, consoles_dir)

if __name__ == "__main__":
    main()
