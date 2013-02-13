#################################################################################
#                                                                               #
# TRMM gauge preprocessor                                                       #
#                                                                               #
#                                                                               #
#                                                                               #
#################################################################################

use strict;

my $inputDirectory = "D:\\KWAJ data\\KWAJ Radar Data test";
my $outputDirectory = "D:\\KWAJ data\\KWAJ Radar Data test output";

my @years=qw/2001/;
my @seasons=qw/MAM JJA SON/;


my $firstRow=44;
my $lastRow=107;

my $firstCol=44;
my $lastCol=107;

my $maxOpenFiles=2000;

my $blankRecord="NA";

my @pixelList=qw//;

for (my $rowNum=$firstRow-1; $rowNum < $lastRow; $rowNum++){
	for (my $colNum=$firstCol-1; $colNum < $lastCol; $colNum++){
		push @pixelList, [$rowNum,$colNum];
	}
}


######################################################################
my @months=qw/01 02 03 04 05 06 07 08 09 10 11 12/;
my %monthLength=("01",31,"02",28,"03",31,"04",30,"05",31,
	"06",30,"07",31,"08",31,"09",30,"10",31,"11",30,"12",31);
my %seasons= ( "DJF"=>["12","01","02"],"MAM"=>["03","04","05"]
	,"JJA"=>["06","07","08"],"SON"=>["09","10","11"]);
######################################################################

sub locationConversion{
	my ($matRow,$matCol)=@_;
	my $x = $matCol+1;
	my $y = 151-$matRow;
	return ($x,$y);
}

sub headerTime{
	my ($header,$season)=@_[0..1];
	$header=~m/^\w{4}\s(\d{2})(\d{2})(\d{2})\s(\d{2})(\d{2})/;
	my ($imageYear,$imageMonth,$imageDay,$imageHour,$imageMinute)=($1,$2,$3,$4,$5);
	my @months=@{$seasons{$season}};
	my $minsTilStart=0;
	my $flag=0;
	foreach my $month (@months){
		if ($month != $imageMonth && $flag==0){
			$minsTilStart=$minsTilStart+1440*$monthLength{$month};
		} else {
			$flag=1;
		}
	}
	my $minutesFromStart=($imageDay-1)*1440+$imageHour*60+$imageMinute+$minsTilStart;
	return $minutesFromStart; # NEEDS FIXING
}

sub readRadarFile{
	# Pass a file location to the function. If the file exists then return 
	# the header and an array with each element being an array containing
	# FINISH
	my ($fileLocation)=$_[0];
	my @output=qw//;
	if (!(-e $fileLocation)){
		return 0;
	}
	open (RADARFILE,"<",$fileLocation);
	my $header=<RADARFILE>;
#	print "Printing Header\n",$header,"\n";
	while (<RADARFILE>){
		chomp(my $line= $_);
		my @line= split(" ",$line);
		push @output, [@line];
	}
	close(RADARFILE);
	print $header,"\n";
	return ($header,@output);
}

sub processSeason{
	my ($season,$year)=@_[0..1];
	if (! $seasons{$season}){
		return 0;
	}
	my @radarFileList=qw//;
	my $seasonMinutes=0;
	foreach my $month (@{$seasons{$season}}){
#	foreach my $month (qw/03/){
		print "Season is $season, month is $month\n";
		my $curYear;
		if ($month==12){
			$curYear=$year-1;
		} else {
			$curYear=$year;
		}
		my $monthDir=$inputDirectory."\\".$month."-".$year;
		opendir(RADARDIR,$monthDir);
		my @monthfiles=map{"${inputDirectory}\\${month}-${year}\\".$_} grep(/txt$/,readdir(RADARDIR));
		push(@radarFileList,@monthfiles);
		closedir(RADARDIR);
		$seasonMinutes=$seasonMinutes+$monthLength{$month}*1440
	}
	print join("\n",@radarFileList),"\n";
#	print join("\n",@radarFileList),"\n";
	my $openPixels=0;
	my $processedPixels=0;
	my @fileHandles=qw//;
	
	while ($processedPixels<scalar(@pixelList)){
		my @fileHandles=qw//;
	
		while ($openPixels<$maxOpenFiles && $processedPixels+$openPixels<scalar(@pixelList)){
			# NEEDS FIXING
			my @currentPixel = @{$pixelList[$openPixels+$processedPixels]};
			my ($x,$y)=&locationConversion($currentPixel[0],$currentPixel[1]);
			my $fileName = $outputDirectory."\\kwaj_file_${x}_${y}.dat";
			open(my $fh, ">",$fileName);
			push @fileHandles, $fh;
			$openPixels++;
		}
		my $currentTime=0;
		foreach my $radarFile (@radarFileList){
			(my $header,my @radarImage)=&readRadarFile($radarFile);
#			print $radarFile,"\n";
			my $imageTime=&headerTime($header,$season);
#			print $header,"\n";
			my $timeDiff=$imageTime-$currentTime;
			foreach my $fileHandle(@fileHandles){
				print $fileHandle "$blankRecord\n" x $timeDiff;
			}
			$currentTime=$imageTime;
			for (my $i=0;$i<scalar(@fileHandles);$i++){
				my @currentPixel=@{$pixelList[$processedPixels+$i]};
#				print $i," - ",$processedPixels,"\n";
				my $fh = $fileHandles[$i];
				print $fh $radarImage[$currentPixel[0]][$currentPixel[1]],"\n";
			}
			$currentTime++;
		}
		my $timeDiff=$seasonMinutes-$currentTime;
		print $timeDiff;
		foreach my $fileHandle(@fileHandles){
			print $fileHandle "$blankRecord\n" x $timeDiff;
		}
		foreach my $fh (@fileHandles){
			close($fh);
			$openPixels--;
			$processedPixels++;
		}
	}
	
}

#############################################################
# MAIN CODE - TEMPORARY                                     #
#############################################################



&processSeason("MAM",2001);
