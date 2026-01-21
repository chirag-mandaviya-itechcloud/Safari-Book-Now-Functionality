import { LightningElement, track, api } from 'lwc';
import {
    registerRefreshContainer,
    unregisterRefreshContainer,
    REFRESH_ERROR,
    REFRESH_COMPLETE,
    REFRESH_COMPLETE_WITH_ERRORS,
} from "lightning/refresh";
import { refreshApex } from '@salesforce/apex';
import TIME_ZONE from '@salesforce/i18n/timeZone';
import GetQuoteLineItemsByService from '@salesforce/apex/QuoteController.getQuoteLineItemsByService';
import CareteExtraServices from '@salesforce/apex/QuoteLineItemController.careteExtraServices';
import GetQuoteDetail from '@salesforce/apex/QuoteController.getQuoteDetail';
export default class quote_Itinerary extends LightningElement {


    //refreshContainerID;

    isLoading = false;
    isDayView = false;

    @api recordId;
    quoteDetail;
    @track isOpenModal = false;
    @track quoteLineItems = [];
    newCardStartDate = null;
    @track quoteLocked = false;
    @track costMarkupLocked = false;
    @track logisticsLocked = false;
    @track hasServices = false;

    connectedCallback() {
        this.isLoading = true;
        // this.refreshContainerID = registerRefreshContainer(this, this.refreshContainer);
        GetQuoteDetail({ quoteId: this.recordId })
            .then(result => {
                this.quoteDetail = result;
                console.log('QuoteStatus>>>', this.quoteDetail.Status);
                this.setLockQuote();
                GetQuoteLineItemsByService({ quoteId: this.recordId })
                    .then(result => {
                        console.log(JSON.parse(JSON.stringify(result)));
                        this.quoteLineItems = result;
                        if (this.quoteLineItems.length > 0) {
                            this.hasServices = true;
                            let lastService = this.quoteLineItems[this.quoteLineItems.length - 1];
                            this.setNewCardStartDate(lastService.Service_Date__c, lastService.Display_Duration__c)
                        }
                        this.isLoading = false;
                    })
                    .catch(error => {
                        console.log(error);
                        this.isLoading = false;
                    })
            })
            .catch(error => {
                console.log('GetQuoteDetail>>Erorr>>', JSON.stringify(error));
                this.isLoading = false;
            })



    }

    refresh() {
        this.isLoading = true;
        // this.refreshContainerID = registerRefreshContainer(this, this.refreshContainer);

        GetQuoteDetail({ quoteId: this.recordId })
            .then(result => {
                this.quoteDetail = result;
                this.setLockQuote();
                GetQuoteLineItemsByService({ quoteId: this.recordId })
                    .then(result => {
                        console.log(JSON.parse(JSON.stringify(result)));
                        this.quoteLineItems = result;
                        if (this.quoteLineItems.length > 0) {
                            this.hasServices = true;
                            let lastService = this.quoteLineItems[this.quoteLineItems.length - 1];
                            this.setNewCardStartDate(lastService.Service_Date__c, lastService.Display_Duration__c)
                        }
                        this.isLoading = false;
                    })
                    .catch(error => {
                        console.log(error);
                        this.isLoading = false;
                    })
            })
            .catch(error => {
                console.log('GetQuoteDetail>>Erorr>>', JSON.stringify(error));
                this.isLoading = false;
            })
    }


    setNewCardStartDate(startDate, duration) {
        console.log('startDate>>>', startDate);
        let date = new Date(startDate);
        date = new Date(date.setUTCDate(date.getUTCDate() + parseInt(duration)));
        this.newCardStartDate = date.getUTCFullYear() + "-" + (date.getUTCMonth() + 1) + "-" + date.getUTCDate();
        console.log('newCardStartDate>>>', this.newCardStartDate);
    }

    handleAddTemplate() {
        console.log('inside handleAddTemplate');
        this.isOpenModal = true;
    }
    handleCloseModal(event) {
        console.log('inside handleCloseModal');

        console.log('event:::', JSON.parse(JSON.stringify(event.detail)));
        if (event.detail) {
            this.isLoading = true;
            this.refresh();
        }
        setTimeout(() => { console.log("inside time-out"); this.isLoading = false; this.isOpenModal = false; }, 2000);

    }

    handleAdd(event) {
        this.isLoading = true;
        let added = false;
        if (this.quoteLineItems.length == 0) {
            this.quoteLineItems.push({ Id: "newitem" });
            added = true;
            CareteExtraServices({ quoteId: this.recordId });

        } else {
            let lastItemId = this.quoteLineItems[this.quoteLineItems.length - 1].Id
            if (lastItemId != '' && lastItemId.length == 18) {
                this.quoteLineItems.push({ Id: "newitem" });
                added = true;
            }
        }
        this.isLoading = false;
        if (added) {
            setTimeout(() => {
                let containerChoosen = this.template.querySelector('[data-id="newitem"]');
                containerChoosen.scrollIntoView({
                    block: 'end',
                    behavior: 'smooth'
                });
            }, 500);
        }
    }
    handleToggle(event) {
        //alert(event.target.checked);
        if (event.target.checked) {
            this.isDayView = true;
        } else {
            this.isDayView = false;
        }
    }

    setLockQuote() {
        this.isLoading = true;
        if (this.quoteDetail.Status == 'Present Quote' ||
            this.quoteDetail.Status == 'Quote Expired' ||
            this.quoteDetail.Status == 'Quote Cancelled' ||
            this.quoteDetail.Status == 'ReQuote Requested' ||
            this.quoteDetail.Status == 'Confirmation Requested' ||
            this.quoteDetail.Status == 'Product Approval' ||
            this.quoteDetail.Status == 'Present Confirmation' ||
            this.quoteDetail.Status == 'Finance Approval' ||
            this.quoteDetail.Status == 'Confirmed' ||
            this.quoteDetail.Status == 'Refund Approval') {
            this.quoteLocked = true;
        }
        if (this.quoteDetail.Status == 'Present Quote' ||
            this.quoteDetail.Status == 'Quote Expired' ||
            this.quoteDetail.Status == 'Quote Cancelled' ||
            this.quoteDetail.Status == 'ReQuote Requested' ||
            this.quoteDetail.Status == 'Confirmed' ||
            this.quoteDetail.Status == 'Refund Approval') {
            this.costMarkupLocked = true;
        }
        if (this.quoteDetail.Status == 'Build Quote' ||
            this.quoteDetail.Status == 'Present Quote' ||
            this.quoteDetail.Status == 'Quote Expired' ||
            this.quoteDetail.Status == 'ReQuote Requested' ||
            this.quoteDetail.Status == 'Confirmation Requested' ||
            this.quoteDetail.Status == 'Finance Approval' ||
            this.quoteDetail.Status == 'Quote Cancelled' ||
            this.quoteDetail.Status == 'Refund Approval' ||
            (this.quoteDetail.Status == 'Confirmed' && this.quoteDetail.Sub_Status__c != 'Confirmed (Confirmed)' && this.quoteDetail.Sub_Status__c != 'Confirmed (Re-Confirmed)')) {
            this.logisticsLocked = true;
        }
        this.isLoading = false;
    }

    deleteCard(event) {
        this.quoteLineItems.pop();
    }
}