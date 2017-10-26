{$A-,B-,D+,E-,F+,G-,I-,L+,N-,O-,P-,Q-,R-,S-,T-,V-,X+,Y+}
Unit ASP_Util;
interface
uses
  Dos,
  ASP_Def;
type
  EBpb = record { Extended BIOS Parametrs Block }
          sectsize  : word;
          clustsize : byte;
          ressecs   : word;
          fatcnt    : byte;
          rootsecs,
          totsecs   : word;
          media     : byte;
          fatsize,
          seccnt,
          headcnt,
          hiddensec_low,
          hiddensec_hi : word;
          drvsecs   : longint;
  end;
  DPB = record
           spec,
           devtype : byte;
           devattr,
           numofcyl: word;
           media_type : byte;
           bpb : ebpb;
           reserv : array [0..5] of byte;
         end;
const
  DiskRead = 2;
  DiskWrite = 3;

procedure MBR;
procedure Boot;
function TrueDosVersion : Word;
{ Get True MS-DOS Version }
function DefaultDrive : Char;
function NumberOfDrives : Char;
procedure SelectDrive( Drv : Char );
function LastDrive : Char;
procedure ClrEol;
function BiosDisk( Funct, Drive, Head : Byte;
                   TrackSector : Word; NSectors : Byte;
                   Var Buffer ) : Boolean;
function NFloppies : Byte;
function DevType( NDrv : byte ) : byte;
function ResolvePathStr( PStr : ComStr ) : ComStr;
function ReadCh : Char;
function CheckMem( Var Msk; Var P ) : Boolean;
function VirSearch( var Msk ) : Word;
function CheckVirus( Var Msk ) : Boolean;
procedure DesactivResident( var SegX, OfsX : Word; SegOld, OfsOld : Word );

implementation
procedure MBR; External;
{$L MBR.OBJ}
procedure Boot; External;
{$L BOOT.OBJ}
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
function DefaultDrive : Char; Assembler;
asm
  mov ah,19h
  int 21h
  add al,41h
end;
function NumberOfDrives : Char; Assembler;
asm
  mov ah,19h
  int 21h
  mov dl,al
  mov ah,0eh
  int 21h
  add al,41h
end;
procedure SelectDrive( Drv : Char ); Assembler;
asm
  mov dl,Drv
  cmp dl,7ah
  ja  @exit
  cmp dl,61h
  jb  @sub2
  sub dl,20h
@sub2:
  sub dl,41h
  mov ah,0eh
  int 21h
@exit: end;

function LastDrive : Char;
var D, DType : Byte;
begin
  D := 1;
  repeat
    DType := DevType( D );
    Inc( D );
  until DType = $0ff;
  LastDrive := Chr( D + Ord('>') );
end;
procedure ClrEol; Assembler;
const
  WindMax = $4f;
asm
  mov ah,3
  xor bh,bh
  int 10h
  mov ax,0600h
  mov bh,07h
  mov cx,dx
  mov dl,WindMax
  int 10h
end;
function BiosDisk( Funct, Drive, Head : Byte;
                   TrackSector : Word; NSectors : Byte;
                   Var Buffer ) : Boolean; Assembler;
asm
  mov di,3
  mov dl,Drive
  mov dh,Head
  mov cx,TrackSector
 @loop:
  les bx,Buffer
  mov al,NSectors
  mov ah,Funct
  push di
  int 13h
  pop di
  mov al,True
  jnc @ex
  xor ax,ax
  int 13h
  dec di
  jnz @loop
  mov al,False {=0}
 @ex:
end;
function NFloppies : Byte; Assembler;
asm
  int 11h
  and al,11000000b
  mov cl,6
  shr al,cl
  inc al
end;
function DevType( NDrv : byte ) : byte; Assembler;
label Er;
var
  _DPB : DPB;
asm
   push ds
   push ss
   pop ds
   lea dx,_DPB
   mov _DPB.spec,0
   mov ax, 440dh
   mov cx,0860h
   mov bl,NDrv
   int 21h
   mov al,0ffh
   jc @er
   mov al,_DPB.devtype
   @er:
   pop ds
  end;

function ResolvePathStr( PStr : ComStr ) : ComStr;
var
  _i     : Byte;
  _PStr  : ComStr;
  _PStr1 : array [1..128] of Char;
begin
  ResolvePathStr := ''; DosError := 0;
  FillChar( _PStr[0], SizeOf(_PStr), 0 );
  Move( PStr[1], _PStr[0], Ord(PStr[0]) );
  asm
    push ds
    push ss
    push ss
    pop ds
    lea si,_PStr
    pop es
    lea di,_PStr1
    mov ah,60h
    int 21h
    pop ds
    jnc @cont
    mov DosError,ax
   @cont:
  end;
  if DosError = 0 then begin
    _i := 1;
    while (_PStr1[_i] <> #0) and (_i <= 128)
      do Inc(_i); Dec(_i);
    if (_i = 0) or (_i = 128) then
      DosError := MaxInt
    else begin
      Move( _PStr1, _PStr[1], _i );
      _PStr[0] :=Chr(_i);
      ResolvePathStr := _PStr;
    end;
  end;
end;

function ReadCh : Char; Assembler;
asm
  mov ah,0
  int 16h
end;

function CheckMem( Var Msk; Var P ) : Boolean; Assembler;
asm
  push ds
  xor ax,ax  {False}
  lds si,Msk
  les di,P
  xor cx,cx
  mov cl,[si]
  add si,3
  cld
  repe cmpsb
  pop ds
  jne @exit
  mov al,True
@exit:
end;

function VirSearch( Var Msk ) : Word; Assembler;
asm
  mov bx,ds
  xor ax,ax
  lds si,Msk
  mov cx,-1
  cld
@loop:
  inc ax
  add si,cx
  inc si
  xor cx,cx
  mov cl,[si]
  inc si
  or cl,cl
  jz @last
  les di,A
  add di,[si]
  inc si
  inc si
  repe cmpsb
  jne @loop
  mov ds,bx
  inc word ptr InfectF
  jnz @exit
  inc word ptr InfectF+2
  jmp @exit
@last:
  xor ax,ax
  mov ds,bx
@exit:
end;

function CheckVirus( Var Msk ) : Boolean; Assembler;
asm
  push ds
  lds si,Msk
  xor cx,cx
  mov cl,[si]
  inc si
  les di,A
  add di,[si]
  inc si
  inc si
  xor ax,ax  {False}
  cld
  repe cmpsb
  pop ds
  jne @exit
  inc ax     {True}
  lea si,InfectF
  inc word ptr [si]
  jnz @exit
  inc word ptr [si+2]
 @exit:
end;

procedure DesactivResident( var SegX, OfsX: Word; SegOld, OfsOld : Word );
begin
  Mem[SegX:OfsX] := $ea;
  MemW[SegX:OfsX+1] := OfsOld;
  MemW[SegX:OfsX+3] := SegOld;
  Write( Lst, Cured );
  Write( Cured );
  SegX := SegOld; OfsX := OfsOld;
end;

end.
