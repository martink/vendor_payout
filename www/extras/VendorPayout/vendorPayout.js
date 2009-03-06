if (typeof WebGUI == "undefined" || !WebGUI) {
    var WebGUI = {};
}

WebGUI.VendorPayout = function ( containerId ) {
    this.container  = document.getElementById( containerId );

    // Vendors data table
    this.vendorList = document.createElement('div');
    this.container.appendChild( this.vendorList );

    // Select buttons
    this.buttonDiv  = document.createElement('div');
    this.container.appendChild( this.buttonDiv );
    this.scheduleAllButton      = new YAHOO.widget.Button({ label: 'Schedule all',   container: this.buttonDiv });
    this.descheduleAllButton    = new YAHOO.widget.Button({ label: 'Deschedule all', container: this.buttonDiv });
//    this.buttonDiv.appendChild( this.scheduleAllButton );
//    this.buttonDiv.appendChild( this.descheduleAllButton );

    // Payout details data table
    this.payoutDetails  = document.createElement('div');
    this.container.appendChild( this.payoutDetails );


    this.itemBaseUrl = '/?shop=vendor;method=payoutDataAsJSON;vendorId='; 

    // Initialise tables
    this.initVendorList();
    this.initPayoutDetails();
    this.initButtons();

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
    var url = '/?shop=vendor;method=vendorTotalsAsJSON;vendorId=';
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
        obj.currentVendorId     = record.getData( 'vendorId' );
        obj.currentVendorRow    = record;
        obj.refreshItemDataTable();
//        var url = obj.itemBaseUrl + obj.currentVendorId;
    } );
}

//----------------------------------------------------------------------------
WebGUI.VendorPayout.prototype.refreshItemDataTable = function () {
    this.itemDataSource.sendRequest( this.currentVendorId, {
        success : this.itemDataTable.onDataReturnReplaceRows, //InitializeTable,
        scope   : this.itemDataTable
    });
}

//----------------------------------------------------------------------------
WebGUI.VendorPayout.prototype.refreshVendorRow = function () {
    var obj = this;
    this.vendorDataSource.sendRequest( this.currentVendorId, {
        // onDataReturnUpdateRows is not available in yui 2.6.0...
        success : function ( req, response , payload ) {
            this.updateRow( obj.currentVendorRow, response.results[0] );
        },
        scope   : this.vendorDataTable
    } );
}

//----------------------------------------------------------------------------
WebGUI.VendorPayout.prototype.initPayoutDetails = function () {
    var obj = this;
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

                // Update vendor row
                obj.refreshVendorRow();
            }
        };
    
        var status = record.getData( 'vendorPayoutStatus' ) === 'NotPayed' ? 'Scheduled' : 'NotPayed';
        var url = '/?shop=vendor;method=setPayoutStatus' + ';itemId=' + record.getData( 'itemId' ) + ';status=' + status;
        YAHOO.util.Connect.asyncRequest( 'post', url, callback );
    } );  
}

//----------------------------------------------------------------------------
WebGUI.VendorPayout.prototype.initButtons = function () {
    var obj = this;

    var updateAll = function ( status ) {
        // TODO: Make this range based.
        var records = obj.itemDataTable.getRecordSet().getRecords();
        var itemIds = new Array;
        for (i = 0; i < records.length; i++) {
            itemIds.push( 'itemId=' + records[i].getData( 'itemId' ) );
        }
        
        var postdata = itemIds.join('&');
        var url      = '/?shop=vendor&method=setPayoutStatus&status=' + status;
        var callback = {
            success: function (o) {
                this.refreshItemDataTable();
                this.refreshVendorRow();
            }, 
            scope: obj 
        };

        YAHOO.util.Connect.asyncRequest( 'POST', url, callback, postdata );
    }

    this.scheduleAllButton.on(   'click', function () { updateAll( 'Scheduled' ) } );
    this.descheduleAllButton.on( 'click', function () { updateAll( 'NotPayed'  ) } );   
        
}

