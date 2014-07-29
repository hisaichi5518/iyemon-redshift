use strict;
use warnings;
use Iyemon::Config;
use Iyemon::Web;
use FindBin;
use 5.10.1;


open my $fh, "<", "$FindBin::Bin/../sql/schema.sql" or die "Cant  open schmea file.";
my $sql = do { local $/; <$fh> };

say $sql;
Iyemon::Web->handler->dbh->do($sql);

say "created table for iyemon.";
