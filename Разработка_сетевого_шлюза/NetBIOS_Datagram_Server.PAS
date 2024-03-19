program NetBIOS_Datagram_Server;
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
	NCBlock: 	ncb;
	reg: 		registers;
	buffer: 	string;
	
BEGIN
	writeln('--> OUTPUT #2');
	writeln('--> Protocol: NetBIOS Datagram');
	writeln;
	{Delete name}
	with NCBlock do begin
		Cmd:=$31;
		OurName:='netbiosserverout';
		PostRoutineOfs:=0;
		PostRoutineSeg:=0;
		AdapterNumber:=3;
	end;
	reg.es:=seg(NCBlock);
	reg.bx:=ofs(NCBlock);
	intr($5C,reg);
	{Add name}
	with NCBlock do begin
		Cmd:=$30;
		OurName:='netbiosserverout';
		PostRoutineOfs:=0;
		PostRoutineSeg:=0;
		AdapterNumber:=3;
	end;
	reg.es:=seg(NCBlock);
	reg.bx:=ofs(NCBlock);
	intr($5C,reg);
	{Receive datagram}
	with NCBlock do begin
		Cmd:=$21;
		NetworkNameNumber:=$FF;
		PostRoutineOfs:=0;
		PostRoutineSeg:=3;
		Size:=16;
		BufSeg:=seg(buffer);
		BufOfs:=ofs(buffer);
		AdapterNumber:=3;
	end;
	reg.es:=seg(NCBlock);
	reg.bx:=ofs(NCBlock);
	repeat
		intr($5C,reg);
		writeln('Message: ', buffer);
	until buffer='exit';
	readln;
END.