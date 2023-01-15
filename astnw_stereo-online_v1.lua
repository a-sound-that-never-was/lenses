
data = {
	humidity = 		DataType{ path = "astnw/weather/outHumidity", 	unit = "°C", nom_fr = "humidité", nom_en = "humidity", min=0, max=100 },
	temp = 			DataType{ path = "astnw/weather/outTemp_C", 	unit = "°C", nom_fr = "température", nom_en = "temperature", min=-30, max=30 },
	pressure = 		DataType{ path = "astnw/weather/pressure_mbar", unit = "mBar", nom_fr = "pression atmosphérique", nom_en = "Atmospheric pressure", min=1000, max=1040},
	time = 			DataType{ path = "astnw/weather/dateTime", 	unit = "epoch", nom_fr = "temps", nom_en = "time", min= 1663908300, max=1663908300+31000000},
--	rain = 			DataType{ path = "astnw/weather/rain_cm", 	unit = "cm", nom_fr = "debit pluie", nom_en = "rain rate", min=0, max=10},
	windspeed = 		DataType{ path = "astnw/weather/windSpeed_kph", unit = "km/h", nom_fr = "vitesse vent", nom_en = "wind speed", min=0, max=10 },
	winddirection= 		DataType{ path = "astnw/weather/windGustDir", 	unit = "°", nom_fr = "direction vent", nom_en = "wind direction", min=0, max=360 },
	radiation = 		DataType{ path = "astnw/weather/radiation_Wpm2", unit = "W/m²", nom_fr = "radiation", nom_en = "radiation" , min=0, max=15 },
--	transpiration = 	DataType{ path = "astnw/weather/ET_cm", 	unit = "cm", nom_fr = "évapotranspiration", nom_en = "evapotranspiration", min=0, max=10 },
	shake = 		DataType{ path = "astnw/shake/shake",	 	unit = "m/s²", nom_fr = "tectonique", nom_en = "tectonic", min=0, max=1 },
	rumble = 		DataType{ path = "astnw/shake/rumble", 		unit = "m/s²", nom_fr = "vibration", nom_en = "vibration", min=0, max=1 },
	silence = 		DataType{ path = "astnw/formal/silence", 	unit = "s", nom_fr = "silence", nom_en = "silence", min=0, max=9999 },
	poly = 			DataType{ path = "astnw/formal/poly", 		unit = "#", nom_fr = "polyphonie", nom_en = "polyphony", min=0, max=9999}
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
		routine = function(self) 
			while true do
				if (data.temp:value() > data.temp:checkpoint()+1) then 
					spawn_lens(self) 
					data.temp:set_checkpoint()
				end
				coroutine.yield(1)
			end
		end,
		db = -6,
	}, { 
		nom = "temperature rising",
		selector = function(sound) return sound.desc.start.morphology.continuous > 0 and sound.desc.start.type.glide > 0 end,
		routine = function(self) 
			while true do
				if (data.temp:value() < data.temp:checkpoint()-1) then 
					spawn_lens(self) 
					data.temp:set_checkpoint()
				end
				coroutine.yield(1)
			end
		end,
		db = -6,
	}, { 
		nom = "pressure rising",
		selector = function(sound) return sound.desc.start.morphology.continuous > 0 and sound.desc.start.type.glide > 0 end,
		routine = function(self) 
			while true do
				if (data.pressure:value() > data.pressure:checkpoint()+0.01) then 
					spawn_lens(self) 
					data.temp:set_checkpoint()
				end
				coroutine.yield(1)
			end
		end,	
		db = -6
	}, { 
		nom = "pressure falling",
		selector = function(sound) return sound.desc.start.signal.notvoices > 0 and sound.desc.start.domain.nature > 0 end,
		routine = function(self) 
			while true do
				if (data.pressure:value() < data.pressure:checkpoint()-0.01) then 
					spawn_lens(self) 
					data.temp:set_checkpoint()
				end
				coroutine.yield(1)
			end
		end,
		db = -6
	}, { 
		nom = "rumble",
		data = data.shake,
		selector = function(sound) return sound.desc.start.type.echo > 0 and sound.desc.start.operation.texture > 0 and sound.desc.start.domain.humanmade > 0 end,
		mixing = function(self)  self:set_db(scale(data.shake.lowpass, 0.02, .05, -10, 0)) end,
		routine = function(self) -- every second
			while true do
				if (data.shake:lowpass(0.5) > 0.05) then 
					spawn_lens(self) -- coordinator will prevent double-spawn
					self:wait{timeout = self:duration()+10} -- 10s gap before next (will play as long as rumble > thresh)
				end
				coroutine.yield(1)
			end
		end
	}, { 
		nom = "random east",
		selector = function(sound) return sound.desc.start.type.glide > 0 and sound.desc.start.signal.integral > 0 end,
		routine = function(self) -- every second
			while true do
				if (data.winddirection:lowpass(0.5) > 45 and data.winddirection:lowpass(0.5) < 135) then 
					if (data.windspeed > 3) then
						spawn_lens(self) -- coordinator will prevent double-spawn
						self:wait{timeout = self:duration()+10} -- 10s gap before next (will play as long as wind is north and sustained)
					end
				end
				coroutine.yield(1)
			end
		end
		db = -10
	}, { 
		nom = "random south",
		selector = function(sound) return sound.desc.start.type.shimmer > 0 and sound.desc.start.signal.integral > 0 end,
		routine = function(self) -- every second
			while true do
				if (data.winddirection:lowpass(0.5) > 135 and data.winddirection:lowpass(0.5) < 215) then 
					if (data.windspeed > 3) then
						spawn_lens(self) -- coordinator will prevent double-spawn
						self:wait{timeout = self:duration()+10} --10s gap before next (will play as long as wind is north and sustained)
					end
				end
				coroutine.yield(1)
			end
		end,
		db = -10
	}, { 
		nom = "random west",
		selector = function(sound) return sound.desc.start.type.buzz > 0 and sound.desc.start.signal.fragmented > 0 end,
		routine = function(self) -- every second
			while true do
				if (data.winddirection:lowpass(0.5) > 215 and data.winddirection:lowpass(0.5) < 305) then 
					if (data.windspeed > 3) then
						spawn_lens(self) -- coordinator will prevent double-spawn
						self:wait{timeout = self:duration()+10} --10s gap before next (will play as long as wind is north and sustained)
					end
				end
				coroutine.yield(1)
			end
		end,
		db = -10	
	}, { 
		nom = "random north",
		routine = function(self) -- every second
			while true do
				if (data.winddirection:lowpass(0.5) > 305 or data.winddirection:lowpass(0.5) < 45) then 
					if (data.windspeed > 3) then
						spawn_lens(self) -- coordinator will prevent double-spawn
						self:wait{timeout = self:duration()+10} -- 10s gap before next (will play as long as wind is north and sustained)
					end
				end
				coroutine.yield(1)
			end
		end,
		db = -10
	}, { 
		nom = "pass dew point",
		selector = function(sound) return sound.desc.start.domain.abstract > 0 and sound.desc.start.signal.integral > 0 end,
		db = 0,
		routine = function(self) 
			while true do
				if (data.temp:value() < current_dew_calculation()) then 
					if (above_dew_point == true) then
						spawn_lens(self) 
						above_dew_point = false
					end
				elseif (above_dew_point == false) then
						spawn_lens(self) 
						above_dew_point = true
				end
				coroutine.yield(1)
			end
		end
	}, { 
		nom = "pass freezing point",
		selector = function(sound) return sound.desc.start.domain.concrete > 0 and sound.desc.start.signal.fragmented > 0 end,
		db = -20,
		routine = function(self) 
			while true do
				if (data.temp:value() < 0) then 
					if (above_zero == true) then
						spawn_lens(self) 
						above_zero = false
					end
				elseif (above_zero == false) then
						spawn_lens(self) 
						above_zero = true
				end
				coroutine.yield(1)
			end
		end
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
		routine = function(self) -- every second
			while true do
					if (data.windspeed > 10) then
						spawn_lens(self) -- coordinator will prevent double-spawn
						self:wait{timeout = self:duration()+60} -- 60s gap min before gust
					end
				end
				coroutine.yield(1)
			end
		end,
		db = -20
	}, { 
		nom = "interrupt",
		selector = function(sound) return sound.desc.start.operation.interruptor > 0 and sound:duration() < 15 end,
		db = 0,
		data=data.poly,
		routine = function (self)
			while true do
				if (#longuish >= 3) then					-- if 3 sounds have been playing for a while
					yield_lens(choose(longuish))		-- stop one of them
					spawn_lens(self)								-- and play a short one
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
				if data.silence:value() > 10 then		-- if it's been silent for 10 seconds
					spawn_lens(self)									-- play a sound
					self:wait{timeout = self:duration()+10}
				end
				coroutine.yield(1)
			end
		end
	}, { 
		nom = "random midnight",
		selector = function(sound) return sound.desc.start.type.echo == 0 and sound.desc.start.operation.interruptor == 0 and sound.desc.start.domain.humanmade == 0 end,
		db = -12,
		routine = function (self)
			while true do
				if (time:hour() == 0 and midnight_gong==false) then					-- if 3 sounds have been playing for a while
					spawn_lens(self)								-- and play a short one
					midnight_gong = true
				else if (time:hour() = 12 and midnight_gong==true) then
					midnight_gong = false
				end
				coroutine.yield(1)
			end
		end
	}, { 
		nom = "random noon",
		selector = function(sound) return sound.desc.start.type.echo == 0 and sound.desc.start.operation.interruptor == 0 and sound.desc.start.domain.humanmade == 0 end,
		db = -12,
		routine = function (self)
			while true do
				if (time:hour() == 12 and noon_gong==false) then					-- if 3 sounds have been playing for a while
					spawn_lens(self)								-- and play a short one
					noon_gong = true
				else if (time:hour() = 0 and noon_gong==true) then
					noon_gong = false
				end
				coroutine.yield(1)
			end
		end
	}
})
