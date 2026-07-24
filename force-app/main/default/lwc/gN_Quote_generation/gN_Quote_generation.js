import { LightningElement, api, wire } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getQuoteLines from '@salesforce/apex/GN_Quote_Generation.getQuoteLines';
import generateAndAttachQuotePdf from '@salesforce/apex/GN_Quote_Generation.generateAndAttachQuotePdf';

const COLUMNS = [
    {
        label: 'Product',
        fieldName: 'productName',
        type: 'text'
    },
    {
        label: 'Quantity',
        fieldName: 'Quantity',
        type: 'number'
    },
    {
        label: 'List Price',
        fieldName: 'ListPrice',
        type: 'currency'
    },
    {
        label: 'Total',
        fieldName: 'TotalPrice',
        type: 'currency'
    }
];

export default class GN_Quote_generation extends LightningElement {

    @api recordId;
    showPreview = false;
    columns = COLUMNS;
    showDataTable = true;
    quoteLines = [];
    error;
    isGenerating = false;

    @wire(getQuoteLines, { quoteId: '$recordId' })
    wiredQuoteLines({ data, error }) {
        if (data) {
            this.quoteLines = data.map(item => ({
                ...item,
                productName: item.Product2?.Name
            }));
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.quoteLines = [];
            console.error(error);
        }
    }

    get vfUrl() {
        return 'https://allied-era-dev-ed--c.develop.vf.force.com/apex/GN_QuoteTemplateVf?id=' + this.recordId;
    }

    handlePreview() {
        this.showPreview = true;
        this.showDataTable = false;
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    async handleDownload() {
        if (!this.recordId) {
            this.error = 'No quote record was provided.';
            return;
        }

        this.error = undefined;
        this.isGenerating = true;

        try {
            await generateAndAttachQuotePdf({ quoteId: this.recordId });
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'The PDF was generated and attached to the quote.',
                    variant: 'success'
                })
            );
        } catch (e) {
            const message = e?.body?.message || e?.message || 'Unable to generate the PDF.';
            this.error = message;
            this.dispatchEvent(new ShowToastEvent({ title: 'Error', message, variant: 'error' }));
        } finally {
            this.isGenerating = false;
        }
    }
}