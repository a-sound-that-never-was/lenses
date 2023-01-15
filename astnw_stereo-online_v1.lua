
data = {
	humidity = 		DataType{ path = "astnw/weather/outHumidity", unit = "°C", nom_fr = "humidité", nom_en = "humidity", min=0, max=100 },
	temp = 				DataType{ path = "astnw/weather/outTemp_C", unit = "°C", nom_fr = "température", nom_en = "temperature", min=-30, max=30 },
	pressure = 		DataType{ path = "astnw/weather/pressure_mbar", unit = "mBar", nom_fr = "pression atmosphérique", nom_en = "Atmospheric pressure", min=1000, max=1040},
	time = 				DataType{ path = "astnw/weather/dateTime", unit = "epoch", nom_fr = "temps", nom_en = "time", min= 1663908300, max=1663908300+31000000},
--	rain = 			DataType{ path = "astnw/weather/rain_cm", unit = "cm", nom_fr = "debit pluie", nom_en = "rain rate", min=0, max=10},
	windspeed = 	DataType{ path = "astnw/weather/windSpeed_kph", unit = "km/h", nom_fr = "vitesse vent", nom_en = "wind speed", min=0, max=10 },
	winddirection= 	DataType{ path = "astnw/weather/windGustDir", unit = "°", nom_fr = "direction vent", nom_en = "wind direction", min=0, max=360 },
	radiation = 		DataType{ path = "astnw/weather/radiation_Wpm2", unit = "W/m²", nom_fr = "radiation", nom_en = "radiation" , min=0, max=15 },
--	transpiration = DataType{ path = "astnw/weather/ET_cm", unit = "cm", nom_fr = "évapotranspiration", nom_en = "evapotranspiration", min=0, max=10 },
	shake = 		DataType{ path = "astnw/shake/shake", unit = "m/s²", nom_fr = "tectonique", nom_en = "tectonic", min=0, max=1 },
	rumble = 		DataType{ path = "astnw/shake/rumble", unit = "m/s²", nom_fr = "vibration", nom_en = "vibration", min=0, max=1 },
	silence = 		DataType{ path = "astnw/formal/silence", unit = "s", nom_fr = "silence", nom_en = "silence", min=0, max=9999 },
	poly = 			DataType{ path = "astnw/formal/poly", unit = "#", nom_fr = "polyphonie", nom_en = "polyphony", min=0, max=9999}
}

Lenses({
	{ 
		nom = "daylight",
		selector = function(sound) return sound:duration() > 60 and sound.desc.start.morphology.iterative > 0 and sound.desc.start.type.shimmer > 0 end,
		mixing = function(self)  self:set_db(scale(data.radiation:value(), 0, 15, -40, 0)) end,
		routine = function(self) 
			while true do
				if (data.radiation:value() > 0) then 
					spawn_lens(self) -- coordinator will prevent double-spawn
					self:wait{timeout = self:duration()+10} -- a constant layer with 10s gap between sounds
				end
				if (data.radiation:value() <= 0.01) then yield_lens(self) end
				coroutine.yield(1)
			end
		end,
	}, { 
		nom = "nightlight",
		selector = function(sound) return sound:duration() > 60 and sound.desc.start.morphology.continuous > 0 or sound.desc.start.type.buzz > 0 end,
		mixing = function(self)  self:set_db(scale(data.radiation:value(), 15, 0, -40, 0)) end,
		routine = function(self) 
			while true do
				if (data.radiation:value() < 15.0) then 
					spawn_lens(self) -- coordinator will prevent double-spawn
					self:wait{timeout = self:duration()+10} -- 10s gap before next
				end
				if (data.radiation:value() >= 15.0) then yield_lens(self) end
				coroutine.yield(1)
			end
		end,
	}, { 
		nom = "temperature rising",
		selector = function(sound) return sound.desc.start.morphology.continuous > 0 and sound.desc.start.type.glide > 0 end,
		spawn_interval = 25000,
		db = -6,
		data = data.temp
	}, { 
		nom = "temperature falling",
		selector = function(sound) return sound.desc.start.morphology.iterative > 0 and sound.desc.start.type.echo > 0 end,
		spawn_interval = 25000,
		db = -6,
		data = data.temp
	}, { 
		nom = "pressure rising",
		selector = function(sound) return sound.desc.start.signal.voices > 0 and sound.desc.start.domain.nature > 0 end,
		spawn_interval = 15000,
		data = data.pressure
	}, { 
		nom = "pressure falling",
		selector = function(sound) return sound.desc.start.signal.notvoices > 0 and sound.desc.start.domain.nature > 0 end,
		spawn_interval = 15000,
		data = data.pressure
	}, { 
		nom = "rumble",
		data = data.shake,
		selector = function(sound) return sound.desc.start.type.echo > 0 and sound.desc.start.operation.texture > 0 and sound.desc.start.domain.humanmade > 0 end,
		mixing = function(self)  self:set_db(scale(data.shake.lowpass, 0.02, .05, -10, 0)) end,
		routine = function(self) -- every second
			while true do
				if (data.shake.lowpass > 0.05) then 
					spawn_lens(self) -- coordinator will prevent double-spawn
					self:wait{timeout = self:duration()+10} -- 10s gap before next (will play as long as rumble > thresh)
				end
				coroutine.yield(1)
			end
		end,
	}, { 
		nom = "random east",
		selector = function(sound) return sound.desc.start.type.glide > 0 and sound.desc.start.signal.integral > 0 end,
		spawn_interval = 30000,
		data = data.windspeed,
		db = -10
	}, { 
		nom = "random west",
		selector = function(sound) return sound.desc.start.type.shimmer > 0 and sound.desc.start.signal.integral > 0 end,
		spawn_interval = 30000,
		data = data.windspeed,
		db = -10
	}, { 
		nom = "random north",
		selector = function(sound) return sound.desc.start.type.buzz > 0 and sound.desc.start.signal.fragmented > 0 end,
		spawn_interval = 30000,
		data = data.windspeed,
		db = -10
	}, { 
		nom = "random south",
		selector = function(sound) return sound.desc.start.type.echo > 0 and sound.desc.start.signal.fragmented > 0 end,
		spawn_interval = 30000,
		data = data.windspeed,
		db = -10
	}, { 
		nom = "dew point",
		selector = function(sound) return sound.desc.start.domain.abstract > 0 and sound.desc.start.signal.integral > 0 end,
		db = 0,
		spawn_interval = 60000,
		data=data.temp
	}, { 
		nom = "freezing point",
		selector = function(sound) return sound.desc.start.domain.concrete > 0 and sound.desc.start.signal.fragmented > 0 end,
		db = -20,
		spawn_interval = 60000,
		data = data.temp
	}, { 
		nom = "shocks",
		selector = function(sound) return sound.desc.start.operation.interruptor > 0 and sound.desc.start.domain.humanmade > 0 end,
		db = 0, -- full on 
		data=data.shake,
		routine = function(self) -- every second
			while true do
				if (data.shake.lowpass > 0.10) then 
					spawn_lens(self) 
					self:wait{timeout = self:duration()+10} -- 10s gap before next
				end
				coroutine.yield(1)
			end
		end,
	}, { 
		nom = "gust",
		selector = function(sound) return sound.desc.start.operation.event > 0 and sound.desc.start.morphology.unpredictable > 0 end,
		db = -20,
		spawn_interval = 60000,
		data = data.windspeed
	}, { 
		nom = "interrupt",
		selector = function(sound) return sound.desc.start.operation.interruptor > 0 and sound:duration() < 15 end,
		db = 0,
		data=data.poly,
		routine = function (self)
			while true do
				if (#longuish >= 3) then
					spawn_lens(self)
					yield_lens(choose(longuish))
					self:wait{timeout = self:duration()+10}
				end
				coroutine.yield(1)
			end
		end
	}, { 
		nom = "spawn",
		selector = function(sound) return sound.desc.start.operation.mesher > 0 and sound.desc.start.signal.integral > 0 end,
		db = -20,
		data = data.silence,
		routine = function (self)
			while true do
				if data.silence:value() > 10 then
					spawn_lens(self)
					self:wait{timeout = self:duration()+10}
				end
				coroutine.yield(1)
			end
		end
	}, { 
		nom = "random midnight",
		selector = function(sound) return sound.desc.start.type.echo == 0 and sound.desc.start.operation.interruptor == 0 and sound.desc.start.domain.humanmade == 0 end,
		db = -12,
		spawn_interval = 60000,
		data = data.windspeed
	}, { 
		nom = "random noon",
		selector = function(sound) return sound.desc.start.type.echo == 0 and sound.desc.start.operation.interruptor == 0 and sound.desc.start.domain.humanmade == 0 end,
		db = -12,
		spawn_interval = 60000,
		data = data.windspeed
	}
})

mqtt_data = {}

data_of_interest = {
	["astnw/weather/outHumidity"] = {
		name = { fr = "humidité", en = "humidity" },
		min = 0, max = 100, unit = "%", last_emit=0
	},
	["astnw/weather/outTemp_C"] = {
		name = { fr = "température air", en = "air temperature" },
		min = 5, max = 20, unit = "ºC", last_emit=0
	},
	["astnw/weather/pressure_mbar"] = {
		name = { fr = "pression atmosphérique", en = "Atmospheric pressure" },
		min = 1000, max = 1040, unit = "mBar", last_emit=0
	},
	["astnw/weather/dateTime"] = {
		name = { fr = "point de temps", en = "timestamp" },
		min = 1663908300, max = 1663908300+31000000, unit = "unix epoch", last_emit=0
	},
	["astnw/weather/rain_cm"] = {
		name = { fr = "débit de pluie", en = "rain rate" },
		min = 0, max = 10, unit = "cm", last_emit=0
	},
	["astnw/weather/radiation_Wpm2"] = {
		name = { fr = "radiation", en = "radiation" },
		min = 0, max = 10, unit = "W/m²", last_emit=0
	},
	["astnw/weather/sunset"] = {
		name = { fr = "coucher du soleil", en = "sunset" },
		min = 1663908300-(3600*24), max = 1663908300+31000000, unit = "unix epoch", last_emit=0
	},
	["astnw/weather/sunrise"] = {
		name = { fr = "lever du soleil", en = "sunrise" },
		min = 1663908300-(3600*24), max = 1663908300+31000000, unit = "unix epoch", last_emit=0
	},
	["astnw/weather/control"] = {
		name = { fr = "controle", en = "controle" },
		min = 0, max = 1, unit = "float", last_emit=0
	},
	["astnw/weather/ET_cm"] = {
		name = { fr = "évapotranspiration", en = "evapotranspiration" },
		min = 0, max = 10, unit = "cm", last_emit=0
	}
}

config = {
	csound_osc = {
		host = "192.168.101.168",
		port = 1984
	},
	mqtt = {
		host = "mqtt.artificiel.org",
		port = 1883,
		client_id = "openframeworks",
		user = "astnw",
		password = "neverwas"
	}
}

randomize = function () 
	print ("OK", math.random())
	set_data("astnw/weather/control", math.random())
end

function set_data(t, v) 
	if data_of_interest[t] ~= nil then
		local d = data_of_interest[t]

		d.normalized = (v-d.min)/(d.max-d.min)
		d.raw = v
		mqtt_data[t]=(v-d.min)/(d.max-d.min)
		-- print("lua: setting ".. t .. " to " .. v .. " = " .. mqtt_data[t])
		return true
	end
	return false
end

longuish = 0
function update ()
	longuish = active_lenses_since(90)
	data.poly:set(#longuish)

	return 1
end

print ("lua parsed correctly" )

-- print ("integral", containers["sound1"].desc.signal.integral)
-- print (containers["sound1"].desc.operation.event)
-- print (containers["sound1"].desc.type.integral)
-- print (lenses["dark drone"].nom)


-- FUNCTIONAL
-- for k,v in ipairs(get_containers()) do
-- 	print ("desc.start.signal.integral", v.desc.start.signal.integral)
-- end

function filter_sounds(selector)
	print("filtering", selector)
	print("sounds", #get_containers())
	local a = filter(selector,  get_containers())
	local b = filter(function(sound) return #sound:get_sounds() > 0 end, a)
	return shuffle(totable(b))
end
