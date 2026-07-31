public with sharing class GN_Quote_Generation {

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