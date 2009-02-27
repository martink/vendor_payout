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
    unshift (@INC, $webguiRoot."/lib");
}

use strict;
use Pod::Usage;
use Getopt::Long;
use WebGUI::Session;
use WebGUI::User;
use WebGUI::Shop::Vendor;

# Get parameters here, including $help
GetOptions(
    'configFile=s'  => \$configFile,
);

my $session = start( $webguiRoot, $configFile );

my $vendors = createVendors( $session );

finish($session);

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
    
    ## If your script is adding or changing content you need these lines, otherwise leave them commented
    #
    # my $versionTag = WebGUI::VersionTag->getWorking($session);
    # $versionTag->set({name => 'Name Your Tag'});
    #
    ##
    
    return $session;
}

#----------------------------------------------------------------------------
sub finish {
    my $session = shift;
    
    ## If your script is adding or changing content you need these lines, otherwise leave them commented
    #
    # my $versionTag = WebGUI::VersionTag->getWorking($session);
    # $versionTag->commit;
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
