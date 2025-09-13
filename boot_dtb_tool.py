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
    "hg36": "GameConsole HG36",
    "r36ultra": "GameConsole R36Ultra",
    "rx6h": "GameConsole RX6H",
    "k36s": "GameConsole K36S | GameConsole R36T",
    "origin r36s panel 0": "GameConsole R36s Panel 0",
    "origin r36s panel 1": "GameConsole R36s Panel 1",
    "origin r36s panel 2": "GameConsole R36s Panel 2",
    "origin r36s panel 3": "GameConsole R36s Panel 3",
    "origin r36s panel 4": "GameConsole R36s Panel 4",
    "origin r36s panel 5": "GameConsole R36s Panel 5",
}

# 2) 排除规则（glob 通配，多条规则其一匹配即排除）
EXCLUDE_PATTERNS = {
    "files", "kenrel", "logo",
}

# 3) 额外复制映射：
#    键：你“选中”的 consoles 子目录名（real name）
#    值：一个列表，里面是“还需要一起复制”的其它目录路径：
#       - 如果是相对路径：相对于 consoles/ 目录（例如 "common"、"shared/skins"）
#       - 如果是绝对路径：按绝对路径处理（例如 "D:/assets/overrides" 或 "/opt/assets"）
#    复制规则与主复制一致：会把来源目录下“所有内容”覆盖复制到目标（脚本目录）。
EXTRA_COPY_MAP = {
    # 示例：选中 r36max 时，同时把 consoles/common 与 consoles/shared/ui 也复制过去
    "mymini": ["logo/480P/", "kenrel/common/"],
    "r36max": ["logo/720P/", "kenrel/common/"],
    "r36pro": ["logo/480P/", "kenrel/common/"],
    "xf35h": ["logo/480P/", "kenrel/common/"],
    "xf40h": ["logo/720P/", "kenrel/common/"],
    "r36ultra": ["logo/720P/", "kenrel/common/"],
    "k36s": ["logo/480P/", "kenrel/common/"],
    "hg36": ["logo/480p/", "kenrel/common/"],
    "origin r36s panel 0": ["logo/480P/", "kenrel/common/"],
    "origin r36s panel 1": ["logo/480P/", "kenrel/common/"],
    "origin r36s panel 2": ["logo/480P/", "kenrel/common/"],
    "origin r36s panel 3": ["logo/480P/", "kenrel/common/"],
    "origin r36s panel 4": ["logo/480P/", "kenrel/common/"],
    "origin r36s panel 5": ["logo/480P/", "kenrel/panel5/"],

    # 示例：选中 mymini 时，从绝对路径再拼一份内容（按需修改/删除）
    # "mymini": ["/absolute/path/to/extra_stuff"],

    # 按需添加更多键值
}

# ===================== 工具函数 =====================
def intro_and_wait():
    if not sys.stdin.isatty():  # 非交互直接返回
        return
    print("\n================ Welcome 欢迎使用 ================")
    print("说明：本系统目前只支持下列机型，如果你的 R36 克隆机不在列表中，则暂时无法使用。")
    print("⚠️ 请不要使用原装 EE 卡中的 dtb 文件搭配本系统，否则会导致系统无法启动！")
    print()
    print("选择机型前请阅读：")
    print("  • 本工具会清理目标目录顶层的 .dtb/.ini/.orig/.tony 文件，并删除 BMPs 文件夹；")
    print("  • 随后复制所选机型及额外映射资源。")
    print("  • 按 Enter 继续；输入 q 退出。")
    print("-----------------------------------------")
    print("NOTE:")
    print("  • This system currently only supports the listed R36 clones;")
    print("    if your clone is not in the list, it is not supported yet.")
    print("  • ⚠️ Do NOT use the dtb files from the stock EE card with this system — it will brick the boot.")
    print()
    print("Before selecting a console:")
    print("  • This tool cleans top-level .dtb/.ini/.orig/.tony files and removes the BMPs/ folder,")
    print("    then copies the chosen console and any mapped extra sources.")
    print("  • Press Enter to continue; type 'q' to quit.")
    cont = input("\n按 Enter 继续 / Press Enter to continue (q to quit): ").strip().lower()
    if cont == 'q':
        print("已退出 / Exited.")
        sys.exit(0)

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
    列出未被排除、且在 EXTRA_COPY_MAP 中配置过的子目录（大小写/前后空格不敏感）。
    返回 [(display_name, real_name)]，按显示名排序
    """
    if not os.path.exists(parent_dir):
        print("❌ 'consoles' folder not found:", parent_dir)
        return []

    # 用规范化后的名字做白名单：strip + casefold
    wl_norm2real = {k.strip().casefold(): k for k in EXTRA_COPY_MAP.keys()}

    items = []
    for name in os.listdir(parent_dir):
        full = os.path.join(parent_dir, name)
        if not os.path.isdir(full):
            continue
        if is_excluded(name):
            continue

        norm = name.strip().casefold()

        if norm not in wl_norm2real:
            # 不在白名单，跳过
            continue

        real_key = wl_norm2real[norm]  # EXTRA_COPY_MAP 里的真实 key
        display = ALIASES.get(real_key, real_key)
        items.append((display, name))   # 显示别名，实际拷目录用扫描到的 name

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

def remove_files_by_ext(base_dir, extensions):
    """
    删除 base_dir 目录（仅该层，不递归）中指定扩展名的所有文件。
    extensions: 形如 {'.dtb', '.ini'}
    返回删除计数
    """
    removed = 0
    for name in os.listdir(base_dir):
        full = os.path.join(base_dir, name)
        if os.path.isfile(full):
            _, ext = os.path.splitext(name)
            if ext.lower() in extensions:
                try:
                    os.remove(full)
                    removed += 1
                    print(f"🧹 Removed file: {full}")
                except Exception as e:
                    print(f"⚠️ Failed to remove {full}: {e}")
    return removed

def remove_dir_if_exists(path):
    """
    删除目录（若存在），返回是否删除成功
    """
    if os.path.isdir(path):
        try:
            shutil.rmtree(path)
            print(f"🧹 Removed folder: {path}")
            return True
        except Exception as e:
            print(f"⚠️ Failed to remove folder {path}: {e}")
    return False

def clean_destination(dst_dir):
    """
    清理目标目录：删除 .dtb / .ini 文件（仅顶层），并删除 BMPs 文件夹。
    """
    print("\n🧽 Cleaning destination directory...")
    removed_files = remove_files_by_ext(dst_dir, {".dtb", ".ini", ".orig", ".tony"})
    bmps_removed = remove_dir_if_exists(os.path.join(dst_dir, "BMPs"))
    print(f"✨ Cleaned. Removed files: {removed_files}, removed BMPs: {bmps_removed}")

def resolve_extra_source(consoles_dir, path_str):
    """
    解析 EXTRA_COPY_MAP 里的路径：
      - 绝对路径：原样返回
      - 相对路径：认为是相对 consoles_dir
    """
    if os.path.isabs(path_str):
        return path_str
    return os.path.join(consoles_dir, path_str)

def copy_with_extras(selected_real_name, consoles_dir, dst_dir):
    """
    先复制选中目录，再根据 EXTRA_COPY_MAP 复制额外来源。
    """
    total_files = 0
    total_dirs = 0

    # 1) 复制选中目录
    selected_src = os.path.join(consoles_dir, selected_real_name)
    print("📂 Copying selected folder (overwrite existing files)...")
    f1, d1 = copy_all_contents(selected_src, dst_dir)
    total_files += f1
    total_dirs += d1
    print(f"✅ Selected copied: files={f1}, dirs={d1}")

    # 2) 复制额外来源（如果配置了）
    extras = EXTRA_COPY_MAP.get(selected_real_name, [])
    if extras:
        print("\n➕ Copying extra mapped sources:")
        for p in extras:
            src_path = resolve_extra_source(consoles_dir, p)
            if not os.path.isdir(src_path):
                print(f"⚠️ Extra source not found or not a directory, skipped: {src_path}")
                continue
            f, d = copy_all_contents(src_path, dst_dir)
            total_files += f
            total_dirs += d
            print(f"   • {src_path}  → files={f}, dirs={d}")
    else:
        print("\n(no extra sources mapped for this selection)")

    return total_files, total_dirs

def choose_folder_and_copy(items, consoles_dir):
    """
    交互选择，并复制选中目录（含额外映射）到“脚本所在目录”；
    在复制前会清理目标目录中的 .dtb / .ini 文件，以及 BMPs 文件夹。
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

            # 先清理，再复制
            clean_destination(dst_dir)

            total_files, total_dirs = copy_with_extras(real, consoles_dir, dst_dir)
            print(f"\n✨ Done! Total files copied: {total_files}, directories created/merged: {total_dirs}.")
            return
        else:
            print("⚠️ Number out of range, try again.")

def main():
    consoles_dir = get_consoles_dir()
    items = list_subfolders(consoles_dir)   # [(display_name, real_name)]
    intro_and_wait()  
    os.system("cls" if os.name == "nt" else "clear")
    show_menu(items)
 
    choose_folder_and_copy(items, consoles_dir)

if __name__ == "__main__":
    main()
