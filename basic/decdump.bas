1 REM SPDX-License-Identifier: GPL-3.0-or-later
9 REM Start address
10 A = 0
19 REM End address (inclusive)
20 B = 255
89 REM Turn off INPUT prompt
90 POKE 14, 0
100 PRINT A;
109 REM Column number for next byte
110 C = 7
120 PRINT TAB(C), PEEK(A);
130 IF A = B THEN GOTO 200
140 A = A + 1
150 C = C + 4
160 IF C <= 35 THEN GOTO 120
170 PRINT TAB(38);
180 INPUT Q
190 GOTO 100
200 PRINT

