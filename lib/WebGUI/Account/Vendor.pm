package WebGUI::Account::Vendor;

use strict;

use WebGUI::Exception;
use WebGUI::International;
use WebGUI::Pluggable;
use WebGUI::Utility;
use base qw/WebGUI::Account/;

=head1 NAME

Package WebGUI::Account::Vendor

=head1 DESCRIPTION

Displays vendor information for the user, like payouts and product sales statistics.

=head1 SYNOPSIS

use WebGUI::Account::Vendor;


=head1 METHODS

These methods are available from this class:

=cut

#-------------------------------------------------------------------

=head2 canView ( )

    Returns whether or not the user can view the the tab for this module

=cut

sub canView {
    my $self  = shift;
    return 1; 
}

#-------------------------------------------------------------------

=head2 editSettingsForm ( )

  Creates form elements for user settings page custom to this account module

=cut

sub editSettingsForm {
    my $self    = shift;
    my $session = $self->session;
    my $i18n    = WebGUI::International->new($session,'Account_Vendor');
    my $f       = WebGUI::HTMLForm->new($session);

    $f->template(
		name      => "vendorStyleTemplateId",
		value     => $self->getStyleTemplateId,
		namespace => "style",
		label     => $i18n->echo("style template label"),
        hoverHelp => $i18n->echo("style template hoverHelp")
    );
    $f->template(
		name      => "vendorLayoutTemplateId",
		value     => $self->getLayoutTemplateId,
		namespace => "Account/Layout",
		label     => $i18n->echo("layout template label"),
        hoverHelp => $i18n->echo("layout template hoverHelp")
    );
    $f->template(
		name      => "vendorViewTemplateId",
		value     => $self->session->setting->get("vendorViewTemplateId"),
		namespace => "Account/Vendor/View",
		label     => $i18n->echo("view template label"),
        hoverHelp => $i18n->echo("view template hoverHelp"),
    );

    return $f->printRowsOnly;
}

#-------------------------------------------------------------------

=head2 editSettingsFormSave ( )

  Creates form elements for the settings page custom to this account module

=cut

sub editSettingsFormSave {
    my $self    = shift;
    my $session = $self->session;
    my $setting = $session->setting;
    my $form    = $session->form;

    $setting->set("vendorStyleTemplateId", $form->process("vendorStyleTemplateId","template"));
    $setting->set("vendorLayoutTemplateId", $form->process("vendorLayoutTemplateId","template"));
    $setting->set('vendorViewTemplateId', $form->process( 'vendorViewTemplateId', 'template') );
}

#-------------------------------------------------------------------

=head2 getLayoutTemplateId ( )

This method returns the templateId for the layout of your new module.

=cut

sub getLayoutTemplateId {
    my $self = shift;
    return $self->session->setting->get("vendorLayoutTemplateId") || $self->SUPER::getLayoutTemplateId;
}


#-------------------------------------------------------------------

=head2 getStyleTemplateId ( )

This method returns the template ID for the main style.

=cut

sub getStyleTemplateId {
    my $self = shift;
    return $self->session->setting->get("vendorStyleTemplateId") || $self->SUPER::getStyleTemplateId;
}

#-------------------------------------------------------------------
sub getViewVars {
    my $self    = shift;
    my $session = $self->session;
    my $vendor  = WebGUI::Shop::Vendor->newByUserId( $session, $session->user->userId );

    my $var = $vendor->getPayoutTotals;

    my $items = $session->db->buildArrayRefOfHashRefs(
        'select *, sum(quantity) as qty, sum(vendorPayoutAmount) as payoutAmount from transactionItem '
        .'where vendorId=? group by assetId order by qty desc',
        [ $vendor->getId ]
    );

    $var->{ item_loop } = $items;

    return $var;
}

#-------------------------------------------------------------------

=head2 www_view ( )

The main view page for editing the user's profile.

=cut

sub www_view {
    my $self    = shift;
    my $session = $self->session;
    my $var     = $self->getViewVars;

    
    use Data::Dumper;
    $session->log->warn( Dumper( $var ));


    return $self->processTemplate($var,$session->setting->get("vendorViewTemplateId"));
}


1;
