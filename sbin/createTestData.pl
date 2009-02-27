#!/usr/bin/env perl

#-------------------------------------------------------------------
# WebGUI is Copyright 2001-2008 Plain Black Corporation.
#-------------------------------------------------------------------
# Please read the legal notices (docs/legal.txt) and the license
# (docs/license.txt) that came with this distribution before using
# this software.
#-------------------------------------------------------------------
# http://www.plainblack.com                     info@plainblack.com
#-------------------------------------------------------------------

$|++; # disable output buffering
our ($webguiRoot, $configFile, $help, $man);

BEGIN {
    $webguiRoot = "..";
    push (@INC, $webguiRoot."/lib");
}

use strict;
use Pod::Usage;
use Getopt::Long;
use WebGUI::Session;
use WebGUI::User;
use WebGUI::Shop::Vendor;
use WebGUI::Shop::Cart;
use WebGUI::Shop::Transaction;
use WebGUI::Shop::Address;
use WebGUI::Shop::AddressBook;

# Get parameters here, including $help
GetOptions(
    'configFile=s'  => \$configFile,
);

my $session = start( $webguiRoot, $configFile );

$session->setting->set( 'versionTagMode', 'multiPerUser' );

my $vendors         = createVendors( $session );
my $products        = createProducts( $session, $vendors );
my $transactions    = createTransactions( $session, $products );


finish($session);

#----------------------------------------------------------------------------
sub createTransactions {
    my $session     = shift;
    my $products    = shift;
    my $productCount = scalar @{ $products };

    # Create a dummy address.
    my $addressBook = WebGUI::Shop::AddressBook->newBySession( $session );
    my $address = WebGUI::Shop::Address->create( $addressBook, {} );

    for my $i (1..50) {
        print "Setting up a new cart...\n";
        my $cart = WebGUI::Shop::Cart->create( $session );
        $cart->update( { 
            shippingAddressId   => $address->getId,
            shipperId           => 'defaultfreeshipping000',
        } );
        
        for (1..int(rand(6))) {
            my $sku = $products->[ int rand $productCount ];
            my $qty = int rand(4) + 1;

            print "\tAdding $qty item(s) ".$sku->getId ." -> ".$sku->get('title')."\n";
            my $item = $cart->addItem( $sku );
#            $item->setQuantity( $qty );
        }

        print "\tCreating transaction\n";
        my $transaction = WebGUI::Shop::Transaction->create( $session, { cart => $cart } );
        $transaction->completePurchase( "test transaction $i", 1, 'OK' );
    }

}

#----------------------------------------------------------------------------
sub createProducts {
    my $session = shift;
    my $vendors = shift;
    my @bazaarItems;

    # First create a bazaar
    print "Adding bazaar\n";
    my $bazaar = WebGUI::Asset->getImportNode( $session )->addChild( {
        className   => 'WebGUI::Asset::Wobject::Bazaar',
        title       => 'Vendor payout test bazaar',
        url         => 'testbazaar',
    } );

    # Create bazaar items
    for my $i (1..20) {
        my $vendor = $vendors->[ int rand( scalar @$vendors ) ];

        my $properties = {
            className               => 'WebGUI::Asset::Sku::BazaarItem',
            title                   => "Test bazaar item $i",
            price                   => $i < 6 ? 0 : $i,
            vendorPayoutPercentage  => $i % 2 ? int rand(101) : 0,
            vendorId                => $vendor->get('vendorId'),
        };

        print "\tAdding bazaar item: $properties->{title}, price: $properties->{price}, "
            ."vpp: $properties->{vendorPayoutPercentage} %, vendor: ".$vendor->get('name')."\n";
        my $item = $bazaar->addChild( $properties );
        $item->requestAutoCommit;
        push @bazaarItems, $item;
    }

    return \@bazaarItems;
}


#----------------------------------------------------------------------------
sub createVendors {
    my $session = shift;

    my @vendorDefinitions = (
        { name => 'Gekke Henk',     userId => 3 },
        { name => 'Lekker Boeie',   userId => 3 },
        { name => 'B Stanie',       userId => 3 },
    );

    my $vendorCount = 0;
    my @vendors;
    
    foreach (@vendorDefinitions) {
        (my $username = lc $_->{name} ) =~ s/ //g;
        my $userId = 'vendortest' . sprintf '%012d', $vendorCount++;

        print "\tCreaing user account. username: [$username] userId: [$userId]\n";
        my $user = WebGUI::User->new( $session, 'new', $userId );
        $user->username( $username );

        print "\tCreating vendor $_->{name}\n"; 
        my $vendor = WebGUI::Shop::Vendor->create( $session, { %$_, userId => $userId } );

        push @vendors, $vendor;
    }

    return \@vendors;
}


#----------------------------------------------------------------------------
sub start {
    my $webguiRoot  = shift;
    my $configFile  = shift;
    my $session = WebGUI::Session->open($webguiRoot,$configFile);
    $session->user({userId=>3});
    
    # If your script is adding or changing content you need these lines, otherwise leave them commented
    
     my $versionTag = WebGUI::VersionTag->getWorking($session);
     $versionTag->set({name => 'Name Your Tag'});
    
    #
    
    return $session;
}

#----------------------------------------------------------------------------
sub finish {
    my $session = shift;
    
    ## If your script is adding or changing content you need these lines, otherwise leave them commented
    
     my $versionTag = WebGUI::VersionTag->getWorking($session);
     $versionTag->commit;
    ##
    
    $session->var->end;
    $session->close;
}

__END__


=head1 NAME

utility - A template for WebGUI utility scripts

=head1 SYNOPSIS

 utility --configFile config.conf ...

 utility --help

=head1 DESCRIPTION

This WebGUI utility script helps you...

=head1 ARGUMENTS

=head1 OPTIONS

=over

=item B<--configFile config.conf>

The WebGUI config file to use. Only the file name needs to be specified,
since it will be looked up inside WebGUI's configuration directory.
This parameter is required.

=item B<--help>

Shows a short summary and usage

=item B<--man>

Shows this document

=back

=head1 AUTHOR

Copyright 2001-2008 Plain Black Corporation.

=cut

#vim:ft=perl
