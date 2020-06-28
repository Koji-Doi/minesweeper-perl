#!/usr/bin/env perl
=head1 NAME

Minesweeper in perl

=head1 SYNOPSIS

minesweeper.pl [width] [height] [mines] [colormode]

=head1 OPTIONS

=over 4

=item 1 width     -- board width (the number of column of game board). Default is 6.

=item 2 height    -- board height (the number of row of game board). Default is 6.

=item 3 mines     -- the number of mines. Default is 4.

=item 4 colormode -- Set this option "rev" to set screen mode "reverse",
which might be suitable for terminal with white background.

=back

=head1 HOW TO PLAY

When you start the game, the board appears in the upper left corner of the screen. This is a "minefield". 
On the top, bottom, left and right of the board is a single letter that represents the coordinates of the square.
A prompt will appear below it. 

Instead of using the mouse, the player must advance through the game by typing a command after this prompt.

=head2 Command

Three pattern of command can be input here; Open cell, Set flag, and Reset flag.

=head3 Open cell

You can enter the coordinates of the square to be opened in row and column order without spaces.
For example, if you want to specify row 5, column 2, just enter 52.

=head3 Set flag

=head3 Reset flag

=head2 Ending


=cut

use strict;
use warnings;
use Data::Dumper;
use FindBin;
use Pod::Usage;

my($width, $height, $mine_num, $col) = @ARGV; # map width, map height, the number of mine, color mode
if($width=~/^-+h/){
  print pod2usage(-verbose => 2, -input => $FindBin::Bin . "/" . $FindBin::Script);
  exit();
}
$width     = $width    || 6;
$height    = $height   || 6;
$mine_num  = $mine_num || 4;
$col       = $col      || '256'; # '8', '256', '8rev', '256rev'; 'rev':board is displayed in reverse mode
srand(0);
# text color
my($color0, $color1) =
 ($col eq '8'     )?(["black"],   ["white"])
:($col eq '256'   )?([qw/0 0 0/], [qw/128 128 128/])
:($col eq '8rev'  )?(["black"],   ["white"])
:($col eq '256rev')?([qw/128 128 128/], [qw/0 0 0/]):'';
# cell color
my @color_n =([204,204,204], [64,64,255], [0,200,0], [255,0,0], [0,0,128], [152,0,0], [0,152,152], [0,0,0], [152,152,152]);

my $hit=0;    # the number of found mines
my $opened=0; # the numbef of opened cells
# make map
my @map;
my @map_open;
for(my $x=0; $x<=$width+1; $x++){
  $map[$x]=();
  for(my $y=0; $y<=$height+1; $y++){
    $map_open[$x][$y]=$map[$x][$y]=0;
  }
}

# set mines
for(my $i=1; $i<=$mine_num; $i++){
  my($x,$y);
  while(1){
    $x = int(rand($width))+1;
    $y = int(rand($height))+1;
    $map[$x][$y]<9 and last;
  }
  $map[$x-1][$y-1]++; $map[$x-1][$y]++; $map[$x-1][$y+1]++;
  $map[$x][$y-1]++;   $map[$x][$y]=9;   $map[$x][$y+1]++;
  $map[$x+1][$y-1]++; $map[$x+1][$y]++; $map[$x+1][$y+1]++;
}

# play
my @index = ('', '1'..'9', 'a'..'z', 'A'..'Z');
my %index;
map {$index{$index[$_]}=$_} 0..$#index;

cls();
color($color1, $color0);
map {locate($_, 0), cll()} (1..$height+4);
put(0,3, join('', @index[1..$width]));
map { put($_+2, 0, $index[$_]) } @index[1..$height];

PLAY: while(1){
  if($hit==$mine_num and $hit+$opened==$width*$height){
    err("Completed!!");
    last PLAY;
  }
  for(my $x=1; $x<=$width; $x++){
    for(my $y=1; $y<=$height; $y++){
      my $status = ($map_open[$x][$y]==2)?'+'
                  :($map_open[$x][$y]==1)?(($map[$x][$y]==0)?'_':$map[$x][$y])
                 :'.';
      put($y+2, $x+2, $status);
    }
  }
  my($cmd,$x,$y);
  while(1){
    message("[opened $opened] x,y?");
    locate($height+4,0); cll();
    my $in = <STDIN>;
# quit : quit game
# + X Y: mark cell at x,y
# - X Y: unmark cell at x,y
# X Y  : open cell at x,y and peripherals

    $in=~/quit/i and last PLAY;
    ($cmd, $x, $y) = $in=~/([-+])?\s*([\da-zA-Z])([\da-zA-Z])/;
    $cmd = $cmd || '';
    if((not defined $x) or (not defined $y)){
      err("Invalid command");
    }elsif((not exists $index{$x}) or (not exists $index{$y})){
      err("out of range");
    }elsif($index{$x}>$width){
      err("too big x");
    }elsif($index{$y}>$height){
      err("too big y");
    }else{
      ($x, $y) =($index{$x}, $index{$y}); last;
    }
  }
  if($cmd eq '+'){
    if($map_open[$x][$y]==0){
      if($map[$x][$y]>=9){
        $hit++;
      }
      $map_open[$x][$y]=2; # mark cell
    }
  }elsif($cmd eq '-'){
    ($map_open[$x][$y]==2) and $map_open[$x][$y]=0;
  }else{
    if($map[$x][$y]>=9){
      err("FAILED!\n");
      last PLAY;
    }
    open_cell($x,$y);
  }
}

# ending
for(my $x=1; $x<=$width; $x++){
  for(my $y=1; $y<=$height; $y++){
    put($y+2, $x+2, ($map[$x][$y]>=9)?'*':'.'); # $map[$x][$y]);
  }
}

sub open_cell{ # check cells recursively, open cell, and modify @map_open
  my($x,$y) = @_;
  if($map_open[$x][$y]==1){
    #already opened
  }else{
    $map_open[$x][$y]=1; # set 'open' flag;
    $opened++;
    $map[$x][$y]==0 or return();
    foreach my $i (-1,0,1){
      my $xx = $x+$i;
      ($xx<=0 or $xx>$width) and next;
      foreach my $j (-1,0,1){
        $i==0 and $j==0 and next;
        my $yy = $y+$j;
        ($yy<=0 or $yy>$height) and next;
#        ($map_open[$xx][$yy]==0 and $map[$xx][$yy]==0) and open_cell($xx, $yy);
        ($map_open[$xx][$yy]==0) and open_cell($xx, $yy);
      }
    }
  }
}


### helper functions supporting escape sequence
sub locate{
  my($x, $y, $t) = @_;
  printf("\e[%d;%dH%s", $x, $y, $t||'');
}

sub cls{ # clear screen
  my($x) = $_[0] || '2';
  #0: clear after cursor, 1:clear before cursor; 2:all
  print "\e[${x}J";
}

sub cll{ # clear line
  my($x) = $_[0] || '0';
  #0: clear after cursor, 1:clear before cursor; 2:all
  print "\e[${x}K";
}

sub color{
  my($color1, $color0) = @_;
  my %col = qw/black 0 red 1 green 2 yellow 3 blue 4 magenta 5 cyan 6 white 7/;
  my $code = (defined $color1->[2])
    ?sprintf("\e[38;2;%d;%d;%dm", @$color1)
    :sprintf("\e[3%dm", $col{$color1->[0]});
  $code .= (defined $color0->[2])
    ?sprintf("\e[48;2;%d;%d;%dm", @$color0)
    :sprintf("\e[4%dm", $col{$color0->[0]});
  print($code);
}

sub ereset{
  print "\e[0m";
}

sub put{
  my($x, $y, $t, $color_fg, $color_bg) = @_;
  locate($x,$y);
  (defined $color_fg and defined $color_bg) and color($color_fg, $color_bg);
  print "$t\n";
  ereset();
}

sub message{
  my($t) = @_;
  locate($height+3,0); cll();
  print "$t\n";
}

sub err{
  my($t) = @_;
  color([255,0,0],$color0);
  locate($height+3,0); cll();
  print "$t\n";
  sleep 1;
  ereset();
}

