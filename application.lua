-- file : application.lua
local module = {}  
m = nil
temperatura_objetivo = 20
temperatura = 25
estado = "off"
encender = "on"

-- Sends a simple ping to the broker
local function send_ping()
  m:publish(config.PING, "id=" .. config.ID,0,0)
end

local function register_myself()
  for key,topic in pairs(config.SUB) do
    print("Subscribirse a " .. topic)
    m:subscribe(topic, 0, function(conn)
      print("sub ok")
    end)
  end
end

-- funcion para definir correctamente la temperatura objetivo del termostato
local function define_temp(t)
  -- vamos a la temperatura maxima
  -- pulsamos suficientes veces hasta llegar a la temp maxima
  --for i = 1, 5 do
  --  print("subo temperatura objetivo " .. i)
  --end

  --for i = 1, config.TERMOSTATO_TEMP_MAX-t do
  --  print("bajo temperatura objetivo " .. i)
  --end

  temperatura_objetivo = t
end

local function send_temp()
  --print("send_temp: " .. temperatura)
  m:publish(config.PUB_TEMP, temperatura, 0, 0)
end

local function send_status()
  --print("send_status: " .. estado)
  m:publish(config.PUB_ESTADO, estado, 0, 0)
end

local function termostato_on()
  print("termostato_on")
  gpio.write(config.PIN_TERMOSTATO_ON, gpio.LOW)
  estado = "on"
end

local function termostato_off()
  print("termostato_off")
  gpio.write(config.PIN_TERMOSTATO_ON, gpio.HIGH)
  estado = "off"
end

local function converger_temperaturas()
  if temperatura > temperatura_objetivo then
    temperatura = temperatura - 1
  elseif temperatura < temperatura_objetivo then
    temperatura = temperatura + 1
  end
end

local function mqtt_start()  
    m = mqtt.Client(config.ID, 120, config.USER, config.PASS)

    -- register message callback beforehand
    m:on("message", function(conn, topic, data) 

      -- topic para definir la temperatura del termostato
      if topic == config.SUB.temp_obj then
        temperatura_objetivo = tonumber(data)
        -- pulsar botones hasta definir temp objetivo
        define_temp(temperatura_objetivo)
      
      -- topic para encender o apagar el termostato
      elseif topic == config.SUB.encender then
        if data == "true" then
          termostato_on()
        elseif data == "false" then
          termostato_off()
        else
          print("Topic encender con valor raro: " .. data)
        end
      else
        print("Topic desconocido: " .. topic)
      end
    end)

    -- Connect to broker
    m:connect(config.HOST, config.PORT, 0, 1, function(con) 
        register_myself()
        
        -- And then pings each 1000 milliseconds
        tmr.stop(6)
        tmr.alarm(6, 5000, 1, send_ping)

        -- reporta cada segundo la temperatura y el estado
        tmr.alarm(5, 3000, 1, send_temp)
        tmr.alarm(4, 3000, 1, send_status)
        tmr.alarm(3, 2000, 1, converger_temperaturas)
    end) 

end

function module.start()  
  mqtt_start()
end

return module  
