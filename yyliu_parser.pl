use strict;
use warnings;

# define the subclass
package IdentityParse;
use base "HTML::Parser";
use Data::Dumper;

my $starthh = 15;
my $endhh = 17;

my $is_table = 0;
my $is_display = 0;
my $table_count = 0;
my $row_count = 0;
my $col_count = 0;

my $current_date;
my $schedule = {};

sub text {
    my ($self, $text) = @_;
    # just print out the original text
	if ( $is_display == 1 ) {
		#print "** ($table_count, $row_count, $col_count)\n";
		# remove ileagle char
		$text =~ s/\n//g;
		#replace 0 or more whitespaces at the beginning
		#     or 0 or more whitespaces at the end
		#     with nothing
		$text =~ s/^\s+|\s+$//g;
    	#print "Text: $text\n";
		if ( $table_count == 0 ) {
			if ( $row_count > 1 ) {
				if ( $col_count == 1 ) {
					$current_date = $text;
				} elsif ( $col_count >= 2 && $col_count <= 3 ) {
					push @{ $schedule->{$current_date} }, $text;
				}
			}
		}
	}
}

sub comment {
    my ($self, $comment) = @_;
    # print out original text with comment marker
    print "";
}

sub start {
    my ($self, $tag, $attr, $attrseq, $origtext) = @_;
    # print out original text
	if ( $tag eq "table" ) {
		$is_table = 1;
		#print "Table: $table_count\n";
	}
	if ( $is_table == 1 ) {
		if ( $tag eq "tr" ) {
			#print "Row: $row_count\n";
			$row_count++;
			$col_count = 0;
		}
		if ( $tag eq "td" ) {
			#print "Col: $col_count\n";
			$col_count++;
			$is_display = 1;
		}
	}
}

sub end {
    my ($self, $tag, $origtext) = @_;
    # print out original text
	if ( $tag eq "table" ) {
		$is_table = 0;
		$is_display = 0;
		$table_count++;
		$row_count = 0;
	}
    #print "/$tag:\t$origtext";
}

open(my $fh, '<', $ARGV[0]) or die "Couldn't open file: $!";
my @content = <$fh>;
close $fh;

use HTTP::Response;
use HTTP::Headers;

my $mess = HTTP::Response->parse(join('', @content));
#print Dumper($mess);

my $p = new IdentityParse;
$p->parse($mess->content);
#print Dumper($schedule);

use Data::ICal;
use Data::ICal::Entry::Event;
use DateTime;
use DateTime::Format::ICal;
use DateTime::Format::HTTP;

my $calendar = Data::ICal->new();
for my $orig_date (keys %{ $schedule }) {
	my ($yyyy, $mm, $dd) = ($orig_date =~ /(\d+)\/(\d+)\/(\d+)*/);
	#print "**$yyyy/$mm/$dd\n";
	my @prensenter_list;
	foreach my $prensenter (@{ $schedule->{$orig_date} }) {
		#print "Prensenter: $prensenter\n";
		push @prensenter_list, $prensenter; 
	}
	my $event = Data::ICal::Entry::Event->new();
	$event->add_properties(
			summary => "NTHU meeting prensenter: " . join(', ', @prensenter_list) ,
			description => "NTHU meeting prensenter: " . join(', ', @prensenter_list) ,
			dtstart => DateTime::Format::ICal->format_datetime(
				DateTime->new(
					year => $yyyy,
					month => $mm,
					day => $dd,
					hour => $starthh,
					minute => 0,
					second => 0,
					time_zone => 'Asia/Taipei')
				),
			dtend => DateTime::Format::ICal->format_datetime(
				DateTime->new(
					year => $yyyy,
					month => $mm,
					day => $dd,
					hour => $endhh,
					minute => 0,
					second => 0,
					time_zone => 'Asia/Taipei')
				),
			created => DateTime::Format::ICal->format_datetime(
				DateTime::Format::HTTP->parse_datetime($mess->header('Last-modified'))
				),
			'last-modified' => DateTime::Format::ICal->format_datetime(
				DateTime::Format::HTTP->parse_datetime($mess->header('Date'))
				),
			);
	$calendar->add_entry($event);
}
$calendar->add_properties(
		calscale => 'GREGORIAN',
		method => 'PUBLISH',
		'X-WR-CALNAME' => 'Prensentation Schedule',
		'X-WR-TIMEZONE' => 'Asia/Taipei',
		);

print $calendar->as_string;
