/**
 * Calls the doc middleware: sends the Word template (stored as a Salesforce File)
 * plus record data, receives the merged .docx back, then hands it to the existing
 * Google Drive upload.
 *
 * Setup expected:
 *  - Named Credential "Doc_Middleware" pointing at the middleware base URL.
 *    Add "X-API-Key" as a Custom Header on its External Credential — then no
 *    secret ever appears in code.
 */
public with sharing class GN_DocumentGeneratorService {

    @AuraEnabled
    public static String generateAndUpload(Id quoteId, String templateTitle) {

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
            'fileName'       => q.QuoteNumber + '.docx'
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
        Blob docFile = EncodingUtil.base64Decode((String) result.get('fileBase64'));
        String docName = (String) result.get('fileName');

        // 4. Push to Google Drive via the existing integration and return the link
        return uploadToDrive(docFile, docName);
    }

    private static String uploadToDrive(Blob file, String fileName) {
        // TODO: plug in the existing Apex + Named Credential (OAuth) Drive upload here
        // (multipart upload, then return the webViewLink and/or save it on the Quote).
        return null;
    }
}
