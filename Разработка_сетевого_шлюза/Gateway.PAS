program Gateway;
uses dos;
type
    ncb=record
		Cmd:                	byte;
		CCode:              	byte;
		LocalSessionNumber: 	byte;
		NetworkNameNumber:  	byte;
		BufOfs:             	word;
		BufSeg:             	word;
		Size:               	word;
		CallName:           	array[1..16] of char;
		OurName:            	array[1..16] of char;
		ReceiveTimeout:     	byte;
		SendTimeout:        	byte;
		PostRoutineOfs:     	word;
		PostRoutineSeg:     	word;
		AdapterNumber:      	byte;
		FinalCCode:         	byte;
		Reserver:           	array[1..14] of char;
    end;
	
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
	blockNCB_D, blockNCB_Ch: 	ncb;
	reg_D, reg_Ch: 				registers;
	buffer: 					string;
	channelNumber: 				byte;
	nameNumber: 				byte;
	
	pac:					packet;
	ECBblock:				ecb;
	regs: 					registers;
	i:						integer;
	dx1:					word;
	al1:                 	byte;
	driver:					array[1..2] of word;
	_seg,_ofs: 				word;
	
procedure NetBIOS_Channel_Server;
	begin
		{Delete name}
		with blockNCB_Ch do begin
			Cmd:=$31;
			OurName:='netbiosserver_in';
			PostRoutineOfs:=0;
			PostRoutineSeg:=0;
			AdapterNumber:=3;
		end;
		reg_Ch.es:=seg(blockNCB_Ch);
		reg_Ch.bx:=ofs(blockNCB_Ch);
		intr($5C,reg_Ch);
		{Add name}
		with blockNCB_Ch do begin
			Cmd:=$30;
			OurName:='netbiosserver_in';
			PostRoutineOfs:=0;
			PostRoutineSeg:=0;
			AdapterNumber:=3;
		end;
		reg_Ch.es:=seg(blockNCB_Ch);
		reg_Ch.bx:=ofs(blockNCB_Ch);
		intr($5C,reg_Ch);
		{Listen for channel creating}
		with blockNCB_Ch do begin
			Cmd:=$11;
			OurName:='netbiosserver_in';
			CallName:='netbiosclient_in';
			ReceiveTimeout:=10;
			SendTimeout:=10;
			PostRoutineOfs:=0;
			PostRoutineSeg:=0;
			AdapterNumber:=3;
		end;
		reg_Ch.es:=seg(blockNCB_Ch);
		reg_Ch.bx:=ofs(blockNCB_Ch);
		intr($5C,reg_Ch);
		channelNumber:=blockNCB_Ch.LocalSessionNumber;
		if channelNumber<>0 then
			writeln('>> Channel is created with number: ', channelNumber)
		else
			writeln('>> Channel is not created');
	end;

procedure IPX_Client;
	begin
		{Check IPX}
		regs.AX:=$7A00;
		intr($2F, regs);
		if regs.al=$FF then begin
			writeln('>> IPX is installed');
			{Open Socket}
			driver[1]:=regs.di;
			driver[2]:=regs.es;
			asm
				mov bx,00h
				mov al,00h
				mov dx,5000h
				call dword ptr driver
				mov al1, al
				mov dx1, dx
			end;
			regs.al:=al1;
			if regs.al=$00 then begin
				writeln('>> Socket is opened: ',dx1);
				{Preparing to send packet}
				with ECBblock do begin
					ESRAddrOfs:=0;
					ESRAddrSeg:=0;
					Socket:=$5000;
					FragCnt:=1;
					Addr1Ofs:=ofs(pac);
					Addr1Seg:=seg(pac);
					Size1:=200;
				end;
				with pac do begin
					PacketType:=4;
					DestSocket:=$6000;
				end;
				for i:= 1 to 4 do begin
					pac.DestNetwork[i]:=0;
				end;
				for i:=1 to 6 do begin
					pac.DestNode[i]:=$FF;
				end;
				_seg:=seg(ECBblock);
				_ofs:=ofs(ECBblock);
				driver[1]:=regs.di;
				driver[2]:=regs.es;
			end
			else
				writeln('>> Socket is not opened');
		end
		else 
			writeln('>> IPX is not installed');
	end;

procedure NetBIOS_Datagram_Client;
	begin
		{Delete name}
		with blockNCB_D do begin
			Cmd:=$31;
			OurName:='netbiosclientout';
			PostRoutineOfs:=0;
			PostRoutineSeg:=0;
			AdapterNumber:=3;
		end;
		reg_D.es:=seg(blockNCB_D);
		reg_D.bx:=ofs(blockNCB_D);
		intr($5C,reg_D);
		{Add name}
		with blockNCB_D do begin
			Cmd:=$30;
			OurName:='netbiosclientout';
			PostRoutineOfs:=0;
			PostRoutineSeg:=0;
			AdapterNumber:=3;
		end;
		reg_D.es:=seg(blockNCB_D);
		reg_D.bx:=ofs(blockNCB_D);
		intr($5C,reg_D);
		nameNumber:= blockNCB_D.NetworkNameNumber;
	end;
	
procedure SendToOutput1;
	begin
		{Send message}
		pac.Data:=buffer;
		asm
			mov bx,03h
			mov es,_seg
			mov si,_ofs
			call dword ptr driver
		end;
		if buffer <> 'exit' then begin
			writeln('Message from NetBIOS Channel Client is sent to IPX Server');
			writeln;
		end;
	end;
	
procedure SendToOutput2;
	begin
		{Send datagram}
		with blockNCB_D do begin
			Cmd:=$20;
			NetworkNameNumber:=nameNumber;
			CallName:='netbiosserverout';
			PostRoutineOfs:=0;
			PostRoutineSeg:=0;
			Size:=16;
			BufSeg:=seg(buffer);
			BufOfs:=ofs(buffer);
			AdapterNumber:=3;
		end;
		reg_D.es:=seg(blockNCB_D);
		reg_D.bx:=ofs(blockNCB_D);
		intr($5C,reg_D);
		if buffer <> 'exit' then begin
			writeln('Message from NetBIOS Channel Client is sent to NetBIOS Datagram Server');
			writeln;
		end;
	end;

BEGIN
	writeln('--> Gateway');
	writeln('--> From protocol: NetBIOS Channel');
	writeln('--> To protocol: IPX and NetBIOS Datagram');
	writeln;
	NetBIOS_Channel_Server;
	IPX_Client;
	NetBIOS_Datagram_Client;
	writeln;
	while (true) do 
	  begin
		{Receive message}
		if channelNumber<>0 then
		  begin
			with blockNCB_Ch do begin
				Cmd:=$16;
				LocalSessionNumber:=channelNumber;
				NetworkNameNumber:=$FF;
				PostRoutineOfs:=0;
				PostRoutineSeg:=0;
				Size:=16;
				BufSeg:=seg(buffer);
				BufOfs:=ofs(buffer);
				AdapterNumber:=3;
			end;
			reg_Ch.es:=seg(blockNCB_Ch);
			reg_Ch.bx:=ofs(blockNCB_Ch);
			intr($5C,reg_Ch);
			writeln('Message: ', buffer);
			if regs.al=$00 then
				SendToOutput1;
			SendToOutput2;
			if buffer = 'exit' then
				break;
		  end;
	  end;
	writeln;
	if channelNumber<>0 then
	  begin
		{Close channel}
		with blockNCB_Ch do begin
			Cmd:=$12;
			LocalSessionNumber:=channelNumber;
			PostRoutineOfs:=0;
			PostRoutineSeg:=0;
			AdapterNumber:=3;
		end;
		reg_Ch.es:=seg(blockNCB_Ch);
		reg_Ch.bx:=ofs(blockNCB_Ch);
		intr($5C,reg_Ch);
		writeln('>> Channel is closed');
	  end;
	if regs.al=$00 then 
	  begin
		{Close socket}
		driver[1]:=regs.di;
		driver[2]:=regs.es;
		asm
			mov bx,01h
			mov al,00h
			mov dx,5000h
			call dword ptr driver
		end;
		writeln('>> Socket is closed');
	  end;
	readln;
END.