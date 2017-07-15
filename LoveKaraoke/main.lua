require("core.Library")
GLOBAL,sThread=require("multi.integration.loveManager").init() -- load the love2d version of the lanesManager and requires the entire multi library
require("core.GuiManager")
require("core.bin")
require("cdgreader")
gui.ff.Color=Color.Black
function formatFix(str,n,cap)
	if cap then
		if #str==8 then
			str=str:sub(3,-1)
		else
			str=string.rep("0",n-#str)..str
		end
	else
		str=string.rep("0",n-#str)..str
	end
--~ 	print(str)
	return str
end
function HEX4ToRGB(HEX)
	HEX=formatFix(HEX,3)
	return tonumber(HEX:sub(1,1),16)*(255)/15, tonumber(HEX:sub(2,2),16)*(255)/15, tonumber(HEX:sub(3,3),16)*(255)/15
end
function RGBToHEX(r,g,b)
	local HEX,L={},{[0]="0",[1]="1",[2]="2",[3]="3",[4]="4",[5]="5",[6]="6",[7]="7",[8]="8",[9]="9",[10]="A",[11]="B",[12]="C",[13]="D",[14]="E",[15]="F"}
	HEX[1]=L[(r*15)/255];HEX[2]=L[(g*15)/255];HEX[3]=L[(b*15)/255]
	return table.concat(HEX)
end
music=love.audio.newSource("test3.mp3", "stream")
player=cdgPlayer:init("test3.cdg")
COLORS={}
print("Loading Colors: "..#player.colors)
for i=1,#player.colors do
	COLORS[i-1]=Color.new(HEX4ToRGB(bin.NumtoHEX(player.colors[i])))
	print(i-1,COLORS[i-1])
end
BGCOLOR=0
ImageData=love.image.newImageData(300,216)
ImageDataRef=love.image.newImageData(300,216)
Image=love.graphics.newImage(ImageData)
screen=gui:newImageLabel(Image,"SCREEN",0,0,300*3,216*3)
screen:centerX()
screen:centerY()
updateFunc=multi:newFunction(function(mself,self)
	local data=player:next()
	if not data then return end
	local cmd=table.remove(data,1)
	if cmd=="MEMORY_PRESET" then
		local r,g,b=unpack(COLORS[data[1]])
		BGCOLOR=data[1]
		for x=0,299 do
			for y=0,215 do
				ImageData:setPixel(x, y, r, g, b, 255)
				ImageDataRef:setPixel(x, y,data[1],0,0,0)
			end
		end
	elseif cmd=="TILE_BLOCK_XOR" then
		--print(data[1],data[2],COLORS[data[2]])
		local r1,g1,b1=unpack(COLORS[data[1]])
		local r2,g2,b2=unpack(COLORS[data[2]])
		local y,x=data[3],data[4]
		local tile={
			formatFix(tostring(bits.new(data[5][1])),6,true),
			formatFix(tostring(bits.new(data[5][2])),6,true),
			formatFix(tostring(bits.new(data[5][3])),6,true),
			formatFix(tostring(bits.new(data[5][4])),6,true),
			formatFix(tostring(bits.new(data[5][5])),6,true),
			formatFix(tostring(bits.new(data[5][6])),6,true),
			formatFix(tostring(bits.new(data[5][7])),6,true),
			formatFix(tostring(bits.new(data[5][8])),6,true),
			formatFix(tostring(bits.new(data[5][9])),6,true),
			formatFix(tostring(bits.new(data[5][10])),6,true),
			formatFix(tostring(bits.new(data[5][11])),6,true),
			formatFix(tostring(bits.new(data[5][12])),6,true)
		}
		for yy=1,#tile do
			for xx=1,#tile[yy] do
				--print(tile[yy]:sub(xx,xx))
				local rc=ImageDataRef:getPixel(x+(xx-1), y+(yy-1))
				local r,g,b=0,0,0
--~ 				local cc=tonumber(RGBToHEX(rc,gc,bc),16)
				if tile[yy]:sub(xx,xx)=="0" then
--~ 					local c1=tonumber(RGBToHEX(r1,g1,b1),16)
					r, g, b = unpack(COLORS[bit.bxor(data[1],rc)])
					ImageDataRef:setPixel(x+(xx-1), y+(yy-1),data[1],0,0,0)
				else
--~ 					local c2=tonumber(RGBToHEX(r2,g2,b2),16)
					r, g, b = unpack(COLORS[bit.bxor(data[2],rc)])
					ImageDataRef:setPixel(x+(xx-1), y+(yy-1),data[2],0,0,0)
				end
				ImageData:setPixel(x+(xx-1), y+(yy-1), r, g, b, 255)
			end
		end
		mself:hold(1/90)
	end
	-- Update the "Screen"
	self:SetImage(love.graphics.newImage(ImageData))
--~ 	print(os.clock())
end)
music:play()
screen:OnUpdate(updateFunc)
--[[
test=bin.stream("test.dat",false)
local cmd=player:next()
for i=1,#player.colors do
	test:tackE("Color"..(i-1).."|"..bin.NumtoHEX(player.colors[i-1]).."\n")
end
while cmd do
	test:tackE(cmd.."\n")
	cmd,dat=player:next()
end
test:close()
]]
--~ t=gui:newTextLabel("",0,0,300,100)
--~ t.Color=Color.purple
--~ microphone = require("love-microphone")
--~ function peakAmplitude(sounddata)
--~     local peak_amp = -math.huge
--~     for t = 0,sounddata:getSampleCount()-1 do
--~         local amp = math.abs(sounddata:getSample(t)) -- |s(t)|
--~         peak_amp = math.max(peak_amp, amp)
--~     end
--~     return peak_amp
--~ end
--~ function rmsAmplitude(sounddata)
--~     local amp = 0
--~     for t = 0,sounddata:getSampleCount()-1 do
--~         amp = amp + sounddata:getSample(t)^2 -- (s(t))^2
--~     end
--~     return math.sqrt(amp / sounddata:getSampleCount())
--~ end
--~ local device,source
--~ local record={}
--~ local recording=false
--~ function love.load()
--~ 	print("Opening microphone:", microphone.getDefaultDeviceName())
--~ 	device = microphone.openDevice(nil, nil, 0)
--~ 	source = microphone.newQueueableSource()
--~ 	device:setDataCallback(function(device, data)
--~ 		if recording then
--~ 			source:queue(data)
--~ 			source:play()
--~ 			table.insert(record,{data,os.clock()})
--~ 			test:setDualDim(nil,nil,nil,nil,nil,nil,peakAmplitude(data))
--~ 			test2:setDualDim(nil,nil,nil,nil,nil,nil,rmsAmplitude(data))
--~ 		end
--~ 	end)
--~ 	device:start()
--~ 	multi:newLoop(function() device:poll() end)
--~ end
--~ test0=t:newTextButton("Start Recording","Start Recording",0,0,100,30)
--~ test0:centerX()
--~ test0:centerY()
--~ test0:ApplyGradient{Color.Green,Color.Darken(Color.Green,.25)}
--~ test0:OnReleased(function(b,self)
--~ 	if self.text=="Start Recording" then
--~ 		self.text="Stop Recording"
--~ 		recording=true
--~ 	elseif self.text=="Stop Recording" then
--~ 		test0.text="Playing Back!"
--~ 		recording=false
--~ 		local step=multi:newStep(1,#record)
--~ 		step:OnStep(function(self,pos)
--~ 			source:queue(record[pos][1])
--~ 			test:setDualDim(nil,nil,nil,nil,nil,nil,peakAmplitude(record[pos][1]))
--~ 			test2:setDualDim(nil,nil,nil,nil,nil,nil,rmsAmplitude(record[pos][1]))
--~ 			if pos>1 then
--~ 				self:hold(record[pos][2]-record[pos-1][2])
--~ 			end
--~ 		end)
--~ 		step:OnEnd(function(self)
--~ 			record={}
--~ 			self:Destroy()
--~ 			loop2:Destroy()
--~ 			test0.text="Start Recording"
--~ 		end)
--~ 		loop2=multi:newLoop(function() source:play() end)
--~ 	end
--~ end)
--~ test=t:newFrame("BAR",0,0,0,30,0,0,0)
--~ test:ApplyGradient{Color.Green,Color.Darken(Color.Green,.25)}
--~ test2=t:newFrame("BAR",0,70,0,30,0,0,0)
--~ test2:ApplyGradient{Color.Green,Color.Darken(Color.Green,.25)}
