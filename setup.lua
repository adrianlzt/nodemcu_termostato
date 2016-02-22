-- file: setup.lua
local module = {}
local led_state = gpio.HIGH

local function toggleLED()
    if led_state == gpio.LOW then
        led_state = gpio.HIGH
    else
        led_state = gpio.LOW
    end

    gpio.write(config.PIN_TERMOSTATO_ON, led_state)
end

local function led_blink(num,freq)
  tmr.alarm(0, freq/2, tmr.ALARM_AUTO, toggleLED)
  tmr.alarm(2, freq*num, tmr.ALARM_SINGLE, function() tmr.stop(0) end)
end

local function wifi_wait_ip()  
  if wifi.sta.getip()== nil then
    print("IP unavailable, Waiting...")
  else
    tmr.stop(2)
    tmr.stop(1)
    print("\n====================================")
    print("ESP8266 mode is: " .. wifi.getmode())
    print("MAC address is: " .. wifi.ap.getmac())
    print("IP is "..wifi.sta.getip())
    print("====================================")
    led_blink(6,150)
    app.start()
  end
end

local function wifi_start(list_aps) 
    wifi.setmode(wifi.STATION);
    key = "grenoble"
    wifi.sta.config(key,config.SSID[key])
    tmr.alarm(1, 2500, 1, wifi_wait_ip)

    -- la mayoria de las veces no encuentro nuestra wifi
    --if list_aps then
    --    for key,value in pairs(list_aps) do
    --        print("wifi con " .. key .. " y " .. value)
    --        if config.SSID and config.SSID[key] then           
    --            wifi.setmode(wifi.STATION);
    --            wifi.sta.config(key,config.SSID[key])
    --            wifi.sta.connect()
    --            print("Connecting to " .. key .. " ...")
    --            --config.SSID = nil  -- can save memory
    --            tmr.alarm(1, 2500, 1, wifi_wait_ip)
    --        end
    --    end
    --else
    --    print("Error getting AP list")
    --end
end

function module.start()
  gpio.mode(config.PIN_TERMOSTATO_ON, gpio.OUTPUT) -- led placa
  gpio.mode(config.PIN_PUERTA, gpio.INPUT) -- sensor hall
  led_blink(50,1000)
  print("Configuring Wifi ...")
  wifi.setmode(wifi.STATION)
  wifi.sta.getap(wifi_start)
end

return module
