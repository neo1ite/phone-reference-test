package Pager::Simple;

use utf8;
use strict;
use warnings;
use Data::Dumper;

sub new {
    my ($invocant, $db, $table, $params) = @_;
    my $class = ref($invocant) || $invocant;
    my $self = {
        db               => $db,
        table            => $table,
        condition        => $params->{condition},
        aggregation      => $params->{aggregation},
        sorting          => $params->{sorting},
        page             => $params->{page} || 1,
        records_per_page => $params->{records_per_page} || 30,
    };
    bless($self, $class);

    $self->{records} = $self->_records;

    return $self;
}

sub first_page {
    my $self = shift;

    $self->{page} = 1;
    return $self->{db}->selectall_arrayref('SELECT * ' . $self->_query_construct . ' LIMIT 0, ' . $self->{records_per_page}, { Slice => {} });
}

sub last_page {
    my $self = shift;

    $self->{page} = $self->pages;
    return $self->{db}->selectall_arrayref('SELECT * ' . $self->_query_construct . ' LIMIT ' . (($self->pages - 1) * $self->{records_per_page}) . ', ' . $self->{records_per_page}, { Slice => {} });
}

sub next_page {

}

sub prev_page {

}

sub get_page {
    my ($self, $page) = @_;
    return if ($page > $self->pages || $page < 1);

    $self->{page} = $page;
    return $self->{db}->selectall_arrayref('SELECT * ' . $self->_query_construct . ' LIMIT ' . ($page * $self->{records_per_page}) . ', ' . $self->{records_per_page}, { Slice => {} });
}

sub pages {
    my $self = shift;

    return int($self->{records} / $self->{records_per_page}) + (($self->{records} % $self->{records_per_page}) ? 1 : 0);
}

sub _records {
    my $self = shift;

    return $self->{db}->select('SELECT COUNT(*) ' . $self->_query_construct);
}

sub _query_construct {
    my $self = shift;

    return 'FROM ' . $self->{table}
        . ($self->{condition}   ? ' WHERE '    . $self->{condition}   : '')
        . ($self->{aggregation} ? ' GROUP BY ' . $self->{aggregation} : '')
        . ($self->{sorting}     ? ' ORDER BY ' . $self->{sorting}     : '');
}

1;
