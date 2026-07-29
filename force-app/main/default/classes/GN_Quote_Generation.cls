public with sharing class GN_Quote_Generation {

    @AuraEnabled
    public static String generateAndAttachQuotePdf(Id quoteId) {
        return generateAndAttachQuoteDocument(quoteId, false);
    }

    @AuraEnabled
    public static String generateAndAttachQuoteWord(Id quoteId) {
        return generateAndAttachQuoteDocument(quoteId, true);
    }

    private static String generateAndAttachQuoteDocument(Id quoteId, Boolean asWord) {
        if (quoteId == null) {
            throw new AuraHandledException('Quote Id is required.');
        }

        try {
            PageReference templatePage = Page.GN_QuoteTemplateVf;
            templatePage.getParameters().put('id', quoteId);
            if (asWord) {
                templatePage.getParameters().put('download', 'word');
            }

            Blob fileBody = Test.isRunningTest()
                ? Blob.valueOf(asWord ? '<html><body>Test DOC</body></html>' : 'Test PDF')
                : (asWord ? templatePage.getContent() : templatePage.getContentAsPDF());

            return uploadAndLinkQuoteDocument(quoteId, fileBody, asWord);
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    private static String uploadAndLinkQuoteDocument(Id quoteId, Blob fileBody, Boolean asWord) {
        Quote quoteRecord = [
            SELECT Id, Name
            FROM Quote
            WHERE Id = :quoteId
            LIMIT 1
        ];

        String safeName = String.isBlank(quoteRecord.Name)
            ? 'Quote'
            : quoteRecord.Name.replaceAll('[^a-zA-Z0-9 _-]', '');

        String fileName = safeName + '_Quote.' + (asWord ? 'doc' : 'pdf');
        String mimeType = asWord ? 'application/msword' : 'application/pdf';

        String driveLink = Test.isRunningTest()
            ? 'https://drive.google.com/test'
            : GoogleDriveService.uploadFile(fileName, fileBody, mimeType);

        if (asWord) {
            quoteRecord.Word_Drive_Link__c = driveLink;
        } else {
            quoteRecord.PDF_Drive_Link__c = driveLink;
        }
        update quoteRecord;

        return driveLink;
    }

    @AuraEnabled(cacheable=true)
    public static List<QuoteLineItem> getQuoteLines(Id quoteId) {
        if (quoteId == null) {
            return new List<QuoteLineItem>();
        }

        return [
            SELECT
                Id,
                QuoteId,
                Product2.Name,
                Quantity,
                UnitPrice,
                ListPrice,
                Discount,
                TotalPrice
            FROM QuoteLineItem
            WHERE QuoteId = :quoteId
            ORDER BY CreatedDate
        ];
    }
}