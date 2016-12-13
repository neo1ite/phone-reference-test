package DBI::Simple;

use utf8;
use strict;
use warnings;
use Data::Dumper;

use DBI;
use Encode qw(:fallbacks encode decode);

our $DEBUG = 0;

sub new {
    my ($invocant, $params) = @_;
    my $class = ref($invocant) || $invocant;
    my $self = { };
    $self->{dbh} = DBI->connect(
        'DBI:mysql:' . $params->{db_name}
            . ';host=' . $params->{db_host}
            . ';port=' . $params->{db_port},
        $params->{db_user},
        $params->{db_pass},
        { mysql_enable_utf8 => 1 }
    ) or die $DBI::errstr;
    bless($self, $class);

    if ($params->{db_charset}) {
        $self->query('SET CHARACTER SET ?;', undef, [ $params->{db_charset} ]);
        $self->query('SET NAMES ?;',         undef, [ $params->{db_charset} ]);
    }

    return $self;
}

# Функция дампа SQL запроса с параметрами
sub _mysql_query_dump { my $query = encode('UTF-8', shift); for ($query) { s/%/%%/g; s/^[\r\n]+//g; s/\?/\%s/g; } return sprintf($query, @_); }

# Обёртки с дампером SQL запросов для одноимённых методов DBI
sub query              { my ($self, $query, $attr, $bind) = @_; warn _mysql_query_dump($query, @{$bind}) if $DEBUG; my $result = $self->{dbh}->do($query, $attr, @{$bind}); return $result; }
sub select             { my ($self, $query, $attr, $bind) = @_; my @result = $self->{dbh}->selectrow_array($query, $attr, @{$bind});    warn _mysql_query_dump($query, @{$bind}) if $DEBUG; return shift @result; }
sub selectrow_array    { my ($self, $query, $attr, $bind) = @_; my @result = $self->{dbh}->selectrow_array($query, $attr, @{$bind});    warn _mysql_query_dump($query, @{$bind}) if $DEBUG; return @result; }
sub selectrow_hashref  { my ($self, $query, $attr, $bind) = @_; my $result = $self->{dbh}->selectrow_hashref($query, $attr, @{$bind});  warn _mysql_query_dump($query, @{$bind}) if $DEBUG; return $result; }
sub selectcol_arrayref { my ($self, $query, $attr, $bind) = @_; my $result = $self->{dbh}->selectcol_arrayref($query, $attr, @{$bind}); warn _mysql_query_dump($query, @{$bind}) if $DEBUG; return $result; }
sub selectall_arrayref { my ($self, $query, $attr, $bind) = @_; my $result = $self->{dbh}->selectall_arrayref($query, $attr, @{$bind}); warn _mysql_query_dump($query, @{$bind}) if $DEBUG; return $result; }

1;
