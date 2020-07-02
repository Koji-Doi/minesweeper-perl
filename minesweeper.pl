#!/usr/bin/env perl
=head1 NAME

Minesweeper in perl

=head1 SYNOPSIS

minesweeper.pl [width] [height] [mines]

=head1 OPTIONS

=over 4

=item 1 width     -- board width (the number of column of game board). Default is 6.

=item 2 height    -- board height (the number of row of game board). Default is 6.

=item 3 mines     -- the number of mines. Default is 4.

=back

=head1 HOW TO PLAY

When you start the game, the board appears in the upper left corner of the screen. This is a "minefield". 
On the top, bottom, left and right of the board is a single letter that represents the coordinates of the square.
A prompt will appear below it. 

Instead of using the mouse, the player must advance through the game by typing a command after this prompt.

=head2 Command

Three pattern of command can be input here; Open cell, Set flag, and Reset flag.

=head3 Open cell

You can enter the coordinates of the square to be opened in column(x) and row(y) order without spaces.
For example, if you want to specify x=5 and y=2, just enter 52.

=head3 Set flag

=head3 Reset flag

=head2 Ending


=cut

use strict;
use warnings;
use Data::Dumper;
use FindBin;
use Pod::Usage;
use Time::Piece;
use Time::Seconds;

# get screen size
my $winsize;
my($scr_row, $scr_col) = (80, 20);
require 'sys/ioctl.ph';
if(defined &TIOCGWINSZ){
  if(open(TTY, "+</dev/tty")){
    unless (ioctl(TTY, &TIOCGWINSZ, $winsize='')) {
      die sprintf "$0: ioctl TIOCGWINSZ (%08x: $!)\n", &TIOCGWINSZ;
    }
    ($scr_row, $scr_col) = unpack('S4', $winsize);
  }
}

$ARGV[0]=~/^-/ and my $opt = shift @ARGV;
my($width, $height, $mine_num, $col) = @ARGV; # map width, map height, the number of mine, color mode
my $recfile = ($ENV{HOME}||'.')."/minesweeper.pl.rec"; # file to save play records
if($opt=~/^-+h/){
  print pod2usage(-verbose => 2, -input => $FindBin::Bin . "/" . $FindBin::Script);
  exit();
}elsif($opt=~/^-+r/){
  show_record($width, $height, $mine_num); exit();
}

$width     = $width    || 6;
$height    = $height   || 6;
$mine_num  = $mine_num || 4;
$col       = $col      || '256'; # '8', '256', '8rev', '256rev'; 'rev':board is displayed in reverse mode
my $col_offset = int(($scr_col - $width)/2);
srand(0);

my %color;
map{
  $color{$_} = {
    fg => ([204,204,204], [64,64,255], [0,200,0], [255,0,0], [0,0,128], [152,0,0], [0,152,152], [0,0,0], [152,152,152])[$_],
    bg => [255,255,255]
  }
} (0..8);
$color{'+'} = {fg=>[0,0,0],       bg=>[255,0,0]};
$color{'_'} = {fg=>[128,128,128], bg=>[200,200,200]};
($color{t}{bg}, $color{t}{fg}) = ([255,255,255],[0,0,0]);

my $hit=0;    # the number of found mines
my $opened=0; # the number of opened cells
my $marked=0; # the number of marked cells

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
my $result; # 0:failed, 1:succeeded
my $starttime = localtime();
cls();
put(0,         3, join('', @index[1..$width]), $color{t}{bg}, $color{t}{fg});
put($height+4, 3, join('', @index[1..$width]), $color{t}{bg}, $color{t}{fg});
map { put($_+2, 0,        $index[$_], $color{t}{bg}, $color{t}{fg}) } 1..$height;
map { put($_+2, $width+4, $index[$_], $color{t}{bg}, $color{t}{fg}) } 1..$height;

PLAY: while(1){
  if($hit==$mine_num and $hit+$opened==$width*$height){
    $result = 1;
    last PLAY;
  }
  # draw cells
  for(my $x=1; $x<=$width; $x++){
    for(my $y=1; $y<=$height; $y++){
      my $status = ($map_open[$x][$y]==2)?'+'
                  :($map_open[$x][$y]==1)?(($map[$x][$y]==0)?'_':$map[$x][$y])
                  :'.';
      put($y+2, $x+2, $status, $color{$status}{fg}, $color{$status}{bg});
    }
  }
  my($cmd,$cmd2,$x,$y);
  my $col_offset2 = int(($scr_col-25)/2);
  while(1){
    locate($height+5,$col_offset2); cll();
    printf "mine:%2d  marked:%2d opened:%3d\n", $mine_num, $marked, $opened;
    message("Input command:");
    locate($height+7,0); cll();
    my $in = <STDIN>;
# quit : quit game
# + X Y: mark cell at x,y
# - X Y: unmark cell at x,y
# X Y  : open cell at x,y and peripherals

    $in=~/quit/i and last PLAY;
    ($cmd, $x, $y, $cmd2) = $in=~/([-+])?\s*([\da-zA-Z])([\da-zA-Z])([-+])?/;
    $cmd = $cmd || $cmd2 || '';
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
      $marked++;
    }
  }elsif($cmd eq '-'){
    ($map_open[$x][$y]==2) and $map_open[$x][$y]=0;
  }else{
    if($map[$x][$y]>=9){
      err("FAILED! GAME OVER!\n");
      $result = 0;
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
locate($height+6, 0);
my $endtime = localtime();
my $ellapsed = $endtime-$starttime;
my ($e_h,$e_m,$e_s) = (int($ellapsed)/3600, int($ellapsed%3600/60), $ellapsed%60);
color(["red"]);
print "YOU WIN!"; cll(); print "\n"; cll(); print "\n";
ereset();
printf <<"EOD", pretty_date($starttime), pretty_date($endtime), $e_h,$e_m,$e_s;
start    : %s
end      : %s
ellapsed : %d:%02d:%02d

EOD

# update record
if($result and $e_h<=10){ # ignore records longer than 10hours as abnormal
  open(my $fho, '>>', $recfile) or die "cannot open recored file";
  print {$fho} join("\t", pretty_date($starttime), $ellapsed, sprintf("%02d:%02d:%02d", $e_h,$e_m,$e_s), $height, $width, "${mine_num}\n");
  close $fho;
}
show_record($height, $width, $mine_num, $ellapsed);

print "\n[V]iew records. [Q]uit game\n";
while(<STDIN>){
  /q/i and last;
  /v/i and exec("perl $0 -r");
}

### END OF MAIN

### helper functions
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
        no warnings 'recursion';
        ($map_open[$xx][$yy]==0) and open_cell($xx, $yy);
        use warnings;
      }
    }
  }
}

# show record
sub show_record{
  my($h, $w, $mine, $elapsed)=@_;
  open(my $fhi, '<', $recfile) or die;
  my @rec = map {chomp; [split(/\t/, $_)]} <$fhi>;
  close $fhi;

  if(defined $h and defined $w and defined $mine){
    my @rec_sort = sort {$a->[1] <=> $b->[1]} grep {$_->[3]==$h and $_->[4]==$w and $_->[5]==$mine} @rec;
    print "* Best 5 records in height=$h, width=$w, mine=$mine\n";

    foreach my $r (@rec_sort[0..4]){
      (defined $r) or next;
#    printf "%s %s %3d %3d %3d\n", $r->[0], $r->[2], $r->[3], $r->[4], $r->[5];
      printf "%s %s\n", $r->[0], $r->[2];
    }
    if(defined $elapsed){
      (scalar @rec>1) and ($elapsed==$rec_sort[0][1]) and print "You have broken the record for the fastest time.\n";
    }
  }
}

# date format
sub pretty_date{
  my($t) = @_; # Time::Piece
  return(join(' ', $t->ymd(), $t->wdayname, $t->hms()));
}

# supporting escape sequence
sub locate{
  my($x, $y, $t) = @_;
  ($x<0) and $x=0;
  ($y<0) and $y=0;
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
    :''; #sprintf("\e[4%dm", $col{$color0->[0]});
  print($code);
}

sub ereset{
  print "\e[0m";
}

sub put{
  my($x, $y, $t, $color_fg, $color_bg) = @_;
  locate($x, $y+$col_offset);
  (defined $color_fg and defined $color_bg) and color($color_fg, $color_bg);
  print "$t\n";
  ereset();
}

sub message{
  my($t) = @_;
  #color($color{t}{fg}, $color{t}{bg});
  locate($height+6,0); cll();
  print "$t\n";
}

sub err{
  my($t) = @_;
  color([255,0,0],$color{t}{bg});
  locate($height+6,0); cll();
  print "$t\n";
  sleep 1;
  ereset();
}

