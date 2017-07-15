require("bit")
--require("luabit.bit")
-- CDG Command Code
CDG_COMMAND 				= 0x09
-- CDG Instruction Codes
CDG_INST_MEMORY_PRESET		= 1
CDG_INST_BORDER_PRESET		= 2
CDG_INST_TILE_BLOCK			= 6
CDG_INST_SCROLL_PRESET		= 20
CDG_INST_SCROLL_COPY		= 24
CDG_INST_DEF_TRANSP_COL		= 28
CDG_INST_LOAD_COL_TBL_0_7	= 30
CDG_INST_LOAD_COL_TBL_8_15	= 31
CDG_INST_TILE_BLOCK_XOR		= 38
-- Bitmask for all CDG fields
CDG_MASK 					= 0x3F
cdgPlayer={}
cdgPlayer.CMD={
	MEMORY_PRESET		= 1,
	BORDER_PRESET		= 2,
	TILE_BLOCK			= 6,
	SCROLL_PRESET		= 20,
	SCROLL_COPY			= 24,
	DEF_TRANSP_COL		= 28,
	LOAD_COL_TBL_0_7	= 30,
	LOAD_COL_TBL_8_15	= 31,
	TILE_BLOCK_XOR		= 38
}
cdgPlayer.tempdata={
	colors={},
	index=1,
	data={},
	frames=0,
	getFrames=function(self)
		return self.frames
	end,
	next=function(self)
		local data=self.data[self.index]
		if not data then return end
		self.index=self.index+1
		return data
	end
}
function cdgPlayer:packCommand(cmd,...)
--~ 	print("Packing: "..cmd)
	table.insert(self.tempdata.data,{cmd,...})
end
function cdgPlayer:dump(...)
	if self.dumpit then
		print(...)
	end
end
function cdgPlayer:init(cdgFileName,dump)
	self.dumpit=dump
	self.FileName = cdgFileName
	-- Check the CDG file exists
	if not love.filesystem.exists(self.FileName) then
		ErrorString = "No such file: ".. self.FileName
		error(ErrorString)
	end
--~ 	if not io.fileExists(self.FileName) then
--~ 		ErrorString = "No such file: ".. self.FileName
--~ 		error(ErrorString)
--~ 	end
	self:decode()
	return self.tempdata
end
function cdgPlayer:decode()
	-- Open the cdg file
	self.cdgFile = bin.new((love.filesystem.read(self.FileName)))
--~ 	self.cdgFile = bin.load(self.FileName)
	-- Main processing loop
	while true do
		packd = self:cdgGetNextPacket()
		if packd then
			self:cdgPacketProcess(packd)
		else
			self.cdgFile:close()
			return
		end
	end
end
-- Decode the CDG commands read from the CDG file
function cdgPlayer:cdgPacketProcess(packd)
	if bit.band(packd['command'], CDG_MASK) == CDG_COMMAND then
		inst_code = bit.band(packd['instruction'], CDG_MASK)
		if inst_code == CDG_INST_MEMORY_PRESET then
			self:cdgMemoryPreset(packd)
		elseif inst_code == CDG_INST_BORDER_PRESET then
			self:cdgBorderPreset(packd)
		elseif inst_code == CDG_INST_TILE_BLOCK then
			self:cdgTileBlockCommon(packd, false)
		elseif inst_code == CDG_INST_SCROLL_PRESET then
			self:cdgScrollPreset(packd)
		elseif inst_code == CDG_INST_SCROLL_COPY then
			self:cdgScrollCopy(packd)
		elseif inst_code == CDG_INST_DEF_TRANSP_COL then
			self:cdgDefineTransparentColour(packd)
		elseif inst_code == CDG_INST_LOAD_COL_TBL_0_7 then
			self:cdgLoadColourTableCommon(packd, 0)
		elseif inst_code == CDG_INST_LOAD_COL_TBL_8_15 then
			self:cdgLoadColourTableCommon(packd, 1)
		elseif inst_code == CDG_INST_TILE_BLOCK_XOR then
			self:cdgTileBlockCommon(packd, 1)
		else
			ErrorString = "Unknown command in CDG file: " .. tostring(inst_code)
			print(ErrorString)
		end
	end
end
-- Read the next CDG command from the file (24 bytes each)
function cdgPlayer:cdgGetNextPacket() -- Come back to this!!!
	packd={}
	packet = bin.new(self.cdgFile:getBlock("s",24))
	--print(packet)
	if packet:getlength() == 24 then
		packd['command']=packet:getBlock("n",1)--struct.unpack('B', packet[0])[0]
		packd['instruction']=packet:getBlock("n",1)--struct.unpack('B', packet[1])[0]
		packd['parityQ']=packet:getBlock("s",2)--struct.unpack('2B', packet:sub(2,4))[0:2]
		packd['data']=bin.newDataBuffer(16)--struct.unpack('16B', packet[4:20])[0:16]
		packd['data']:fillBuffer(packet:getBlock("s",16),1)
		packd['parity']=packet:getBlock("s",4)--struct.unpack('4B', packet[20:24])[0:4]
		return packd
	elseif packet:getlength() > 0 then
		print("Didn't read 24 bytes")
		return nil
	end
end
function cdgPlayer:cdgMemoryPreset(packd)
	colour = bit.band(packd['data'][1], 0x0F)
	repea = bit.band(packd['data'][2], 0x0F)
	self:dump(string.format("cdgMemoryPreset [Colour=%d, Repeat=%d]", colour, repea))
	self:packCommand("MEMORY_PRESET",colour, repea)
	return
end
function cdgPlayer:cdgBorderPreset(packd)
	colour = bit.band(packd['data'][1], 0x0F)
	self:dump(string.format("cdgMemoryPreset [Colour=%d]", colour))
	self:packCommand("MEMORY_PRESET",colour)
	self.tempdata.frames=self.tempdata.frames+1
	return
end
function cdgPlayer:cdgScrollPreset(packd)
	self:cdgScrollCommon(packd, false)
	return
end
function cdgPlayer:cdgScrollCopy(packd)
	self.cdgScrollCommon(packd, true)
	return
end
function cdgPlayer:cdgScrollCommon(packd, copy)
	-- Decode the scroll command parameters
	data_block = packd['data']
	colour = bit.band(data_block[1], 0x0F)
	hScroll = bit.band(data_block[2], 0x3F)
	vScroll = bit.band(data_block[3], 0x3F)
	hSCmd = bit.rshift(bit.band(hScroll, 0x30), 4)
	hOffset = bit.band(hScroll, 0x07)
	vSCmd = bit.rshift(bit.band(vScroll, 0x30), 4)
	vOffset = bit.band(vScroll, 0x0F)

	if copy then
		typeStr = "SCROLL_COPY"
	else
		typeStr = "SCROLL_PRESET"
	end
	self:dump(string.format("%s [colour=%d, hScroll=%d, vScroll=%d]", typeStr, colour, hScroll, vScroll))
	self:packCommand(typeStr, colour, hScroll, vScroll)
	return
end
function cdgPlayer:cdgTileBlockCommon(packd, xor)
	-- Decode the command parameters
	data_block = packd['data']
	colour0 = bit.band(data_block[1], 0x0F)
	colour1 = bit.band(data_block[2], 0x0F)
	column_index = bit.band(data_block[3], 0x1F) * 12
	row_index = bit.band(data_block[4], 0x3F) * 6
	titlepixels={
		bit.band(data_block[5], 0x3F),
		bit.band(data_block[6], 0x3F),
		bit.band(data_block[7], 0x3F),
		bit.band(data_block[8], 0x3F),
		bit.band(data_block[9], 0x3F),
		bit.band(data_block[10], 0x3F),
		bit.band(data_block[11], 0x3F),
		bit.band(data_block[12], 0x3F),
		bit.band(data_block[13], 0x3F),
		bit.band(data_block[14], 0x3F),
		bit.band(data_block[15], 0x3F),
		bit.band(data_block[16], 0x3F)
	}
	if xor then
		typeStr = "TILE_BLOCK_XOR"
	else
		typeStr = "TILE_BLOCK"
	end
	self:dump(string.format("%s [Colour0=%d, Colour1=%d, ColIndex=%d, RowIndex=%d]", typeStr, colour0, colour1, column_index, row_index))
	self:packCommand(typeStr, colour0, colour1, column_index, row_index, titlepixels)
	return
end
function cdgPlayer:cdgDefineTransparentColour(packd)
	data_block = packd['data']
	colour = bit.band(data_block[1], 0x0F)
	self:dump(string.format("cdgDefineTransparentColour [Colour=%d]", colour))
	self:packCommand("DEF_TRANSP_COL",colour)
	return
end
function cdgPlayer:cdgLoadColourTableCommon (packd, tab)
	if tab == 0 then
		colourTableStart = 0
		self:dump("cdgLoadColourTable0..7")
	else
		colourTableStart = 8
		self:dump("cdgLoadColourTable8..15")
	end
	for i=0,7 do
		colourEntry = bit.lshift(bit.band(packd['data'][(2 * i)+1], CDG_MASK), 8)
		colourEntry = colourEntry + bit.band(packd['data'][(2 * i) + 2], CDG_MASK)
		colourEntry = bit.bor(bit.rshift(bit.band(colourEntry, 0x3F00), 2), bit.band(colourEntry, 0x003F))
		self:dump(string.format("  Colour %d = 0x%X", (i + colourTableStart), colourEntry))
		self.tempdata.colors[#self.tempdata.colors+1]=colourEntry
	end
	return
end
