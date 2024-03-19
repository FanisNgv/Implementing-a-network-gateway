program IPX_Server;
uses dos;
type
	packet=record
		CheckSum:				word;
		Length:					word;
		TransportControl:		byte;
		PacketType:				byte;
		DestNetwork:			array[1..4] of byte;
		DestNode:				array[1..6] of byte;
		DestSocket:				word;
		SourceNetwork:			array[1..4] of byte;
		SourceNode:				array[1..6] of byte;
		SourceSocket:			word;
		Data:					string;
	end;

	ecb=record
		Link:					array[1..2] of word;
		ESRAddrOfs:				word;
		ESRAddrSeg:				word;
		InUse:					byte;
		CCode:					byte;
		Socket:					word;
		IPXWork:				array[1..2] of word;
		DrvWork:				array[1..6] of word;
		ImmAddr:				array[1..6] of byte;
		FragCnt:				word;
		Addr1Ofs:				word;
		Addr1Seg:				word;
		Size1:					word;
		Addr2Ofs:				word;
		Addr2Seg:				word;
		Size2:					word;
	end;

var 
	pac:				packet;
	ECBblock:			ecb;
	regis: 				registers;
	i:					integer;
	driver:				array[1..2] of word;
	dx1:				word;
	al1:                byte;
	_seg,_ofs: 			word;
	message:			string;

BEGIN
	writeln('--> OUTPUT #1');
	writeln('--> Protocol: IPX');
	writeln;
	{Check IPX}
	regis.AX:=$7A00;
	intr($2F, regis);
	if regis.AL=$FF then begin
		writeln('>> IPX is installed');
		{Open socket}
		driver[1]:=regis.di;
		driver[2]:=regis.es;
		asm
			mov bx,00h
			mov al,00h
			mov dx,6000h
			call dword ptr driver
			mov al1, al
			mov dx1, dx
		end;
		regis.al:=al1;
		if regis.al=$00 then begin
			writeln('>> Socket is opened: ',dx1);
			writeln;
			pac.PacketType:=4;
			for i:= 1 to 4 do begin
				pac.DestNetwork[i]:=0;
			end;
			for i:=1 to 6 do begin
				pac.DestNode[i]:=$FF;
			end;
			pac.DestSocket:=$5000;
			with ECBblock do begin
				ESRAddrOfs:=0;
				ESRAddrSeg:=0;
				Socket:=$6000;
				FragCnt:=1;
				Addr1Ofs:=ofs(pac);
				Addr1Seg:=seg(pac);
				Size1:=200;
			end;
			_seg:=seg(ECBblock);
			_ofs:=ofs(ECBblock);
			driver[1]:=regis.di;
			driver[2]:=regis.es;
			repeat
				asm
					mov bx,04h
					mov es,_seg
					mov si,_ofs
					call dword ptr driver
				end;	
				while true do
					begin
						if ECBblock.InUse=0 then
							break;
					end;
				writeln('Message: ', pac.Data)
			until pac.Data = 'exit';
			writeln;
			{Close socket}
			driver[1]:=regis.di;
			driver[2]:=regis.es;
			asm
				mov bx,01h
				mov al,00h
				mov dx,6000h
				call dword ptr driver
			end;
			writeln('>> Socket is closed');
			readln;
		end
		else
			writeln('>> Socket is not opened');
	end
	else 
		writeln('>> IPX is not installed');
END.
