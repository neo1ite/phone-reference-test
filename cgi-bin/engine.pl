#!/usr/bin/perl

use utf8;
use strict;
use warnings;
use Data::Dumper;
no if $] >= 5.018, 'warnings', "experimental::smartmatch";

use CGI qw/:standard/;
use Time::HiRes qw/gettimeofday tv_interval/;
use DBI::Simple;
#use Template::Simple;
use Template;
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
my $index_size    = $DB->select('SELECT ROUND(INDEX_LENGTH/1024/1024, 3) FROM information_schema.TABLES WHERE TABLE_SCHEMA = ? AND TABLE_NAME = ?', undef, [ $config{DB}{db_name}, $config{DB}{db_table} ]);

#my $tmpl = Template::Simple->new();
my $tt = Template->new({
    INCLUDE_PATH => 'templates',
    INTERPOLATE  => 1,
}) or die "$Template::ERROR";

print header('text/html; charset=UTF-8');
#$tmpl->compile( 'index', 1 );

my $sort    = ((param('sort') // '') eq 'd') ? 'DESC' : 'ASC';
my $sort_by = ((param('sort_by') // '') =~ /^(?:id|name|phone|created)$/) ? param('sort_by') : 'created';
warn $sort_by . ' ' . $sort;

my $pager = Pager::Simple->new(
    $DB,
    $config{DB}{db_table},
    {
        records_per_page => 30,
        (int(param('phone') // '') ? (condition => 'phone = ' . int(param('phone') // '')) : ()),
        sorting => $sort_by . ' ' . $sort
    }
);

#print ${$tmpl->render(
$tt->process(
    'index.tmpl',
    {
        'phones'     => $pager->first_page,
        #'pager'      => [map { {} } 1 .. 10],
        'exec_time'  => $timer->(),
        'records'    => $total_records =~ s/(\d)(?=(\d{3})+(\D|$))/$1\,/gr,
        'index_size' => $index_size,
        'sort'       => $sort,
        'sort_by'    => $sort_by,
    },
#    1
#)};
) or die $tt->error();

exit;

sub make_timer {
	my @times = ([gettimeofday()]);

	return sub {
		push(@times, [gettimeofday()]);

		return encode('utf-8', sprintf("%.06f с", tv_interval($times[-2], $times[-1])));
	};
}
