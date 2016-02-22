-- file : application.lua
local module = {}  
m = nil

--temperatura_objetivo = 20
--temperatura = 25
estado = "off"

local function register_myself()
  for key,topic in pairs(config.SUB) do
    print("Subscribirse a " .. topic)
    m:subscribe(topic, 0, function(conn)
      print("sub ok")
    end)
  end
end

local function mqtt_start()  
    m = mqtt.Client(config.ID, 120, config.USER, config.PASS)
    m:on("message", function(conn, topic, data) 

      -- topic para definir la temperatura del termostato
      if topic == config.SUB.temp_obj then
        -- pulsar botones hasta definir temp objetivo
        temperatura_objetivo = tonumber(data)
      
      -- topic para encender o apagar el termostato
      elseif topic == config.SUB.encender then
        if data == "true" then
            gpio.write(config.PIN_TERMOSTATO_ON, gpio.LOW)
            estado = "on"
        elseif data == "false" then
            gpio.write(config.PIN_TERMOSTATO_ON, gpio.HIGH)
            estado = "off"
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
        tmr.stop(6)

        tmr.alarm(5, 10000, 1, function ()
        
          -- send_status
          m:publish(config.PUB_ESTADO, estado, 0, 0)
          
          -- send_temp
          temp,hum = termo.getTemp(config.PIN_TERMO)
          m:publish(config.PUB_TEMP, temp, 0, 0)
          m:publish(config.PUB_HUM, hum, 0, 0)
          temp = nil
          hum = nil
          --m:publish(config.PUB_TEMP_FICTICIA, temperatura, 0, 0)
          
          -- check_puerta
          if gpio.read(config.PIN_PUERTA) == 0 then
            m:publish(config.PUB_PUERTA, "cerrada", 0, 0)
          else
            m:publish(config.PUB_PUERTA, "abierta", 0, 0)
          end
          
          -- converger_temperaturas
          --if temperatura > temperatura_objetivo then
          --  temperatura = temperatura - 1
          --elseif temperatura < temperatura_objetivo then
          --  temperatura = temperatura + 1
          --end
        end)
    end) 

end

function module.start()  
  mqtt_start()
end

return module  
