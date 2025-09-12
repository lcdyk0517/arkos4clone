#!/usr/bin/env bash
set -euo pipefail

MOUNT_DIR="/home/lcdyk/arkos/mnt"

# 统一的 rsync 选项：
# -rltD   ：递归/保留软链/保留时间/保留设备文件（尽量通用）
# --no-owner --no-group --no-perms ：不要在 FAT32 上设置属主/属组/权限，避免 EPERM
# --omit-dir-times ：不尝试写目录时间戳（FAT32 上也可能受限）
RSYNC_BOOT_OPTS="-rltD --no-owner --no-group --no-perms --omit-dir-times"

echo "== 注入 boot =="
sudo mkdir -p "$MOUNT_DIR/boot/consoles"
# 不同步 consoles/files 目录（按你原本需求）
sudo rsync $RSYNC_BOOT_OPTS --exclude='files' ./consoles/ "$MOUNT_DIR/boot/consoles/"

# 这些都是普通文件，直接复制即可
sudo cp -f ./clone.sh ./dtb_selector.exe ./boot_dtb_tool.py ./expandtoexfat.sh "$MOUNT_DIR/boot/"

echo "== 注入按键信息 =="
sudo mkdir -p "$MOUNT_DIR/root/home/ark/.quirks"
# 这里你要的是把 consoles/files 这个“目录”复制进去，所以必须 -r
sudo cp -r ./consoles/files/* "$MOUNT_DIR/root/home/ark/.quirks/"
# 只有 ext4/f2fs 才能 chown，boot(FAT32) 不要 chown
sudo chown -R 1002:1002 "$MOUNT_DIR/root/home/ark/.quirks/"

echo "== 注入 clone 用配置 =="
sudo mkdir -p "$MOUNT_DIR/root/opt/system/clone" "$MOUNT_DIR/root/usr/bin"
sudo cp -f ./adjust-keys.sh ./joyled.sh "$MOUNT_DIR/root/opt/system/clone/"
sudo cp -f ./mcu_led ./ws2812 "$MOUNT_DIR/root/usr/bin/"
sudo chown -f 1002:1002 "$MOUNT_DIR/root/usr/bin/ws2812" || true
sudo chown -f 1002:1002 "$MOUNT_DIR/root/usr/bin/mcu_led" || true
sudo chown -R 1002:1002 "$MOUNT_DIR/root/opt/system/clone"
sudo chmod -R 755 "$MOUNT_DIR/root/opt/system/clone"
sudo chmod 755 "$MOUNT_DIR/root/usr/bin/mcu_led" "$MOUNT_DIR/root/usr/bin/ws2812"

echo "== 注入 915 驱动 =="
sudo mkdir -p "$MOUNT_DIR/root/usr/lib/firmware" \
             "$MOUNT_DIR/root/usr/lib/modules/4.4.189/kernel/drivers/net/wireless"
# 通配符不存在会让 cp 失败，加 || true 容错
sudo cp -f ./rk915_*.bin "$MOUNT_DIR/root/usr/lib/firmware/" 2>/dev/null || true
sudo cp -f ./rk915.ko "$MOUNT_DIR/root/usr/lib/modules/4.4.189/kernel/drivers/net/wireless/" 2>/dev/null || true
sudo chmod 755 "$MOUNT_DIR/root/usr/lib/modules/4.4.189/kernel/drivers/net/wireless/rk915.ko" 2>/dev/null || true
sudo chmod 755 "$MOUNT_DIR/root/usr/lib/firmware/"rk915_*.bin 2>/dev/null || true

echo "== 注入 351Files 资源 =="
sudo mkdir -p "$MOUNT_DIR/root/opt/351Files/res"
# 这里 res/* 是多个“目录”，必须 -r
sudo cp -r ./res/* "$MOUNT_DIR/root/opt/351Files/res/" 2>/dev/null || true

# 重命名 351Files -> 351Files.r36s（存在才动）
if [[ -e "$MOUNT_DIR/root/opt/351Files/351Files" ]]; then
  sudo mv "$MOUNT_DIR/root/opt/351Files/351Files" "$MOUNT_DIR/root/opt/351Files/351Files.r36s"
else
  echo "[warn] 未找到 $MOUNT_DIR/root/opt/351Files/351Files，跳过重命名"
fi

sudo chown -R 1002:1002 "$MOUNT_DIR/root/opt/351Files/" 2>/dev/null || true
sudo chmod -R 755 "$MOUNT_DIR/root/opt/351Files/" 2>/dev/null || true

echo "== 注入 retrorun 启动脚本 =="
sudo cp -f ./replace_file/*.sh "$MOUNT_DIR/root/usr/local/bin/"
sudo chown root:root "$MOUNT_DIR/root/usr/local/bin/atomiswave.sh" 2>/dev/null || true
sudo chown root:root "$MOUNT_DIR/root/usr/local/bin/dreamcast.sh" 2>/dev/null || true
sudo chown root:root "$MOUNT_DIR/root/usr/local/bin/naomi.sh" 2>/dev/null || true
sudo chown root:root "$MOUNT_DIR/root/usr/local/bin/saturn.sh" 2>/dev/null || true
sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/atomiswave.sh" 2>/dev/null || true
sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/dreamcast.sh" 2>/dev/null || true
sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/naomi.sh" 2>/dev/null || true
sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/saturn.sh" 2>/dev/null || true


echo "== 复制 roms.tar 出来操作 =="
sudo cp "$MOUNT_DIR/root/roms.tar" /home/lcdyk/arkos/
mkdir -p /home/lcdyk/arkos/tmproms
tar -xf /home/lcdyk/arkos/roms.tar -C /home/lcdyk/arkos/tmproms
mkdir -p /home/lcdyk/arkos/tmproms/roms/ports
cp -f Install.Full.PortMaster.sh /home/lcdyk/arkos/tmproms/roms/ports/
cp -rf libs /home/lcdyk/arkos/tmproms/roms/ports/
chmod +x /home/lcdyk/arkos/tmproms/roms/ports/Install.Full.PortMaster.sh
tar -cf /home/lcdyk/arkos/roms.tar -C /home/lcdyk/arkos/tmproms .
rm -rf /home/lcdyk/arkos/tmproms
sudo cp /home/lcdyk/arkos/roms.tar "$MOUNT_DIR/root/"
sudo chmod -R 755 $MOUNT_DIR/root/roms.tar

echo "== ogage快捷键复制 =="
sudo cp -r ./replace_file/ogage "$MOUNT_DIR/root/usr/local/bin/"
sudo cp -r ./replace_file/ogage "$MOUNT_DIR/root/home/ark/.quirks/"

echo "== 完成 =="