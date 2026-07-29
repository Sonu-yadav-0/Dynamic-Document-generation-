public with sharing class GoogleDriveService {

    private static final String UPLOAD_ENDPOINT = 'callout:GoogleDrive/upload/drive/v3/files?uploadType=multipart&supportsAllDrives=true&fields=id,webViewLink';
    private static final String BOUNDARY = '58NCUpNZULCkuJq6dbFuqNyRLAtWKM';

    public class GoogleDriveException extends Exception {}

    public static String uploadFile(String fileName, Blob fileBody, String mimeType) {
        Google_Drive_Setting__mdt settings = Google_Drive_Setting__mdt.getInstance('googledriveserviceaccount');
        if (settings == null || String.isBlank(settings.Drive_Folder_Id__c)) {
            throw new GoogleDriveException('Google_Drive_Setting__mdt record "googledriveserviceaccount" is not configured.');
        }

        Map<String, Object> metadata = new Map<String, Object>{
            'name' => fileName,
            'parents' => new List<String>{ settings.Drive_Folder_Id__c }
        };

        String body = '--' + BOUNDARY + '\r\n'
            + 'Content-Type: application/json; charset=UTF-8\r\n\r\n'
            + JSON.serialize(metadata) + '\r\n'
            + '--' + BOUNDARY + '\r\n'
            + 'Content-Type: ' + mimeType + '\r\n'
            + 'Content-Transfer-Encoding: base64\r\n\r\n'
            + EncodingUtil.base64Encode(fileBody) + '\r\n'
            + '--' + BOUNDARY + '--';

        HttpRequest request = new HttpRequest();
        request.setEndpoint(UPLOAD_ENDPOINT);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'multipart/related; boundary=' + BOUNDARY);
        request.setBody(body);
        request.setTimeout(120000);

        HttpResponse response = new Http().send(request);
        if (response.getStatusCode() != 200) {
            throw new GoogleDriveException('Google Drive upload failed (' + response.getStatusCode() + '): ' + response.getBody());
        }

        Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        return (String) responseBody.get('webViewLink');
    }
}
