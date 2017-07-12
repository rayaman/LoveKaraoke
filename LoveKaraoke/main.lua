require("core.Library")
GLOBAL,sThread=require("multi.integration.loveManager").init() -- load the love2d version of the lanesManager and requires the entire multi library
require("core.GuiManager")
require("core.bin")
gui.ff.Color=Color.Black
t=gui:newTextLabel("",0,0,300,100)
t.Color=Color.purple
microphone = require("love-microphone")
function peakAmplitude(sounddata)
    local peak_amp = -math.huge
    for t = 0,sounddata:getSampleCount()-1 do
        local amp = math.abs(sounddata:getSample(t)) -- |s(t)|
        peak_amp = math.max(peak_amp, amp)
    end
    return peak_amp
end
function rmsAmplitude(sounddata)
    local amp = 0
    for t = 0,sounddata:getSampleCount()-1 do
        amp = amp + sounddata:getSample(t)^2 -- (s(t))^2
    end
    return math.sqrt(amp / sounddata:getSampleCount())
end
local device,source
local record={}
local recording=false
function love.load()
	print("Opening microphone:", microphone.getDefaultDeviceName())
	device = microphone.openDevice(nil, nil, 0)
	source = microphone.newQueueableSource()
	device:setDataCallback(function(device, data)
		if recording then
			source:queue(data)
			source:play()
			table.insert(record,{data,os.clock()})
			test:setDualDim(nil,nil,nil,nil,nil,nil,peakAmplitude(data))
			test2:setDualDim(nil,nil,nil,nil,nil,nil,rmsAmplitude(data))
		end
	end)
	device:start()
	multi:newLoop(function() device:poll() end)
end
test0=t:newTextButton("Start Recording","Start Recording",0,0,100,30)
test0:centerX()
test0:centerY()
test0:ApplyGradient{Color.Green,Color.Darken(Color.Green,.25)}
test0:OnReleased(function(b,self)
	if self.text=="Start Recording" then
		self.text="Stop Recording"
		recording=true
	elseif self.text=="Stop Recording" then
		test0.text="Playing Back!"
		recording=false
		local step=multi:newStep(1,#record)
		step:OnStep(function(self,pos)
			source:queue(record[pos][1])
			test:setDualDim(nil,nil,nil,nil,nil,nil,peakAmplitude(record[pos][1]))
			test2:setDualDim(nil,nil,nil,nil,nil,nil,rmsAmplitude(record[pos][1]))
			if pos>1 then
				self:hold(record[pos][2]-record[pos-1][2])
			end
		end)
		step:OnEnd(function(self)
			record={}
			self:Destroy()
			loop2:Destroy()
			test0.text="Start Recording"
		end)
		loop2=multi:newLoop(function() source:play() end)
	end
end)
test=t:newFrame("BAR",0,0,0,30,0,0,0)
test:ApplyGradient{Color.Green,Color.Darken(Color.Green,.25)}
test2=t:newFrame("BAR",0,70,0,30,0,0,0)
test2:ApplyGradient{Color.Green,Color.Darken(Color.Green,.25)}
--test:centerY()
