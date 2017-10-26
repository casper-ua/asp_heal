{$A-,B+,D+,E-,F-,G-,I-,L+,N-,O-,P+,Q-,R-,S-,T-,V-,X+,Y-}
{$M 16384,5120,5120}
program ASP_Heal;
uses
  ASP_Def,
  ASP_Util,
  Dos;

procedure Mem_Virus;
label Ex, Ex1, Ex2, Ex3;
var
  Vir_Seg, Vir_Ofs : Word;
  P : Pointer Absolute Vir_Ofs;
  VirSeg, VirOfs : Word;
  P1: Pointer Absolute VirOfs;
  OldInf : Word;
begin
 { Вирусы, перехватываюшие int 13h }
 Vir_Ofs := MemW[ $0070:$0b4 ];
 Vir_Seg := MemW[ $0070:$0b6 ];
 repeat
  OldInf := Inf;
  if ( Vir_Ofs = $0027 ) and
     ( MemL[ Vir_Seg:Vir_Ofs ] = 1962540160 )
  then begin
    Inc( Inf );
    Write( Lst, Detect_Mem,'ANTI-EXE' );
    Write( Detect_Mem,'ANTI-EXE' );
    DesactivResident( Vir_Seg, Vir_Ofs, MemW[ 0:$034e ], MemW[ 0:$034c ]);
  end;
 until (OldInf = Inf);
 { Вирусы, перехватываюшие int 21h }
 Vir_Ofs := MemW[ 0:$21*4 ];
 Vir_Seg := MemW[ 0:$21*4+2 ];
 repeat
  OldInf := Inf;
  asm
    mov ax,4bffh
    xor di,di
    xor si,si
    int 21h
    cmp di,55aah
    jnz Ex
  end; Inc( Inf );
  Writeln( Lst, Detect_Mem, Names[11] );
  Writeln( Detect_Mem,  Names[11] );
Ex:asm
   mov bx,002ch
   clc
   mov ax,0c603h
   int 21h
   jnc Ex1
   end;
  {if CheckMem( DoodleMem, P^ ) then begin}
    Inc( Inf );
    Writeln( Lst, Detect_Mem, Names[13] );
    Writeln( Detect_Mem, Names[13] );
  {  DesactivResident( Vir_Seg, Vir_Ofs, MemW[Vir_Seg:(Vir_Ofs-$7d4+$2c)],
                      MemW[Vir_Seg:(Vir_Ofs-$7d4+$2a)] );
  end;}
Ex1:
  if CheckMem( MagMem, P^ ) then begin {int 21h, ah=87h => al=3}
    Inc( Inf );
    Write( Lst, Detect_Mem, Names[16] );
    Write( Detect_Mem, Names[16] );
    DesactivResident( Vir_Seg, Vir_Ofs, MemW[Vir_Seg:(Vir_Ofs-$f4+$4c)],
                      MemW[Vir_Seg:(Vir_Ofs-$f4+$4a)] );
  end;
  VirOfs := MemW[Vir_Seg:Vir_Ofs+1];
  VirSeg := MemW[Vir_Seg:Vir_Ofs+3];
  if CheckMem( FATMem, P1^ ) then begin {int 21h, ah=88h => al=3}
    Inc( Inf );
    Write( Lst, Detect_Mem, Names[17] );
    Write( Detect_Mem, Names[17] );
    DesactivResident( Vir_Seg, Vir_Ofs, MemW[VirSeg:$254],
                      MemW[VirSeg:$252] );
  end;
Ex3:if CheckMem( RC414_414, P^ ) then begin
    Inc( Inf );
    Write( Lst, Detect_Mem,Names[18]);
    Write( Detect_Mem, Names[18] );
    DesactivResident( Vir_Seg, Vir_Ofs, MemW[0:$ee*4+2], MemW[0:$ee*4] );
  end;
  if CheckMem( PhonixMem, P^ ) then begin
    Inc( Inf );
    Write( Lst, Detect_Mem, Names[20] );
    Write( Detect_Mem, Names[20] );
    DesactivResident( Vir_Seg, Vir_Ofs,
                      MemW[Vir_Seg:(Vir_Ofs-$124+$3a1)],
                      MemW[Vir_Seg:(Vir_Ofs-$124+$39f)] );
  end;
 until (OldInf = Inf);
end;

procedure Disk_Check;
var
  _S  : ComStr;
  Dsk : Byte;
  OldInf, OldCorr : Longint;
  VirDh : Byte;
  VirCx : Word;
  ZFill : Boolean;
  P : Pointer;
begin
  Dsk := DevType(Ord(Drive)-Ord('@'));
  ZFill := Dsk in [0..2,7,9]; {Floppy}
  if (Dsk=$0FF) or (Dsk=6) or (Dsk=8) or (Dsk>9) then Exit;
     {no device}   { tape }   {CD-ROM}   {unknown}
  _S := ResolvePathStr( ParamS );
  { сетевой диск }
  if (DosError<>0) or ((_S[1]='\') and (_S[2]='\')) then Exit;
  { логический диск }
  if _S[1] <> Drive then Drive := _S[1];
  case Drive of
    'A' : if ZFill then Dsk := 0;
    'B' : Dsk := NFloppies-1;
    'C' : if Dsk = 5
          then
            Dsk := $80
          else
            if (NFloppies >= 3) and ZFill
            then
              Dsk := 2
            else
              Exit;
    'D' : if (NFloppies = 4) and ZFill
          then
            Dsk := 3
          else
            Exit;
    else Exit;
  end;
  repeat
    OldInf := InfectF; OldCorr := CorrectF;
    FillChar( A^, 1024, 0 );
    if not BiosDisk( DiskRead, Dsk, 0, 1, 1, A^ ) then
    begin
      Write( Lst, ErRead1Sect );
      Write( ErRead1Sect );
      Break;
    end;
    if CheckVirus( AntiEXE ) then
    begin
      Write( Lst, Detect_Disk,'"ANTI-EXE"');
      Write( Detect_Disk,'"ANTI-EXE"');
      if not Heal then
      begin
        Write(Lst, #13#10);
        Write(#13#10);
        Break;
      end
      else begin  { Heal_Disk }
        VirDh := A^[6]; VirCx := wA^[2]; ZFill := True;
        if (not BiosDisk( DiskRead, Dsk, VirDh, VirCx, 1, A^[512] ))
         or (wA^[511]<>$aa55) then
        begin
          if Dsk = $80 then
          begin
            P := @MBR;
            Move( P, A^[512], 512 );
            Move( A^[$1be], A^[$3be], 64 );
          end else
          begin
            P := @Boot;
            Move( P, A^[512], 512 );
            Move( A^[$0b], A^[$20b], 51 );
          end;
          ZFill := False;
          Write( Lst, Problems );
          Write( Problems );
        end;
        if not BiosDisk( DiskWrite, Dsk, 0, 1, 1, A^[512] ) then
        begin
          Write( Lst, UnCorrectable );
          Write( UnCorrectable );
          Break;
        end else
        begin
          Write( Lst, Cured ); Write( Cured );
          Inc( CorrectF );
          if ZFill then
          begin
            FillChar( A^, 512, 0 );
            BiosDisk( DiskWrite, Dsk, VirDh, VirCx, 1, A^ );
          end;
        end;
      end;
    end;
  until (OldInf=InfectF) or (OldCorr=CorrectF);
end;

procedure FindVirus( Dir : PathStr );
var
  ExeFile    : Boolean;
  SizeOfFile,
  lOfst      : Longint;
  wOfst,
  Nr, Nw,
  VirN       : Word;

function BlkRead( SeekPos : LongInt; var P; N : Word;
                  CheckLen : Boolean ) : Boolean;
begin
  BlkRead := True;
  if SeekPos < SizeOfFile then begin
    Seek( F, SeekPos ); BlockRead( F, P, N, Nr );
    if (Nr = 0) or (CheckLen and (Nr < N)) then begin
      WriteAccessDenied;
      BlkRead := False;
    end;
  end;
end;

procedure AssignedLst;
begin
  if Fname <> '' then Write( Lst, Dir );
end;

procedure COM_end;
var
  i     : Word;
  L     : Longint;
  LL    : array [0..1] of Word Absolute L;
  Ok    : Boolean;
  CutB  : Longint;

function BegNBytes( NBytes : Word ) : Boolean;
var F1 : File;
begin
  BegNBytes := False;
  Assign( F1, Dir );
  {FileMode := 0;}
  Reset( F1, 1 ); {FileMode := 2;}
  if IOResult <> 0 then
  begin
    WriteAccessDenied;
    Exit;
  end;
  Seek( F, 0 ); Seek( F1, NBytes );
  repeat
    BlockRead( F1, A^, Count, Nr );
    BlockWrite( F, A^, Nr, Nw );
  until ( Nr = 0 ) or ( Nw = 0 );
  Close( F1 );
  if ( Nr > 0 ) and ( Nw = 0 ) then
    WriteAccessDenied
  else
    BegNBytes := True;
end;
procedure EndNBytes( N, OfsNBytes : Word; TruncLen : Longint );
begin
  if N > 0 then
    begin
      Seek( F, 0 ); BlockWrite( F, A^[OfsNBytes], N, Nw );
    if Nw < N then
    begin
      WriteAccessDenied;
      Exit;
    end;
  end;
  CutB := SizeOfFile - TruncLen;
  Seek( F, TruncLen ); Truncate( F );
  if IOResult <> 0 then
    WriteAccessDenied
  else
    Ok := True;
end;
procedure EraseFile;
begin
  Inc( EraseF ); Write( Lst, Erased );
  Write( Erased );
end;

begin
  { Поиск вируса в файлах }
  VirN := VirSearch( C289_ASP );
  if VirN > 0 then
  begin
  AssignedLst;
  if (VirN in [14,20,21]) then 
    Dec( InfectF )
  else begin
    Write( Lst, Infected );
    Write( Infected );
  end;
  Write( Lst, Names[VirN] );
  Write( Names[VirN] );
  if Heal then begin
   FileMode := 2;
   Reset( F, 1 );
   Ok := False;
   case VirN of
    1:begin
        if BegNBytes( 289 ) then
          EndNBytes( 0, 0, SizeOfFile - 289 - 3 );
    end;
    2:begin
       if (SizeOfFile = 1024) then
       begin
         {YesOrNo;}
         EraseFile;
       end;
    end;
    3:begin
        EndNBytes( 3, $1c2, Longint(A^[$1ba]) shl 8 +
                            Longint(A^[$1b9]) );
    end;
    4:begin
        EndNBytes( 3, $1d6, Longint(A^[$1ce]) shl 8 +
                            Longint(A^[$1cd]) );
    end;
    5:begin
        EndNBytes( 3, wA^[1]+$a-wOfst-$100,
                      Longint(wOfst) );
    end;
    6:begin
       asm
         push ds
         mov  bx,sp
         lds  di,A
         add  di,22h
         mov  si,wOfst
         add  si,122h
         mov  sp,682h
        @loop:
         xor  [di],si
         xor  [di],sp
         inc  si
         inc  di
         dec  sp
         cmp  sp,672h
         jnz  @loop
         mov  sp,bx
         pop  ds
       end;
       EndNBytes( 3, $2e, wOfst );
     end;
     7:begin
         Writeln(Lst);
         Writeln;
     end;
     8:begin
         L := 2885; if ExeFile then Dec( L, 4 );
         if BlkRead( SizeOfFile - L, A^, $29, True ) then
         if not CheckMem( RCE2885_M_2c, A^ ) then
         begin
           Writeln( Lst, Problems );
           Writeln( Problems );
         end else begin
           LL[0] := wA^[3]; LL[1] := wA^[2];
           if ExeFile and (wA^[5] <> $5a4d) then begin
             Write( Lst, Uncorrectable );
             Write( Uncorrectable )
           end else
             EndNBytes( $20, 10, L );
         end;
     end;
     9:begin
         Writeln(Lst);
         Writeln;
     end;
    10:begin
        if BlkRead( SizeOfFile - 4912, A^, 4912, True )
        then
          EndNBytes( 4912, 0, SizeOfFile - 4912);
    end;
    11:begin
        asm
         les  di,A
         mov  cx,140h
         mov  dl,es:[di+0bh]
         mov  dh,dl
         add  di,23h
        @loop:
         xor  es:[di],dx
         inc  di
         inc  di
         loop @loop
       end;
       Writeln(Lst);
       Writeln;
   end;
   12:begin
      asm
       les  di,A
       mov  cx,15eh
       mov  dl,es:[di+0bh]
       mov  dh,dl
       add  di,23h
      @loop:
       xor  es:[di],dx
       inc  di
       inc  di
       loop @loop
      end;
      Writeln(Lst);
      Writeln;
    end;
    13:begin
        A^[$17e]:=A^[$17e] xor A^[$6b];
        A^[$17f]:=A^[$17f] xor A^[$6b];
        A^[$180]:=A^[$180] xor A^[$6b];
        A^[$181]:=A^[$181] xor A^[$6b];
        if Pos('COMMAND.COM', Dir) > 0 then
          EndNBytes( 4, $17e, SizeOfFile )
        else
          EndNBytes( 4, $17e, wOfst );
    end;
    14:begin
     if DelVac then
      if ExeFile then begin
       A^[$18+$14] := A^[$106];
       A^[$18+$15] := A^[$107];
       wA^[$81] := wA^[$81] - $10;
       A^[$18+$16] := A^[$102];
       A^[$18+$17] := A^[$103];
       wA^[($18+$2) div 2] := wA^[($18+$2) div 2] + $74; {Last}
       if wA^[($18+$2) div 2] >= $200 then
         wA^[($18+$2) div 2] := wA^[($18+$2) div 2] - $200
       else
         wA^[($18+$4) div 2] := wA^[($18+$4) div 2] - 1; {Pages}
       EndNBytes( $18, $18, lOfst );
      end else begin
       if Pos('MSCAN.COM', Dir) = 0 then begin
         EndNBytes( $18, $18, wOfst );
         A^[$f0] := A^[$f2];
         EndNBytes( 3, $ee, wOfst );
       end else begin Writeln(Lst); Writeln; end;
      end
     else begin Writeln(Lst); Writeln; end;
    end;
    15:begin
       Writeln(Lst);
       Writeln;
    end;
    16:begin
      EndNBytes( 4, $37b+3, SizeOfFile-927 );
    end;
    17:begin
       Writeln(Lst);
       Writeln;
    end;
    18:begin
        EndNBytes( 3, $1d2, wOfst );
    end;
    19:begin
       Writeln(Lst);
       Writeln;
    end;
    20: {COM file}
     if DelVac then begin
       if not ExeFile then begin
        if BlkRead( SizeOfFile - 41, A^, 14, True )
        then
          EndNBytes( 14, 0, SizeOfFile - 779 );
       end;
     end else begin
       Writeln(Lst); Writeln;
     end;
    21: {EXE file}
     if DelVac then begin
        Writeln(Lst); Writeln;
{       if ExeFile then begin
       end;}
     end else begin
        Writeln(Lst); Writeln;
     end;
    22:
    begin
      for i := 0 to 3 do
        A^[3037+i] := A^[3037+i] xor A^[$43];
      if ExeFile then
        EndNBytes( 24, 3037, SizeOfFile - 3061 )
      else
        EndNBytes( 4, 3037, SizeOfFile - 3061 );
    end;
    23:begin
        EndNBytes( 4, $49, wOfst );
    end;
    24, 25:begin
        if BlkRead( wOfst - 3, A^, 3, True )
        then
          EndNBytes( 3, 0, wOfst-3 );
    end;

   end; {case}
   if Ok then
   begin
     Write( Lst, '\', CutB, Cured );
     Write( '\', CutB, Cured );
     Inc( CorrectF );
   end;
   FileMode := 0;
  end else begin
   Writeln(Lst);
   Writeln;
   Exit;
  end;
  end;
{ Поиск анормального заражения вирусом }
  if Slow then begin
   Ok := False;
   if (SizeOfFile >= 9824) then
      if BlkRead( SizeOfFile - 4912, A^, 32, True ) then
        if CheckVirus( E4912_CNIT2 )
   then begin
     AssignedLst;
     Write( Lst, Infected, Names[10] );
     Write( Infected, Names[10] );
     if not Heal then begin
       Writeln(Lst); Writeln;
     end else begin
       FileMode := 2;
       Reset( F, 1 );
       EndNBytes( 0, 0, SizeOfFile-4912 );
       FileMode := 0;
     end;
   end;
   if Ok then
   begin
     Write( Lst, '\', CutB, Cured );
     Write( '\', CutB, Cured );
     Inc( CorrectF );
   end;
  end;
end;

var OldCorrectF,
    OldInfectF,
    OldEraseF  : Longint;
begin
  Assign(F, Dir);
  if Heal or DelVac then begin
    GetFTime( F, Time );
    GetFAttr(F, Attr);
    if DosError <> 0 then begin
      WriteAccessDenied;
      Exit;
    end;
    SetFAttr(F, $20);
    if (DosError <> 0) and (Drive >= 'C')
    then begin
      WriteAccessDenied;
      Exit;
    end;
  end;
  repeat
    OldInfectF := InfectF;
    OldCorrectF := CorrectF;
    OldEraseF := EraseF;
    Reset( F, 1 );
    if IOResult <> 0 then begin
      WriteAccessDenied;
      Break;
    end;
    SizeOfFile := FileSize( F );
    if SizeOfFile > 0 then
    begin
      FillChar( A^, Count, 0 );
      BlockRead(F, A^, 1024, Nr);
      if (Nr<SizeOfFile) and (SizeOfFile<=1024) then
        WriteAccessDenied
      else begin
        ExeFile := False;
        if (wA^[0]=$5a4d) then begin
          lOfst := ( (Longint(wA^[4]) + Longint(wA^[11])) shl 4 +
                     Longint(wA^[10]) ) and $fffff;
          if lOfst >= SizeOfFile then begin
           AssignedLst;
           Write( Lst, Corrupted ); Write( Corrupted ); Exit;
          end;
          if not BlkRead( lOfst, A^, Count, False ) then Exit;
          ExeFile := True;
          COM_end;
        end else
        if (wA^[0]=$ffff) then { SYS file }
        else
        if (A^[0]=$e9) then begin
          wOfst := Word(A^[1]) + Word(A^[2]) shl 8 + 3;
          if wOfst >= SizeOfFile then begin
           AssignedLst;
           Write( Lst, Corrupted );
           Write( Corrupted ); Exit;
          end;
          if not BlkRead( wOfst, A^, Count, False ) then Exit;
          COM_end;
        end else
          COM_end;
      end;
    end;
    Close( F );
  until ((DelVac=False) and (OldInfectF=InfectF)) or (OldCorrectF=CorrectF);
  if Heal or DelVac then begin
    if EraseF > OldEraseF then begin
      Erase( F );
      DosError := IOResult;
    end else begin
      SetFTime( F, Time ); Time := 0;
      SetFAttr( F, Attr ); Attr := 0;
    end;
    if DosError <> 0 then WriteAccessDenied;
  end;
end;

procedure AllDir( Dir : PathStr );
var
  SR : SearchRec;
  I  : Integer;
begin
  for I := J to J1 do begin
    FindFirst( Dir + SJoker[i], AnyFile-Directory-VolumeID, SR );
    while DosError = 0 do
      with SR do begin
        Write( Dir + Name );
        ClrEol; Inc( CountF );
        FindVirus( Dir + Name );
        Write(#13);
        FindNext( SR );
      end;
  end;
  FindFirst( Dir + SJoker[1], Directory, SR );
  while DosError = 0 do
    with SR do begin
      if (Name[1] <> '.') and
         (Attr = Directory)
      then
        AllDir( Dir + Name + '\' );
      FindNext( SR );
    end;
end;

procedure DisksCheck;
begin
  repeat
    Write( Lst, Check );
    Write( Check );
    if ParamStr(1) = '*' then begin
      Write( Lst, Drive+':');
      Write( Drive+':');
    end else begin
      Write(Lst, ParamStr(1));
      Write(ParamStr(1));
    end;
    Write(Lst, '"'#13#10);
    Write('"'#13#10);
    Disk_Check;
    AllDir( ParamS );
    Write(Lst, Drive+':'); Write( Drive+':'); ClrEol;
    Write(Lst, #13#10'Пеpевipено: ', CountF, #13#10,
                'Iнфiковано: ', InfectF,#13#10#13#10 );
    Write(#13#10'Пеpевipено: ', CountF, #13#10,
                'Iнфiковано: ', InfectF,#13#10#10 );
    if Heal or DelVac then
    begin
      Write(Lst, 'Виправлено: ', CorrectF, #13#10,
            'Знищено   : ', EraseF,#13#10#13#10 );
      Write('Виправлено: ', CorrectF, #13#10,
            'Знищено   : ', EraseF,#13#10#10 );
    end;
    if not Infct then
      Infct := InfectF > 0;
    Inc( Drive );
    ParamS := Drive + ':\';
    CountF := 0; InfectF := 0;
    CorrectF := 0; EraseF := 0;
  until (not AllDisks) or (Drive>LastDrive);
  if Inf > 0 then begin
    Write(#10'Рекомендовано перезавантаження DOS. Перезавантажити(Y/n)?');
    if (Byte(ReadCh) and $df) <> Byte('N') then
      asm
        db 0eah
        dw 0fff0h,0f000h
      end;
  end
end;

procedure SelfCheck;
var
  S : String;
  F : File of byte;
begin
  S := ParamStr(0);
  if S = '' then S := SelfName;
  Assign( F, S );
  Reset( F );
  if IOResult <> 0 then
  begin
    Write(Lst,  S, AccessDenied );
    Write( S, AccessDenied );
    Halt(1);
  end;
  if FileSize( F ) <> SelfLen then
  begin
    Write(Lst,  S, ' пошкоджено : довжина змiнилася на ',
           FileSize(F)-SelfLen,' байт');
    Write( S, ' пошкоджено : довжина змiнилася на ',
           FileSize(F)-SelfLen,' байт');
    Close( F );
    Heal := True; {FileMode := 2;}
    FindVirus( S );
    if InfectF = 0 then begin
      Write(Lst, #13#10);
      Write(#13#10);
      Halt(253);
    end;
    Heal := False; {FileMode := 0;}
  end else Close( F );
end;

procedure GetCommand;
var
  I, Attr: Word;
  F: File;
begin
  if (ParamCount = 0) then Help;
  for I := 2 to ParamCount do begin
    ParamS := ParamStr(I);
    if ParamS[1] = '/' then
      case UpCase(ParamS[2]) of
        'P': begin
               FName := Copy( ParamS, 3, Ord(ParamS[0])-2 );
               if FName = '' then FName := 'PRN';
               {FileMode := 2;}
               Assign( Lst, FName );
               Rewrite( Lst );
               {FileMode := 0;}
               if IOResult <> 0 then begin
                 Assign( Lst, 'NUL' ); Rewrite( Lst );
               end else
                 Writeln( Lst, 'ASP_HEAL версiя ',
                          Version:6,' вiд ', Date:10 );
             end;
        'G': begin
               Global := True;
               J := 1; J1 := 1;
             end;
        'F': begin
               Heal := True;
               {FileMode := 2;}
             end;
        'S': Slow := True;
        'X': begin
               DelVac := True;
               {FileMode := 2;}
             end;
        else Help;
      end;
  end;
  ParamS := ParamStr( 1 );
  if ParamS[1] = '/' then Help;
  if ParamS = '*' then begin
    AllDisks := True; ParamS := 'C:\';
  end else begin
    if ((ParamS[0]=#2) and (ParamS[2]=':')) then
      ParamS := ParamS + '\'
    else begin
      Assign(F, ParamS);
      GetFAttr(F, Attr);
      if (DosError=0) and (Attr and Directory <> 0) then
      begin
        if (ParamS[Ord(ParamS[0])] <> '\') then
          ParamS := ParamStr(1) + '\';
      end else begin
        repeat
          i := Pos( '\', ParamS );
          if i > 0 then Delete( ParamS, 1, i );
        until ( i = 0 );
        if ParamS <> '' then begin
          i := Ord( ParamS[0] );
          if i > 12 then
            i := 0
          else begin
            J := 2; J1 := 2;
            Move( ParamS, SJoker[J], i+1 );
          end;
          ParamS := ParamStr(1);
          Delete( ParamS, Ord( ParamS[0] )+1-i, 255 );
        end else
          ParamS := ParamStr(1);
      end;
    end;
  end;
  if ParamS[2]=':' then
    Drive := UpCase( ParamS[1] )
  else
    Drive := DefaultDrive;
end;

Begin
 {$IFDEF FinalCompile}
  SelfCheck;
 {$ENDIF}
  GetCommand;
  Mem_Virus;
  DisksCheck;
End.