import os
import shutil
import sys

def get_base_dir():
    """
    Return the directory of the running script/executable.
    Works for normal Python and PyInstaller-frozen executables.
    """
    if getattr(sys, "frozen", False):
        return os.path.dirname(sys.executable)
    return os.path.dirname(os.path.abspath(__file__))

def get_consoles_dir():
    return os.path.join(get_base_dir(), "consoles")

def list_subfolders(parent_dir):
    if not os.path.exists(parent_dir):
        print("❌ 'consoles' folder not found:", parent_dir)
        return []
    folders = [
        name for name in os.listdir(parent_dir)
        if os.path.isdir(os.path.join(parent_dir, name))
    ]
    folders.sort(key=str.lower)
    return folders

def show_menu(folders):
    print("\n📂 Found {} subfolders in 'consoles':".format(len(folders)))
    for i, name in enumerate(folders, 1):
        print(f"{i}. {name}")
    print("0. Exit (or press q)")

def copy_file(src, dst):
    # Overwrite by default, no prompt
    shutil.copy2(src, dst)
    print(f"✅ Copied {src} → {dst}")

def copy_all_contents(src_dir, dst_dir):
    """
    Copy everything under src_dir into dst_dir (preserve structure), overwrite files.
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

def choose_folder_and_copy(folders, consoles_dir):
    if not folders:
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
        if 1 <= idx <= len(folders):
            selected = folders[idx - 1]
            src_dir = os.path.join(consoles_dir, selected)
            dst_dir = get_base_dir()

            print(f"\n✅ You chose: {selected}")
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
    folders = list_subfolders(consoles_dir)
    show_menu(folders)
    choose_folder_and_copy(folders, consoles_dir)

if __name__ == "__main__":
    main()
