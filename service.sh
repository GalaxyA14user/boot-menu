#!/system/bin/sh

# COPYRIGHT 2024 BrotherBoard,
# ALL RIGHTS RESERVED.
# Nobody is allowed to modify or publish this.
# Bug? Feedback? @GalaxyA14user on Telegram!

# Stock filenames
name="bootsamsung"
f1="${name}"
f2="${name}loop"

# Core & frames
home="/data/adb/modules/boot-menu/core-files"
anim="${home}/draw"
dun="${home}/dun"
index="${home}/index"

# Stock backup
cach="/cache/boot-menu"
back="${cach}/backup"
g1="${back}/${f1}"
g2="${back}/${f2}"

# System files
sm="/system/media"
bs="${sm}/${f1}.qmg"
bl="${sm}/${f2}.qmg"

# Signal codes
vup_code="0001 0073 00000001"
vdn_code="0001 0072 00000001"
pwr_code="0001 0074 00000001"

# Other (temp, cords & logs)
dump="/cache/boot-menu/boot-menu.tmp"
disp="${home}/display.so"
logs="${cach}/boot-menu.log"

# Extract screen dimensions
res=$(cat "/sys/class/graphics/fb0/modes")
res2="${res##*:}"
res3="${res2%%p*}"
resx="${res3%%x*}"
resy="${res3##*x}"

# Index
echo "0" > "$dun"
echo "1" > "$index"
count=$(awk 'NF' "$disp" | wc -l)

# Vibrate
vib() {
  echo "$1" > /sys/class/timed_output/vibrator/enable
  log "VIBRATE VALUE=$1"
}

# Change brightness
lit() {
  echo "$1" > /sys/class/backlight/panel/brightness
  log "BRIGHTNESS VALUE=$1"
}

# Restart animation
fresh() {
  stop bootanim; start bootanim
  log "REFRESHED BOOTANIM SERVICE"
}

# Validate index & update frame
vdx() {
  cindex=$(cat "$index")
  [ ! -f "$dump" ] || [ -z "$cindex" ] && return
  log "VALIDATE IN=$cindex"
  [ "$cindex" -gt "$count" ] && echo "1" > "$index"
  [ "$cindex" -lt 1 ] && echo "$count" > "$index"
  cindex=$(cat "$index")
  log "VALIDATE OUT=$cindex"
  cp "${anim}/F${cindex}" "$bl"
  log "COPIED FRAME ${anim}/F${cindex} TO $bl"
  fresh
  vib 70
}

# On volume up
vup() {
  cindex=$(cat "$index")
  echo "$((cindex - 1))" > "index"
  log "VOLUME UP INDEX=$cindex"
  vdx
}

# On volume down
vdn() {
  cindex=$(cat "$index")
  echo "$((cindex + 1))" > "$index"
  log "VOLUME DOWN INDEX=$cindex"
  vdx
}

# On power
pwr() {
  cindex=$(cat "$index")
  log "POWER SELECTED $cindex"
  echo "$cindex" > "$dun"; pew
  [ "$cindex" = 2 ] && su -c "reboot recovery"
  [ "$cindex" = 3 ] && su -c "reboot -p"
#  [ "$cindex" = 4 ] && su -c "reboot download"
#  [ "$cindex" = 5 ] && su -c "reboot fastboot"
}

# Listen for buttons
ear() {
  timeout 2 su -c "getevent -c 1 | grep -Eo \"${vup_code}|${vdn_code}|${pwr_code}\""
}

# Listen for touches
feel() {
  su -c getevent -lc3 /dev/input/event2 |\
  grep -E '_X|_Y' | awk '{print $NF}' |\
  while read -r h; do
    printf "%d " "0x$h"
  done
}

# Parse touch codes
hmm() {
  n=1
  log "|>PARSING ${1}x${2}"
  while IFS=' ' read -r x1 y1 x2 y2
  do
    log "|PARSING $x1 $y1 $x2 $y2"
    [ -z "$y2" ] && log "|SKIPPED" && continue
    log "|$1 GT $x1"
    log "|$2 GT $y1"
    log "|$1 LT $x2"
    log "|$2 LT $y2"
    [ "$1" -gt "$x1" ] &&\
    [ "$2" -gt "$y1" ] &&\
    [ "$1" -lt "$x2" ] &&\
    [ "$2" -lt "$y2" ] &&\
    echo "$n" && break
    n=$((n + 1))
  done < "$disp" || log "|ERROR READING $disp"
}

# Clean up
pew() {
  rm -rf "$dump"
  log "REMOVED TEMP FILE $dump"
  cp -f "${g1}.qmg" "$bs"
  log "COPIED STOCK ${g1}.qmg TO $bs"
  cp -f "${g2}.qmg" "$bl"
  log "COPIED STOCK ${g2}.qmg TO $bs"
  fresh
}

# Logging
log() {
  echo "$@" >> "$logs"
}

# Start logging
rm -rf "$logs"
log ">LOGGING STARTED"
log "EXTRACT ($res -> $res2 -> $res3)"
log "RESOLUTION=${resx}x${resy}"

# Add frames
su -c "mount -o rw,remount /"
cp "${anim}/SP" "$bs"
log "COPIED ${anim}/SP TO ${bs}"
cp "${anim}/F1" "$bl"
log "COPIED ${anim}/F1 TO ${bl}"

# Preview frames
fresh

# Delay placeholder
sleep 1
cp "${anim}/F0" "$bs"
log "COPIED NEW PLACEHOLDER ${anim}/F0 TO $bs"

# Spy on hardware
touch "$dump"
log "CREATED TEMP FILE $dump"
while [ -f "/cache/boot-menu/boot-menu.tmp" ]; do
  o=$(ear)
  [ "$o" = "$vup_code" ] && vup
  [ "$o" = "$vdn_code" ] && vdn
  [ "$o" = "$pwr_code" ] && pwr
done &
while [ -f "/cache/boot-menu/boot-menu.tmp" ]; do
  cindex=$(cat "$index")
  c=$(feel)
  c=$(echo "$c" | xargs)
  x="${c%% *}"
  y="${c##* }"
  log "TOUCH AT ${x}x${y}"
  [ -z "$y" ] && continue
  xc="$((x * 1000 / resx))"
  yc="$((y * 1000 / resy))"
  log "TRANSLATED TO ${xc}x${yc}"
  at=$(hmm "$xc" "$yc")
  log "|PARSED TO $at"
  [ ! -z "$at" ] && {
    [ "$at" = "$cindex" ] && pwr && break
    echo "$at" > "$index"
    vdx
  }
done &

# Clean up on timeout
sleep 10
log "TIMEOUT"
[ $(cat "$dun") = 0 ] && {
  pew
  log "DEFAULT APPLIED"
  vib 350
}

# Failsafe
sleep 5
stop bootanim
log "APPLIED FAILSAFE"
