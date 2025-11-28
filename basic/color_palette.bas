1 REM SPDX-License-Identifier: GPL-3.0-or-later

199 REM Init H array for hex conversion
200 FOR I = 0 TO 9
210 H(I) = I + 48
220 NEXT
250 FOR I = 10 TO 15
260 H(I) = I + 55
270 NEXT

955 REM Turn off INPUT prompt
960 POKE 14, 0

965 REM Clear screen to blue
970 PRINT CHR$(230, 222);

975 REM Set border color to blue
980 POKE 53250, OR(AND(PEEK(53250), 240), 6)

1000 FOR J = 0 TO 3
1100 FOR I = 0 TO 3
1200 C = 4*J + I
1210 X = 8*I + 4
1220 Y = 4*J + 4
1300 PRINT AT(X, Y), CHR$(224+C), "        ", CHR$(230);
1310 PRINT AT(X, Y+1), CHR$(224+C), "  ", CHR$(H(C)), "  ", CHR$(240, H(C), 241), "  ", CHR$(230);
1320 PRINT AT(X, Y+2), CHR$(224+C), "        ", CHR$(230);
1330 PRINT AT(X, Y+3), CHR$(224+C), "        ", CHR$(230);
1700 NEXT
1800 NEXT

1900 INPUT T$

1955 REM Reset colors
1960 PRINT CHR$(230);
1970 POKE 53250, OR(AND(PEEK(53250), 240), 7)
