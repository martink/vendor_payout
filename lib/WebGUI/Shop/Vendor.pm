package WebGUI::Shop::Vendor;

use strict;
use Class::InsideOut qw{ :std };
use WebGUI::Shop::Admin;
use WebGUI::Exception::Shop;
use WebGUI::International;
use WebGUI::Utility qw{ isIn };
use JSON qw{ encode_json };

=head1 NAME

Package WebGUI::Shop::Vendor

=head1 DESCRIPTION

Keeps track of vendors that sell merchandise in the store.

=head1 SYNOPSIS

 use WebGUI::Shop::Vendor;

 my $vendor = WebGUI::Shop::Vendor->new($session, $vendord);

=head1 METHODS

These subroutines are available from this package:

=cut

readonly session => my %session;
readonly properties => my %properties;

#-------------------------------------------------------------------

=head2 create ( session, properties )

Constructor. Creates a new vendor.

=head3 session

A reference to the current session.

=head3 properties

A hash reference containing the properties for this vendor. See update() for details.

=cut

sub create {
    my ($class, $session, $properties) = @_;
    unless (defined $session && $session->isa("WebGUI::Session")) {
        WebGUI::Error::InvalidObject->throw(expected=>"WebGUI::Session", got=>(ref $session), error=>"Need a session.");
    }
    my $id = $session->id->generate;
    $session->db->write("insert into vendor (vendorId, dateCreated) values (?, now())",[$id]);
    my $self = $class->new($session, $id);
    $self->update($properties);
    return $self;
}

#-------------------------------------------------------------------

=head2 delete ()

Deletes this vendor.

=cut

sub delete {
    my ($self) = @_;
    $self->session->db->deleteRow("vendor","vendorId",$self->getId);
}

#-------------------------------------------------------------------

=head2 get ( [ property ] )

Returns a duplicated hash reference of this object�s data. See update() for details.

=head3 property

Any field returns the value of a field rather than the hash reference.

=head3 Additional properties

=head4 dateCreated

The date this vendor was created in the system.

=head4 vendorId

The id of this vendor from the database.  Use getId() instead.

=cut

sub get {
    my ($self, $name) = @_;
    if (defined $name) {
        return $properties{id $self}{$name};
    }
    my %copyOfHashRef = %{$properties{id $self}};
    return \%copyOfHashRef;
}

#-------------------------------------------------------------------

=head2 getId () 

Returns the unique id of this item.

=cut

sub getId {
    my $self = shift;
    return $self->get("vendorId");
}

#-------------------------------------------------------------------

=head2 getVendors ( session, options )

Class method. Returns an array reference of WebGUI::Shop::Vendor objects.

=head3 session

A reference to the current session.

=head3 options

A hash reference of optional flags.

=head4 asHashRef

A boolean indicating that the vendors should be returned as a hash reference of id/names rather than an array of objects.

=cut

sub getVendors {
    my ($class, $session, $options) = @_;
    my $vendorList = $session->db->buildHashRef("select vendorId,name from vendor order by name");
    if ($options->{asHashRef}) {
        return $vendorList;
    }
    my @vendors = ();
    foreach my $id (keys %{$vendorList}) {
        push @vendors, $class->new($session, $id);
    }
    return \@vendors;
}

#-------------------------------------------------------------------

=head2 new ( session, vendorId )

Constructor.   Returns a WebGUI::Shop::Vendor object.

=head3 session

A reference to the current session.  If the session variable is not passed, then an WebGUI::Error::InvalidObject
Exception will be thrown.

=head3 vendorId

A unique id for a vendor that already exists in the database.  If the vendorId is not passed
in, then a WebGUI::Error::InvalidParam Exception will be thrown.  If the requested Id cannot
be found in the database, then a WebGUI::Error::ObjectNotFound exception will be thrown.

=cut

sub new {
    my ($class, $session, $vendorId) = @_;
    unless (defined $session && $session->isa("WebGUI::Session")) {
        WebGUI::Error::InvalidObject->throw(expected=>"WebGUI::Session", got=>(ref $session), error=>"Need a session.");
    }
    unless (defined $vendorId) {
        WebGUI::Error::InvalidParam->throw( param=>$vendorId, error=>"Need a vendorId.");
    }
    my $vendor = $session->db->quickHashRef("select * from vendor where vendorId=?",[$vendorId]);
    if ($vendor->{vendorId} eq "") {
        WebGUI::Error::ObjectNotFound->throw(error=>"Vendor not found.", id=>$vendorId);
    }
    my $self = register $class;
    my $id        = id $self;
    $session{ $id } = $session;
    $properties{ $id } = $vendor;
    return $self;
}

#-------------------------------------------------------------------

=head2 newByUserId ( session, [userId] )

Constructor. 

=head3 session

A reference to the current session.

=head3 userId

A unique userId. Will pull from the session if not specified.

=cut

sub newByUserId {
    my ($class, $session, $userId) = @_;
        unless (defined $session && $session->isa("WebGUI::Session")) {
        WebGUI::Error::InvalidObject->throw(expected=>"WebGUI::Session", got=>(ref $session), error=>"Need a session.");
    }
    $userId ||= $session->user->userId;
    unless (defined $userId) {
        WebGUI::Error::InvalidParam->throw( param=>$userId, error=>"Need a userId.");
    }
    return $class->new($session, $session->db->quickScalar("select vendorId from vendor where userId=?",[$userId]));
}


#-------------------------------------------------------------------

=head2 session () 

Returns a reference to the current session.

=cut

#-------------------------------------------------------------------

=head2 update ( properties )

Sets properties of the vendor

=head3 properties

A hash reference that contains one of the following:

=head4 name

The name of the vendor.

=head4 userId

The name of the vendor.

=head4 url

The vendor's url.

=head4 paymentInformation

????

=head4 preferredPaymentType

????

=cut

sub update {
    my ($self, $newProperties) = @_;
    my $id = id $self;
    my @fields = (qw(name userId url paymentInformation preferredPaymentType));
    foreach my $field (@fields) {
        $properties{$id}{$field} = (exists $newProperties->{$field}) ? $newProperties->{$field} : $properties{$id}{$field};
    }
    $self->session->db->setRow("vendor","vendorId",$properties{$id});
}

#-------------------------------------------------------------------

=head2 www_delete (  )

Deletes a vendor.

=cut

sub www_delete {
    my ($class, $session)    = @_;
    my $admin   = WebGUI::Shop::Admin->new($session);
    return $session->privilege->adminOnly() unless ($admin->canManage);
    my $self = $class->new($session, $session->form->get("vendorId"));
    if (defined $self) {
        $self->delete;
    }
    return $class->www_manage($session);
}

#-------------------------------------------------------------------

=head2 www_edit (  )

Displays an edit form for a vendor.

=cut

sub www_edit {
    my ($class, $session)    = @_;
    my $admin   = WebGUI::Shop::Admin->new($session);
    return $session->privilege->adminOnly() unless ($admin->canManage);
    
    # get properties
    my $self = eval{$class->new($session, $session->form->get("vendorId"))};
    my $properties = {};
    if (!WebGUI::Error->caught && defined $self) {
        $properties = $self->get;
    }
    
    # draw form
    my $i18n    = WebGUI::International->new($session, "Shop");
    my $f = WebGUI::HTMLForm->new($session);
    $f->hidden(name=>'shop',value=>'vendor');
    $f->hidden(name=>'method',value=>'editSave');
    $f->hidden(name=>'vendorId',value=>$properties->{vendorId});
    $f->readOnly(label=>$i18n->get('date created'),value=>$properties->{dateCreated});
    $f->text(name=>'name', label=>$i18n->get('name'),value=>$properties->{name});
    $f->user(name=>'userId',label=>$i18n->get('username'),value=>$properties->{userId},defaultValue=>3);
    $f->url(name=>'url', label=>$i18n->get('company url'),value=>$properties->{url});
    $f->text(name=>'preferredPaymentType', label=>$i18n->get('Preferred Payment Type'),value=>$properties->{preferredPaymentType});
    $f->textarea(name=>'paymentInformation', label=>$i18n->get('Payment Information'),value=>$properties->{paymentInformation});
    $f->submit();

    # Wrap in admin console
    my $console = $admin->getAdminConsole;
    return $console->render($f->print, $i18n->get("vendors"));
}

#-------------------------------------------------------------------

=head2 www_editSave (  )

Saves the results of www_edit()

=cut

sub www_editSave {
    my ($class, $session)    = @_;
    my $admin   = WebGUI::Shop::Admin->new($session);
    return $session->privilege->adminOnly() unless ($admin->canManage);
    my $form = $session->form;
    my $properties = {
        name                    => $form->get("name","text"),              
        preferredPaymentType    => $form->get("preferredPaymentType","text"),              
        paymentInformation      => $form->get("paymentInformation","textarea"),              
        userId                  => $form->get("userId","user",'3'),              
        url                     => $form->get("url","url"),              
        };
    my $self = eval{$class->new($session, $form->get("vendorId"))};
    if (!WebGUI::Error->caught && defined $self) {
        $self->update($properties);
    }
    else {
        $class->create($session, $properties);
    }
    return $class->www_manage($session);
}


#-------------------------------------------------------------------

=head2 www_manage (  )

Displays the list of vendors.

=cut

sub www_manage {
    my ($class, $session)    = @_;
    my $admin   = WebGUI::Shop::Admin->new($session);
    my $i18n    = WebGUI::International->new($session, "Shop");

    return $session->privilege->adminOnly() unless ($admin->canManage);

    # Button for adding a vendor
    my $output = WebGUI::Form::formHeader($session)
        .WebGUI::Form::hidden($session,     { name  => "shop",      value   => "vendor" })
        .WebGUI::Form::hidden($session,     { name  => "method",    value   => "edit" })
        .WebGUI::Form::submit($session,     { value => $i18n->get("add a vendor") })
        .WebGUI::Form::formFooter($session);

    # Add a row with edit/delete buttons for each 
    foreach my $vendor (@{$class->getVendors($session)}) {
        $output .= '<div style="clear: both;">'
            # Delete button 
			.WebGUI::Form::formHeader($session, {extras=>'style="float: left;"' })
            .WebGUI::Form::hidden($session, { name   => "shop",                value => "vendor" })
            .WebGUI::Form::hidden($session, { name   => "method",              value => "delete" })
            .WebGUI::Form::hidden($session, { name   => "vendorId",    value => $vendor->getId })
            .WebGUI::Form::submit($session, { value  => $i18n->get("delete"), extras => 'class="backwardButton"' }) 
            .WebGUI::Form::formFooter($session)

            # Edit button
            .WebGUI::Form::formHeader($session, {extras=>'style="float: left;"' })
            .WebGUI::Form::hidden($session, { name   => "shop",              value => "vendor" })
            .WebGUI::Form::hidden($session, { name   => "method",            value => "edit" })
            .WebGUI::Form::hidden($session, { name   => "vendorId",  value => $vendor->getId })
            .WebGUI::Form::submit($session, { value  => $i18n->get("edit"), extras => 'class="normalButton"' })
            .WebGUI::Form::formFooter($session)

            # Append name
            .' '. $vendor->get("name") 
        .'</div>';        
    }

    # Wrap in admin console
    my $console = $admin->getAdminConsole;
    return $console->render($output, $i18n->get("vendors"));
}


#-------------------------------------------------------------------
sub www_submitScheduledPayouts {
    my $class   = shift;
    my $session = shift;

    $session->db->write(
        q{ update transactionItem set vendorPayoutStatus = 'Payed' where vendorPayoutStatus = 'Scheduled' }
    );

    return $class->www_managePayouts( $session );
}

#-------------------------------------------------------------------
sub www_setPayoutStatus {
    my $class   = shift;
    my $session = shift;
    my @itemIds = $session->form->process('itemId');
    my $status  = $session->form->process('status');
    return "error: wrong status [$status]" unless isIn( $status, qw{ NotPayed Scheduled } );

    foreach  my $itemId (@itemIds) {
       my $item = WebGUI::Shop::TransactionItem->newByDynamicTransaction( $session, $itemId );
       return "error: invalid transactionItemId [$itemId]" unless $item;
    
       $item->update({ vendorPayoutStatus => $status });
    }

    return $status;
}

#-------------------------------------------------------------------
sub www_vendorTotalsAsJSON {
    my $class       = shift;
    my $session     = shift;
    my $vendorId    = $session->form->process('vendorId');
    my ($vendorPayoutData, @placeholders);
  
    my @sql;
    push @sql,
        'select vendorId, vendorPayoutStatus, sum(vendorPayoutAmount) as total from transactionItem';
    push @sql, ' where vendorId=? ' if $vendorId;
    push @sql, ' group by vendorId, vendorPayoutStatus ';

    push @placeholders, $vendorId if $vendorId;

    my $sth = $session->db->read( join( ' ', @sql) , \@placeholders );
    while (my $row = $sth->hashRef) {
        $vendorPayoutData->{ $row->{vendorId} }->{ $row->{vendorPayoutStatus} } = $row->{total};
    }
    $sth->finish;

    my @dataset;
    foreach my $vendorId (keys %{ $vendorPayoutData }) {
        my $vendor = WebGUI::Shop::Vendor->new( $session, $vendorId );

        push @dataset, {
            %{ $vendor->get },
            %{ $vendorPayoutData->{ $vendorId } },
        }
    }

    $session->http->setMimeType( 'application/json' );
    return JSON::to_json( { vendors => \@dataset } );
}

#-------------------------------------------------------------------
sub www_payoutDataAsJSON {
    my $class   = shift;
    my $session = shift;
    my $vendorId = $session->form->process('vendorId');
    my $limit   = $session->form->process('limit') || 100;

    my $data = $session->db->buildArrayRefOfHashRefs(
        "select t1.* from transactionItem as t1 join transaction as t2 on t1.transactionId=t2.transactionId "
        ." where vendorId=? order by t2.orderNumber limit ?",
        [ $vendorId, $limit ],
    );

    $session->http->setMimeType( 'application/json' );

    return JSON::to_json( { results => $data } );
}

#-------------------------------------------------------------------
sub www_managePayouts {
    my $class   = shift;
    my $session = shift;
    my $vendors = {};

    my $sth = $session->db->read(
        "select itemId from transactionItem "
        ." where vendorId is not null and vendorId != ? and vendorPayoutStatus=?", 
        [
            'defaultvendor000000000',
            'NotPayed',
        ],
    );

    while (my $row = $sth->hashRef) {
        my $item    = WebGUI::Shop::TransactionItem->newByDynamicTransaction( $session, $row->{ itemId } );
        next unless defined $item;

        my $sku     = $item->getSku;
        next unless defined $sku;
        
        my $vendorId = $item->get('vendorId');

        unless (exists $vendors->{ $vendorId }) {
            my $vendor = WebGUI::Shop::Vendor->new( $session, $item->get('vendorId') );
            $vendors->{ $vendorId } = $vendor->get;
        }
        my $vendor = $vendors->{ $vendorId };
            
        my $payoutAmount = $sku->getVendorPayout * $item->get('quantity');
        $vendor->{ totalPayout } += $payoutAmount;

        push @{ $vendor->{ itemLoop }  }, {
            %{ $item->get },
            # TODO: remove the line below
            vendorPayoutPercentage  => $sku->get('vendorPayoutPercentage'),
            vendorPayoutAmount      => $payoutAmount,
        }
    }

    $sth->finish;

    # For now just put everything in some inline html. If it'll stay like this, move 
    # this code into the while loop above.
    $session->style->setLink('/extras/yui/build/datatable/assets/skins/sam/datatable.css', {type=>'text/css', rel=>'stylesheet'});
    $session->style->setScript('/extras/yui/build/yahoo-dom-event/yahoo-dom-event.js', {type=>'text/javascript'});
    $session->style->setScript('/extras/yui/build/element/element-beta-min.js', {type=>'text/javascript'});
    $session->style->setScript('/extras/yui/build/connection/connection-min.js', {type=>'text/javascript'});
    $session->style->setScript('/extras/yui/build/json/json-min.js', {type=>'text/javascript'});
    $session->style->setScript('/extras/yui/build/datasource/datasource-min.js', {type=>'text/javascript'});
    $session->style->setScript('/extras/yui/build/datatable/datatable-min.js', {type=>'text/javascript'});
    $session->style->setScript('/extras/yui/build/button/button-min.js', {type=>'text/javascript'});
    $session->style->setScript('/extras/VendorPayout/vendorPayout.js', {type=>'text/javascript'});

    my $output = q{<div id="vendorPayoutContainer" class="yui-skin-sam"></div>}
        .q{<script type="text/javascript">var vp = new WebGUI.VendorPayout( 'vendorPayoutContainer' );</script>};

#    my $dataDef = [
#        { key => 'itemId',              label => 'ID'               },
#        { key => 'configuredTitle',     label => 'Item'             },
#        { key => 'price',               label => 'Price'            },
#        { key => 'quantity',            label => 'Qty'              },
#        { key => 'vendorPayoutAmount',  label => 'Payout'           },
#        { key => 'vendorPayoutStatus',  label => 'Payout status'    },
#    ];
#    my $dataDefJSON = encode_json( $dataDef );
#
#    my $output = qq{<script type="text/javascript">var vpDataDef = $dataDefJSON;</script>};
#    $output .= qq{<div class="yui-skin-sam">};
#
#    my $vendorCount = 0;
#    foreach my $vendor ( values %{ $vendors } ) {
#        $vendorCount++;
#
#        my $id              = "v$vendorCount";
#        my $jsonUrl         = $session->url->page('shop=vendor;method=payoutDataAsJSON;vendorId='.$vendor->{vendorId});
#        my $updateStatusUrl = $session->url->page('shop=vendor;method=setPayoutStatus');
#
#        $output .= '<h2>' . $vendor->{name}. ' - total amount: '. $vendor->{totalPayout} . '</h2>';
#        $output .= qq|\n<div id="$id"></div>\n|;
#        $output .= 
#<<EOJS;
#            <script type="text/javascript">
#                var ds_$id  = new YAHOO.util.DataSource( '$jsonUrl' );
#                ds_$id.responseType = YAHOO.util.DataSource.TYPE_JSON;
#                ds_$id.responseSchema = {
#                        resultsList : 'results',
#                        fields : [
#                            { key: 'itemId' },
#                            { key: 'configuredTitle' }, 
#                            { key: 'price' }, 
#                            { key: 'quantity' }, 
#                            { key: 'vendorPayoutAmount' }, 
#                            { key: 'vendorPayoutStatus' }
#                        ]
#                };
#                var vpt_$id = new YAHOO.widget.DataTable( '$id', vpDataDef, ds_$id );
#                vpt_$id.subscribe( "rowClickEvent", function (e) {
#                    var record      = this.getRecord( e.target );
#                    var callback    = {
#                        scope   : this,
#                        success : function ( o ) {
#                            var status = o.responseText;
#                            if ( status.match(/^error/) ) {
#                                alert( status );
#                                return;
#                            }
#
#                            this.updateCell( record, 'vendorPayoutStatus', status );
#                        }
#                    };
#                
#                    var status = record.getData( 'vendorPayoutStatus' ) === 'NotPayed' ? 'Scheduled' : 'NotPayed';
#                    var url = '$updateStatusUrl' + ';itemId=' + record.getData( 'itemId' ) + ';status=' + status;
#                    YAHOO.util.Connect.asyncRequest( 'post', url, callback );
#                } );
#                
#            </script>
#EOJS
#    }        
#
#    $output .= q{</div>};

    my $console = WebGUI::Shop::Admin->new($session)->getAdminConsole;
    return $console->render($output, 'Vendor payout'); #$i18n->get("vendors"));
}

1;
