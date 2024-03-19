program NetBIOS_Channel_Client;
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

var 
	blockNCB: 			ncb;
	channelNumber: 		byte;
	reg: 				registers;
	i: 					integer;
	buffer: 			string;

BEGIN
	writeln('--> INPUT');
	writeln('--> Protocol: NetBIOS Channel');
	writeln;
	{Delete name}
	with blockNCB do begin
		Cmd:=$31;
		OurName:='netbiosclient_in';
		PostRoutineOfs:=0;
		PostRoutineSeg:=0;
		AdapterNumber:=3;
	end;
	reg.es:=seg(blockNCB);
	reg.bx:=ofs(blockNCB);
	intr($5C,reg);
	{Add name}
	with blockNCB do begin
		Cmd:=$30;
		OurName:='netbiosclient_in';
		PostRoutineOfs:=0;
		PostRoutineSeg:=0;
		AdapterNumber:=3;
	end;
	reg.es:=seg(blockNCB);
	reg.bx:=ofs(blockNCB);
	intr($5C,reg);
	{Call for channel creating}
	with blockNCB do begin
		Cmd:=$10;
		OurName:='netbiosclient_in';
		CallName:='netbiosserver_in';
		ReceiveTimeout:=10;
		SendTimeout:=10;
		PostRoutineOfs:=0;
		PostRoutineSeg:=0;
		AdapterNumber:=3;
	end;
	reg.es:=seg(blockNCB);
	reg.bx:=ofs(blockNCB);
	intr($5C,reg);
	channelNumber:=blockNCB.LocalSessionNumber;
	if channelNumber<>0 then
	  begin
		writeln('>> Channel is created with number #', channelNumber);
		writeln;
		{Send message}
		with blockNCB do begin
			Cmd:=$14;
			LocalSessionNumber:=channelNumber;
			BufSeg:=seg(buffer);
			BufOfs:=ofs(buffer);
			Size:=16;
			PostRoutineOfs:=0;
			PostRoutineSeg:=0;
			AdapterNumber:=3;
		end;
		reg.es:=seg(blockNCB);
		reg.bx:=ofs(blockNCB);
		repeat
			write('Enter the message: ');
			readln(buffer);
			intr($5c,reg);
			writeln('Your message: ', buffer);
			writeln('Message is sent');
			writeln;
		until buffer='exit';
		{Closing of channel'}
		with blockNCB do begin
			Cmd:=$12;
			LocalSessionNumber:=channelNumber;
			PostRoutineOfs:=0;
			PostRoutineSeg:=0;
			AdapterNumber:=3;
		end;
		reg.es:=seg(blockNCB);
		reg.bx:=ofs(blockNCB);
		intr($5C,reg);
		writeln;
		writeln('>> Channel is closed');
	  end
	else
		writeln('>> Channel is not created');
	readln;
END.