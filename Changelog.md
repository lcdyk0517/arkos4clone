# ArkOS4Clone 20260915

## 1. New Features

1. Added RTL8723DU Wi-Fi driver
2. Added DSperate NDS standalone emulator

## 2. Adjustments

1. Added adjustment of volume ADC values in ES for compatibility with more clone devices
2. Clone configuration name adjustments
   2.1 Type 3 Panel 1 -> Type 1 Panel 2
   2.2 Type 3 Panel 2 -> Type 1 Panel 3
   2.3 Type 3 Panel 3 -> Type 1 Panel 4
   2.4 Type 5 -> Type 1 Panel 5
   2.5 Added Type 1 Panel 6 and Type 2 Panel 2
3. Clone device command Type is now distinguished by the GPIO multiplexed with the joystick ADC
4. Adjusted SD card game switching: changed from a script to switching within ES

## 3. Bug Fixes

1. Fixed the crash bug in EASYRPG
2. Fixed the crash bugs in N64's Glide64mk2 and GlideN64


# ArkOS4Clone 20260905

## 1. New Features
1. Added support for CoolBoy RS16

## 2. Adjustments

1. Updated PPSSPP to the Gold version (no functional changes)
2. Fixed the issue where the R36Max selector could not select correctly
3. Added search functionality to DTB_SELECT
4. Allowed users to dynamically switch refresh rates within the ES interface (except for the default refresh rate, other refresh rates cannot be guaranteed to work properly on all screens; please do not persist them before ensuring compatibility with your device)
5. Updated the Flycast standalone emulator to V2.7 and completed Chinese i18n support
6. Updated ES to allow users to individually adjust CPU, GPU, and DMC frequencies within the corresponding emulator interface (thanks to user kx230 for the suggestion)
7. Former Clone R36S Type4 changed to Clone R36S Type 3 Panel 3
8. Former Game Console R36S Panel 4 changed to Game Console R36S Panel 4 Type 1
9. Former Game Console R36S V22 changed to Game Console R36S Panel 4 Type 2
10. Removed Game Console R36S V30; motherboard numbering is no longer used.

## 3. Bug Fixes

1. Fixed the bug where the arkos4clone battery driver caused interference noise from the speaker after full charge. In this version, the registers used by the battery driver have been aligned with the original driver, and aging information is stored in /var/lib. Thanks to user kx230 for testing.
2. Fixed the bug where V22 users' OTG enable port was occupied by vibration, causing OTG to be unusable.
3. Fixed the bug on XU10 devices where there was no sound when headphones were not plugged in, and the speaker produced sound after headphones were plugged in.
4. Fixed the bug where RP1 device joysticks were reversed.
5. Fixed the bug where the R36TMax device's charging power indicator did not light up when charging in the powered-off state.

## 4. Final Notes

Originally planned to release after testing all devices, but it was too tiring. After testing about 50+ devices, I gave up. Users please test on your own. If some devices have incorrect joystick values, unusable OTG ports (only handling the issue of external RTL8188 Wi-Fi being unusable), unusable built-in Wi-Fi, no sound output, or headphone jack not working correctly, please submit an issue.


# ArkOS4Clone 20260825

## 1. New Features

1. Added a new R36Max variant. For the original R36Max, please select R36Max Type1; for the original R36Max no amp, please select R36Max Type2.
2. Added support for RG36PRO, allowing control of the joystick LED.

## 2. Adjustments

1. Updated DuckStation; the current version can automatically handle rotation
2. Added deadzone adjustment to the ES menu, allowing users to adjust the deadzone themselves
3. Added support for battery plus in the ES menu; the project comes from Mikhailzrick/knubat.components
4. Added support for Gamma in the ES menu; the source files are in the corresponding directory and support individual adjustment of RGB channels
5. Recompiled PPSSPP, PPSSPP2021, MUPEN64PLUS, and FAKE08 standalone emulators to the latest versions
6. Fixed PortMaster-Gui; it can now correctly enter PortMaster Gui
7. Improved the arkos4clone battery driver to make it more accurate.
8. Fixed the OCV for GameConsole and YMC.

## 3. Bug Fixes

1. Fixed the resolution error issue in mediaplayer, mvem, and mupen64plus on some devices
2. Fixed the crash bug in drastic-kk on some devices (for NDS, please switch to this emulator).

## 4. Final Notes

1. All devices with built-in Wi-Fi in this project can use Wi-Fi normally
2. All devices without Wi-Fi in this project can use external RTL8188EU normally
3. Some users have reported being unable to use external keyboards and mice. Since I only have 2.4G keyboards and mice on hand, I will test after purchasing online.

## FAQ

1. Black screen after displaying logo
   1.1 If the logo displays normally, it means the DTB screen selection is correct. Please replace the SD card and test again.
   1.2 If the backlight does not turn on even after the logo is displayed, please long-press the power button or remove the battery, connect the charger, and then power on again.
2. No logo displayed, directly black screen
   1.1 Please use the DTB selector to select the corresponding device.
3. I only know it is an R36S and I lost the original DTB. What should I do?
   The most primitive method: test one by one among the three options Soy sauce | Clone R36S | GameConsole, looking for R36S. After testing one, you need to long-press to power off or reinsert the battery before testing the next one, until the logo displays. However, this only indicates screen parameter compatibility. If the original DTB is lost, the original screen initialization parameters cannot be fully obtained. (Note: For R36S devices that become incompatible after losing the original DTB, please do not submit Issues. Thank you.)


# ArkOS4Clone 20260815

## 1. New Features

1. Added support for RGB1O, RGBV1O, RGB10X, RGB10MAX2, RG351MP, RG351P, RG351V, RF45H, and RF55H

## 2. Adjustments
1. Updated the ScummVM standalone emulator to version 2026.3.0
2. No longer forward adckey in user space, allowing the odroidgo3 driver to support ADC channel buttons
3. Added joystick drift calibration in the ES menu.
4. Added a new feature for some devices without a right joystick: hold the custom hotkey + left joystick to fully simulate the right joystick and R3
   Devices supporting right joystick simulation: K36S, R36T, Mini40, MyMini, RG351V, RGB10X, RGB10, RP1, XF28, XGB36
   For K36S, R36T, RG351V, XF28, and XGB36, the default mapping key is FN, and users can remap it in ES.
   For RGB10 and RP1, - is L3 and + is FN, and + is set as the right joystick mapping key, meaning holding + and moving the left joystick simulates the right joystick, and holding + and - simulates R3.
   For RGB10X, - is FN and + is FN2, and + is set as the right joystick mapping key, meaning holding + and moving the left joystick simulates the right joystick.
   The right joystick simulation keys for the above devices can all be redefined in ES.
   For RG351V, the default right joystick mapping key is FN, and remapping in ES is temporarily not supported (will modify the driver later when there is time)

## 3. Bug Fixes

1. Fixed the bug where R50S WIFI became unavailable due to a previous update
2. Fixed the crash bug in the easyrpg core
3. Fixed the crash bug caused by an N64 spelling error
4. Fixed the bug where the drastic-kk emulator had a black screen at some resolutions due to missing json
5. Fixed the bug where the Flycast emulator could not handle automatic rotation
6. Fixed the bug where some menus were missing at low resolutions in three versions of YabaSanshiro



# ArkOS4Clone 20260805

## 1. New Features

1. Added support for say souce panel 5
2. Added support for Lenovo Go2 and GUSGU H7 devices

## 2. Adjustments

1. Updated the easyrpg core to v0.8.1.1
2. Updated the parallel_n64_libretro 32-bit core, greatly improving performance
3. Updated the PPSSPP configuration file, fixing the default Chinese language and improving efficiency
4. Updated the retrorun emulator
5. Updated a series of snex9x emulator versions
6. Fixed the bug where R50H WiFi was unavailable
7. Fixed the bug in the R36ultraX joystick channel
8. Fixed the bug where freej2mesa displayed a relatively small area on non-480P devices
9. Fixed the bug where the arkos4clone battery driver did not update numbers in a timely manner in the screen-off state
10. Fixed the bug where the GPU driver would still overclock to 600MHz after running games when set to a non-600MHz value. This bug caused devices to become laggy after running large games. It is fixed after the update.
11. Adjusted ES so that users can now choose whether to display the Wi-Fi and Bluetooth icons at startup in ES

## 3. New Emulators
1. Added support for the spmp8000 emulator
   Project: https://github.com/jiangxincode/SPMP8000Emu
2. Added OpenBORLns
   Project: https://github.com/AveyondFly/openbor-fflns
3. Added the KrKr2 emulator
   Project: https://github.com/AveyondFly/KrKr2-Next
4. Added the retrorun-sdl emulator


# ArkOS4Clone 20260709

## 1. New Features

1. Added support for more devices.
   - Supported list as follows
   - YMC[A10mini,A10miniV4]
   - UDT[R36Ultra,R36UltraX]
   - AISLPC[K36S,R36T,R36TMax]
   - MagicX[xu10]
   - Batlexp[G350]
   - Kinhank[K36]
   - RetroBox[P1]
   - Powkiddy[rgb10,rgb10max1,rgb20s]
   - Clone R36s[type1,type2,type3,type4,type5]
   - SoySauce R36s[panel1,panel2,panel3,panel4]
   - Diium[dr28s,d007(plus)]
   - GameConsole[R36S(panel0,1,2,3,4,v21,v22,v30),r33s,r36xx,o30s,r46h,r40xxpromax,r40xx,r45h,r36hpromax,r50s,r50h]
   - XiFan[Mymini,Mini40,R36Max,R36Pro,XF35H,RF35H,XF40H,RF40H,DC35V,XF40V,DC40V,XF28,R36MAX2,XF45V,DC45V,RF45V]
   - Other[HG36,RX6H,XGB36,T16MAX,U8,RG36,R40S,R39S]
2. Retain the original DTB. You can visit https://r36s.dpdns.org/dtbTools.html to detect and confirm your device type.
3. Please connect the charger when powering on. If it is an original machine, please ensure the battery voltage is not lower than 3.3V before powering on, otherwise it may fail to boot.
4. Added the ArkOS4Clone battery driver. Compared with the original driver, battery level display is more accurate during charging and the discharge curve is smoother.
5. Added overclocking support (for user testing only).
6. Adjusted U-Boot; `uboot.dtb` is no longer required, and the issue where connecting the charger in the powered-off state automatically powers on the device has been fixed.
7. Removed most useless services, including `batt_led.service`, now controlled by the driver layer.
8. Added RK915 and AIC8800DC Wi-Fi driver support, and fixed the random MAC address issue on RK915.
9. Use `console-detect` for device detection. Please do not modify the DTB name.

## 2. Adjustments

### 2.1 EmulationStation (ES)

- Moved emulator settings to each emulator interface; press **Select** to enter settings.
- Removed the original ES Select screensaver feature and changed it to display the time.
- Added the ES ArkOS4Clone menu.
- Added ZRAM support, which can be set to apply automatically at startup.

### 2.2 RetroArch

- Automatically rotates the screen according to the device.
- Updated to **1.2.22**.

### 2.3 Retrorun

- Automatically rotates according to the device.
- Key mapping is consistent with RG351MP.

### 2.4 PPSSPP

- Updated to **1.20.4**.

### 2.5 ScummVM

- Updated to **2026.2.0**.

### 2.6 FlycastSA

- Updated to **v2.6**.
- Supports automatic detection of Chinese and English menus.

## 3. Added Emulator Features

### 3.1 OGAGE Global Hotkeys

- Devices with an FN key: FN
- Devices without an FN key: Select

### 3.2 Other Updates

1. Updated some cores.
2. Added FBNeoPlus (IPS support)  
   Project: https://github.com/lrf739146825/FBNeo
3. Added a gpSP core supporting EZODE vibration and MGBA cheat codes  
   Project: https://github.com/lcdyk0517/gpsp-mod
4. Updated PS core Chinese cheat codes  
   Project: https://github.com/lcdyk0517/pcsx_rearmed_mod
5. Added the ONS standalone emulator.
6. Added the drastic-kk emulator.
   - Configuration file: `/opt/drastic-kk/resources/bg/{resolution}/layout.json`
   - Hotkeys:
     - Select + Y: OSD small menu
     - Select + B: Switch overlay
     - Select + X: Large menu
   - Uses drastic by default; can switch to drastic-kk in the Select menu.
7. Added the freej2me-sa emulator.
   - Project: https://github.com/lcdyk0517/freej2mesa
   - Hotkey: Select + X to open OSD.
   - Game path: /roms(2)/j2me/{resolution}/xxx.jar
   - Resolution value format: 240x320|320x240|480x640. The game will automatically apply the resolution at runtime.
8. Added flycastsa-2022 (functions identical to v2.6).
9. Added GameTank-SA and GameTank Core support.
10. Added CPyMO (PyMO) support.  
    Project: https://github.com/Strrationalism/CPyMO
11. Adjusted freej2me to support Chinese ROMs and automatically read resolution. The logic is consistent with freej2me-sa.
12. Added Native32 support.  
    Project: https://github.com/jiangxincode/Native32Emu
13. Added BBK game support.  
    Project: https://github.com/jiangxincode/BBKEmu
14. Added Flash game support.  
    Project: https://github.com/aweigit/ruffle-miyooflip

#### Flash Default Keys

| Gamepad | Keyboard |
|---------|----------|
| A | A |
| B | S |
| X | U |
| Y | J |
| D-Pad | ↑↓←→ |
| L1 | A |
| R1 | D |
| L2 | W |
| R2 | S |
| L3 | O |
| R3 | L |
| Start | I |
| Select | K |

#### Flash Hotkeys

- Select + X: Mouse mode (Y = mouse down)
- Select + A: WASD mode
- Select + Start: Exit emulator

15. Added flycastsa-r7 (higher efficiency, slightly lower accuracy).
16. Added yabasanshiro, yabasanshiro-pi4, and yabasanshiro-1.11.
    - Supports automatic detection of Chinese and English menus.
    - Fixed the issue where menus were not centered.