1 REM SPDX-License-Identifier: GPL-3.0-or-later
9 REM Start address
10 A = 0
19 REM End address (inclusive)
20 B = 255
29 REM Number of lines to print at once
30 L = 16
59 REM Turn off INPUT prompt
60 POKE 14, 0
88 REM Number of lines left to print
89 REM (user is prompted once this reaches 0)
90 N = L
100 PRINT A;
109 REM Column number for next byte
110 C = 7
120 PRINT TAB(C), PEEK(A);
130 IF A = B THEN GOTO 500
140 A = A + 1
150 C = C + 4
160 IF C <= 35 THEN GOTO 120
200 N = N - 1
210 IF N = 0 THEN GOTO 300
220 PRINT
230 GOTO 100
300 PRINT TAB(38);
310 INPUT Q
320 IF Q > 0 THEN L = Q
330 GOTO 90
500 PRINT

