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

#sub editSettingsForm {
#    my $self    = shift;
#    my $session = $self->session;
#    my $i18n    = WebGUI::International->new($session,'Account_NewModule');
#    my $f       = WebGUI::HTMLForm->new($session);
#
#    $f->template(
#		name      => "moduleStyleTemplateId",
#		value     => $self->getStyleTemplateId,
#		namespace => "style",
#		label     => $i18n->get("style template label"),
#        hoverHelp => $i18n->get("style template hoverHelp")
#    );
#    $f->template(
#		name      => "moduleLayoutTemplateId",
#		value     => $self->getLayoutTemplateId,
#		namespace => "Account/Layout",
#		label     => $i18n->get("layout template label"),
#        hoverHelp => $i18n->get("layout template hoverHelp")
#    );
#    $f->template(
#		name      => "moduleViewTemplateId",
#		value     => $self->session->setting->get("moduleViewTemplateId"),
#		namespace => "Account/NewModule/View",
#		label     => $i18n->get("view template label"),
#        hoverHelp => $i18n->get("view template hoverHelp")
#    );
#
#    return $f->printRowsOnly;
#}

#-------------------------------------------------------------------

=head2 editSettingsFormSave ( )

  Creates form elements for the settings page custom to this account module

=cut

#sub editSettingsFormSave {
#    my $self    = shift;
#    my $session = $self->session;
#    my $setting = $session->setting;
#    my $form    = $session->form;
#
#    $setting->set("moduleStyleTemplateId", $form->process("moduleStyleTemplateId","template"));
#    $setting->set("moduleLayoutTemplateId", $form->process("moduleLayoutTemplateId","template"));
#    $setting->set("moduleViewTemplateId", $form->process("moduleViewTemplateId","template"));
#}

#-------------------------------------------------------------------

=head2 getLayoutTemplateId ( )

This method returns the templateId for the layout of your new module.

=cut

#sub getLayoutTemplateId {
#    my $self = shift;
#    return $self->session->setting->get("moduleLayoutTempalteId") || $self->SUPER::getLayoutTemplateId;
#}


#-------------------------------------------------------------------

=head2 getStyleTemplateId ( )

This method returns the template ID for the main style.

=cut

#sub getStyleTemplateId {
#    my $self = shift;
#    return $self->session->setting->get("moduleStyleTemplateId") || $self->SUPER::getStyleTemplateId;
#}

#-------------------------------------------------------------------

=head2 www_view ( )

The main view page for editing the user's profile.

=cut

sub www_view {
    my $self    = shift;
    my $session = $self->session;
    my $var     = {};
    my $vendor  = WebGUI::Shop::Vendor->newByUserId( $session, $session->user->userId );

    my $payoutTotals = $session->db->buildHashRef(
        'select vendorPayoutStatus, sum(vendorPayoutAmount) from transactionItem '
        .'where vendorId=? group by vendorPayoutStatus ',
        [ $vendor->getId ]
    );

    my $output = <<EOHTML;
        Paid : $payoutTotals->{ Paid }<br />
        Scheduled for payment : $payoutTotals->{ Scheduled }<br />
        Pending : $payoutTotals->{ NotPaid }<br />
EOHTML
    return $output;
    
    return $self->processTemplate($var,$session->setting->get("moduleViewTemplateId"));
}


1;