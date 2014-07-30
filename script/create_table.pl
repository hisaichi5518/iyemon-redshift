use strict;
use warnings;
use Iyemon::Config;
use Iyemon::Web;
use FindBin;
use 5.10.1;

my $having_table = Iyemon::Web->handler->dbh->selectrow_hashref("SELECT 1 FROM information_schema.tables WHERE table_name = 'action_logs'");
exit if $having_table;

open my $fh, "<", "$FindBin::Bin/../sql/schema.sql" or die "Cant  open schmea file.";
my $sql = do { local $/; <$fh> };

say $sql;
Iyemon::Web->handler->dbh->do($sql);

say "created table for iyemon.";
