#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import sys
import xml.etree.ElementTree as ET
import unicodedata

DEFAULT_INPUT_DRIVER = "udev"
DEFAULT_PLATFORM = "Linux"
DEFAULT_VENDOR_ID = None
DEFAULT_PRODUCT_ID = None

# ---------- 工具函数 ----------
def clear_screen():
    os.system("cls" if os.name == "nt" else "clear")

def disp_len(s: str) -> int:
    total = 0
    for ch in str(s):
        ea = unicodedata.east_asian_width(ch)
        total += 2 if ea in ("F", "W") else 1
    return total

def pad_to(s: str, width: int) -> str:
    cur = disp_len(s)
    return s + " " * (width - cur) if cur < width else s

# ---------- 解析 ----------
def parse_es_multi(path):
    tree = ET.parse(path)
    root = tree.getroot()
    if root.tag == "inputList":
        cfg_nodes = root.findall("inputConfig")
    elif root.tag == "inputConfig":
        cfg_nodes = [root]
    else:
        cfg_nodes = root.findall(".//inputConfig")

    pads = []
    for node in cfg_nodes:
        meta = {
            "deviceName": node.attrib.get("deviceName", "Unknown Gamepad"),
            "deviceGUID": node.attrib.get("deviceGUID", ""),
        }
        inputs = {}
        for inp in node.findall("input"):
            name = (inp.attrib.get("name") or "").lower()
            itype = (inp.attrib.get("type") or "").lower()
            iid = inp.attrib.get("id")
            val = inp.attrib.get("value")
            if name and itype and iid is not None and val is not None:
                try:
                    inputs[name] = {"type": itype, "id": int(iid), "value": int(val)}
                except ValueError:
                    continue
        pads.append({"deviceName": meta["deviceName"], "deviceGUID": meta["deviceGUID"], "inputs": inputs})
    return pads

# ---------- RA/GDB 生成 ----------
def axis_pm(ent):
    return f'+{ent["id"]}' if ent and ent["type"]=="axis" and ent["value"]>0 else (f'-{ent["id"]}' if ent else None)

def build_ra_text(pad, input_driver=DEFAULT_INPUT_DRIVER, vendor_id=DEFAULT_VENDOR_ID, product_id=DEFAULT_PRODUCT_ID):
    name, inputs = pad["deviceName"], pad["inputs"]
    btn_map = {
        "a":"input_a_btn","b":"input_b_btn","x":"input_x_btn","y":"input_y_btn",
        "start":"input_start_btn","select":"input_select_btn",
        "up":"input_up_btn","down":"input_down_btn","left":"input_left_btn","right":"input_right_btn",
        "leftshoulder":"input_l_btn","rightshoulder":"input_r_btn",
        "lefttrigger":"input_l2_btn","righttrigger":"input_r2_btn",
        "leftthumb":"input_l3_btn","rightthumb":"input_r3_btn",
    }
    axis_map = {
        "leftanalogleft":"input_l_x_minus_axis","leftanalogright":"input_l_x_plus_axis",
        "leftanalogup":"input_l_y_minus_axis","leftanalogdown":"input_l_y_plus_axis",
        "rightanalogleft":"input_r_x_minus_axis","rightanalogright":"input_r_x_plus_axis",
        "rightanalogup":"input_r_y_minus_axis","rightanalogdown":"input_r_y_plus_axis",
    }
    lines=[f'input_driver = "{input_driver}"',f'input_device = "{name}"']
    for es,ra in btn_map.items():
        ent=inputs.get(es)
        if ent and ent["type"]=="button":
            lines.append(f'{ra} = "{ent["id"]}"')
    for es,ra in axis_map.items():
        ent=inputs.get(es)
        if ent and ent["type"]=="axis":
            s=axis_pm(ent)
            if s: lines.append(f'{ra} = "{s}"')
    if vendor_id is not None: lines.append(f'input_vendor_id = "{vendor_id}"')
    if product_id is not None: lines.append(f'input_product_id = "{product_id}"')
    return "\n".join(lines)+"\n"

def build_gdb_line(pad, platform=DEFAULT_PLATFORM):
    name,guid,inputs=pad["deviceName"], pad["deviceGUID"] or "00000000000000000000000000000000", pad["inputs"]
    btn_map={"a":"a","b":"b","x":"x","y":"y","select":"back","start":"start",
             "leftshoulder":"leftshoulder","rightshoulder":"rightshoulder",
             "lefttrigger":"lefttrigger","righttrigger":"righttrigger",
             "leftthumb":"leftstick","rightthumb":"rightstick",
             "up":"dpup","down":"dpdown","left":"dpleft","right":"dpright"}
    parts=[]
    for es,sdl in btn_map.items():
        ent=inputs.get(es)
        if ent and ent["type"]=="button": parts.append(f"{sdl}:b{ent['id']}")
    axis_pairs={"leftx":["leftanalogleft","leftanalogright"],
                "lefty":["leftanalogup","leftanalogdown"],
                "rightx":["rightanalogleft","rightanalogright"],
                "righty":["rightanalogup","rightanalogdown"]}
    for sdl_axis,pair in axis_pairs.items():
        aid=None
        for es in pair:
            ent=inputs.get(es)
            if ent and ent["type"]=="axis":
                aid=ent["id"]; break
        if aid is not None: parts.append(f"{sdl_axis}:a{aid}")
    return f"{guid},{name},"+",".join(parts)+f",platform:{platform},"

# ---------- 展示（含排序与中文映射） ----------
def pretty_print_pad_values(pad):
    name = pad["deviceName"]
    guid = pad["deviceGUID"]
    inputs = pad["inputs"]

    cn_map = {
        "a": "按键 A", "b": "按键 B", "x": "按键 X", "y": "按键 Y",
        "start": "开始", "select": "选择",
        "up": "方向 ↑", "down": "方向 ↓", "left": "方向 ←", "right": "方向 →",
        "leftshoulder": "L1", "rightshoulder": "R1",
        "lefttrigger": "L2", "righttrigger": "R2",
        "leftthumb": "左摇杆按下 (L3)", "rightthumb": "右摇杆按下 (R3)",
        "leftanalogup": "左摇杆 ↑", "leftanalogdown": "左摇杆 ↓",
        "leftanalogleft": "左摇杆 ←", "leftanalogright": "左摇杆 →",
        "rightanalogup": "右摇杆 ↑", "rightanalogdown": "右摇杆 ↓",
        "rightanalogleft": "右摇杆 ←", "rightanalogright": "右摇杆 →",
        "hotkeyenable": "热键",
    }

    # 固定 axis 顺序：左摇杆(↑↓←→)，右摇杆(↑↓←→)
    axis_order = [
        "leftanalogup", "leftanalogdown", "leftanalogleft", "leftanalogright",
        "rightanalogup", "rightanalogdown", "rightanalogleft", "rightanalogright"
    ]

    W_EN, W_CN, W_TP, W_ID, W_VL = 18, 20, 8, 6, 6
    SEP = "  "

    print(f"{name}  (GUID: {guid})")
    line_len = W_EN + W_CN + W_TP + W_ID + W_VL + disp_len(SEP) * 4
    print("-" * line_len)

    if not inputs:
        print("（无记录的输入项）")
        print("-" * line_len)
        return

    # button：按 id 升序，其次英文名
    btn_rows = sorted(
        [(k, v) for k, v in inputs.items() if v["type"] == "button"],
        key=lambda x: (x[1]["id"], x[0])
    )
    # axis：按预定义逻辑顺序
    ax_rows = [(k, inputs[k]) for k in axis_order if k in inputs]

    rows = btn_rows + ax_rows

    head = (
        pad_to("英文名", W_EN) + SEP +
        pad_to("中文名", W_CN) + SEP +
        pad_to("类型",   W_TP) + SEP +
        pad_to("id",     W_ID) + SEP +
        pad_to("value",  W_VL)
    )
    print(head)
    print("-" * line_len)

    for k, v in rows:
        cn = cn_map.get(k, k)
        row = (
            pad_to(k,  W_EN) + SEP +
            pad_to(cn, W_CN) + SEP +
            pad_to(v["type"], W_TP) + SEP +
            pad_to(str(v["id"]), W_ID) + SEP +
            pad_to(str(v["value"]), W_VL)
        )
        print(row)

    print("-" * line_len)

# ---------- 主程序（含新选项：转换全部为 GDB） ----------
def main():
    cfg_path=os.path.join(os.path.abspath(os.path.dirname(__file__)),"es_input.cfg")
    if not os.path.isfile(cfg_path):
        print(f"[错误] 未找到 {cfg_path}"); sys.exit(1)
    try:
        pads=parse_es_multi(cfg_path)
    except Exception as e:
        print(f"[错误] 解析失败：{e}"); sys.exit(2)
    if not pads:
        print("未找到手柄配置"); sys.exit(0)

    while True:
        clear_screen()
        print(f"=== 手柄列表 (共 {len(pads)} 个) ===\n")
        for i,p in enumerate(pads):
            print(f"[{i}] {p['deviceName']} (GUID: {p['deviceGUID']})")
        print("\n[a] 转换全部为 gamecontrollerdb.txt")
        print("[q] 退出")
        choice=input("\n选择手柄序号 / 选项: ").strip().lower()

        if choice == "q":
            break
        if choice == "a":
            clear_screen()
            print("===== 全部手柄的 gamecontrollerdb.txt 映射行 =====\n")
            for idx, pad in enumerate(pads):
                line = build_gdb_line(pad)
                print(f"# [{idx}] {pad['deviceName']} (GUID: {pad['deviceGUID']})")
                print(line)
                print()
            input("输出完毕，回车返回主菜单…")
            continue

        if not choice.isdigit() or not (0<=int(choice)<len(pads)):
            input("无效输入，按回车返回…")
            continue

        pad=pads[int(choice)]
        while True:
            clear_screen()
            print("=== 已选择手柄 ===\n")
            pretty_print_pad_values(pad)
            print("\n--- 操作菜单 ---")
            print("[0] 转换为 RetroArch 配置（控制台输出）")
            print("[1] 转换为 gamecontrollerdb.txt 行（控制台输出）")
            print("[b] 返回上一级")
            sub=input("\n选择操作: ").strip().lower()

            if sub=="b":
                break
            elif sub=="0":
                clear_screen()
                print("===== RetroArch 配置 =====\n")
                print(build_ra_text(pad))
                input("\n输出完毕，回车返回手柄菜单…")
            elif sub=="1":
                clear_screen()
                print("===== gamecontrollerdb.txt 映射行 =====\n")
                print(build_gdb_line(pad))
                input("\n输出完毕，回车返回手柄菜单…")
            else:
                input("无效输入，按回车重试…")

if __name__=="__main__":
    main()
