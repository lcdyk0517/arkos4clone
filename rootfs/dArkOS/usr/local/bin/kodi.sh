#!/bin/bash
# Kodi 21.3 (GBM) for RK3326: 3562 build, runtime panel rotation via console_detect.
export KODI_HOME=/opt/kodi/share/kodi
export PYTHONHOME=/opt/kodi
export MALLOC_MMAP_THRESHOLD_=131072
export LD_LIBRARY_PATH=/opt/kodi/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
# Mesa libgbm: Mali's own gbm hands out AFBC buffers that RK3326's RGA2 cannot
# blit; Mesa wants linear ones, which RGA2 can read. On the 4.4 kernel the
# libgbm.so.1 in /usr/lib is the Mali blob itself, so prefer the Mesa build.
MESA_GBM=/usr/local/lib/aarch64-linux-gnu/libgbm.so.1
case "$(uname -r)" in
  4.4*)
    [ -f "$MESA_GBM" ] && export LD_PRELOAD="$MESA_GBM"
    ;;
esac
[ -n "${LD_PRELOAD:-}" ] || export LD_PRELOAD=/usr/lib/aarch64-linux-gnu/libgbm.so.1

command -v perfmax >/dev/null 2>&1 && sudo perfmax kodi

# kodi runs as ark; the MPP service node ships root-only, which makes rkmpp
# fail and video fall back to software decoding.
sudo chmod 666 /dev/mpp_service /dev/vpu_service /dev/hevc_service 2>/dev/null

# Keep Kodi from grabbing the volume/power keys
for ev in /dev/input/event0 /dev/input/event2; do
  [ -e "$ev" ] && sudo chown root:root "$ev" 2>/dev/null
done

# Follow the ES language: zh-CN switches Kodi to Simplified Chinese.
KODI_LANG=resource.language.en_gb
if grep -q '<string name="Language" value="zh-CN" />' \
      /home/ark/.emulationstation/es_settings.cfg 2>/dev/null; then
  KODI_LANG=resource.language.zh_cn
fi

if [ ! -d /home/ark/.kodi ]; then
  mkdir -p /home/ark/.kodi
  [ -d /opt/kodi/userdata ] && cp -a /opt/kodi/userdata /home/ark/.kodi/
fi
mkdir -p /home/ark/.kodi/userdata
if [ -f /home/ark/.kodi/userdata/guisettings.xml ]; then
  sed -i -E "s#<setting id=\"locale.language\"[^>]*>[^<]*</setting>#<setting id=\"locale.language\">${KODI_LANG}</setting>#" \
    /home/ark/.kodi/userdata/guisettings.xml
  # Keep the web UI off: enabled with an empty password makes Kodi pop a
  # "web server disabled" dialog on every start.
  sed -i -E "s#<setting id=\"services.webserver\"[^>]*>[^<]*</setting>#<setting id=\"services.webserver\">false</setting>#" \
    /home/ark/.kodi/userdata/guisettings.xml
  sed -i -E "s#<setting id=\"services.webserverpassword\"[^>]*>[^<]*</setting>#<setting id=\"services.webserverpassword\">kodi</setting>#" \
    /home/ark/.kodi/userdata/guisettings.xml
  sed -i -E "s#<setting id=\"services.webserverpassword\"[^>]*/>#<setting id=\"services.webserverpassword\">kodi</setting>#" \
    /home/ark/.kodi/userdata/guisettings.xml
  # Input comes from oga_controls (keyboard events); Kodi's own joystick
  # support would pop the "new controller" wizard and find no controller.
  if grep -q 'id="input.enablejoystick"' /home/ark/.kodi/userdata/guisettings.xml; then
    sed -i -E "s#<setting id=\"input.enablejoystick\"[^>]*>[^<]*</setting>#<setting id=\"input.enablejoystick\">false</setting>#" \
      /home/ark/.kodi/userdata/guisettings.xml
  else
    sed -i "s#</settings>#    <setting id=\"input.enablejoystick\">false</setting>\\n</settings>#" \
      /home/ark/.kodi/userdata/guisettings.xml
  fi
fi

# Map this unit's gamepad to keyboard keys for Kodi's GUI (quitter helper).
param_device="chi"
if [ -e /dev/input/by-path/platform-odroidgo3-joypad-event-joystick ]; then
  param_device="ogs"
elif [ -e /dev/input/by-path/platform-odroidgo2-joypad-event-joystick ]; then
  param_device="oga"
elif [ -e /dev/input/by-path/platform-singleadc-joypad-event-joystick ] || \
     [ -e /dev/input/by-path/platform-fe5b0000.i2c-event ]; then
  param_device="rg552"
fi

cd /opt/kodi
sudo /opt/quitter/oga_controls kodi-gbm $param_device > /tmp/oga_controls.log 2>&1 &

# On the 4.4 kernel mali-select links the 2020 BSP userspace (10.6) while the
# kernel is 11.7: Kodi's EGL then cannot create a context. Retry with the
# g29p1 userspace, which matches the kernel, without touching the system link
# (the stock 4.4 kernel still needs the old one).
run_kodi() {
  ./lib/kodi/kodi-gbm > /tmp/kodi.log 2>&1
  return $?
}

run_kodi
KODI_RC=$?
if [ "$KODI_RC" -ne 0 ] && grep -q "is not of a compatible version" /tmp/kodi.log 2>/dev/null \
   && case "$(uname -r)" in 4.4*) true ;; *) false ;; esac; then
  MALI_DIR=/tmp/kodi-mali-g29p1
  mkdir -p "$MALI_DIR"
  ln -sfn /usr/lib/aarch64-linux-gnu/mali/libmali-bifrost-g31-g29p1.so "$MALI_DIR/libMali.so"
  ln -sfn libMali.so "$MALI_DIR/libEGL.so"
  ln -sfn libMali.so "$MALI_DIR/libEGL.so.1"
  ln -sfn libMali.so "$MALI_DIR/libGLESv2.so"
  ln -sfn libMali.so "$MALI_DIR/libGLESv2.so.2"
  cp -f /tmp/kodi.log /tmp/kodi.first.log
  LD_LIBRARY_PATH="$MALI_DIR:${LD_LIBRARY_PATH}" run_kodi
  KODI_RC=$?
fi

if [ -n "$(pidof oga_controls)" ]; then
  sudo kill -9 $(pidof oga_controls) 2>/dev/null
fi
sudo systemctl restart ogage 2>/dev/null || true

# Kodi needed the power/volume event nodes root-only; ES runs as ark (input
# group) and reopens its controllers when it comes back, so hand the nodes
# back before returning.
for ev in /dev/input/event*; do
  sudo chown root:input "$ev" 2>/dev/null
  sudo chmod 660 "$ev" 2>/dev/null
done
sync

command -v perfnorm >/dev/null 2>&1 && sudo perfnorm
printf "\033c" >> /dev/tty1
exit 0
