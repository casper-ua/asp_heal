Unit ASP_Def;
Interface
Uses
  Dos;
const
  Version = '22+.f';
  Date = '28.01.1997';
  SelfName : String[12] = 'ASP_HEAL.EXE';
  SelfLen = 12913;
  SJoker : array [ 1..5 ] of string[5] =
    ( '*.*', '*.SYS', '*.COM', '*.EXE', '*.OV?' );
  J  : Byte = 2;
  J1 : Byte = 5;
  Detect_Mem : String[18] = 'У пам''ятi вipус ';
  Cured      : String[15] = ' - ВИПРАВЛЕНО'#13#10;
  Detect_Disk: String[28] = 'Вipус у початковому сектоpi ';
  Infected   : String[13] = ' - хвоpий на ';
  Corrupted  : String[14] = ' - ЗIПСОВАНО'#13#10;
  Erased     : String[12] = ' - ЗНИЩЕНО'#13#10;
  AccessDenied : String[20] = ' - ПОМИЛКА ДОСТУПУ'#13#10;
  Uncorrectable : String[24] = ' - ВИПРАВИТИ НЕМОЖЛИВО'#13#10;
  ErRead1Sect : String[37] = 'Помилка читання початкового сектора'#13#10;
  Problems : String[13] = ' (є проблеми)';
  Check  : String[18] = #13#10'Пеpевipка "';
  CountF   : Longint = 0;
  InfectF  : Longint = 0;
  Infct    : Boolean = False;
  CorrectF : Longint = 0;
  EraseF   : Longint = 0;
  Global   : Boolean = False;
  Heal     : Boolean = False;
  Slow     : Boolean = False;
  DelVac   : Boolean = False;
  AllDisks : Boolean = False;
  Inf      : Word    = 0;
  Count   = 5120;
Type
  PDinAr= ^DinAr;
  DinAr = array [0..Count-1] of byte;
  wAr   = array [0..Count div 2-1] of word;
  ArOfMask = array [0..17] of byte;
  Array7 = array [0..7] of byte;

Const
  Names : array [1..25] of PChar =
{1} ('C289 (ASP#1)',
     'DIR-1024',
     'C780 (A&D Virus)',
     'C765 (GOV#1)',
     'C648 (Vienna)',
     'RC1701 (Cascade)',
     'RC1704 (Cascade)',
     'RCE2885 (Doodle2C)',
     'RCE4928 (XPEH)',
{10} 'E4912 (CNIT)',
     'RE606 (Magelan)',
     'RE666 (SillyRE/FAT)',
     'RC414 (QuickDragon)',
     ' - MScan Antivirus',
{15} 'RCE927 (Phonix)',
     'RCE927 (Phonix)',
     'RC663 (Tune)',
     'C469 (Khizhnjak)',
{19} 'RC510 (Devastator)',
     ' - Turbo Antivirus',
     ' - Turbo Antivirus (дивись документацiю)',
     'CE3061 (Demiurg)',
     'RC291 (Rom)',
     'RC677 (Lz)',
{25} 'RC693 (Lz)'
    );

  { ====== Бутовые вирусы ====== }
  AntiEXE : ArOfMask =
    ($0e,$17,$1,
     $33,$ff,$8e,$df,$c4,$16,$4c,0,$89,$16,$4c,$03,$8c,$06,$4e);
  EndMaskBoot : Byte = 0;

  { ===== Файловые  вирусы ===== }
  C289_ASP : ArOfMask =
  ($0e,$30,0,
   $2A,$2E,$43,$4F,$4D,$00,$BB,$00,$20,$B4,$4A,$CD,$21,$73,$03);
  Dir1024 : ArOfMask =
    ($0e,0,0,
     $bc,0,6,$ff,6,$eb,4,$31,$c9,$8e,$d9,$c5,6,$c1,0);
  C780_A_D : ArOfMask =
    ($0e,8,0,
     $a0,$d2,2,$2e,$a2,0,1,$a0,$d3,2,$2e,$a2,1,1,$a0);
  C765_Gov1 : ArOfMask =
    ($0e,8,0,
     $a0,$e6,2,$2e,$a2,0,1,$a0,$e7,2,$2e,$a2,1,1,$a0);
  C648_Vienna : ArOfMask =
    ($0e,4,0,
     $fc,$8b,$f2,$81,$c6,$0a,0,$bf,0,1,$b9,3,0,$f3,$a4);
   { $8b,$f2,$b4,$30,$cd,$21,$3c,$00 }
  RC1701_Cascade : ArOfMask =
    ($0e,$13,0,
     $8d,$b7,$4d,$01,$bc,$82,$06,$31,$34,$31,$24,$46,$4c,$75,$f8);
  RC1704_Cascade : ArOfMask =
    ($0e,$13,0,
     $8d,$b7,$4d,$01,$bc,$85,$06,$31,$34,$31,$24,$46,$4c,$75,$f8);
                                             { RC1704f - $77 } 
  RCE2885_M2C : ArOfMask =
    ($0e,0,0,
     $e8,0,0,$5b,$81,$eb,$d4,7,$2e,$c6,$87,$5c,0,$ff,$fc);
  RCE4928_XPEH : ArOfMask =
    ($0e,0,0,
     $e8,0,0,$5b,$81,$eb,$86,9,$50,$56,$57,$2e,$c6,$87,$7a);
  E4912_CNIT : ArOfMask =
    ($0e,0,0,
     $9a,0,0,$6e,0,$55,$89,$e5,$81,$ec,2,2,$c6,6,$bc);
  RE606_Magelan : ArOfMask =
    ($0e,$0c,0,
     $8c,$d3,$fa,$8b,$ec,$0e,$17,$8b,$e6,$83,$c4,$23,$58,$32,$e2);
  RE666_FAT : array [0..25] of byte =
    ($16,$0c,0,
     $8C,$D5,$FA,$8B,$DC,$0E,$17,$8B,$E6,$83,$C4,$23,$5A,$32,$F0,
     $32,$D0,$52,$FA,$44,$44,$E2,$F5);
  RC414_414 : array [0..25] of byte =
    ($16,$70,0,
     $FA,$56,$57,$51,$53,$50,$06,$1E,$52,$FB,$3D,$00,$4B,$74,$25,$80,
     $FC,$4F,$75,$1D,$B4,$2F,$CD);
  MScan_Vac : array [0..25] of byte =
    ($16,0,0,$B4,$52,$CD,$21,$26,$8B,$7F,$04,$26,$C4,$7D,$FC,$4F,$26,
     $81,$7D,$FE,$8A,$E1,$75,$F7,$E8,$72);
  _Phonix_Exe : array [0..25] of byte =
    ($16,$1d,0,$E8,$00,$00,$5E,$81,$C6,$7B,$03,$BF,$00,$01,$B9,$04,
     $00,$F3,$A4,$E8,$09,$00,$0E,$1F,$0E,$07);
  _Phonix : array [0..25] of byte =
    ($16,0,0,$E8,$00,$00,$5E,$81,$C6,$7B,$03,$BF,$00,$01,$B9,$04,
     $00,$F3,$A4,$E8,$09,$00,$0E,$1F,$0E,$07);
  _Tune : array [0..25] of byte =
    ($16,0,0,$EB,$03,$90,$17,$22,$B8,$21,$35,$CD,$21,$BE,$08,$00,
     $26,$81,$3C,$17,$22,$74,$48,$8C,$C8,$48);
  _Khizhnjak : array [0..25] of byte =
    ($16,8,0,$B9,$03,$00,$33,$DB,$8A,$87,$E2,$02,$2E,$88,$87,$00,
     $01,$43,$E2,$F4,$B9,$00,$01,$33,$DB,$2E);
  _Devastator : array [0..25] of byte =
    ($16,0,0,$B4,$74,$CD,$21,$32,$C4,$74,$51,$1E,$8E,$C3,$BF,$00,
    $05,$F3,$A5,$53,$53,$1F,$BB,$C2,$06,$8B);
  _tnt : array [0..10] of byte =
    ($08,0,0,$E9,$FA,$FC,$4D,$73,$44,$6F,$73);
  __tnt : array [0..25] of byte =
    ($16,$23,$00,$5B,$81,$EB,$03,$01,$50,$51,$52,$56,$57,$8B,
     $EB,$1E,$2E,$C6,$86,$35,$04,$00,$26,$8E,$06,$2C);
  _Demiurg : array [0..25] of byte =
    ($16,6,0,$33,$C0,$8E,$D8,$A1,$9C,$00,$2E,$89,$85,$28,$09,$A1,
    $9E,$00,$2E,$89,$85,$2A,$09,$8D,$95,$2B);
  _Rom : array [0..25] of byte =
    ($16,0,0,$E8,$00,$00,$5E,$83,$EE,$03,$06,$33,$C0,$8E,$C0,$26,
     $3B,$06,$86,$00,$74,$1D,$1E,$26,$C5,$06);
  _Lz677 : array [0..25] of byte =
    ($16,2,0,$00,$5E,$83,$EE,$06,$BF,$00,$01,$B9,$03,$00,
     $F3,$A4,$B4,$FE,$CD,$21,$80,$FC,$4C,$74,$72,$B4);
  _Lz693 : array [0..25] of byte =
    ($16,2,0,0,$5E,$83,$EE,$06,$BF,$00,$01,$B9,$03,$00,$F3,$A4,$B4,
     $FE,$CD,$21,$80,$FC,$4C,$74,$71,$B4);

  EndMsk : Byte = 0;
  {======================}
  { Дополнительные маски }
  RCE2885_M_2c : array [0..6] of byte = (3,0,0,244,122,44,0);
  E4912_CNIT2 : ArOfMask =
    ($0e,0,0,
     $4d,$5a,48,1,10,0,57,0,16,0,253,2,253,2,224);

  { Резидентные вирусы }
  MagMem    : ArOfMask =
    ($0e,0,0,                      { $eb,$05 - desactive }
     $80,$fc,$87,$74,$f8,$80,$fc,$4e,$74,$0a,$80,$fc,$4f,$74,$0b);
  FATMem    : ArOfMask =
    ($0e,0,0,
     $80,$fc,$88,$74,$f8,$80,$fc,$4e,$74,$30,$80,$fc,$4f,$74,$31);
  PhonixMem : ArOfMask =
    ($0e,0,0,
     $80,$fc,$11,$75,$03,$e9,$e2,$01,$80,$fc,$4e,$75,$03,$e9,$da);
  DoodleMem : ArOfMask =
    ($0e,0,0,      { $90,$90 - desactive }
     $9c,$80,$fc,$4b,$74,$23,$80,$fc,$c5,$74,$1b,$3d,$00,$c6,$74);
  RomMem : ArOfMask =
    ($0e,0,0,
     $51,$57,$50,$56,$06,$2E,$C7,$06,$27,$03,$00,$00,$8B,$FA,$B9);
     { 0122 ea 0123-0126 addr int 21h }

Var
  OldExitProc : Pointer;
  Drive    : Char;
  ParamS   : ComStr;
  F        : File;
  FRec     : FileRec Absolute F;
  FName    : ComStr;
  Lst      : Text;
  A        : PDinAr;
  wA       : ^wAr absolute A;
  Attr     : Word;
  Time     : Longint;

procedure WriteAccessDenied;
procedure Help;

Implementation

procedure WriteAccessDenied;
begin
  Write( Lst, AccessDenied );
  Write( AccessDenied );
end;

function HeapFunc( Size : Word ): Integer; far;
begin
  if Size > 0 then
    HeapFunc := 1;
end;

procedure _Exit; far;
begin
  if (ErrorAddr <> nil) or (ExitCode = 255 ) then begin
    ErrorAddr := nil;
    if ExitCode = 254 then
      Write(#13#10'**** Мало пам''ятi ****'#13#10)
    else begin
      if ExitCode = 255 then begin
      with FRec do begin
        Write(#13#10'**** Перервано по Ctrl-Break ****'#13#10);
          if Mode=fmInOut then Close( F );
          if Heal and (Mode=fmClosed) then
          begin
            if Attr <> 0 then SetFAttr( F, Attr );
            if DosError <> 0 then WriteAccessDenied;
            if Time <> 0 then SetFTime( F, Time );
          end;
      end end else
        Write(#13#10'**** Неноpмальне завеpшення(',ExitCode,') ****'#13#10);
      if Assigned(A) then FreeMem( A, Count );
    end;
  end else if Assigned(A) then FreeMem( A, Count );
  if Infct then ExitCode := 1;
  Close( Lst );
  ExitProc := OldExitProc;
end;

function TrueDosVersion : Word; Assembler;
asm
  mov ax,3306h
  int 21h
  cmp ax,3306h
  mov ax,bx
  je @Dos5
  mov ax,3000h
  int 21h
 @Dos5:
end;

procedure Help;
begin
 Write( #13#10,
  'Виклик: ASP_HEAL path [/F [/X]] [/G] [/S] [/P[FileName]], де'#13#10,
  '  path - обов''язковий паpаметp, який задає пiдмножину файлiв для перевiрки'#13#10,
  '         (* - перевiрити всi диски, починаючи з C:)'#13#10,
  '  /F - лiкувати iнфiкованi пpогpами та знищувати безнадiйно зiпсованi'#13#10,
  '       ( /F /X - знищувати вакцини )'#13#10,
  '  /G - перевiрити всi файли (не тiльки COM, EXE, SYS, OV?)'#13#10,
  '  /S - повiльна перевiрка для виявлення зiпсованих вiрусiв'#13#10,
  '  /P[FileName] - видати протокол на друк [або у файл FileName]'#13#10{,
  '  /C - циклiчна перевiрка гнучких дискiв'#13#10'}
 );
 Halt(3);
end;

function DefaultDrive : Char; Assembler;
asm
  mov ah,19h
  int 21h
  add al,41h
end;

Begin
  OldExitProc := ExitProc;
  HeapError := @HeapFunc;
  ExitProc := @_Exit;
  FileMode := 0;
  Attr := 0; Time := 0;
  A := nil;
  FName := ''; Assign( Lst, 'NUL' ); Rewrite( Lst );
  Write('╔══════════════════════════════════════╗'#13#10,
        '║          А н т и в i p у с           ║'#13#10,
        '║           A S P _ H E A L            ║ Ви можете отримати допомогу, звер-'#13#10,
        '║    Веpсiя ', Version : 6,
                       ' вiд  ', Date:10 ,'     ║ нувшися ( письмово!!! ) за адресою,'#13#10,
        '║        Copyright (C) 1992-97         ║ яка вказана в документацiї.'#13#10,
        '║   Андpiй С. Панков, Хаpкiв, Укpаїна  ║'#13#10,
        '╚══════════════════════════════════════╝'#13#10);
  if (Lo(TrueDosVersion) < 3) or (Lo(TrueDosVersion) > 6)
  then begin
    Writeln('Пiдтpимуються лише MS-DOS веpсiй 3.x - 6.x');
    Halt(2);
  end;
  GetMem( A, Count );
  if A = nil then RunError(254);
End.