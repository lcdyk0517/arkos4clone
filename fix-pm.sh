#!/bin/bash
# pm_fix_semicolon.sh - 把 control.txt 中目标 sed 行禁用：行首插入 "; "
set -euo pipefail

# 扫描范围（先小范围试，OK 再加其它路径）
roots=(
  "/opt/system/Tools/PortMaster"
  "/opt/tools/PortMaster"
  "$HOME/.local/share/PortMaster"
  "/roms/ports/PortMaster"
  "/PortMaster"
)

# 需要命中的特征（ogs 这条：... rightstick:b17/rightstick:b15 ...）
PAT_SED='sed[[:space:]]*-i'
PAT_BACK='back:b14'
PAT_GUIDE12='guide:b12'
PAT_GUIDE14='guide:b14'
PAT_START='start:b15'
PAT_LEFTSTICK='leftstick:b16'
PAT_RIGHTSTICK='rightstick:b17/rightstick:b15'
PAT_FILE='gamecontrollerdb\.txt'

need_sudo() { local f="$1"; [[ -w "$f" ]] && return 1 || return 0; }

# 不再用 [[ =~ ]]；用 grep -Eq 判断一行是否已被 "; sed" 禁用
is_disabled_line() {
  printf '%s\n' "$1" | grep -Eq '^[[:space:]]*;[[:space:]]*sed'
}

patch_file() {
  local f="$1"
  local bak="${f}.bak"
  local changed=0

  # 找到所有命中行号（必须同时包含这些片段）
  mapfile -t hits < <(
    grep -nE "${PAT_SED}" "$f" 2>/dev/null \
    | grep -E "${PAT_BACK}" \
    | grep -E "${PAT_GUIDE12}" \
    | grep -E "${PAT_GUIDE14}" \
    | grep -E "${PAT_START}" \
    | grep -E "${PAT_LEFTSTICK}" \
    | grep -E "${PAT_RIGHTSTICK}" \
    | grep -E "${PAT_FILE}" \
    || true
  )
  [[ ${#hits[@]} -eq 0 ]] && return 1

  # 备份
  if need_sudo "$f"; then sudo cp -f -- "$f" "$bak"; else cp -f -- "$f" "$bak"; fi

  for h in "${hits[@]}"; do
    local ln="${h%%:*}"
    local line; line="$(sed -n "${ln}p" "$f" 2>/dev/null || true)"

    if is_disabled_line "$line"; then
      echo "[OK] already disabled: $f:$ln"
      continue
    fi

    # 在该行行首插入一个分号（保留原缩进与内容之后也无所谓；你要求是以 ';' 开头即可禁用）
    local sedcmd="${ln}s/^/;/"

    if need_sudo "$f"; then
      sudo sed -i "$sedcmd" "$f"
    else
      sed -i "$sedcmd" "$f"
    fi

    # 核验
    local newline; newline="$(sed -n "${ln}p" "$f" 2>/dev/null || true)"
    if is_disabled_line "$newline"; then
      echo "[OK] disabled: $f:$ln"
      changed=1
    else
      echo "[ERR] failed: $f:$ln ; restoring..."
      if need_sudo "$f"; then sudo mv -f -- "$bak" "$f"; else mv -f -- "$bak" "$f"; fi
      return 1
    fi
  done

  return $changed
}

echo "[TEST] scanning for control.txt ..."
changed_files=0
for root in "${roots[@]}"; do
  [[ -d "$root" ]] || continue
  while IFS= read -r -d '' f; do
    [[ -f "$f" ]] || continue
    if patch_file "$f"; then
      changed_files=$((changed_files+1))
    fi
  done < <(find "$root" -type f -name "control.txt" -print0 2>/dev/null)
done
echo "[TEST] done. files changed: $changed_files"
