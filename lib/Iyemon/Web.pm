package Iyemon::Web;
use 5.10.1;
use strict;
use warnings;
use utf8;
use Kossy;
use Scalar::Util qw/looks_like_number blessed/;
use DateTime;
use DateTime::Format::Strptime;
use Iyemon::Config;
use DBIx::Handler;
use SQL::Maker;

my $handler = DBIx::Handler->new(@{config->param("DBIx::Handler")});
sub handler {
    $handler;
}

sub sql_maker {
    state $sql_maker = SQL::Maker->new(driver => "Pg");
}

get '/' => sub {
    my ($self, $c) = @_;

    $c->render('index.tx', {config => Iyemon::Config->current});
};

get '/search' => sub {
    my ($self, $c) = @_;

    my @where = map { $_ => scalar $c->req->param($_) }
        grep { scalar $c->req->param($_) }
        qw(uid type);

    my $start_date = $c->req->param("start_date") or $c->halt(400);
    my $end_date   = $c->req->param("end_date" )  || DateTime->now;

    my $strp = DateTime::Format::Strptime->new(pattern => '%Y-%m-%dT%H:%M');
    push @where, (
        time => {
            ">=" => $strp->parse_datetime($start_date)->epoch,
            "<=" => $strp->parse_datetime($end_date)->epoch,
        },
    );

    my $page  = $c->req->param("page");
    my $limit = 100 * $page;

    my ($sql, @binds) = sql_maker->select("action_logs",
        ["uid", "time", "type", "json"],
        \@where,
        {limit => $limit, offset => $limit - 100},
    );

    my ($rows) = handler->dbh->selectall_arrayref($sql, {Slice => {}}, @binds);

    $c->render_json({results => _build($rows)});
};

sub _build {
    my $obj = shift;

    for my $hashref (@$obj) {
        $hashref->{time} = DateTime->from_epoch(
            epoch => $hashref->{time},
        )->strftime("%Y-%m-%d %H:%M:%S")
    }
    $obj;
}

1;
