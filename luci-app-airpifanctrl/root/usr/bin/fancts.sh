#!/bin/sh

LOCK_FILE="/var/run/airpifanctrl.pid"
PWM_PATH="/sys/devices/platform/pwm-fan/hwmon/hwmon2/pwm1"
SPEED_CONF="/usr/bin/fanspeed.conf"
FAN_MODE="/etc/fanvall"
TEMP_SOURCE="/etc/fanvallv.conf"

if [ -e "$LOCK_FILE" ]; then
    old_pid="$(cat "$LOCK_FILE" 2>/dev/null)"
    if [ -n "$old_pid" ] && kill -0 "$old_pid" >/dev/null 2>&1; then
        echo "airpifanctrl is already running with PID $old_pid."
        exit 1
    fi
    rm -f "$LOCK_FILE"
fi

echo "$$" > "$LOCK_FILE"
trap "rm -f '$LOCK_FILE'; exit" INT TERM EXIT

[ -w /sys/class/thermal/thermal_zone0/mode ] && echo disabled > /sys/class/thermal/thermal_zone0/mode

write_pwm() {
    pwm="$1"
    echo "$pwm" > "$PWM_PATH"
    echo "$pwm" > "$SPEED_CONF"
}

fan_mode="$(cat "$FAN_MODE" 2>/dev/null)"

case "$fan_mode" in
    3)
        write_pwm 255
        exit 0
        ;;
    2)
        write_pwm 192
        exit 0
        ;;
    1)
        write_pwm 128
        exit 0
        ;;
    0)
        write_pwm 64
        exit 0
        ;;
esac

while true; do
    fan_source="$(cat "$TEMP_SOURCE" 2>/dev/null)"
    if [ "$fan_source" = "模块温度" ]; then
        temp="$(sendat 1 'AT^CHIPTEMP?' | grep 'CHIPTEMP' | sed -n '1p' | cut -d, -f9 | sed '/^$/d')"
        if [ -n "$temp" ]; then
            temp=$((temp * 100))
        else
            temp="$(cat /sys/class/thermal/thermal_zone0/temp)"
        fi
    else
        temp="$(cat /sys/class/thermal/thermal_zone0/temp)"
    fi

    if [ "$temp" -le 45000 ]; then
        pwm=0
    elif [ "$temp" -le 50000 ]; then
        pwm=40
    elif [ "$temp" -le 55000 ]; then
        pwm=70
    elif [ "$temp" -le 60000 ]; then
        pwm=100
    elif [ "$temp" -le 65000 ]; then
        pwm=130
    elif [ "$temp" -le 70000 ]; then
        pwm=160
    elif [ "$temp" -le 75000 ]; then
        pwm=190
    elif [ "$temp" -le 80000 ]; then
        pwm=220
    else
        pwm=255
    fi

    write_pwm "$pwm"
    sleep 8
done
