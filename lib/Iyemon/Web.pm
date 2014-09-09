package Iyemon::Web;
use 5.10.1;
use strict;
use warnings;
use utf8;
use Kossy;
use Scalar::Util qw/looks_like_number blessed/;
use DateTime;
use DateTime::Format::Strptime;
use DateTime::TimeZone;
use Iyemon::Config;
use DBIx::Handler;
use SQL::Maker;
use Digest::SHA1;

my $handler = DBIx::Handler->new(@{config->param("DBIx::Handler")});
sub handler {
    $handler;
}

sub sql_maker {
    state $sql_maker = SQL::Maker->new(driver => "Pg");
}

sub time_zone {
    state $time_zone = DateTime::TimeZone->new(name => config->param("time_zone"));
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
    my $end_date   = $c->req->param("end_date" )  || DateTime->now(time_zone => time_zone());

    my $strp = DateTime::Format::Strptime->new(
        pattern   => '%Y-%m-%dT%H:%M',
        time_zone => time_zone(),
    );
    push @where, (
        time => [
            "-and",
            { ">=" => $strp->parse_datetime($start_date)->epoch },
            { "<=" => $strp->parse_datetime($end_date)->epoch },
        ],
    );

    my $page  = $c->req->param("page");
    my $limit = 100 * $page;

    my ($sql, @binds) = sql_maker->select("action_logs",
        ["uid", "time", "type", "json"],
        \@where,
        {order_by => "time", limit => $limit, offset => $limit - 100},
    );

    my ($rows) = handler->dbh->selectall_arrayref($sql, {Slice => {}}, @binds);

    $c->render_json({results => _build($rows)});
};

sub _build {
    my $obj = shift;

    for my $hashref (@$obj) {
        $hashref->{time} = DateTime->from_epoch(
            epoch     => $hashref->{time},
            time_zone => time_zone(),
        )->strftime("%Y-%m-%d %H:%M:%S");
        $hashref->{_id} = Digest::SHA1::sha1_hex(rand(100000) . $$ . {} . $hashref->{time});
    }
    $obj;
}

1;
