#!/usr/bin/perl

use strict;
use CGI;
use vars qw($width);
use vars qw($height);

$width = 20;
$height = 20;

sub fisher_yates_shuffle {
	my $array = shift;
	my $i;
	for ($i = @$array; --$i; ) {
		my $j = int rand ($i+1);
		next if $i == $j;
		@$array[$i, $j] = @$array[$j, $i];
	}
}


sub mapToGrid {
	my ($GR, $word, $x, $y, $pos, $direction, $RR, $DR) = @_;

	if ($direction eq 'right') {
		$x -= $pos;
		
		if ($x < 0 or $y < 0) { return;}
		
		for (my $i = 0; $i < length $word; $i++) {
			$$GR[$x+$i][$y] = substr $word, $i, 1; 
			if ($x + $i >= $width) { $width = $x + $i + 1; }
		}
		push @$RR, [$word, $x, $y];
	} else {
		$y -= $pos;
		
		if ($x < 0 or $y < 0) { return;}
		
		for (my $i = 0; $i < length $word; $i++) {
			$$GR[$x][$y+$i] = substr $word, $i, 1;
			if ($y + $i >= $height) { $height = $y + $i + 1; }
		}
		push @$DR, [$word, $x, $y]; 
	}
}

sub canMapToGrid {
	my ($GR, $word, $x, $y, $pos, $direction) = @_;

	if ($direction eq 'right') {
		$x -= $pos;
			
		for (my $i = 0; $i < length $word; $i++) {
			if ($$GR[$x+$i][$y]) {
				return if ($$GR[$x+$i][$y] ne substr ($word, $i, 1)  );	
			} 
		}
	} else {
		$y -= $pos;

		for (my $i = 0; $i < length $word; $i++) {
			if ($$GR[$x][$y+$i]) {
				return if ($$GR[$x][$y+$i] ne substr ($word, $i, 1));	
			}
		}
	}
	1;
}

sub goRight {
	my ($word, $DR, $GR) = @_;

	fisher_yates_shuffle ($DR) if @$DR > 1;
		
	for (my $i = 0; $i < length $word; $i++) {
		my $letter = substr $word, $i, 1;

		foreach my $REF (@$DR) {
			my $index = 0;

			while ($index = index ($$REF[0], $letter, $index) and $index >= 0) { 
				return ($$REF[1], $$REF[2] + $index, $i, "right")
				if (canMapToGrid ($GR, $word, $$REF[1], $$REF[2] + $index, $i, "right")); 
				$index++;
			}
		}

	}

	return (0, 0, 0, 0);

	print "uh-oh!  We got an X floater: $word\n";
}

sub goDown {
	my ($word, $RR, $GR) = @_; 

	fisher_yates_shuffle $RR if @$RR > 1;	
	for (my $i = 0; $i < length $word; $i++) {
		my $letter = substr $word, $i, 1;

		foreach my $REF (@$RR) {
			my $index = 0;
	#		print "hi $$REF[0], $$REF[1], $$REF[2]\n";
			
			while ($index = index ($$REF[0], $letter, $index) and $index >= 0) { 
				return ($$REF[1] + $index, $$REF[2], $i, "down")
				if (canMapToGrid ($GR, $word, $$REF[1] + $index, $$REF[2], $i, "down")); 
				$index++;
			}
		}

	}

	return (0, 0, 0, 0);
	print "uh-oh!  We got a Y floater: $word\n";
}

sub findPlace {
	my ($word, $GR) = @_;

	#we'll try 100 places

	for (my $i = 0; $i < 100; $i++) {
		my $x = int rand ($width);
		my $y = int rand ($height);
		if (canMapToGrid ($GR, $word, $x, $y, 0, 'right')) {
			return ($x, $y, 0, 'right');
		} elsif (canMapToGrid ($GR, $word, $x, $y, 0, 'down')) {
			return ($x, $y, 0, 'down');
		}
	}
	
	return (0, 0, 0, 0);
}

#thanks daron
sub printHtmlTable {
	my($width, $height, $gr)=@_;
	print "<table>\n";
	for(my($c)=0; $c<$width; $c++)
	{
   		print "<tr>\n";
   		for(my($d)=0; $d<$height; $d++)
   		{
      			print "<td>$$gr[$c][$d]</td>";
   		}
   		print "</tr>\n";
	}
	print "</table>\n";
}

sub main {

	my @grid;

	my @right;
	my @down;

	my $query = new CGI;


	my $string;

	if ($query->param('galaxytext')) {
		$string = $query->param('galaxytext');
	} else {
		$string  = "
We are currently upgrading the operating system in e2's frontend servers. Sorry for the inconvenience. In the meantime, you can check up on the upgrade status in our IRC channel linked above.
 
-- the [edev] team

";
	}

	my @words = split /\W/, $string;

	fisher_yates_shuffle \@words;

	my $count;

	while ($count < @words) {
		my @return;
		my $word = $words[$count];
		my ($x, $y, $pos, $dir);

		#evens build across, odds build down 
		if ($count % 2) {
			($x, $y, $pos, $dir) = goRight ($word, \@down, \@grid);
			($x, $y, $pos, $dir) = goDown ($word, \@right, \@grid) unless $dir;
	
		} else {
			($x, $y, $pos, $dir) = goDown ($word, \@right, \@grid);
			($x, $y, $pos, $dir) = goRight ($word, \@down, \@grid) unless $dir;
		}

		($x, $y, $pos, $dir) = findPlace ($word, \@grid) unless $dir;

		mapToGrid \@grid, $words[$count], $x, $y, $pos, $dir, \@right, \@down if $dir;
	
		$count++;
	}

#open DATA, ">/home/oostendo/public_html/data/gridout";
#	foreach my $REF (@grid) {
#		foreach my $letter (@$REF) {
#		$letter ||= ' ';	
#		print DATA $letter;
#	}
#	print DATA "\n";
#}
#close DATA;



$query->header( -type => 'text/html' ); 
print "
	<html>
	<body text=#000000 bgcolor=#ffffff link=#801f2f vlink=#1f2f80>
	<title>Word Galaxy</title>
	<center><table align=center width=90%>
	<tr><td><br>";
	print "<h3>Nate's Word Galaxy Generator</h3><br>";
	print "<a href=\"http://webchat.freenode.net/?channels=everything2\">Check up on the upgrade status in IRC</a><br/>";
	print "<font size=2><b>spin your own:</b></font>\n";
	print	$query->startform .
	$query->textarea ('galaxytext', $string, 10, 50) .
	$query->submit ('explore');
	print "</form>";
	printHtmlTable $width, $height, \@grid;
	print "<p align=right><font size=2>this affordable entertainment provided by Nate Oostendorp.<br>";
        print "<a href=\"http://web.archive.org/web/20080128191325/oostendorp.net/wordgalaxy.html\">About word galaxies</a></font></p>";
	print "</td>
	</table></body>
	</html>
	
	";
}
main;

