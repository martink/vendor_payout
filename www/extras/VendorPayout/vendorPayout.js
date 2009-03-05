if (typeof WebGUI == "undefined" || !WebGUI) {
    var WebGUI = {};
}

WebGUI.VendorPayout = function ( containerId ) {
    this.container  = document.getElementById( containerId );

    this.vendorList     = document.createElement('div');
    this.container.appendChild( this.vendorList );

    this.payoutDetails  = document.createElement('div');
    this.container.appendChild( this.payoutDetails );

    this.itemBaseUrl = '/?shop=vendor;method=payoutDataAsJSON;vendorId='; 


    this.initVendorList();
    this.initPayoutDetails();

    return this;
}

//----------------------------------------------------------------------------
WebGUI.VendorPayout.prototype.initVendorList = function () {
    var obj = this;
    this.vendorSchema = [
        { key: 'vendorId'   },
        { key: 'name' },
        { key: 'Scheduled'  }, 
        { key: 'NotPayed'   }
    ];

    // setup data source
    var url = '/?shop=vendor;method=vendorTotalsAsJSON';
    this.vendorDataSource = new YAHOO.util.DataSource( url );
    this.vendorDataSource.responseType      = YAHOO.util.DataSource.TYPE_JSON;
    this.vendorDataSource.responseSchema    = {
        resultsList : 'vendors',
        fields : this.vendorSchema
    };

    // initialise data table
    this.vendorDataTable = new YAHOO.widget.DataTable( this.vendorList, this.vendorSchema, this.vendorDataSource );

    // add row click handler that fetches this vendor's data for the payout details table
    this.vendorDataTable.subscribe( "rowClickEvent", function (e) {
        var record  = this.getRecord( e.target );
        obj.currentVendorId = record.getData( 'vendorId' );

        var url = obj.itemBaseUrl + obj.currentVendorId;
        obj.itemDataSource.sendRequest( obj.currentVendorId, {
            success : obj.itemDataTable.onDataReturnReplaceRows, //InitializeTable,
            scope   : obj.itemDataTable
        });
    } );
}

//----------------------------------------------------------------------------
WebGUI.VendorPayout.prototype.initPayoutDetails = function () {
    this.itemSchema = [
        { key: 'itemId' },
        { key: 'configuredTitle' }, 
        { key: 'price' }, 
        { key: 'quantity' }, 
        { key: 'vendorPayoutAmount' }, 
        { key: 'vendorPayoutStatus' }
    ]

    var url = this.itemBaseUrl + this.currentVendorId;
    this.itemDataSource  = new YAHOO.util.DataSource( this.itemBaseUrl );
    this.itemDataSource.responseType    = YAHOO.util.DataSource.TYPE_JSON;
    this.itemDataSource.responseSchema  = {
        resultsList : 'results',
        fields      : this.itemSchema
    };
    this.itemDataTable = new YAHOO.widget.DataTable( this.payoutDetails, this.itemSchema, this.itemDataSource, {
        dynamicData : true }
    );
    this.itemDataTable.subscribe( "rowClickEvent", function (e) {
        var record      = this.getRecord( e.target );
        var callback    = {
            scope   : this,
            success : function ( o ) {
                var status = o.responseText;
                if ( status.match(/^error/) ) {
                    alert( status );
                    return;
                }

                this.updateCell( record, 'vendorPayoutStatus', status );
            }
        };
    
        var status = record.getData( 'vendorPayoutStatus' ) === 'NotPayed' ? 'Scheduled' : 'NotPayed';
        var url = '/?shop=vendor;method=setPayoutStatus' + ';itemId=' + record.getData( 'itemId' ) + ';status=' + status;
        YAHOO.util.Connect.asyncRequest( 'post', url, callback );
    } );
    

}

