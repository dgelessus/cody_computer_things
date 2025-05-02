1 REM SPDX-License-Identifier: GPL-3.0-or-later

5 REM === Parameters ===

9 REM Start address
10 A = 0

19 REM End address (inclusive)
20 B = 255

29 REM Number of lines to print at once
30 L = 16

95 REM === Initialization ===

99 REM Turn off INPUT prompt
100 POKE 14, 0

199 REM Init H array for hex conversion
200 FOR I = 0 TO 9
210 H(I) = I + 48
220 NEXT
250 FOR I = 10 TO 15
260 H(I) = I + 55
270 NEXT

995 REM === Main loop ===

998 REM Number of lines left to print
999 REM (user is prompted once this reaches 0)
1000 N = L

1003 REM Read next line from memory into temp array
1004 REM X will be set to 0 when end reached
1005 X = 1
1007 FOR I = 0 TO 7
1009 REM End already reached in a previous iteration?
1010 IF X = 0 THEN GOTO 1060
1020 V(I) = PEEK(A + I)
1029 REM Was this the last byte?
1030 IF A + I <> B THEN GOTO 1070
1039 REM "break"
1040 X = 0
1050 GOTO 1070
1059 REM Placeholder value for "past end of memory range"
1060 V(I) = -1
1070 NEXT

1079 REM Print address
1080 X = A
1090 GOSUB 2100

1099 REM Print hex values
1100 FOR I = 0 TO 7
1110 IF V(I) = -1 THEN GOTO 1190
1120 PRINT TAB(5 + 3*I);
1130 X = V(I)
1140 GOSUB 2000
1190 NEXT

1199 REM Print character values
1200 FOR I = 0 TO 7
1210 IF V(I) = -1 THEN GOTO 1390
1220 PRINT TAB(29 + I);
1230 X = V(I)
1240 IF X < 32 THEN GOTO 1300
1250 IF X > 194 THEN GOTO 1350
1260 PRINT CHR$(X);
1270 GOTO 1390
1300 PRINT CHR$(223, X + 64, 223);
1310 GOTO 1390
1350 PRINT CHR$(223, X - 128, 223);
1390 NEXT

1499 REM Stop if end reached during previous read
1500 IF V(7) = -1 THEN GOTO 1950
1509 REM Increase address
1510 A = A + 8
1519 REM Stop if end address reached
1520 IF A - 1 = B THEN GOTO 1950

1699 REM Tail of loop over lines
1700 N = N - 1
1710 IF N = 0 THEN GOTO 1900
1720 PRINT
1730 GOTO 1005

1899 REM Wait for user before continuing, prompt for new number of lines
1900 PRINT TAB(38);
1910 INPUT Q
1920 IF Q > 0 THEN L = Q
1930 GOTO 1000

1950 REM PRINT
1960 END

1995 REM === Subroutines ===

1999 REM Print X (0 to 255) as hex (2 digits)
2000 PRINT CHR$(H(X / 16)), CHR$(H(AND(X, 15)));
2010 RETURN

2099 REM Print X as unsigned hex (4 digits)
2100 X(1) = 0
2110 IF X < 0 THEN X(1) = 8
2120 X = AND(X, 32767)
2130 PRINT CHR$(H(X / 4096 + X(1))), CHR$(H(AND(X / 256, 15))), CHR$(H(AND(X / 16, 15))), CHR$(H(AND(X, 15)));
2140 RETURN
