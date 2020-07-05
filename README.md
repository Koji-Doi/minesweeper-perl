# minesweeper-perl

## NAME
       Minesweeper in perl

## SYNOPSIS
       minesweeper.pl [width] [height] [mines]

       minesweeper.pl -r

## OPTIONS
       1 width     -- board width (the number of column of game board). Default is 6.
       2 height    -- board height (the number of row of game board). Default is 6.
       3 mines     -- the number of mines. Default is 4.

## HOW TO PLAY
       When you start the game, the board appears in the upper left corner of the screen.
       This is a "minefield".  On the top, bottom, left and right of the board is a single
       letter that represents the coordinates of the square.  A prompt will appear below it.

       Instead of using the mouse, the player must advance through the game by typing a
       command after this prompt.
          
## Command
       Three pattern of command can be input here; Open cell, Set flag, and Reset flag.

       Open cell

       You can enter the coordinates of the square to be opened in column(x) and row(y)
       order without spaces.  For example, if you want to specify x=5 and y=2, just enter
       52.

       Set flag

       Reset flag

## Ending
       When all mines are correctly marked or a cell with mine is opened, the game is ended
       and game records are displayed.  When you win, records are updated.
       
