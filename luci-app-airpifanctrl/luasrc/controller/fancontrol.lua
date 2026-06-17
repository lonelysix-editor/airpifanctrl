module("luci.controller.fancontrol", package.seeall)

local http = require "luci.http"

local PWM_PATH = "/sys/devices/platform/pwm-fan/hwmon/hwmon2/pwm1"
local SPEED_CONF = "/usr/bin/fanspeed.conf"
local FAN_MODE = "/etc/fanvall"
local TEMP_SOURCE = "/etc/fanvallv.conf"

local function read_all(path)
    local file = io.open(path, "r")
    if not file then
        return nil
    end

    local content = file:read("*a")
    file:close()
    return content
end

local function write_value(path, value)
    local file = io.open(path, "w")
    if not file then
        return false
    end

    file:write(tostring(value))
    file:write("\n")
    file:close()
    return true
end

local function request_context(rv)
    local p = http.formvalue("p") or ""
    rv["at"] = http.formvalue("set")
    rv["port"] = string.gsub(p, "\"", "~")
end

local function json_response(rv)
    http.prepare_content("application/json")
    http.write_json(rv)
end

local function stop_fancts()
    local handle = io.popen("pgrep -f fancts.sh")
    local pid = handle and handle:read("*a") or ""
    if handle then
        handle:close()
    end

    pid = pid and pid:match("%d+")
    if pid then
        os.execute("kill -9 " .. pid)
    end
end

local function set_pwm(speed)
    local pwm = tonumber(speed)
    if not pwm then
        return false
    end

    pwm = math.floor(pwm)
    if pwm < 0 or pwm > 255 then
        return false
    end

    write_value(PWM_PATH, pwm)
    write_value(SPEED_CONF, pwm)
    return true, pwm
end

local function fixed_speed_action(mode, speed, result)
    local rv = {}
    request_context(rv)
    stop_fancts()
    write_value(FAN_MODE, mode)
    set_pwm(speed)
    rv["result"] = result
    json_response(rv)
end

function index()
    entry({"admin", "status", "fancontrol"}, template("airpifanctrl/fancontrol"), _("风扇控制"), 94)
    entry({"admin", "fancontrol", "fanstop"}, call("action_fanstop"))
    entry({"admin", "fancontrol", "fanst1"}, call("action_fanst1"))
    entry({"admin", "fancontrol", "fanst2"}, call("action_fanst2"))

    -- Allow local button automation to switch fan modes without a LuCI session.
    local e_fanst3 = entry({"admin", "fancontrol", "fanst3"}, call("action_fanst3"))
    e_fanst3.sysauth = false
    e_fanst3.leaf = true

    local e_fanst4 = entry({"admin", "fancontrol", "fanst4"}, call("action_fanst4"))
    e_fanst4.sysauth = false
    e_fanst4.leaf = true

    entry({"admin", "fancontrol", "fansttp"}, call("action_fansttp"))
    entry({"admin", "fancontrol", "fanst"}, call("action_fanst"))
    entry({"admin", "fancontrol", "fansvm"}, call("action_fansvm"))
    entry({"admin", "fancontrol", "fansvc"}, call("action_fansvc"))
    entry({"admin", "fancontrol", "fanswj"}, call("action_fanswj"))
    entry({"admin", "fancontrol", "fanswj2"}, call("action_fanswj2"))

    local e_msg = entry({"admin", "fancontrol", "msg"}, call("action_msg"))
    e_msg.sysauth = false
    e_msg.leaf = true
end

function action_msg()
    local rv = {}
    request_context(rv)

    local filepath = "/tmp/lucimsg.file"
    local content = read_all(filepath)
    if content then
        rv["lucimsg"] = content
        os.remove(filepath)
    end

    json_response(rv)
end

function action_fanswj()
    local rv = {}
    request_context(rv)
    stop_fancts()

    local ok, pwm = set_pwm(http.formvalue("p"))
    if ok then
        write_value(FAN_MODE, 999)
        rv["result"] = "fanswj"
        rv["pwm"] = pwm
    else
        rv["result"] = "invalid_pwm"
    end

    json_response(rv)
end

function action_fanswj2()
    local rv = {}
    request_context(rv)
    stop_fancts()
    write_value(FAN_MODE, 999)
    rv["result"] = read_all(SPEED_CONF) or "无法读取 " .. SPEED_CONF
    json_response(rv)
end

function action_fanst()
    local rv = {}
    rv["fanspd"] = read_all(SPEED_CONF) or "未获取到转速"

    local process_check = io.popen("pgrep -f fancts.sh")
    local process_result = process_check and process_check:read("*a") or ""
    if process_check then
        process_check:close()
    end

    local fanvall_content = read_all(FAN_MODE)
    if fanvall_content and fanvall_content:match("^%s*999%s*$") then
        rv["fancts"] = "无极"
    elseif process_result ~= "" then
        rv["fancts"] = "智能"
    else
        rv["fancts"] = "手动"
    end

    request_context(rv)
    json_response(rv)
end

function action_fansttp()
    local rv = {}
    request_context(rv)

    local fansv = "温度类型获取中..."
    local temperature = 0
    local config = read_all(TEMP_SOURCE)

    if config and config:match("模块温度") then
        fansv = "5G模块温度"
        local sendat_command = io.popen("sendat 1 'AT^CHIPTEMP?' | grep 'CHIPTEMP' | sed -n '1p' | cut -d, -f9 | sed '/^$/d'")
        local temp_output = sendat_command and sendat_command:read("*a") or ""
        if sendat_command then
            sendat_command:close()
        end

        local temp_value = tonumber(temp_output)
        temperature = temp_value and (temp_value / 10) or "null"
    else
        fansv = "CPU温度"
        local file = io.open("/sys/class/thermal/thermal_zone0/temp", "r")
        if file then
            temperature = file:read("*n")
            file:close()
            temperature = temperature and (temperature / 1000) or "null"
        else
            temperature = "null"
        end
    end

    rv["fansttp"] = temperature
    rv["fansv"] = fansv
    json_response(rv)
end

function action_fanst2()
    fixed_speed_action(2, 192, "fanst2")
end

function action_fanst1()
    fixed_speed_action(1, 128, "fanst1")
end

function action_fanst3()
    fixed_speed_action(3, 255, "fanst3")
end

function action_fanst4()
    local rv = {}
    request_context(rv)
    stop_fancts()
    write_value(FAN_MODE, 9)
    os.execute("/usr/bin/fancts.sh &")
    rv["result"] = "fanst4"
    json_response(rv)
end

function action_fanstop()
    fixed_speed_action(0, 64, "fanstop")
end

function action_fansvm()
    local rv = {}
    request_context(rv)
    write_value(FAN_MODE, 9)
    write_value(TEMP_SOURCE, "模块温度")
    rv["result"] = "fansvm"
    json_response(rv)
end

function action_fansvc()
    local rv = {}
    request_context(rv)
    write_value(FAN_MODE, 9)
    write_value(TEMP_SOURCE, "CPU温度")
    rv["result"] = "fansvc"
    json_response(rv)
end
