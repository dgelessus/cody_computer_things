1 REM SPDX-License-Identifier: GPL-3.0-or-later
9 REM Starting character
10 S = 30
19 REM Number of characters per row
20 C = 256
100 FOR I = S TO 219
110 REM Calculate column number for the character to ensure vertical alignment
120 W = (MOD(I - S, C) + 1) * 4 - 1
130 PRINT I, TAB(W), CHR$(I);
140 REM Force line break after C characters
150 IF MOD(I - S, C) = C - 1 THEN PRINT
160 NEXT
170 REM Reset text color to black
180 PRINT CHR$(240)
