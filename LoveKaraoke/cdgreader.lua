require("bin")
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
function cdgPlayer:init(cdgFileName)
	self.FileName = cdgFileName
	-- Check the CDG file exists
	if not io.fileExists(self.FileName) then
		ErrorString = "No such file: ".. self.FileName
		error(ErrorString)
	end
	self:decode()
end
function cdgPlayer:decode()
	-- Open the cdg file
	self.cdgFile = bin.load(self.FileName)
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
			ErrorString = "Unknown command in CDG file: " + str(inst_code)
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
	print (string.format("cdgMemoryPreset [Colour=%d, Repeat=%d]", colour, repea))
	return
end
function cdgPlayer:cdgBorderPreset(packd)
	colour = bit.band(packd['data'][1], 0x0F)
	print (string.format("cdgMemoryPreset [Colour=%d]", colour))
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
		typeStr = "cdgScrollCopy"
	else
		typeStr = "cdgScrollPreset"
	end
	print(string.format("%s [colour=%d, hScroll=%d, vScroll=%d]", typeStr, colour, hScroll, vScroll))
	return
end
function cdgPlayer:cdgTileBlockCommon(packd, xor)
	-- Decode the command parameters
	data_block = packd['data']
	colour0 = bit.band(data_block[1], 0x0F)
	colour1 = bit.band(data_block[2], 0x0F)
	column_index = bit.band(data_block[3], 0x1F) * 12
	row_index = bit.band(data_block[4], 0x3F) * 6

	if xor then
		typeStr = "cdgTileBlockXOR"
	else
		typeStr = "cdgTileBlockNormal"
	end
	print(string.format("%s [Colour0=%d, Colour1=%d, ColIndex=%d, RowIndex=%d]", typeStr, colour0, colour1, column_index, row_index))
	return
end
function cdgPlayer:cdgDefineTransparentColour(packd)
	data_block = packd['data']
	colour = bit.band(data_block[1], 0x0F)
	print (string.format("cdgDefineTransparentColour [Colour=%d]", colour))
	return
end
function cdgPlayer:cdgLoadColourTableCommon (packd, tab)
	if tab == 0 then
		colourTableStart = 0
		print ("cdgLoadColourTable0..7")
	else
		colourTableStart = 8
		print ("cdgLoadColourTable8..15")
	end
	for i=0,7 do
		colourEntry = bit.lshift(bit.band(packd['data'][(2 * i)+1], CDG_MASK), 8)
		colourEntry = colourEntry + bit.band(packd['data'][(2 * i) + 2], CDG_MASK)
		colourEntry = bit.bor(bit.rshift(bit.band(colourEntry, 0x3F00), 2), bit.band(colourEntry, 0x003F))
		print (string.format("  Colour %d = 0x%X", (i + 1 + colourTableStart), colourEntry))
	end
	return
end
--[[

colourEntry = ((packd['data'][2 * i] & CDG_MASK) << 8)
colourEntry = colourEntry + (packd['data'][(2 * i) + 1] & CDG_MASK)
colourEntry = ((colourEntry & 0x3F00) >> 2) | (colourEntry & 0x003F)

]]
player=cdgPlayer:init("test.cdg")
