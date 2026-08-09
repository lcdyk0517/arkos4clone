# (d)ArkOS 4.4 Kernel Support for Unsupported Devices

Bringing **(d)ArkOS 4.4 kernel** support to unsupported devices. Contributions via PRs are always welcome.

> 💡 Use the [DTB Analysis Tool](https://lcdyk0517.github.io/dtbTools.html) to identify your clone type or request support for unsupported devices.

---

## Table of Contents

- [Quick Start](#quick-start)
- [Supported Devices](#supported-devices)
- [Manual Configuration](#manual-configuration)
- [Joystick Axis Remapping](#joystick-axis-remapping)
- [Technical Implementation](#technical-implementation)
- [Known Limitations](#known-limitations)
- [Contributing](#contributing)
- [Support the Project](#support-the-project)

---

## Quick Start

### Build (d)ArkOS4Clone Image

**For ArkOS4Clone:**

Option 1: Fork the repository, go to **Actions** tab, run the build workflow, then download the image from your fork's **Releases** page.

Option 2: Build manually:

```bash
git clone git@github.com:lcdyk0517/arkos4clone.git
cd arkos4clone
sudo ./build_image.sh ArkOS-R3XS.img .
```

**For dArkOS4Clone:**

> ⚠️ **Note:** dArkOS4Clone build process still requires more testing to fix bugs.

1. Download G350/RG351MP image from [christianhaitian/dArkOS](https://github.com/christianhaitian/dArkOS)
2. Extract to get `dArkOS-xxx.img`
3. Run:

```bash
git clone git@github.com:lcdyk0517/arkos4clone.git
cd arkos4clone
sudo ./build_image.sh dArkOS-xxx.img .
```

After the script finishes, `(d)ArkOS4Clone.img.xz` will be generated in the root directory.

### Usage

1. Download the **ArkOS** release image
2. Flash to SD card
3. Run `dtb_selector.exe` (Windows) to select your device
4. Select battery driver version (Original or arkos4clone_fix) when prompted
5. Reboot the device

Non-Windows users, see [Manual Configuration](#manual-configuration).

---

## Supported Devices

### YMC

| Device | Logo | Kernel | Config Files | Notes |
|--------|------|--------|--------------|-------|
| A10MINI | `480P` | User Select | `consoles/a10mini/` | Thanks to Mr.Wu |
| A10MINI V4 | `540P` | User Select | `consoles/a10miniv4/` | Thanks to Mr.Wu |

### UDT

| Device | Logo | Kernel | Config Files | Notes |
|--------|------|--------|--------------|-------|
| R36Ultra | `720P` | User Select | `consoles/r36ultra/` | Thanks to Mr.Li |
| R36UltraX | `768P` | User Select | `consoles/r36ultrax/` | Thanks to Mr.Li |

### GUSGU

| Device | Logo | Kernel | Config Files | Notes |
|--------|------|--------|--------------|-------|
| H7 | `768P` | User Select | `consoles/h7/` | Thanks to Mr.Li |

### AISLPC

| Device | Logo | Kernel | Config Files | Notes |
|--------|------|--------|--------------|-------|
| K36S | `480P` | User Select | `consoles/k36s/` | Thanks to Mr.Yin |
| R36T | `480P` | User Select | `consoles/k36s/` | Thanks to Mr.Yin |
| R36T MAX | `720P` | User Select | `consoles/r36tmax/` | Thanks to Mr.Yin |

### Lenovo

| Device | Logo | Kernel | Config Files | Notes |
|--------|------|--------|--------------|-------|
| GO2 | `768P` | User Select | `consoles/h7/` | Thanks to Mr.Li |

### MagicX

| Device | Logo | Kernel | Config Files | Notes |
|--------|------|--------|--------------|-------|
| xu10 | `480P` | User Select | `consoles/xu10/` | |

### Batlexp

| Device | Logo | Kernel | Config Files | Notes |
|--------|------|--------|--------------|-------|
| G350 | `480P` | User Select | `consoles/g350/` | |

### Kinhank

| Device | Logo | Kernel | Config Files | Notes |
|--------|------|--------|--------------|-------|
| K36 (Origin Panel) | `480P` | User Select | `consoles/k36/` | |

### Ambernic

| Device | Logo | Kernel | Config Files | Notes |
|--------|------|--------|--------------|-------|
| RG351MP | `480P` | User Select | `consoles/rg351mp/` | |
| RG351P | `320P` | User Select | `consoles/rg351p/` | |
| RG351V Panel 2 | `480P` | User Select | `consoles/rg351v/` | |
| RG351V Panel 2 | `480P` | User Select | `consoles/rg351v-v2/` | |

### RetroBox

| Device | Logo | Kernel | Config Files | Notes |
|--------|------|--------|--------------|-------|
| P1 | `480P-270` | User Select | `consoles/rp1/` | |

### Powkiddy

| Device | Logo | Kernel | Config Files | Notes |
|--------|------|--------|--------------|-------|
| RGB10 | `320P` | User Select | `consoles/rgb10/` | |
| RGBV10 | `320P` | User Select | `consoles/rgbv10/` | |
| RGB10X | `480P` | User Select | `consoles/rgb10x/` | |
| RGB10MAX1 | `854x480P` | User Select | `consoles/rgb10max1/` | |
| RGB10MAX2 | `854x480P` | User Select | `consoles/rgb10max2/` | |
| RGB20S | `480P` | User Select | `consoles/rgb20s/` | |

### Clone R36s Series

| Device | Logo | Kernel | Config Files | Notes |
|--------|------|--------|--------------|-------|
| Type 1 (With Amplifier) | `480P` | User Select | `consoles/r36pro/` | Thanks to XiFan |
| Type 1 (Without Amplifier) | `480P` | User Select | `consoles/hg36/` | |
| Type 1 (No Amp + Inverted Right Joystick) | `480P` | User Select | `consoles/k36/` | |
| Type 2 (With Amplifier) | `480P` | User Select | `consoles/clone type2 amp/` | Thanks to XiFan |
| Type 2 (Without Amplifier) | `480P` | User Select | `consoles/clone type2/` | Thanks to Mr.Li |
| Type 3 (Panel 1) | `480P` | User Select | `consoles/clone type3 panel1/` | Thanks to LangZi |
| Type 3 (Panel 2) | `480P` | User Select | `consoles/clone type3 panel2/` | |
| Type 4 | `480P` | User Select | `consoles/clone type4/` | |
| Type 5 | `480P` | User Select | `consoles/clone type5/` | |

### GameConsole

| Device | Logo | Kernel | Config Files | Notes |
|--------|------|--------|--------------|-------|
| R36H ProMax | `768P` | User Select | `consoles/r45h/` | Thanks to Mr.Lang |
| R40XX | `768P` | User Select | `consoles/r40xx/` | Thanks to Mr.Lang |
| R40XX ProMax | `768P` | User Select | `consoles/r46h/` | Thanks to Mr.Lang |
| R45H | `768P` | User Select | `consoles/r45h/` | Thanks to Mr.Lang |
| R46H | `768P` | User Select | `consoles/r46h/` | Thanks to Mr.Lang |
| R36sPlus | `720P` | User Select | `consoles/r36splus/` | Thanks to Mr.Lang |
| R33s | `480P` | User Select | `consoles/r33s/` | |
| R36s Panel 0 | `480P` | User Select | `consoles/origin panel0/` |  |
| R36s Panel 1 | `480P` | User Select | `consoles/origin panel1/` | |
| R36s Panel 2 | `480P` | User Select | `consoles/origin panel2/` | |
| R36s Panel 3 | `480P` | User Select | `consoles/origin panel3/` | |
| R36s Panel 4 | `480P` | User Select | `consoles/origin panel4/` | Thanks to 海拉姆电玩 |
| R36s V22 | `480P` | User Select | `consoles/v22 panel4/` | |
| R36s V30 | `480P` | User Select | `consoles/v30 panel4/` | Thanks to 海拉姆电玩 and Mr.Lang |
| R36XX | `480P` | User Select | `consoles/origin panel4/` | Thanks to Mr.Lang |
| R36H | `480P` | User Select | `consoles/r36h/` | Thanks to Mr.Lang |
| O30S | `480P` | User Select | `consoles/r36h/` | |
| R50S | `854x480P` | User Select | `consoles/r50s/` | Thanks to Mr.Lang |
| R50H | `720x1280P` | User Select | `consoles/r50h/` | Thanks to Mr.Lang |

### SoySauce R36s

| Device | Logo | Kernel | Config Files | Notes |
|--------|------|--------|--------------|-------|
| Panel 1 | `480P` | User Select | `consoles/sauce panel1/` | |
| Panel 2 | `480P` | User Select | `consoles/sauce panel2/` | Thanks to QQ:2824907016 |
| Panel 3 | `480P` | User Select | `consoles/sauce panel3/` | |
| Panel 4 | `480P` | User Select | `consoles/sauce panel4/` | |
| Panel 5 | `480P` | User Select | `consoles/sauce panel5/` | No devices modifications, looks like a Soysauce screen-swapped version. |

### Diium / SZDiiER

| Device | Logo | Kernel | Config Files | Notes |
|--------|------|--------|--------------|-------|
| Dr28s | `480P-270` | `User Select` | `consoles/dr28s/` | |
| D007 / D007 Plus | `480P` | User Select | `consoles/d007/` | |

### XiFan

| Device | Logo | Kernel | Config Files | Notes |
|--------|------|--------|--------------|-------|
| Mymini | `480P` | User Select | `consoles/mymini/` | Thanks to XiFan |
| Mini40 | `720P` | User Select | `consoles/mini40/` | Thanks to XiFan |
| R36Max | `720P` | User Select | `consoles/r36max/` | Thanks to XiFan |
| R36Pro | `480P` | User Select | `consoles/r36pro/` | Thanks to XiFan |
| XF35H | `480P` | User Select | `consoles/xf35h/` | Thanks to XiFan |
| RF35H | `480P` | User Select | `consoles/rf35h/` | Thanks to XiFan |
| XF40H | `720P` | User Select | `consoles/xf40h/` | Thanks to XiFan |
| RF40H | `720P` | User Select | `consoles/rf40h/` | Thanks to XiFan |
| DC35V | `480P` | User Select | `consoles/dc35v/` | Thanks to XiFan |
| DC40V | `720P` | User Select | `consoles/dc40v/` | Thanks to XiFan |
| XF40V | `720P` | User Select | `consoles/dc40v/` | Thanks to XiFan |
| XF28 | `480P-1` | User Select | `consoles/xf28/` | Thanks to XiFan |
| R36Max2 | `768P` | User Select | `consoles/r36max2/` | Thanks to XiFan |
| XF45V | `768P` | User Select | `consoles/xf45v/` | Thanks to XiFan |
| DC45V | `768P` | User Select | `consoles/dc45v/` | Thanks to XiFan |
| RF45V | `768P` | User Select | `consoles/rf45v/` | Thanks to XiFan |
| RF55H | `720x1280P-90` | User Select | `consoles/rf55h/` | Thanks to XiFan |

### Other Devices

| Device | Logo | Kernel | Config Files | Notes |
|--------|------|--------|--------------|-------|
| HG36 (HG3506) | `480P` | User Select | `consoles/hg36/` | |
| RX6H | `480P` | User Select | `consoles/rx6h/` | Thanks to Mr.Yin |
| XGB36 (G26) | `480P` | User Select | `consoles/xgb36/` | |
| T16MAX | `720P` | User Select | `consoles/t16max/` | |
| U8 | `480P5-3` | User Select | `consoles/u8/` | Thanks to Mr.Yin |
| U8 V2 | `480P5-3` | User Select | `consoles/u8-v2/` | |
| RG36 | `480P` | User Select | `consoles/rg36/` | |
| R40S | `480P5-3` | User Select | `consoles/r40s/`     | Thanks to Miss.Ding |
| R39S | `480P5-3` | User Select | `consoles/r40s/`     |  |

> **Logo Path:** `consoles/logo/<Logo>/logo.bmp`  
> **Kernel Path:** `consoles/kernel/original/Image` or `consoles/kernel/arkos4clone_fix/Image` (user selects during setup)

---

## Manual Configuration

For non-Windows users:

1. Mount the `BOOT` partition of the SD card
2. Copy `boot.ini` and the two `.dtb` files from `consoles/<device>/` to the root directory
3. Copy the appropriate kernel Image:
   - For Original battery driver: `consoles/kernel/original/Image`
   - For arkos4clone_fix battery driver: `consoles/kernel/arkos4clone_fix/Image`
4. Copy `consoles/logo/<resolution>/logo.bmp` to the root directory
5. Unmount the SD card, insert into device, and reboot

---

## Joystick Axis Remapping

Visit 👉 **https://lcdyk0517.github.io/tools/dtb-tools.html**

Adjust joystick axis mappings (Joymux / amux), battery parameters, and generate new `.dtb` files directly in your browser.

> **Note:** Only DTB files from **(d)ArkOS4Clone** are supported. DTBs from stock systems or other distributions are not compatible.

---

## Technical Implementation

- **Kernel Driver Modifications** — [lcdyk0517/arkos.bsp.4.4](https://github.com/lcdyk0517/arkos.bsp.4.4)
- **DTS Reverse Porting** — Backported from 5.10 kernel to 4.4 kernel, see [AveyondFly/rocknix_dts](https://github.com/AveyondFly/rocknix_dts/tree/main/3326/arkos_4.4_dts)
- **Base System** — Built on [AeolusUX/ArkOS-R3XS](https://github.com/AeolusUX/ArkOS-R3XS)
- **File Manager** — [lcdyk0517/351Files](https://github.com/lcdyk0517/351Files)
- **Ogage Tool** — [lcdyk0517/ogage](https://github.com/lcdyk0517/ogage)
- **Drastic-KK Patch** — [drastic-kk/patch](https://github.com/lcdyk0517/arkos4clone/tree/main/replace_file/drastic-kk/patch)

---

## Battery Driver Selection

When using the `dtb_selector` tool, you will be prompted to select a battery driver version:

- **Original battery driver** — For devices using the original kernel battery driver
- **arkos4clone_fix battery driver** — For devices using the arkos4clone_fix kernel battery driver

The selected version's `Image` file will be copied to the root directory of your SD card.

---

## Known Limitations

- **eMMC installation not yet supported** — Currently only booting from SD card is available

---

## Contributing

If your device is not yet supported by (d)ArkOS4Clone, you can request support via the [DTB Analysis Tool](https://lcdyk0517.github.io/dtbTools.html).

Please provide:
- A photo of the motherboard
- The DTB file from your device
- Your contact information

If you want to help improve compatibility for other unsupported devices, feel free to submit a **PR**!

---

## Support the Project

If you find (d)ArkOS4Clone helpful and want to support future development:

👉 **https://ko-fi.com/lcdyk**

Thank you for your support! 🙏

---

## Acknowledgments

Special thanks to:

- **[christianhaitian](https://github.com/christianhaitian)** — for dArkOS
- **[AeolusUX](https://github.com/AeolusUX)** — for ArkOS-R3XS
- **[PortMaster](https://github.com/PortsMaster)** — for PortMaster
- **[Jason3_Scripte](https://github.com/Jason3x)** — for useful scripts
