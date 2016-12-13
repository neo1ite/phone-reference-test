#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
use utf8;

use DBI;
use Config::General qw(ParseConfig SaveConfig);
use String::Random qw/random_string/;
use Term::ProgressBar::Simple;

use constant CONFIG_FILE   => '../cgi-bin/site.conf';
use constant MYSQL_DEBUG   => 0;
use constant MYSQL_RECORDS => 12_000_000;
use constant BULK_SIZE     => 1000;

# Load config
my %config = ParseConfig( -ConfigFile => CONFIG_FILE );

my $dbh = DBI->connect(
    'DBI:mysql:' . $config{DB}{db_name}
        . ';host=' . $config{DB}{db_host}
        . ';port=' . $config{DB}{db_port},
    $config{DB}{db_user},
    $config{DB}{db_pass},
    { mysql_enable_utf8 => 1 }
) or die $DBI::errstr;
query($dbh, 'SET CHARACTER SET ?;', undef, [ $config{DB}{db_charset} ]);
query($dbh, 'SET NAMES ?;',         undef, [ $config{DB}{db_charset} ]);

my $progress = Term::ProgressBar::Simple->new( MYSQL_RECORDS / BULK_SIZE );

my $insert_count = 0;
for (1 .. MYSQL_RECORDS / BULK_SIZE) {

    query($dbh,
        'INSERT INTO `' . $config{DB}{db_table} . '` (name, phone) VALUES ' . join(', ', ('(?, ?)') x BULK_SIZE),
        undef,
        [
            map {
                (random_string('0' x 12, ['A' .. 'Z', 'a' .. 'z']), random_string('n' x 11))
            } (1 .. BULK_SIZE)
        ]
    );
    $progress++;
    $insert_count++;
}

print "DONE! $insert_count inserts with " . BULK_SIZE . " bulk size (total " . ($insert_count * BULK_SIZE) . " records inserted)\n";

exit 0;

# Функция дампа SQL запроса с параметрами
sub _mysql_query_dump { my $query = encode('UTF-8', shift); for ($query) { s/%/%%/g; s/^[\r\n]+//g; s/\?/\%s/g; } return sprintf($query, @_); }
# Обёртки с дампером SQL запросов для одноимённых методов DBI
sub query              { my ($dbh, $query, $attr, $bind) = @_; warn _mysql_query_dump($query, @{$bind}) if MYSQL_DEBUG; my $result = $dbh->do($query, $attr, @{$bind}); return $result; }
sub selectrow_array    { my ($dbh, $query, $attr, $bind) = @_; my @result = $dbh->selectrow_array($query, $attr, @{$bind});    warn _mysql_query_dump($query, @{$bind}) if MYSQL_DEBUG; return @result; }
sub selectrow_hashref  { my ($dbh, $query, $attr, $bind) = @_; my $result = $dbh->selectrow_hashref($query, $attr, @{$bind});  warn _mysql_query_dump($query, @{$bind}) if MYSQL_DEBUG; return $result; }
sub selectcol_arrayref { my ($dbh, $query, $attr, $bind) = @_; my $result = $dbh->selectcol_arrayref($query, $attr, @{$bind}); warn _mysql_query_dump($query, @{$bind}) if MYSQL_DEBUG; return $result; }
sub selectall_arrayref { my ($dbh, $query, $attr, $bind) = @_; my $result = $dbh->selectall_arrayref($query, $attr, @{$bind}); warn _mysql_query_dump($query, @{$bind}) if MYSQL_DEBUG; return $result; }
