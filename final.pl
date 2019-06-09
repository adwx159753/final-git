#!/usr/bin/perl -w

use threads;
use threads::shared;
no warnings;
use Time::HiRes qw/ gettimeofday /;
use Term::ReadKey;

our $clear = `clear`;
our $players_exist = 1;

#game states:
#0	menu
#1	gaming
#2	stop
#3	exit
#4	game over 

our $states = 0;

#set the games window w*h = 22*20
#box[][] = 1 means wall
#box[][] = 2 means obstacle
#box[][] = 3 players space
our @box;

for(my $m = 0; $m < 10; $m += 1)
{
	#height
	for(my $n = 0; $n < 20; $n += 1)
	{
		#width
		#if x != 0 or 19 && #y!= 0 or 21
		if($n != 0 && $n != 19 && $m != 0 && $m != 9)		
		{
			$box[$m][$n] = 0;
		}
		else
		{
			$box[$m][$n] = 1;
		}
	}
}


#where user
our $user_x = 15;
our $last_x = 15;
our $user_y = 7;
our $last_y = 7;

#setting where user is
$box[$last_y][$last_x] = 3;

sub obstacle2
{
	my $x = int(rand(5) + 1);
	my $y = 0;
	my $w = int(rand(5) + 2);
	my $h = int(rand(6) + 2);
	return ($x, $y, $w, $h);
}

sub obstacle3
{
	my $x = int(rand(5) + 5);
	my $y = 0;
	my $w = int(rand(5) + 2);
	my $h = int(rand(6) + 2);
	return ($x, $y, $w, $h);
}

sub obstacle4
{
	my $x = int(rand(5) + 10);
	my $y = 0;
	my $w = int(rand(5) + 2);
	my $h = int(rand(6) + 2);
	return ($x, $y, $w, $h);
}
 
#		*
#w,h=(4,3)	*
#x,y=(1,0+3)	****
#x should be in range(1~20)
#y 	     in range(1~18)
#the place of obstacle2

my ($s, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime;

my ($epocsec, $microsec) = gettimeofday();
our ($obs_2x, $obs_2y, $obs_2w, $obs_2h)= &obstacle2();#to get obs2 -> x,y,w,h
our ($obs_3x, $obs_3y, $obs_3w, $obs_3h)= &obstacle3();
our ($obs_4x, $obs_4y, $obs_4w, $obs_4h)= &obstacle4();
our $obs2 = 1;
our $obs3 = 1;
our $obs4 = 1;
our $key = ();

$start_game = 0;
$end_game = 0;

$count = 0;

#Game executing 
while(1)
{	
	my ($a, $b) = gettimeofday();
	if($microsec ne $b){
		if($obs2 == 0){
			($obs_2x, $obs_2y, $obs_2w, $obs_2h)= &obstacle2();
			$obs2 = 1;
		}
		if($obs3 == 0){
			($obs_3x, $obs_3y, $obs_3w, $obs_3h)= &obstacle3();
			$obs3 = 1;
		}
		if($obs4 == 0){
			($obs_4x, $obs_4y, $obs_4w, $obs_4h)= &obstacle4();
			$obs4 = 1;
		}
		for(my $m = 0; $m < 10; $m += 1){#reset the frame
			#height
			for(my $n = 0; $n < 20; $n += 1){
				#width
				#if x != 0 or 19 && #y!= 0 or 21
				if($n != 0 && $n != 19 && $m != 0 && $m != 9)		
				{
					#$box[$m][$n] = 0;
				}
				else
				{
					$box[$m][$n] = 1;
				}
			}
		}
		$microsec = $b;
		$count++;
		#menu
		if($states == 0){
			do{
				print 	"--------Menu----------\n"
					."<select mode:\n"
					."<1.normal\n"
					."<2.hard\n"
					."<3.exit\n"
					."Enter your choice:";
					
				ReadMode 'normal';
				my $choice = ReadKey(0);
				
				if($choice eq "3"){
					$states = 3;
				}
				else{
					print "3 seconds begin";
					sleep(3);
					print $clear;		
					$states = 1;
					$start_game = $a;
				}
			}while($states == 0);	
		}
		#gaming
		elsif ($states == 1){
			#clear screen
			
			#print "\n---Game start!--------\n";
			&gaming($sec);
		}
		#stop
		elsif ($states == 2){			
			
			print "\n---Stop--------\n";
			&stop();
		}
		#exit
		elsif ($states == 3){
			print "\n---GOODBYE__QAQ--------\n";
			$end_game = $a;
			$grade = ($end_game - $start_game)*100;
			print "your grade is: $grade\n";
			exit 0;
		}
		#game over
		elsif ($states == 4){
			for(my $m = 0; $m < 10; $m += 1){#height
				for(my $n = 0; $n < 20; $n += 1){#width
					#if x != 0 or 19 && #y!= 0 or 21
					if($n != 0 && $n != 19 && $m != 0 && $m != 9){
						$box[$m][$n] = 0;
					}
					else
					{
						$box[$m][$n] = 1;
					}
				}
			}
			print $clear;
			do {
				$end_game = $a;
				$grade = ($end_game - $start_game)*100;
				print "\nGAME OVER...\n"
					."your grade is: $grade\n"
					."press r to restart the game\npress e to exit\n"
					."Enter your choice:";
				ReadMode 'normal';
				my $choice_r_e = ReadKey(0);
				print ": $choice_r_e";
				if($choice_r_e eq "r"){
					$states = 0;
				}
				elsif ($choice_r_e eq "e"){
					$states = 3;
				}
			}while($states == 4);		
		}
	}
}

sub obstacle_moving 
{
	#obs have three situation
	#1.obs go through the end (thread join)
	#2.game over (thread join)
	#3.stop 
	#1.or 2.
	my($array,$obs_x, $obs_y, $obs_w, $obs_h, $number)=@_;
		if($players_exist == 1){#threads stop
			if($states == 1){
				if($$array[$$obs_y - $$obs_h][$a] != 1 && $$obs_y - $$obs_h > 1)#if obs2 is disappear
				{
					$$number = 0;#destroy
				}
				for(my $a = $$obs_x;$a < $$obs_x + $$obs_w; $a++)
				{
					#if top is no wall
					if($$array[$$obs_y - $$obs_h][$a] != 1 || $$obs_y > 1)
					{
						#remove top line	
						$$array[$$obs_y - $$obs_h][$a] = 0;
						
						if($$array[$$obs_y + 1][$a] != 1)
						{
							#add newline
							$$array[$$obs_y + 1][$a] = 2;
						}
						for(my $m = 0; $m < 10; $m += 1)
						{
							#height
							for(my $n = 0; $n < 20; $n += 1)	
							{
								#width
								#if x != 0 or 19 && #y!= 0 or 21
								if($n != 0 && $n != 19 && $m != 0 && $m != 9)		
								{
									#$box[$m][$n] = 0;
								}
								else
								{
									$box[$m][$n] = 1;
								}
							}
						}
					}
				}
				$$obs_y++;
			}
		}
}

sub gaming
{		
	my ($a, $b, $c, $d, $e, $f, $g, $h, $i) = localtime;#control moving per second
	if($a != $s){#obs moves once per second
		$s = $a;
		my $obs2_thread = threads->create(\&obstacle_moving(\@box, \$obs_2x, \$obs_2y, \$obs_2w, \$obs_2h, \$obs2),Thread_1);
		my $obs3_thread = threads->create(\&obstacle_moving(\@box, \$obs_3x, \$obs_3y, \$obs_3w, \$obs_3h, \$obs3),Thread_2);
		my $obs4_thread = threads->create(\&obstacle_moving(\@box, \$obs_4x, \$obs_4y, \$obs_4w, \$obs_4h, \$obs4),Thread_3);
	}
		#players
		&players_movement(\@user_move);
		
		#print array
		&printarray(\@box);
}

sub stop
{
	while($states == 2){
		my $input;
		print "press space to continued the game.\n"."press e to exit\n";
		ReadMode 'normal';
		$input = ReadKey(0);
		if($input eq " "){
			$states = 1;
		}
		elsif($input eq "e"){
			$states = 3;
		}
	}
}

sub printarray
{
	my($array) = @_;
	if($players_exist == 1){
		print $clear;
		if($states==2){
			#stop and
			&stop;
		}
		else{
			print $clear;
			for(my $m = 0; $m < 10; $m += 1){
				for(my $n = 0; $n < 20; $n += 1){
					if($$array[$m][$n]==0){
						print " ";
					}
					elsif($$array[$m][$n]==1){
						print "*";
					}
					elsif($$array[$m][$n]==2){
						print "*";
					}
					elsif($$array[$m][$n]==3){
						print "@";
					}
				}
				print "\n";
			}
		}
	}
}

sub players_movement
{
	#if we don't do this, we couldn't change the global data
	my($data)=@_;
	
	#players have two situation		
		#1.game over (thread join)
		#2.stop
	
	#check if game over or not
	if($players_exist == 1){
		#threads stop
		if($states == 1){
			#movement of user		
			ReadMode 'cbreak';
			#default "n" be a stopped move
			$key = "n";
			
			#after 0.8 seconds read the key in if none key == "n"
			$key = ReadKey 0.8;
			
			$last_x = $user_x;
			$last_y = $user_y;
			
			if($box[$user_y][$user_x]==2){
				$states = 4;
				
				$obs2 = 0;
				$obs3 = 0;
				
				#go to gameover screen
				$states = 4;
			}
			
			#normal mean default mode 
			ReadMode 'normal';
			#to limit user move on width	
			if($key eq "a" && $user_x != 1 && $box[$user_y][$user_x - 1] != 2)
			{
				$last_x = $user_x;
				$user_x--;
			}
			elsif($key eq "d" && $user_x != 18 && $box[$user_y][$user_x + 1] != 2)
			{			
				$last_x = $user_x;
				$user_x++;
			}
			#to limit user move on height
			elsif($key eq "w" && $user_y != 1 && $box[$user_y - 1][$user_x] != 2)
			{			
				$last_y = $user_y;
				$user_y--;
			}
			elsif($key eq "s" && $user_y != 9 && $box[$user_y + 1][$user_x] != 2)
			{			
				$last_y = $user_y;
				$user_y++;
			}
			elsif($key eq " " )
			{
				$states = 2;
			}
			$box[$last_y][$last_x] = 0;#old place so delete	
			$box[$user_y][$user_x] = 3;#new place
		}
	}
}



