#!/usr/bin/perl

use File::PCAP::Reader;
use Net::TcpDumpLog;
use NetPacket::Ethernet;
use NetPacket::IP;
use NetPacket::TCP;
use NetPacket::UDP;
use POSIX qw(strftime);

use DBI;

use Net::DNS ();
use Socket;

use strict;
use warnings;

####################################################################################### global variable

my $pcap_dir = "tcpdump/";

my $db_name = "objective2";
my $table_name = "packets";
my $user = "root";
my $pw = "0000";

my $id_col = "id";
my $date_col = "Date";
my $time_col = "Time";
my $usec_col = "usec";
my $sip_col = "SourceIP";
my $spt_col = "SourcePort";
my $dip_col = "DestinationIP";
my $dpt_col = "DestinationPort";
my $fqdn_col = "FQDN";

my $max_row_pcap = 1000;

#my @fnames = ("tcpdump/20190821-1311.pcap", "tcpdump/20190821-1312.pcap");


#######################################################################################

sub main()
{
	my $dbh = StartSqlTable();
	
	my @fnames = GetFilesInDir();

	GetPacketHashInPcaps(\@fnames, $dbh);
	
	#ViewSqlTable($dbh);
	
	StopSqlTable($dbh);
}

####################################################################################### do SQL

sub ViewSqlTable
{
	my ( $dbh) = @_;
	
	my $prepare = $dbh->prepare("SELECT * FROM ${table_name}");
	
	$prepare->execute();
	
	while ( my $ref = $prepare->fetchrow_hashref() )
	{
		print "ID: ", $ref->{$id_col}, ", FQDN: ", $ref->{$fqdn_col}, "\n";
	}
	
	$prepare->finish();
}

sub InsertSqlTable
{
	my ( $packet_hash, $sql_id, $dbh) = @_;
	
	##### 
	my $date = $packet_hash->{$date_col};
	my $time = $packet_hash->{$time_col};
	my $usec = $packet_hash->{$usec_col};
	my $source_ip = $packet_hash->{$sip_col};
	my $source_port = $packet_hash->{$spt_col};
	my $destination_ip = $packet_hash->{$dip_col};
	my $destination_port = $packet_hash->{$dpt_col};
	my $fqdn = $packet_hash->{$fqdn_col};
	
	#####
	$dbh->do("INSERT INTO ${table_name} VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
			undef, $$sql_id, $date, $time, $usec, $source_ip, $source_port, $destination_ip, $destination_port, $fqdn);
	
	#####
	$$sql_id += 1;
}

sub StartSqlTable()
{
	my $dbh = DBI->connect("DBI:mysql:${db_name}",$user,$pw);

	if(!$dbh){
		die "failed to connect to MySQL database DBI->errstr()";
	}else{
		print("Connected to MySQL server successfully.\n");
	}
	
	eval { $dbh->do("DROP TABLE ${table_name}") };
	print "Dropping foo failed: $@\n" if $@;

	$dbh->do("CREATE TABLE ${table_name} (${id_col} INTEGER, ${date_col} DATE, ${time_col} TIME, ${usec_col} INTEGER, ${sip_col} CHAR(15), ${spt_col} INTEGER, ${dip_col} CHAR(15), ${dpt_col} INTEGER, ${fqdn_col} TEXT)");
	
	return $dbh;
}

sub StopSqlTable()
{
	my ( $dbh ) = @_;
	
	$dbh->disconnect();
}

####################################################################################### do pcap

sub GetPacketHashInPcaps
{
	my ( $fnames,  $dbh) = @_;
	
	#####
	my $sql_id = 1;
	
	#####
	foreach ( @$fnames )
	{
		my $fname = $_;
		my $fpr = File::PCAP::Reader->new( $fname );
		my $gh = $fpr->global_header();
		
		#####
		print "Extract Pcap [${fname}], and insert to sql\n";
		
		#####
		my $i = 0;
		while( my $np = $fpr -> next_packet() and $i < $max_row_pcap)
		{
			$i += 1;
			
			#####
			my %packet_hash = GetPacketHashInPcap( $np);
			
			#####
			InsertSqlTable(\%packet_hash, \$sql_id, $dbh);
		}
	}
}

sub GetPacketHashInPcap()
{
	my ( $np ) = @_;
	
	my $packet = $np -> {buf};
	
	my $ether_data = NetPacket::Ethernet::strip($packet);

	my $ip = NetPacket::IP->decode($ether_data);
	
	my $tcp = NetPacket::TCP->decode( $ip->{'data'});
	my $udp = NetPacket::UDP->decode( $ip->{'data'});
	
	#####
	my $date = strftime "%F", localtime($np -> {ts_sec});
	my $time = strftime "%H:%M:%S", localtime($np -> {ts_sec});
	my $usec = $np -> {ts_usec};
	my $source_ip = $ip -> {'src_ip'};
	my $source_port = $tcp -> {'src_port'};
	my $destination_ip = $ip -> {'dest_ip'};
	my $destination_port = $tcp -> {'dest_port'};
	my $fqdn = $udp -> {'data'};
	
	#####
	my %packet_hash = ($date_col, $date, 
			$time_col, $time, 
			$usec_col, $usec,
			$sip_col, $source_ip,
			$spt_col, $source_port,
			$dip_col, $destination_ip,
			$dpt_col, $destination_port,
			$fqdn_col, $fqdn);
	
	
	return %packet_hash;
}

####################################################################################### utility

sub GetFilesInDir()
{
	opendir my $dir, $pcap_dir or die "Cannot open directory: $!";
	
	my @files = readdir $dir;
	
	closedir $dir;
	
	my @pcap_filenames = ();
	
	#####
	foreach (@files)
	{
		my $file = $_;
		unless( $file eq "." || $file eq "..")
		{
			my $filename = $pcap_dir . $file;
			push(@pcap_filenames, ($filename));
			
			#print $filename, "\n";
		}
	}
	
	return @pcap_filenames;
}

#######################################################################################

main();

#######################################################################################
