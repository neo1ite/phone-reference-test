#!/usr/bin/perl

use utf8;
use strict;
use warnings;
use Data::Dumper;
no if $] >= 5.018, 'warnings', "experimental::smartmatch";

use CGI qw/:standard/;
use Time::HiRes qw/gettimeofday tv_interval/;
use DBI::Simple;
use Template::Simple;
use Pager::Simple;
use Config::General qw(ParseConfig SaveConfig);
use Encode qw(:fallbacks encode decode);

use constant CONFIG_FILE  => 'site.conf';

my $timer = make_timer();

my %config = ParseConfig( -ConfigFile => CONFIG_FILE );

$DBI::Simple::DEBUG = 1;
# Подключаемся к БД, сразу задаем верную кодировку подключения
my $DB = DBI::Simple->new($config{DB});
my $total_records = $DB->select('SELECT COUNT(*) FROM ' . $config{DB}{db_table});

my $tmpl = Template::Simple->new();

print header('text/html; charset=UTF-8');
$tmpl->compile( 'index', 1 );

my $pager = Pager::Simple->new(
    $DB,
    $config{DB}{db_table},
    {
        records_per_page => 30,
        (int(param('phone') // '') ? (condition => 'phone = ' . int(param('phone') // '')) : ())
    }
);

print ${$tmpl->render(
    'index',
    {
        phones => $pager->first_page,
        exec_time => $timer->(),
        records => $total_records =~ s/(\d)(?=(\d{3})+(\D|$))/$1\,/gr
    },
    1
)};

exit;

sub make_timer {
	my @times = ([gettimeofday()]);

	return sub {
		push(@times, [gettimeofday()]);

		return encode('utf-8', sprintf("%.06f с", tv_interval($times[-2], $times[-1])));
	};
}
