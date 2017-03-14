{Program  : PCX-Viewer for 256 color images} 
{Version  : 3.1, last update: 18.7.96} 
{Language : Turbo-Pascal 6.0} 
{Author   : Moritz Mertinkat} 
{eMail    : Moehrchen@T-ONLINE.DE}

{You may freely copy and modify this program, but please eMail me, if 
 you make changes or improvements. Thank you!!}

{$X+} 
Uses DOS, Crt; 
Const 
  BufferSize = 4096;

Type 
  HeaderTyp = RECORD 
    Kennung, 
    Version, 
    Kodierung, 
    Bits_Pixel  :  Byte; 
    X_Start, 
    Y_Start, 
    X_Ende, 
    Y_Ende, 
    X_Auloesung, 
    Y_Auloesung  :  Word; 
    Palette_16  :  ARRAY[1..48] OF Byte; 
    Reserviert, 
    Anz_Ebenen  :  Byte; 
    Bytes_Zeile, 
    Paletten_Typ  :  Word; 
    Dummy  :  ARRAY[1..58] OF Byte; 
  END;

Var 
  NumRead, Counter: Word; 
  Header: HeaderTyp; 
  X_Ende_2: Word; 
  Lauf1, Lauf2, X, Y: Word; 
  Datei:  File; 
  Buffer:  ARRAY[1..BufferSize] OF Byte; 
  Farbe, Faktor:  Byte; 
  RGB_Palette: ARRAY[0..255] of Record 
                                  Red, 
                                  Green, 
                                  Blue: Byte 
    end;

Procedure Abort(Msg: String); 
begin 
  Writeln(Msg); 
  Writeln; 
  halt; 
end;

begin 
  Writeln('PCX-VIEW, Version 3.1, Coded by Moehrchen@T-Online.de, *FREEWARE*'); 
  If ParamCount < 1 then Abort('Syntax: PCXVIEW <pcxfile.pcx>'); 
  Assign(Datei, ParamStr(1)); 
  {$I-} 
    Reset(Datei, 1); 
  {$I+} 
  Case IOResult of 
    2: Abort('ERROR: File not found - '+ParamStr(1)); 
    3: Abort('ERROR: Path not found!'); 
    5: Abort('ERROR: Access denied - cannot open pcx-file!'); 
    8: Abort('ERROR: Not enough memory to open file!'); 
  end;

  BlockRead(Datei, Header, SizeOf(Header), NumRead); 
  If NumRead <> SizeOf(Header) then 
    Abort('ERROR: PCX-Header damaged!');

  X_Ende_2:= Header.Bytes_Zeile;

  If Header.Kennung <> 10 then Abort('ERROR: Inputfile is NOT a valid PCX-File!'); 
  If Header.Version <> 5 then Abort('ERROR: Wrong PCX-Version!');

  If (Header.Bits_Pixel = 8) and (Header.Anz_Ebenen = 3) then 
    Abort('ERROR: 24-Bit images are NOT supported!');

  If (Header.Bits_Pixel = 1) and (Header.Anz_Ebenen = 4) then 
    Abort('ERROR: 16 color images are NOT supported!');

  If (Header.Bits_Pixel = 1) and (Header.Anz_Ebenen = 1) then 
    Abort('ERROR: 2 color images are NOT supported!');

  ASM; 
    MOV AX, $30          {13h = 320x200x256; 2Eh = 640x480x256} 
    INT 10h              {30h = 800x600x256; 38h = 1024x768x256} 
  END;

  Seek(Datei, FileSize(Datei)-256*3-1); 
  BlockRead(Datei, Buffer, 256*3+1); 
  Lauf1:= 1; 
    FOR Lauf2 := 0 TO 255 DO 
     BEGIN 
 RGB_Palette[Lauf2].Red := Buffer[1+Lauf1] div 4; 
        RGB_Palette[Lauf2].Green := Buffer[1+Lauf1+1] div 4; 
 RGB_Palette[Lauf2].Blue := Buffer[1+Lauf1+2] div 4; 
 Inc(Lauf1, 3); 
     END; 
  ASM 
    MOV AH, 10h 
    MOV AL, 12h 
    XOR BX, BX 
    MOV CX, 100h 
    MOV DX, Seg(RGB_Palette) 
    MOV ES, DX 
    MOV DX, Offset(RGB_Palette) 
    INT 10h 
  END; 
  Seek(Datei, 128);      { Jump to the end of the pcx-header }

  Y:= 0; 
  X:= 0;

  Counter:= 4096;

  While (Y < Header.Y_Ende-1) and (Port[$60] > $80) do 
  begin 
    Inc(Counter); 
    If Counter > BufferSize then 
    begin 
      BlockRead(Datei, Buffer, BufferSize, NumRead); 
      Counter:= 1; 
    end;

    If Buffer[Counter] >= 192 then 
    begin 
      Faktor:= Buffer[Counter]-192; 
      Inc(Counter); 
      If Counter > BufferSize then 
      begin 
        BlockRead(Datei, Buffer, BufferSize, NumRead); 
        Counter:= 1; 
      end; 
      Farbe:= Buffer[Counter]; 
    end 
    else 
    begin 
      Faktor:= 1; 
      Farbe:= Buffer[Counter]; 
    end;

    For Lauf1:= 1 to Faktor do 
    begin 
      If X = X_Ende_2 then 
      begin 
        Inc(Y); 
        X:= 0; 
      end; 
      ASM; 
        MOV AH, $0C 
        MOV AL, Farbe 
        MOV BH, 0 
        MOV CX, X 
        MOV DX, Y 
        INT 10h 
      END; 
      Inc(X) 
    end; 
  end; 
  ReadKey; 
  ASM 
    MOV AX, $3; 
    INT 10h 
  END; 
  Close(Datei); 
End.
