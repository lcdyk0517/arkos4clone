#!/bin/bash
# 3DS 启动器：游戏按需解密后运行；DLC 解密（或已解密）后离线安装进 Azahar 的模拟 NAND。
# 不修改核心。密钥来自 /roms/bios/boot9.bin 或 boot9_prot.bin。
# 提示信息统一用英文：ArkOS 的 fb console 没有中文字库。
set -u

ROM="${1:-}"
[ -n "$ROM" ] || { echo "usage: azahar-dec.sh <game.3ds|game.cci|game.cia>" >&2; exit 2; }

# 解密/安装期间 ES 已经让出 DRM master, fb console 是黑的; kxstatus 自己接管
# KMS 画一页状态, 从 $STATUS_FILE 读取要显示的文字.
STATUS_FILE="${AZAHAR_STATUS_FILE:-/tmp/azahar-dec.status}"
KXSTATUS_PID=""

msg() {
    echo "$*" >&2
    [ -n "$LOG" ] && echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "$LOG"
    [ -w /dev/tty1 ] && echo "$*" > /dev/tty1
    if [ -n "$KXSTATUS_PID" ]; then
        tail -n 6 "$STATUS_FILE" 2>/dev/null > "$STATUS_FILE.tmp"
        echo "$*" >> "$STATUS_FILE.tmp"
        mv -f "$STATUS_FILE.tmp" "$STATUS_FILE"
    fi
}

screen_start() {
    printf '%s\n' "$@" > "$STATUS_FILE" 2>/dev/null
    if [ -z "$KXSTATUS_PID" ] && [ -x /usr/local/bin/kxstatus ]; then
        /usr/local/bin/kxstatus "$STATUS_FILE" >/dev/null 2>&1 &
        KXSTATUS_PID=$!
        sleep 0.3
    fi
}

screen_stop() {
    if [ -n "$KXSTATUS_PID" ]; then
        kill "$KXSTATUS_PID" 2>/dev/null
        wait "$KXSTATUS_PID" 2>/dev/null
        KXSTATUS_PID=""
        sleep 0.2
    fi
    rm -f "$STATUS_FILE" "$STATUS_FILE.tmp" 2>/dev/null
}

trap screen_stop EXIT
trap 'screen_stop; exit 130' INT
trap 'screen_stop; exit 143' TERM

TOOL="${DSDEC_BIN:-/usr/local/bin/3dsdec}"
AZAHAR="${AZAHAR_BIN:-/usr/local/bin/azahar.sh}"

# 失败提示一闪而过, 同时落盘一份供事后查看
LOG="${AZAHAR_DEC_LOG:-/tmp/azahar-dec.log}"
: > "$LOG" 2>/dev/null || LOG=""
[ -n "$LOG" ] && echo "$(date '+%Y-%m-%d %H:%M:%S') launch: $ROM" >> "$LOG"

# 等 A 键再返回 ES (buttonmon 的 Test_Button_A 按下时返回 10)
wait_for_a() {
    if [ -z "$KXSTATUS_PID" ]; then
        screen_start "3DS" "$(basename "$ROM")"
    fi
    msg "Press A to continue"
    if [ ! -r /usr/local/bin/buttonmon.sh ]; then
        sleep 3
        return 0
    fi
    . /usr/local/bin/buttonmon.sh
    local i=0
    while [ "$i" -lt 1200 ]; do
        Test_Button_A
        if [ $? -eq 10 ]; then
            sleep 0.3
            return 0
        fi
        sleep 0.1
        i=$((i + 1))
    done
    return 0
}

# 安装完成后: A = 删除源文件, B = 保留. 返回 0 表示删除, 1 表示保留.
wait_delete_or_keep() {
    if [ -z "$KXSTATUS_PID" ]; then
        screen_start "3DS" "$(basename "$ROM")"
    fi
    msg "Press A to DELETE the source file, B to KEEP it"
    if [ ! -r /usr/local/bin/buttonmon.sh ]; then
        sleep 3
        return 1
    fi
    . /usr/local/bin/buttonmon.sh
    local i=0
    while [ "$i" -lt 1200 ]; do
        Test_Button_A
        if [ $? -eq 10 ]; then
            sleep 0.3
            return 0
        fi
        Test_Button_B
        if [ $? -eq 10 ]; then
            sleep 0.3
            return 1
        fi
        sleep 0.1
        i=$((i + 1))
    done
    return 1
}

after_install_prompt() {
    if wait_delete_or_keep; then
        rm -f "$ROM" && msg "Source file deleted" || msg "Delete failed: $ROM"
    else
        msg "Source file kept"
    fi
}

case "${ROM,,}" in
    *.zip|*.7z) msg "Extract the archive before launching"; exit 1 ;;
esac

# 没有 3dsdec 时只允许直接启动已解密的镜像; 这里只看 NoCrypto 标志, 不依赖外部工具.
image_is_decrypted() {
    local f="$1" magic shift unit off flags
    magic=$(od -An -tx1 -j 256 -N4 "$f" 2>/dev/null | tr -d ' \n')
    case "$magic" in
        4e435344)  # "NCSD"
            shift=$(od -An -tu1 -j 398 -N1 "$f" 2>/dev/null | tr -d ' ')
            unit=$((512 << ${shift:-0}))
            off=$(od -An -tu4 -j 288 -N4 "$f" 2>/dev/null | tr -d ' ')
            [ -n "$off" ] || return 1
            flags=$(od -An -tu1 -j $((off * unit + 399)) -N1 "$f" 2>/dev/null | tr -d ' ')
            ;;
        4e434348)  # "NCCH"
            flags=$(od -An -tu1 -j 399 -N1 "$f" 2>/dev/null | tr -d ' ')
            ;;
        *) return 1 ;;
    esac
    [ -n "$flags" ] && [ $((flags & 4)) -ne 0 ]
}

if [ ! -x "$TOOL" ]; then
    case "${ROM,,}" in
        *.cia)
            msg "3dsdec not installed: CIA needs decryption/install"
            wait_for_a
            exit 1
            ;;
        *)
            if image_is_decrypted "$ROM"; then
                screen_stop
                exec "$AZAHAR" "$ROM"
            fi
            msg "3dsdec not installed: encrypted image cannot be launched"
            wait_for_a
            exit 1
            ;;
    esac
fi

status="$("$TOOL" --check "$ROM" 2>/dev/null)"
rc=$?
if [ "$rc" -eq 2 ]; then
    screen_start "3DS" "$(basename "$ROM")"
    msg "Not a valid 3DS image: $ROM"
    wait_for_a
    exit 1
fi

BOOT9=""
for f in /roms/bios/boot9.bin /roms/bios/boot9_prot.bin \
         /roms2/bios/boot9.bin /roms2/bios/boot9_prot.bin; do
    [ -f "$f" ] && { BOOT9="$f"; break; }
done
KEYS=()
for k in /roms/bios/3dsdec.keys /roms2/bios/3dsdec.keys; do
    [ -f "$k" ] && { KEYS=(--keys "$k"); break; }
done
SEEDDB=""
for f in /roms/bios/seeddb.bin /roms2/bios/seeddb.bin; do
    [ -f "$f" ] && { SEEDDB="$f"; break; }
done

USERDIR="${AZAHAR_USER_DIR:-}"
if [ -z "$USERDIR" ]; then
    SAVE=$(sed -n 's/^savefile_directory = "\(.*\)"/\1/p' /home/ark/.config/retroarch/retroarch.cfg 2>/dev/null | tail -n1)
    [ -n "$SAVE" ] || SAVE="\${HOME}/.config/retroarch/saves"
    SAVE=${SAVE/#\~/$HOME}
    USERDIR="$SAVE/Azahar"
fi
mkdir -p "$USERDIR" 2>/dev/null || true

key_opts() {
    [ -n "$BOOT9" ] && printf '%s\n' --boot9 "$BOOT9"
    [ ${#KEYS[@]} -gt 0 ] && printf '%s\n' "${KEYS[@]}"
    [ -n "$SEEDDB" ] && printf '%s\n' --seeddb "$SEEDDB"
}

ROMDIR="$(dirname "$ROM")"

# 核心只在 NAND 缺 0004009B/00014002 时才回落内置开源字体, 不会读
# sysdata/shared_font.bin. 按游戏同名字库目录决定用哪个字体:
#   <游戏文件名>_字库/  存在 -> 用它装进 NAND
#   不存在               -> 删掉我们装的字体, 核心回落上游开源字库
FONT_DIR="$USERDIR/nand/00000000000000000000000000000000/title/0004009b"
FONT_STAMP="$USERDIR/.shared-font-source"

ensure_shared_font() {
    local base stem stem2 dir f
    base=$(basename "$ROM")
    stem="${base%.*}"
    stem2="${stem%.decrypted}"
    [ "$stem2" = "$stem" ] && stem2="${stem%.解密}"

    dir=""
    for c in "$ROMDIR/${stem}_字库" "$ROMDIR/${stem2}_字库"; do
        [ -d "$c" ] && { dir="$c"; break; }
    done

    if [ -z "$dir" ]; then
        if [ -f "$FONT_STAMP" ] || [ -d "$FONT_DIR/00014002" ]; then
            rm -rf "$FONT_DIR/00014002" "$FONT_DIR/00014102" "$FONT_STAMP"
        fi
        return 0
    fi

    f=""
    for c in "$dir/sysdata/cbf_std.bcfnt" "$dir/sysdata/shared_font.bin" \
             "$dir/sysdata/cbf_std.bcfnt.lz" "$dir/cbf_std.bcfnt" \
             "$dir/shared_font.bin" "$dir/cbf_std.bcfnt.lz"; do
        [ -f "$c" ] && { f="$c"; break; }
    done
    [ -n "$f" ] || return 0
    [ -x "$TOOL" ] || return 0

    local src="$f|$(stat -c '%s|%Y' "$f" 2>/dev/null)"
    [ "$(cat "$FONT_STAMP" 2>/dev/null)" = "$src" ] && return 0

    msg "Installing shared font..."
    if "$TOOL" --install-font "$f" "$USERDIR" >>"${LOG:-/dev/null}" 2>&1; then
        echo "$src" > "$FONT_STAMP"
        msg "Shared font installed"
    else
        msg "Shared font install failed"
    fi
}

ensure_shared_font

# 签名体长度 (与 3dsdec 的 signature_body 一致), 输入: 文件 + 偏移
sig_body() {
    local s
    s=$(od -An -tx1 -j "$2" -N4 "$1" 2>/dev/null | tr -d ' \n')
    case "$s" in
        00010000*|00010003*) echo 576 ;;
        00010001*|00010004*) echo 320 ;;
        00010002*|00010005*) echo 124 ;;
        *) echo 0 ;;
    esac
}

# CIA 标题 ID: ticket 在 0x2040+证书链对齐之后, title id 在签名体后 +0x9C
cia_title_id() {
    local cert ticket tb
    cert=$(od -An -tu4 -j 8 -N4 "$ROM" 2>/dev/null | tr -d ' ')
    [ -n "$cert" ] || return 1
    ticket=$((0x2040 + ((cert + 63) / 64) * 64))
    tb=$(sig_body "$ROM" "$ticket")
    [ "$tb" -gt 0 ] || return 1
    od -An -tx1 -j $((ticket + tb + 0x9c)) -N8 "$ROM" 2>/dev/null | tr -d ' \n'
}

case "${ROM,,}" in
    *.cia)
        # 标题 ID 高 32 位为 0004008c 的是 DLC：只安装，不启动。
        tid=$(cia_title_id || true)
        is_dlc=no
        is_update=no
        if [ ${#tid} -eq 16 ]; then
            case "${tid,,}" in
                0004008c*) is_dlc=yes ;;
                0004000e*) is_update=yes ;;
            esac
        fi

        if [ "$is_update" = yes ]; then
            # 0004000E 是更新补丁 (Update): 安装到模拟 NAND 的 title 目录, 不启动
            msg "Installing update $tid..."
            out=$("$TOOL" --install-update "$ROM" "$USERDIR" $(key_opts) 2>&1)
            rc=$?
            if [ "$rc" -eq 0 ]; then
                msg "Update installed successfully"
                after_install_prompt
                exit 0
            fi
            msg "Update install failed: $out"
            wait_for_a
            exit 1
        fi

        if [ "$is_dlc" = yes ]; then
            # DLC 内容在模拟 SD 卡 (media_type=1), ticket 在 NAND dbs.
            SDMC="$USERDIR/sdmc/Nintendo 3DS/00000000000000000000000000000000/00000000000000000000000000000000/title/${tid:0:8}/${tid:8:8}"
            TMD="$SDMC/content/00000000.tmd"
            already=no
            if [ -f "$TMD" ]; then
                mb=$(sig_body "$TMD" 0)
                b1=$(od -An -tu1 -j $((mb + 0x9e)) -N1 "$TMD" 2>/dev/null | tr -d ' ')
                b2=$(od -An -tu1 -j $((mb + 0x9f)) -N1 "$TMD" 2>/dev/null | tr -d ' ')
                want=$(( ${b1:-0} * 256 + ${b2:-0} ))
                have=$(find "$SDMC/content" -name '*.app' 2>/dev/null | wc -l)
                [ "$want" -gt 0 ] && [ "$have" -ge "$want" ] && already=yes
                # 旧版本只写了内容没写 ticket, 视为未装完并重装一次.
                TB="$USERDIR/nand/00000000000000000000000000000000/dbs/ticket.db"
                [ -n "$(find "$TB" -iname "${tid}.*.tik" 2>/dev/null | head -n1)" ] || already=no
            fi
            if [ "$already" = yes ]; then
                msg "DLC already installed"
                wait_for_a
                exit 0
            fi
            screen_start "Installing 3DS DLC" "$(basename "$ROM")" "First launch can take a while"
            msg "Installing DLC..."
            out=$("$TOOL" --install-dlc "$ROM" "$USERDIR" $(key_opts) 2>&1)
            rc=$?
            if [ "$rc" -eq 0 ]; then
                msg "DLC installed successfully"
                after_install_prompt
                exit 0
            fi
            msg "DLC install failed: $out"
            wait_for_a
            exit 1
        fi

        is_game=no
        [ ${#tid} -eq 16 ] && [ "${tid:0:8}" = "00040000" ] && is_game=yes

        # 只有标题 ID 读不到时才用 --install-dlc 探测; 已知是游戏的直接解密
        if [ "$is_dlc" = no ] && [ "$is_game" != yes ]; then
            out=$("$TOOL" --install-dlc "$ROM" "$USERDIR" $(key_opts) 2>&1)
            rc=$?
            if [ "$rc" -eq 0 ]; then
                msg "DLC installed successfully"
                wait_for_a
                exit 0
            fi
            if ! printf '%s' "$out" | grep -q "not a DLC title"; then
                msg "DLC install failed: $out"
                wait_for_a
                exit 1
            fi
        fi

        # 游戏 CIA：核心只能读 CCI，在源文件旁生成 xxx.decrypted.cci 再运行。
        DIR="$(dirname "$ROM")"
        BASE="$(basename "$ROM")"
        CACHE="$DIR/${BASE%.*}.decrypted.cci"
        if [ ! -f "$CACHE" ] || [ "$ROM" -nt "$CACHE" ]; then
            screen_start "Decrypting 3DS game" "$(basename "$ROM")" "First launch can take a while"
            msg "Decrypting game CIA..."
            # 临时名必须保留 .cci 后缀: 3dsdec 按输出扩展名决定是否把 CIA 重封装成 NCSD。
            TMP="$DIR/.${BASE%.*}.part.cci"
            rm -f "$TMP"
            "$TOOL" --decrypt "$ROM" "$TMP" $(key_opts) || { rm -f "$TMP"; msg "Decryption failed"; wait_for_a; exit 1; }
            mv -f "$TMP" "$CACHE" || exit 1
        fi
        screen_stop
        exec "$AZAHAR" "$CACHE"
        ;;
    *)
        case "$status" in
            decrypted)
                screen_stop
                exec "$AZAHAR" "$ROM"
                ;;
            encrypted:seed)
                msg "Seed-encrypted images are not supported; decrypt on a 3DS/PC first"
                wait_for_a
                exit 1
                ;;
            encrypted:*)
                if [ -z "$BOOT9" ] && [ ${#KEYS[@]} -eq 0 ]; then
                    msg "Missing keys: /roms/bios/boot9.bin or 3dsdec.keys"
                    wait_for_a
                    exit 1
                fi
                DIR="$(dirname "$ROM")"
                BASE="$(basename "$ROM")"
                CACHE="$DIR/${BASE%.*}.decrypted.cci"
                if [ -f "$CACHE" ] && [ "$CACHE" -nt "$ROM" ]; then
                    screen_stop
                    exec "$AZAHAR" "$CACHE"
                fi
                screen_start "Decrypting 3DS game" "$(basename "$ROM")" "First launch can take a while"
                msg "Decrypting $(basename "$ROM")... (first launch may take a while)"
                TMP="$DIR/.${BASE%.*}.part.cci"
                rm -f "$TMP"
                "$TOOL" --decrypt "$ROM" "$TMP" $(key_opts) || { rm -f "$TMP"; msg "Decryption failed"; wait_for_a; exit 1; }
                mv -f "$TMP" "$CACHE" || exit 1
                screen_stop
                exec "$AZAHAR" "$CACHE"
                ;;
            *)
                msg "Unrecognized image encryption state: $status"
                wait_for_a
                exit 1
                ;;
        esac
        ;;
esac
