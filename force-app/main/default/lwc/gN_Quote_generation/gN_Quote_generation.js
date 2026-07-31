import { LightningElement, api, wire } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getQuoteLines from '@salesforce/apex/GN_Quote_Generation.getQuoteLines';
import generateAndUpload from '@salesforce/apex/GN_DocumentGeneratorService.generateAndUpload';
import previewQuoteDocument from '@salesforce/apex/GN_DocumentGeneratorService.previewQuoteDocument';

const TEMPLATE_TITLE = 'sample-template';

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
    columns = COLUMNS;
    quoteLines = [];
    error;
    isGenerating = false;
    isPreviewing = false;
    showPreview = false;
    previewUrl;

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

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleBack() {
        this.showPreview = false;
        this.previewUrl = undefined;
    }

    async handlePreview() {
        if (!this.recordId) {
            this.error = 'No quote record was provided.';
            return;
        }

        this.error = undefined;
        this.isPreviewing = true;

        try {
            const base64 = await previewQuoteDocument({
                quoteId: this.recordId,
                templateTitle: TEMPLATE_TITLE
            });
            this.previewUrl = 'data:application/pdf;base64,' + base64;
            this.showPreview = true;
        } catch (e) {
            const message = e?.body?.message || e?.message || 'Unable to generate the preview.';
            this.error = message;
            this.dispatchEvent(new ShowToastEvent({ title: 'Error', message, variant: 'error' }));
        } finally {
            this.isPreviewing = false;
        }
    }

    handleDownloadPdf() {
        return this.generateDocument('PDF', 'pdf');
    }

    handleDownloadWord() {
        return this.generateDocument('Word document', 'docx');
    }

    async generateDocument(label, outputFormat) {
        if (!this.recordId) {
            this.error = 'No quote record was provided.';
            return;
        }

        this.error = undefined;
        this.isGenerating = true;

        try {
            const driveLink = await generateAndUpload({
                quoteId: this.recordId,
                templateTitle: TEMPLATE_TITLE,
                outputFormat
            });
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'The {0} was generated and uploaded to Google Drive: {1}',
                    messageData: [label, { url: driveLink, label: 'Open in Google Drive' }],
                    variant: 'success',
                    mode: 'sticky'
                })
            );
        } catch (e) {
            const message = e?.body?.message || e?.message || `Unable to generate the ${label}.`;
            this.error = message;
            this.dispatchEvent(new ShowToastEvent({ title: 'Error', message, variant: 'error' }));
        } finally {
            this.isGenerating = false;
        }
    }
}