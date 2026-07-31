/**
 * Calls the doc middleware: sends the Word template (stored as a Salesforce File)
 * plus record data, receives the merged document back (.docx, or .pdf when the
 * middleware converts it via LibreOffice), then hands it to the existing
 * Google Drive upload.
 *
 * Setup expected:
 *  - Named Credential "Doc_Middleware" pointing at the middleware base URL.
 *    Add "X-API-Key" as a Custom Header on its External Credential — then no
 *    secret ever appears in code.
 */
public with sharing class GN_DocumentGeneratorService {

    @AuraEnabled
    public static String generateAndUpload(Id quoteId, String templateTitle, String outputFormat) {
        Boolean wantsPdf = 'pdf'.equalsIgnoreCase(outputFormat);
        Map<String, Object> result = callMiddleware(quoteId, templateTitle, wantsPdf);

        Blob docFile = EncodingUtil.base64Decode((String) result.get('fileBase64'));
        String docName = (String) result.get('fileName');

        // Push to Google Drive via the existing integration, save the link, and return it
        String contentType = wantsPdf
            ? 'application/pdf'
            : 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
        String driveLink = GoogleDriveService.uploadFile(docName, docFile, contentType);

        Quote quoteUpdate = new Quote(Id = quoteId);
        if (wantsPdf) {
            quoteUpdate.PDF_Drive_Link__c = driveLink;
        } else {
            quoteUpdate.Word_Drive_Link__c = driveLink;
        }
        update quoteUpdate;

        return driveLink;
    }

    // Renders the quote as a PDF via the middleware without uploading to Drive,
    // so the LWC can show it inline before the user commits to generating a file.
    @AuraEnabled
    public static String previewQuoteDocument(Id quoteId, String templateTitle) {
        Map<String, Object> result = callMiddleware(quoteId, templateTitle, true);
        return (String) result.get('fileBase64');
    }

    private static Map<String, Object> callMiddleware(Id quoteId, String templateTitle, Boolean wantsPdf) {
        // 1. The template .docx uploaded in Salesforce (latest version by title)
        ContentVersion cv = [
            SELECT VersionData
            FROM ContentVersion
            WHERE Title = :templateTitle AND IsLatest = true
            LIMIT 1
        ];

        // 2. Quote header + line items -> merge data (keys must match the {tags})
        Quote q = [
            SELECT QuoteNumber, GrandTotal, CreatedDate, Account.Name
            FROM Quote WHERE Id = :quoteId
        ];

        List<Map<String, Object>> items = new List<Map<String, Object>>();
        for (QuoteLineItem li : [
            SELECT Product2.Name, Quantity, UnitPrice, TotalPrice
            FROM QuoteLineItem WHERE QuoteId = :quoteId ORDER BY SortOrder
        ]) {
            items.add(new Map<String, Object>{
                'Product_Name' => li.Product2.Name,
                'Quantity'     => String.valueOf(li.Quantity.intValue()),
                'Unit_Price'   => li.UnitPrice.setScale(2).format(),
                'Total'        => li.TotalPrice.setScale(2).format()
            });
        }

        Map<String, Object> data = new Map<String, Object>{
            'Quote_Number' => q.QuoteNumber,
            'Account_Name' => q.Account.Name,
            'Quote_Date'   => q.CreatedDate.date().format(),
            'Grand_Total'  => q.GrandTotal.setScale(2).format(),
            'lineItems'    => items
        };

        Map<String, Object> payload = new Map<String, Object>{
            'templateBase64' => EncodingUtil.base64Encode(cv.VersionData),
            'data'           => data,
            'fileName'       => q.QuoteNumber,
            'outputFormat'   => wantsPdf ? 'pdf' : 'docx'
        };

        // 3. Call the middleware
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Doc_Middleware/generate-document');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setTimeout(120000);
        req.setBody(JSON.serialize(payload));

        HttpResponse res = new Http().send(req);
        if (res.getStatusCode() != 200) {
            // 422 responses include per-tag details when a template tag is broken
            throw new AuraHandledException('Document generation failed: ' + res.getBody());
        }

        Map<String, Object> result =
            (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        if (result.get('fileBase64') == null) {
            throw new AuraHandledException('Document generation failed: middleware returned no file.');
        }
        return result;
    }
}
