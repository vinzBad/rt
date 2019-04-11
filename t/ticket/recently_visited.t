use strict;
use warnings;

# test the RecentlyViewedTickets method

use Test::Deep;
use RT::Test::Shredder tests => 8;
my $test = "RT::Test::Shredder";

$test->create_savepoint('clean');

use RT::Ticket;

{   my @tickets=(undef); # the empty element is there so that $ticket[$i]->Id is $i
                         # (arrays start at 0, ids at 1);


    my $user = RT->SystemUser;
    is( $user->_visited_nb, 0, 'init: empty RecentlyViewedTickets');

    foreach my $ticket_nb (1..20) {
        my $ticket = RT::Ticket->new( $user );
        my ($id) = $ticket->Create( Subject => "test #$ticket_nb", Queue => 1 );
        push @tickets, $ticket;
        $ticket->ApplyTransactionBatch;
    }

    is( $user->_visited_nb, 0, 'tickets created: empty RecentlyViewedTickets');

    foreach my $viewed ( 1, 2, 3, 4, 5, 2, 16, 17, 3) {
      $user->AddRecentlyViewedTicket( $tickets[$viewed]);
    }

    is( $user->_visited, '3,17,16,2,5,4,1', 'visited tickets after inital visits');

    my $shredder = $test->shredder_new();

    $shredder->PutObjects( Objects => $tickets[13] );
    $shredder->WipeoutAll;
    is( $user->_visited, '3,17,16,2,5,4,1', 'visited tickets after shredding an unvisited ticket');

    $shredder->PutObjects( Objects => $tickets[16]);
    $shredder->PutObjects( Objects => $tickets[4] );
    $shredder->WipeoutAll;
    is( $user->_visited, '3,17,2,5,1', 'visited tickets after shredding 2 visited tickets');

    $tickets[2]->MergeInto( 10); 
    is( $user->_visited, '3,17,10,5,1', 'visited tickets after merging into a ticket that was NOT on the list');
    
    $tickets[5]->MergeInto( 10); 
    is( $user->_visited, '3,17,10,1', 'visited tickets after merging into a ticket that was on the list');

    foreach my $viewed ( 12, 14, 18, 10, 3, 8, 11, 3, 17, 3, 11, 9) {
      $user->AddRecentlyViewedTicket( $tickets[$viewed]);
    }
    is( $user->_visited, '9,11,3,17,8,10,18,14,12,1', 'visited more than 10 tickets');
}    

package RT::User;

sub _visited_nb
  { return scalar shift->RecentlyViewedTickets; }

sub _visited
  { return join ',', map { $_->{id} } shift->RecentlyViewedTickets; }




