/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 07-24-2026
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class GN_QuoteTemplateController {
    
    //variable lists
    public boolean annexure1 {get; set;}
    public boolean annexure2 {get; set;}
    public boolean annexure3 {get; set;}
    public boolean annexure4 {get; set;}
    public boolean annexure5 {get; set;}
    public boolean annexure6 {get; set;}
    public String darkShadeColor {get; set;}
    public String mediumShadeColor {get; set;}
    public String lightShadeColor {get; set;}
    public String showcaseImageNameUrl {get; set;}
    public String bottomCoverImageUrl {get; set;}
    public string vfType {get; set;}
    public static string freightAmount {get; set;}
    public static string finalBasicAmount {get; set;}
    public List<String> selectedAnnexure {get; set;}
    public String myAttribute { get; set; } 
    public Id quoteId {get;set;} 
    public Quote placeholderQuote {get; set;}
    public User userOwner {get; set;}
    public List<Section__c> sectionList {get; set;} 
    public String rightHeaderContent {get; set;}
    public String leftHeaderContent {get; set;}
    public String footerContent {get; set;} 
    public Decimal footerWidth {get; set;}
    public Decimal headerLogoWidth {get; set;}
    public Decimal headerLogoHeight {get; set;}
    public Decimal headerAddressLeftSpacing {get; set;}
    public String coverPageTitle {get; set;}
    public List<eachSectionContentWrapper> EachSectionDataToDisplay {get; set;}
    public List<eachSectionContentWrapper> imagesToDisplay {get; set;}
    public Set<Id> sectionIds {get; set;}
    public List<String> productFamilyList {get; set;}
    public String ps_specialinstructions {get; set;}
    public static Map<String, Map<string,schema.SObjectField>> sobjecttomfields = new Map<String, Map<string,schema.SObjectField>>();
    public static Map<String, Map<string,schema.SObjectField>> sobjecttomfieldsUser = new Map<String, Map<string,schema.SObjectField>>();
    public static List<String> relationshipfields = new List<String>();
    public static List<String> relationshipfieldsUser = new List<String>();
    public static Map<String, schema.SObjectField> mfields = new Map<String, schema.SObjectField>();
    public static Map<String, schema.SObjectField> ufields = new Map<String, schema.SObjectField>();
    public static Map<Section__C, List<section_condition__c>> sectionBasedCondition = new Map<Section__C, List<section_condition__c>>();
    Map<Id, string> productIdWithImageLinkMap = new Map<Id, string>();
    Map<String, String> imageNamesBasedUrl = new Map<String, String>();
    Map<String, Id> productNameBasedProductId = new Map<String, Id>();
    Map<Decimal, List<QuoteLineItem>> sequenceByQuoteLineItem = new Map<Decimal, List<QuoteLineItem>>();
    Map<Id, List<Product_Specification__c>> productIdByProductSpecification = new Map<Id, List<Product_Specification__c>>();
    List<Decimal> subTotalOfQuoteLine = new List<Decimal>();
    Map<Decimal, String> sequenceByAlphabet = new Map<Decimal, String>();
    
     /**
     * @description GN_QuoteTemplateController: Controller Constructor
    */   
    public GN_QuoteTemplateController(ApexPages.StandardController controller) {
        
       this.vfType = ApexPages.currentPage().getParameters().get('download') == 'word'
            ? 'application/msword#QuoteDocument.doc'
            : 'text/html; charset=UTF-8';
        this.annexure1 = true;
        this.annexure2 = true;
        this.annexure3 = true;
        this.annexure4 = true;
        this.annexure5 = true;
        this.annexure6 = true;
        
        productFamilyList = new List<String>();
        selectedAnnexure = new List<String>();
        sectionList = new List<Section__C>();
        quoteId = System.currentPagereference().getParameters().get('Id'); // Quote id get
        Set<Id> accId = new Set<Id>();
        Set<Id> productIds = new Set<Id>();
        Id quoteTemplateId;
        list<Quote> qtOwnerid = [SELECT Id, Ownerid FROM Quote WHERE Owner.Type = 'User' and  id =: quoteId];
         Quote qt = [Select id, name,Account.Account_Email__c,Contact.Name,Contact.Email,Contact.Phone,Account.Owner.Name,BillingStreet,BillingCity,BillingState,BillingStateCode,BillingCountry,BillingPostalCode,Account.Name, Account.Phone,Quote_Template__c, Grand_Total_FOP_Price__c, Total_Customer_Discount_Formula__c, Quote_Template__r.Template_Theme_Color__c, Quote_Template__r.BottomCoverImage_Name__c, Quote_Template__r.Showcase_Image_Name__c, Opportunity.Owner.CompanyName, Opportunity.Owner.Account_Name__c, Opportunity.Owner.Account.Header_Address__c, Opportunity.Owner.Account.Header_Logo__c, Opportunity.Owner.Account.Footer_Logo__c, Opportunity.Owner.Account.Header_Address_Left_Spacing__c, Opportunity.Owner.Account.Footer_Width__c, Opportunity.Owner.Account.Header_Logo_Height__c, Opportunity.Owner.Account.Header_Logo_Width__c, Opportunity.Owner.AccountId, OwnerId, Owner.Name, Owner.Title, Owner.Email, Offer_Price__c, Total_Customer_Discount__c, Total_Unit_Basic__c,Add_Technical_Specification__c,QuoteNumber, (Select id, Product2Id, Product2.Name, Product2.Commodity_code__c, Product2.Component_Type__c, Product2.Variant_Type__c, Product2.Search_Key_I__c, Quantity, UnitPrice, TotalPrice, Approval_Status__c, Total_Approved_Customer_Discount__c, Sequence_Number__c, Include_In_Bundle__c from QuoteLineItems) from Quote where id =: quoteId];
       system.debug('quoteId '+quoteId);
        //Get Cover Page Title
        User u = new User();
        if(!qtOwnerid.isempty()){
          u = [Select id, CompanyName, Account_Name__c from User where id =: qtOwnerid[0].ownerid];  
        }
       if(u.Account_Name__c != null){
        this.coverPageTitle = u.Account_Name__c;
        }
   
        
        //Dynamic Theme Color
        if(qt.Quote_Template__r.Template_Theme_Color__c == 'Pink'){
            this.darkShadeColor = '#c43782';
            this.mediumShadeColor = '#fcc5e5';
            this.lightShadeColor = '#f7e6ee';
        }else if(qt.Quote_Template__r.Template_Theme_Color__c == 'Blue'){
            this.darkShadeColor = '#4187CE';
            this.mediumShadeColor = '#81acd6';
            this.lightShadeColor = '#b9d9fa';
        }else if(qt.Quote_Template__r.Template_Theme_Color__c == 'Green'){
            this.darkShadeColor = '#5FB233';
            this.mediumShadeColor = '#89d162';
            this.lightShadeColor = '#bafc97';
        }else {
            this.darkShadeColor = '#7f7f7f';
            this.mediumShadeColor = '#b5b5b5';
            this.lightShadeColor = '#d9d9d9';
        }   
        
        for(QuoteLineItem qli : qt.QuoteLineItems){
            
            productNameBasedProductId.put(qli.Product2.Name, qli.Product2Id);
            productIds.add(qli.Product2Id);
            
            if (!qli.Product2.Name.contains('Freight')) {
                List<QuoteLineItem> sequencedQuoteLineItemsList = sequenceByQuoteLineItem.get(qli.Sequence_Number__c);
                if(sequencedQuoteLineItemsList == null){
                    sequencedQuoteLineItemsList = new List<QuoteLineItem>();
                }
                sequencedQuoteLineItemsList.add(qli);
                sequenceByQuoteLineItem.put(qli.Sequence_Number__c, sequencedQuoteLineItemsList);
            }
        }
        
        String alphabetValue = 'ABCDEFGHIJKLMNOPQRSTUVWXYZAabcdefghijklmnopqrstuvwxyza';
        List<Decimal> sortedSequenceList = new List<Decimal>(sequenceByQuoteLineItem.keySet());
        
        sortedSequenceList.sort();
        for(Integer i = 0; i < sortedSequenceList.size() && i < alphabetValue.length(); i++){
            Decimal decimalValue = sortedSequenceList[i];
            String alphabetChar = alphabetValue.substring(i, i+1);
            sequenceByAlphabet.put(decimalValue, alphabetChar);
        }
        List<Product_Specification__c>  productSpecificationRecords = [SELECT Id, Name, Section__c, Subsection1__c, Subsection2__c, Subsection3__c, Product__c, Sequence__c, Is_Bold__c FROM Product_Specification__c WHERE Product__c =: productIds ORDER BY Sequence__c ASC];
        for(Product_Specification__c eachPs : productSpecificationRecords){
            
            List<Product_Specification__c> productByPsList = productIdByProductSpecification.get(eachPs.Product__c);
            if(productByPsList == null){
                productByPsList = new List<Product_Specification__c>();
            }
            productByPsList.add(eachPs);
            productIdByProductSpecification.put(eachPs.Product__c, productByPsList);    
        }
        
       
        //Get Cover Page Data
        Set<Id> quoteTemplateIdToGetImages = new Set<Id>();
        quoteTemplateId = qt.Quote_Template__c;
        quoteTemplateIdToGetImages.add(quoteTemplateId);
        system.debug('quoteTemplateIdToGetImages '+quoteTemplateIdToGetImages);
        imageNamesBasedUrl = getImageUrlByName(quoteTemplateIdToGetImages);
        String showcaseImageName = qt.Quote_Template__r.Showcase_Image_Name__c;
        String bottomCoverImage = qt.Quote_Template__r.BottomCoverImage_Name__c;
        if(showcaseImageName != null){
            this.showcaseImageNameUrl = imageNamesBasedUrl.get(showcaseImageName);
        }
        
        if(bottomCoverImage != null){
            this.bottomCoverImageUrl = imageNamesBasedUrl.get(bottomCoverImage);
        }
        
        //Getting Header&Footer data 
        if(qt.Opportunity != null ){
        if(qt.Opportunity.Owner.CompanyName.contains('Apex')){
            Set<Id> accountId = new Set<Id>();
            Id staticAccountId = System.Label.Godrej_Static_Account_Id_For_PDF_Use;
            Account acc;
            if(staticAccountId != null){
                 if(!test.isRunningTest()){
                     acc = [Select id, Name, Header_Address__c, Header_Logo__c, Footer_Logo__c, Footer_Width__c, Header_Logo_Height__c, Header_Logo_Width__c, Header_Address_Left_Spacing__c From Account Where Id =: staticAccountId]; 
                 }else{
                  acc = [Select id, Name, Header_Logo__c, Header_Address__c, Footer_Logo__c, Footer_Width__c, Header_Logo_Height__c, Header_Logo_Width__c, Header_Address_Left_Spacing__c from Account where Header_Logo__c!=null limit 1];
                 }
            }
            if(acc.Id != null){
                accountId.add(acc.Id);
            }
            if(acc.Header_Address__c != null){
                this.rightHeaderContent = acc.Header_Address__c;
            }
            imageNamesBasedUrl = getImageUrlByName(accountId);
            if(acc.Header_Logo__c != null){
                this.leftHeaderContent = imageNamesBasedUrl.get(acc.Header_Logo__c);
            }
            if(acc.Footer_Logo__c != null){
                this.footerContent = imageNamesBasedUrl.get(acc.Footer_Logo__c);
            }
            if(acc.Footer_Width__c != null){
                this.footerWidth = acc.Footer_Width__c;
            }
            if(acc.Header_Address_Left_Spacing__c != null){
                this.headerAddressLeftSpacing = acc.Header_Address_Left_Spacing__c;
            }
            if(acc.Header_Logo_Height__c != null){
                this.headerLogoHeight = acc.Header_Logo_Height__c;
            }
            if(acc.Header_Logo_Width__c != null){
                this.headerLogoWidth = acc.Header_Logo_Width__c;
            }
        }
        else {
            if(qt.Opportunity.Owner.AccountId != null){
                accId.add(qt.Opportunity.Owner.AccountId);
            }
            if(qt.Opportunity.Owner.Account.Header_Address__c != null){
                this.rightHeaderContent = qt.Opportunity.Owner.Account.Header_Address__c;
            }
            imageNamesBasedUrl = getImageUrlByName(accId);
            if(qt.Opportunity.Owner.Account.Header_Logo__c != null){
                this.leftHeaderContent = imageNamesBasedUrl.get(qt.Opportunity.Owner.Account.Header_Logo__c);
            }
            if(qt.Opportunity.Owner.Account.Footer_Logo__c != null){
                this.footerContent = imageNamesBasedUrl.get(qt.Opportunity.Owner.Account.Footer_Logo__c);
            }
            if(qt.Opportunity.Owner.Account.Footer_Width__c != null){
                this.footerWidth = qt.Opportunity.Owner.Account.Footer_Width__c;
            }
            if(qt.Opportunity.Owner.Account.Header_Address_Left_Spacing__c != null){
                this.headerAddressLeftSpacing = qt.Opportunity.Owner.Account.Header_Address_Left_Spacing__c;
            }
            if(qt.Opportunity.Owner.Account.Header_Logo_Height__c != null){
                this.headerLogoHeight = qt.Opportunity.Owner.Account.Header_Logo_Height__c;
            }
            if(qt.Opportunity.Owner.Account.Header_Logo_Width__c != null){
                this.headerLogoWidth = qt.Opportunity.Owner.Account.Header_Logo_Width__c;
            }
        }
        } //Header&Footer ends here
        
		// True annexure value based on selection
        /*myAttribute = ApexPages.currentPage().getParameters().get('values');
        system.debug(myAttribute);
        for(String Annexure : myAttribute.split(',')){
            if(Annexure == 'Technical Details'){
                this.annexure1 = true;
            }
            if(Annexure == 'Product Benefits'){
                this.annexure2 = true;
            }
            if(Annexure == 'Extended Warranty Plan'){
                this.annexure3 = true;
            }
            if(Annexure == 'Optional Safety Accessories'){
                this.annexure4 = true;
            }
            if(Annexure == 'Price Matrix & Commercial Terms'){
                this.annexure5 = true;
            }
            if(Annexure == 'General Terms and Conditions for Sale of Equipment'){
                this.annexure6 = true;
            }
        }*/
        system.debug(productIds);
        Map<String,Schema.SObjectType> gd = Schema.getGlobalDescribe();
        Schema.SObjectType sobjType = gd.get('Quote');
        Schema.DescribeSObjectResult r = sobjType.getDescribe();
        Map<String, Schema.SObjectField> MapofField = r.fields.getMap();
        Map<String, Schema.SObjectField> testMap = new Map<String, Schema.SObjectField>();
        
        for(String fieldName : MapofField.keySet()) {
            Schema.SObjectField field = MapofField.get(fieldName);
            Schema.DescribeFieldResult F = field.getDescribe();
            testMap.put(F.getName(),field);
            mfields.put(F.getName().tolowercase(),field);
        }
        sobjecttomfields.put('Quote',testMap);
        
        
        Map<String,Schema.SObjectType> gdu = Schema.getGlobalDescribe();
        Schema.SObjectType sobjuType = gdu.get('User');
        Schema.DescribeSObjectResult ru = sobjuType.getDescribe();
        Map<String, Schema.SObjectField> MapofFieldUser = ru.fields.getMap();
        Map<String, Schema.SObjectField> testMapUser = new Map<String, Schema.SObjectField>();
        
        for(String fieldName : MapofFieldUser.keySet()) {
            Schema.SObjectField fieldUser = MapofFieldUser.get(fieldName);
            Schema.DescribeFieldResult FU = fieldUser.getDescribe();
            testMapUser.put(FU.getName(),fieldUser);
            ufields.put(FU.getName().tolowercase(),fieldUser);
        }
        sobjecttomfieldsUser.put('User',testMapUser);
        
        
        String query = '';
        String queryFields = '';
        placeholderQuote = new Quote(); 
        userOwner = new User();
        sectionIds = new Set<Id>();
        EachSectionDataToDisplay = new List<eachSectionContentWrapper>();
        imagesToDisplay = new List<eachSectionContentWrapper>();
        List<Section__c> technicalAndProductBenefitsSectionList  = new List<Section__C>();
        Map<Section__c, string> sectionBasedContent = new Map<Section__c, string>();
        Map<String,List<Section__c>> sectionByType  = new Map<String,List<Section__c>>();
        Map<String, ImageData> imageData = new Map<String, ImageData>();
        Map<String, ImageWithTextData> imageWithText = new Map<String, ImageWithTextData>();
        Map<String, List<EachRowWrapper>> productSpecificationData = new Map<String, List<EachRowWrapper>>();
        Map<Id, List<Section__c>> sectionsByBaseProduct = new Map<Id, List<Section__c>>();
        
        // Map of type based section
        sectionList = FilteredSections.getsectionRecords(quoteTemplateId,quoteId,u);//fetch sections w.r.t conditions
        for(Section__c sec : sectionList){
            system.debug('Map of type based section ' + sec);
            List<Section__c> sectionTypeBasedList = sectionByType.get(sec.Type__c);
            if(sectionTypeBasedList == null){
                sectionTypeBasedList = new List<Section__c>();
            }
            sectionTypeBasedList.add(sec);
            sectionByType.put(sec.Type__c, sectionTypeBasedList);
        }
        
        // Getting section data by passing type based section
        placeholderQuote = getPlaceHolderQuote(sectionByType.get('Dynamic Text'), quoteId);
        if(!qtOwnerid.isempty() && qtOwnerid.size() <> 0){
         userOwner = getPlaceHolderQuoteOwner(sectionByType.get('Dynamic Text'), qtOwnerid[0].ownerid);
        }
        imageData = getImageData(sectionByType.get('Image'), productNameBasedProductId);
        imageWithText = getImageWithTextData(sectionByType.get('Image With Text'), productNameBasedProductId);
        Map<String, ImageWithQRCode> imageWithQRCodeData = getImageWithQRCodeData(sectionByType.get('Image With QRCode'), productNameBasedProductId);
        Map<String, List<List<HeaderWrapper>>> invoiceTableWrapperMapToDisplayData = getInvoiceData(sectionByType.get('Table'), quoteId, darkShadeColor, lightShadeColor, qt);
        Map<decimal,list<eachSectionContentWrapper>> sectionWrapper = new Map<decimal,list<eachSectionContentWrapper>>();
        
        // Iterate over the section for making wrapper records to show on UI 
        for(Section__c section : sectionList){
            if(section.Annexure__c == 'Technical Details' || section.Annexure__c == 'Product Benefits'){
               system.debug('section for making wrapper records to show on UI  =>' +section );
                technicalAndProductBenefitsSectionList.add(section); 
            }else{
                eachSectionContentWrapper wrapObj = new eachSectionContentWrapper();
                wrapObj.sectionAlignment = section.Section_Alignment__c;
                wrapObj.displayOrder = section.Display_Order__c;
                if(section.Page_Break__c == true){
                    wrapObj.PageBreak = 'always';
                }
                wrapObj.annexureValue = section.Annexure__c;
                wrapObj.SectionType = section.Type__c;
                
                if(section.Type__c == 'Dynamic Text'){
                    wrapPlaceHolderSection(section, wrapObj, placeholderQuote, 0, sequenceByAlphabet,userOwner);
                }else if(section.Type__c == 'Text'){
                    wrapObj.content = section.Content__c;
                }else if(section.Type__c == 'Image'){
                    wrapObj.imagesData = imageData.get(section.Id);
                }else if(section.Type__c == 'Image With Text'){
                    wrapObj.imageWithText = imageWithText.get(section.Id);
                }else if(section.Type__c == 'Table'){
                    wrapObj.invoiceTableData = invoiceTableWrapperMapToDisplayData.get(section.Id);
                }
                if(!sectionWrapper.containskey(section.Display_Order__c)){
                    sectionWrapper.put(section.Display_Order__c,new list<eachSectionContentWrapper>{wrapObj});  
                }
            }
        } // section loop ends here 
        
        sectionsByBaseProduct = getSectionsByBaseProduct(technicalAndProductBenefitsSectionList);
        
        //sequencing for technical details and product benefits functionality starts
        map<id,integer> prBenf = new map<id,integer>();
        map<id,integer> prBenfSec = new map<id,integer>();
        set<decimal> synedOrder = new set<decimal>();
        map<id,set<decimal>> baseProOrder = new map<id,set<decimal>>();
        map<decimal,list<eachSectionContentWrapper>> outerWrapper = new map<decimal,list<eachSectionContentWrapper>>();
        
        for(Decimal eachSequenceCount : sequenceByQuoteLineItem.keySet()){
            Id eachSequenceBaseProductId;
            for(QuoteLineItem LineItemm : sequenceByQuoteLineItem.get(eachSequenceCount)){
                if(!prBenf.containskey(LineItemm.Product2.Id)){
                    prBenf.put(LineItemm.Product2.Id,1); 
                }
                else{
                    prBenf.put(LineItemm.Product2.Id,prBenf.get(LineItemm.Product2.Id)+1); 
                }
                if(LineItemm.Product2.Component_Type__c == 'Base Product'){
                   eachSequenceBaseProductId = LineItemm.Product2.Id; 
                }
            }//lineitem loop ends here
            if(eachSequenceBaseProductId != null){
                if(sectionsByBaseProduct.get(eachSequenceBaseProductId) != null){
                    for(Section__c baseProductRelatedSection : sectionsByBaseProduct.get(eachSequenceBaseProductId)){
                        if(!baseProOrder.containskey(eachSequenceBaseProductId)){
                            baseProOrder.put(eachSequenceBaseProductId, new set<decimal>{baseProductRelatedSection.Display_Order__c});
                        }
                        else{
                            set<decimal> existingOrder = baseProOrder.get(eachSequenceBaseProductId);
                            existingOrder.add(baseProductRelatedSection.Display_Order__c);
                            baseProOrder.put(eachSequenceBaseProductId, existingOrder);
                        }
                    }//loop ends here
                }
            }
           
        }//loops ends here
        map<id,list<decimal>> mapOfOrderList =  new map<id,list<decimal>>();
        for(id baseProductId : baseProOrder.keyset()){
            if(!mapOfOrderList.containskey(baseProductId)){
                List<Decimal> listOfBeSorted = new List<Decimal>(baseProOrder.get(baseProductId));
                listOfBeSorted.sort();
                mapOfOrderList.put(baseProductId,listOfBeSorted);
            }
        }//loop ends here
        for(Decimal eachSequence : sequenceByQuoteLineItem.keySet()){
            List<Product_Specification__c> sequencedPsList = new List<Product_Specification__c>();
            Set<Id> SequensedProductIdsSet = new Set<Id>();
            Id eachSequenceBaseProduct;
            integer syncOrder=0;
            decimal defaultOrder=0;
            map<decimal,list<eachSectionContentWrapper>> orderWrapper = new map<decimal,list<eachSectionContentWrapper>>();
            boolean befDet= false;
            
            for(QuoteLineItem LineItem : sequenceByQuoteLineItem.get(eachSequence)){    
                if(LineItem.Product2.Component_Type__c == 'Base Product'){
                    
                    //get value from search key field for cover page 
                    if(LineItem.Product2.Search_Key_I__c != null){
                        productFamilyList.add(LineItem.Product2.Search_Key_I__c);
                    }
                    
                    //  product benefits functionality starts
                    if(!prBenfSec.containskey(LineItem.Product2.Id)){
                        prBenfSec.put(LineItem.Product2.Id,1); 
                    }
                    else{
                        prBenfSec.put(LineItem.Product2.Id,prBenfSec.get(LineItem.Product2.Id)+1); 
                    }
                    if(prBenf.containskey(LineItem.Product2.Id) && (prBenf.get(LineItem.Product2.Id) == prBenfSec.get(LineItem.Product2.Id))){
                        befDet = true; 
                    }
                    // product benefits functionality ends
                    eachSequenceBaseProduct = LineItem.Product2.Id;
                    SequensedProductIdsSet.add(LineItem.Product2.Id);
                    if(productIdByProductSpecification.get(LineItem.Product2.Id) != null){
                        for(Product_Specification__c baseProductPs : productIdByProductSpecification.get(LineItem.Product2.Id)){
                            sequencedPsList.add(baseProductPs);
                        }
                    }
                    
                }else if(LineItem.Product2.Variant_Type__c == 'Mast'){
                    SequensedProductIdsSet.add(LineItem.Product2.Id);
                    if(productIdByProductSpecification.get(LineItem.Product2.Id) != null){
                        for(Product_Specification__c baseProductPs : productIdByProductSpecification.get(LineItem.Product2.Id)){
                            sequencedPsList.add(baseProductPs);
                        }                        
                    }
                    
                }
            }
            if(eachSequenceBaseProduct != null){
                if(sectionsByBaseProduct.get(eachSequenceBaseProduct) != null){
                    for(Section__c baseProductRelatedSection : sectionsByBaseProduct.get(eachSequenceBaseProduct)){
                        
                        eachSectionContentWrapper wrapObj = new eachSectionContentWrapper();
                        wrapObj.sectionAlignment = baseProductRelatedSection.Section_Alignment__c;
                        wrapObj.displayOrder = baseProductRelatedSection.Display_Order__c;
                        
                        if(baseProductRelatedSection.Page_Break__c == true){
                            wrapObj.PageBreak = 'always';
                        }
                        if((befDet && baseProductRelatedSection.Annexure__c == 'Product Benefits') || (baseProductRelatedSection.Annexure__c != 'Product Benefits') ){
                         wrapObj.annexureValue = baseProductRelatedSection.Annexure__c;
                        }
                        wrapObj.SectionType = baseProductRelatedSection.Type__c;                 
                        if(baseProductRelatedSection.Type__c == 'Dynamic Text'){
                            wrapPlaceHolderSection(baseProductRelatedSection, wrapObj, placeholderQuote, eachSequence, sequenceByAlphabet,userOwner);
                        }else if(baseProductRelatedSection.Type__c == 'Text'){
                            wrapObj.contentLineSpacing = baseProductRelatedSection.Content_Line_Spacing__c;
                            if(baseProductRelatedSection.Content__c.contains('{! SequenceAlphabate }')){
                                String str = baseProductRelatedSection.Content__c;
                                Pattern pattern = Pattern.compile('\\{\\!\\s*SequenceAlphabate\\s*\\}');
                                Matcher matcher = pattern.matcher(str);
                                while (matcher.find()) {
                                    str = str.replace(matcher.group(), sequenceByAlphabet.get(eachSequence));
                                }
                                wrapObj.content = str;   
                            }else {
                                wrapObj.content = baseProductRelatedSection.Content__c;
                            }
                        }else if(baseProductRelatedSection.Type__c == 'Image With QRCode'){
                            wrapObj.imageWithQRCodeData = imageWithQRCodeData.get(baseProductRelatedSection.Id);
                        }else if(baseProductRelatedSection.Type__c == 'Image'){
                            wrapObj.imagesData = imageData.get(baseProductRelatedSection.Id);
                        }else if(baseProductRelatedSection.Type__c == 'Image With Text'){
                            wrapObj.imageWithText = imageWithText.get(baseProductRelatedSection.Id);
                        }else if(baseProductRelatedSection.Type__c == 'Product Specification'){
                            
                            wrapObj.psRowSpacing = String.valueof(baseProductRelatedSection.Product_Specification_Row_Spacing__c)+'px';
                            //method call for ps pass base product and mast Id
                            wrapObj.eachRowWrapData = getProductSpecificationWrap(sequencedPsList, SequensedProductIdsSet);   
                            
                        }
                        if(mapOfOrderList.containskey(eachSequenceBaseProduct)){
                            if(defaultOrder == 0  && mapOfOrderList.get(eachSequenceBaseProduct)[0] == baseProductRelatedSection.Display_Order__c){
                                defaultOrder = baseProductRelatedSection.Display_Order__c;
                                orderWrapper.put(defaultOrder,new list<eachSectionContentWrapper>{wrapObj});
                            }
                            else if(syncOrder!= 0 && defaultOrder!= 0 && mapOfOrderList.get(eachSequenceBaseProduct)[syncOrder] == baseProductRelatedSection.Display_Order__c){
                                list<eachSectionContentWrapper> existingOrder = orderWrapper.get(defaultOrder);
                                existingOrder.add(wrapObj);
                                orderWrapper.put(defaultOrder,existingOrder);
                            }
                            syncOrder +=1;
                         }
                        
                    }//loop ends here
                    for(decimal dd: orderWrapper.keyset()){
                        if(!outerWrapper.containskey(dd)){
                            outerWrapper.put(dd,orderWrapper.get(dd));  
                        }
                        else{
                            list<eachSectionContentWrapper> esc =  outerWrapper.get(dd);
                            esc.addall(orderWrapper.get(dd)); 
                            outerWrapper.put(dd,esc);
                        }
                        
                    }//loop ends here
                }
                
            }
        }//loop ends here
        for(decimal dmll: outerWrapper.keyset()){
            if(!sectionWrapper.containskey(dmll)){
              sectionWrapper.put(dmll,outerWrapper.get(dmll));   
            }
        }//loop ends here
        List<decimal> wrpper = new List<decimal>(sectionWrapper.keyset());
        wrpper.sort();
        for(decimal dc: wrpper){
           list<eachSectionContentWrapper> rt = sectionWrapper.get(dc);
            EachSectionDataToDisplay.addall(rt);
        }//loop ends here
        //sequencing for technical details and product benefits functionality ends here
        
        //Set Product Specification Special Instructions only for first table
        Integer counter = 0;
        for(eachSectionContentWrapper eachWrapRec : EachSectionDataToDisplay){
            if(eachWrapRec.SectionType == 'Product Specification'){
                counter++;
                
                if(counter == 1 && qt.Add_Technical_Specification__c != null){
                    this.ps_specialinstructions = qt.Add_Technical_Specification__c;
                    eachWrapRec.show_SI_For_Ps = true;
                }else{
                    eachWrapRec.show_SI_For_Ps = false;
                }
                
            }            
        }//loop ends here 
        
        
    }
    /**
    * @description getSectionsByBaseProduct: This method return map of base product and its related sections
    */ 
    public static Map<Id, List<Section__c>> getSectionsByBaseProduct(List<Section__c> technicalAndProductBenifitsSections) {
        Map<Id, List<Section__c>> sectionsByBaseProductToReturn = new Map<Id, List<Section__c>>();
        
        for(Section__c sec : technicalAndProductBenifitsSections){
            
            if(sec.Section_Related_Base_Product__r.Component_Type__c == 'Base Product'){
                
                List<Section__c> sectionsByBaseProduct = sectionsByBaseProductToReturn.get(sec.Section_Related_Base_Product__c);
                if(sectionsByBaseProduct == null){
                    sectionsByBaseProduct = new List<Section__c>();
                }
                sectionsByBaseProduct.add(sec);
                sectionsByBaseProductToReturn.put(sec.Section_Related_Base_Product__c, sectionsByBaseProduct);
            }
        }
        system.debug('sectionsByBaseProductToReturn '+ sectionsByBaseProductToReturn);
        return sectionsByBaseProductToReturn;
    }
    /**
    * @description getProductSpecificationWrap: This method returns list of (EachRowWrapper) records by passing list of ProductSpecificationn and set of productIds
    *                                           to make technical details table.
    */
    public static List<EachRowWrapper> getProductSpecificationWrap(List<Product_Specification__c> sequencedProductSpecificationList, Set<Id> SequensedProductIdsSet){
        
        //map order base ps record
        //map keySet add to list 
        //iterate over the sorted list and get ps record
        Map<Decimal, Product_Specification__c> sequenceBasedPs = new Map<Decimal, Product_Specification__c>();
        List<Product_Specification__c> psListTopass = new List<Product_Specification__c>();
        
        for(Product_Specification__c psRec : sequencedProductSpecificationList){
            sequenceBasedPs.put(psRec.Sequence__c, psRec);
        }
        
        List<Decimal> sortedPs = new List<Decimal>(sequenceBasedPs.keySet());
        sortedPs.sort();
        for(Decimal des : sortedPs){
            psListTopass.add(sequenceBasedPs.get(des));
        }
        
        List<EachRowWrapper> listToAdd = new List<EachRowWrapper>();
        Map<String, List<Product_Specification__c>> sortedPsMap = getPsOfASectionByPsSequenceAndPsSection(psListTopass);
        
        for(String psSection : sortedPsMap.keySet()){
            List<Product_Specification__c> psList = sortedPsMap.get(psSection);
            List<SectionBasedData> sectionBasedList = getSectionBasedDataFromPs(psList);
            EachRowWrapper eachWrap = new EachRowWrapper();
            eachWrap.sectionName = psList.get(0).Section__c;
            eachWrap.rowData = sectionBasedList;
            listToAdd.add(eachWrap);
        }
        return listToAdd; 
    }
    /**
    * @description getImageUrlByName: This method return image url by its name
    */
    private static Map<String, String> getImageUrlByName(Set<Id> sObjectIds) {
        system.debug(sObjectIds);
        Map<String, String> imageNamesBasedUrl = new Map<String, String>();
        Set<Id> ContentDocumentIds = new Set<Id>();
        
        if(sObjectIds.size() > 0){
            for(ContentDocumentLink cdl : [Select id, LinkedEntityId, ContentDocumentId, IsDeleted, SystemModstamp, ShareType, Visibility from ContentDocumentLink where LinkedEntityId in : sObjectIds]){
                ContentDocumentIds.add(cdl.ContentDocumentId);
            } 
        }
        
        if(ContentDocumentIds.size() > 0){
            String baseUrl = URL.getOrgDomainUrl().toExternalForm();
            Map<Id, ContentVersion> latestVersionByDocumentId = new Map<Id, ContentVersion>();
            for(ContentVersion cv : [SELECT Id, ContentDocumentId, FileExtension, VersionData FROM ContentVersion WHERE ContentDocumentId IN :ContentDocumentIds AND IsLatest = true]){
                latestVersionByDocumentId.put(cv.ContentDocumentId, cv);
            }
            for(ContentDistribution conDistribution: [select Id, Name, ContentVersionId, ContentDocumentId, ContentDownloadUrl from ContentDistribution where ContentDocumentId =: ContentDocumentIds]){
                String imageName = conDistribution.Name;
                imageName = imageName.replaceAll('\\s\\d{1,2}/\\d{1,2}/\\d{4}', '');
                String imageUrl = conDistribution.ContentDownloadUrl;
                ContentVersion cv = latestVersionByDocumentId.get(conDistribution.ContentDocumentId);
                if(cv != null && cv.VersionData != null){
                    String mimeType = 'image/png';
                    if(cv.FileExtension != null){
                        String ext = cv.FileExtension.toLowerCase();
                        if(ext == 'png') mimeType = 'image/png';
                        else if(ext == 'jpg' || ext == 'jpeg') mimeType = 'image/jpeg';
                        else if(ext == 'gif') mimeType = 'image/gif';
                        else if(ext == 'svg') mimeType = 'image/svg+xml';
                        else if(ext == 'bmp') mimeType = 'image/bmp';
                        else if(ext == 'webp') mimeType = 'image/webp';
                    }
                    imageUrl = 'data:' + mimeType + ';base64,' + EncodingUtil.base64Encode(cv.VersionData);
                } else if(imageUrl != null && !imageUrl.startsWithIgnoreCase('http')){
                    if(imageUrl.startsWith('/')){
                        imageUrl = baseUrl + imageUrl;
                    } else {
                        imageUrl = baseUrl + '/' + imageUrl;
                    }
                }
                imageNamesBasedUrl.put(imageName, imageUrl);
            }
        }
        system.debug('imageNamesBasedUrl '+imageNamesBasedUrl);
        return imageNamesBasedUrl;
    }
    /**
    * @description getImageWithTextData: This method return image and its associate text populated on content field
    */
    public static Map<String, ImageWithTextData> getImageWithTextData(List<Section__c> imageWithTextSections, Map<String, Id> productNameBasedProductId){
        Map<String, ImageWithTextData> imageWithTextMapToReturn = new Map<String, ImageWithTextData>();
        List<Section_Condition__c> sectionRelatedSectionCondition = new List<Section_Condition__c>();
        List<ContentVersion> sectionRelatedFile = new List<ContentVersion>();
        Set<Id> sectionIds = new Set<Id>();
        Set<Id> productIds = new Set<Id>();
        
        if(imageWithTextSections != null ){
            for(Section__c eachSection : imageWithTextSections){
                sectionIds.add(eachSection.Id);
            }
        }
        if(sectionIds != null){
            sectionRelatedSectionCondition = [Select Id, Name, Object_Name__c, Field__c, Section__c, Operator__c, Value__c FROM Section_Condition__c WHERE Section__c =: sectionIds ];
        }
        for(Section_Condition__c sc : sectionRelatedSectionCondition){
            productIds.add(productNameBasedProductId.get(sc.Value__c));
        }
        
        Map<String, String> productImages = getImageUrlByName(productIds);
        Map<String, String> sectionImages = getImageUrlByName(sectionIds);
        
        if(imageWithTextSections != null){
            for(Section__c eachSection : imageWithTextSections){
                ImageWithTextData imageWithTextData = new ImageWithTextData();
                imageWithTextData.imageName = eachSection.Image_Name__c;
                imageWithTextData.imageContent = eachSection.Content__c;
                imageWithTextData.imageURL = productImages.get(eachSection.Image_Name__c);
                
                if(imageWithTextData.imageURL == null){
                    imageWithTextData.imageURL = sectionImages.get(eachSection.Image_Name__c);
                }
                imageWithTextData.imageWidth = eachSection.Image_Width__c;
                imageWithTextData.imageHeight = eachSection.Image_Height__c;
                imageWithTextMapToReturn.put(eachSection.Id, imageWithTextData);
            }
        }
        
        return imageWithTextMapToReturn;
    }
    /**
	* @description wrapPlaceHolderSection: This method replace the fields place holders with it's value. Placeholder Examples: {Quote.QuoteNumber},{Quote.Name}
    */ 
    public static void wrapPlaceHolderSection(Section__c secObj, eachSectionContentWrapper wrapObj, Quote placeholderQuote, Decimal eachSequence, Map<Decimal, String> sequenceByAlphabet,User userOwner){
        String val = '';
        String eachContent = secObj.Content__c;
       // eachContent = eachContent.stripHtmlTags();
        
        if(eachContent.contains('{! SequenceAlphabate }')){
            Pattern pattern = Pattern.compile('\\{\\!\\s*SequenceAlphabate\\s*\\}');
            Matcher matcher = pattern.matcher(eachContent);
            while (matcher.find()) {
                eachContent = eachContent.replace(matcher.group(), sequenceByAlphabet.get(eachSequence));
            }
            wrapObj.content = eachContent;
            wrapObj.contentLineSpacing = secObj.Content_Line_Spacing__c;
        }else {
            getrelationshipfieldsUser(eachContent);
            getrelationshipfields(eachContent);
            string ruf= replaceUserPlaceholdersWithOwnerValue(eachContent,userOwner);
            val = replacePlaceholdersWithValue(ruf,placeholderQuote);
            wrapObj.content = val;
            if(secObj.Page_Break__c == true){
                wrapObj.PageBreak = 'always';
            }
            wrapObj.annexureValue = secObj.Annexure__c;
            wrapObj.SectionType = secObj.Type__c;
            wrapObj.contentLineSpacing = secObj.Content_Line_Spacing__c;
        }
        
    }
    /**
    * @description getPlaceHolderQuote: This method return User with field value
    */ 
    public static User getPlaceHolderQuoteOwner(List<Section__c> placeHolderSections, Id userId){
      String queryFieldValue;
        User quoteOwnerToReturn;
        if(placeHolderSections != null){
         queryFieldValue = getQuoteOwnerQueryFields(placeHolderSections);   
        }
        if(queryFieldValue != null && queryFieldValue != ''){
            quoteOwnerToReturn = (User) Database.query('SELECT '+queryFieldValue+' FROM User WHERE Id =: userId')[0];
        }
        return quoteOwnerToReturn;      
    }
    
     /**
    * @description getQuoteQueryFields: This method return owner fields from sections
    */ 
    public static String getQuoteOwnerQueryFields(List<Section__c> placeholderSections){
        Set<String> values = new Set<String>();
        Pattern pattern = Pattern.compile('\\{!Quote.(.*?)\\}');
        if(placeholderSections != null){
            for(Section__c section : placeholderSections){
                String str = section.Content__c.stripHtmlTags();
                str = str.replace('quote', 'Quote');
                Matcher matcher = pattern.matcher(str);
                
                while (matcher.find()) {
                    if(matcher.group(0).contains('Quote.Owner.')){
                      String updatedFields = matcher.group(0).replace('Quote.Owner.', '');
                      values.add(matcher.group(1).replace('Owner.', ''));  
                    }
                    
                } 
            } 
        }
        return String.join(values, ',');
    }
    
    /**
    * @description getPlaceHolderQuote: This method return quote with field value
    */ 
    public static Quote getPlaceHolderQuote(List<Section__c> placeHolderSections, Id quoteId){
        String queryFieldValue;
        Quote quoteToReturn;
        if(placeHolderSections != null){
         queryFieldValue = getQuoteQueryFields(placeHolderSections);   
        }
        if(queryFieldValue != null && queryFieldValue != ''){
            quoteToReturn = (Quote) Database.query('SELECT '+queryFieldValue+' FROM Quote WHERE Id =: quoteId ')[0];
        }
        return quoteToReturn;
    }
    /**
    * @description getQuoteQueryFields: This method return fields from sections
    */ 
    public static String getQuoteQueryFields(List<Section__c> placeholderSections){
        Set<String> values = new Set<String>();
        Pattern pattern = Pattern.compile('\\{!Quote.(.*?)\\}');
        if(placeholderSections != null){
            for(Section__c section : placeholderSections){
                String str = section.Content__c.stripHtmlTags();
                str = str.replace('quote', 'Quote');
                Matcher matcher = pattern.matcher(str);
                
                while (matcher.find()) {
                    
                    if(!matcher.group(0).contains('Quote.Owner.')){ 
                      values.add(matcher.group(1));  
                    }
                    
                } 
            } 
        }
        return String.join(values, ',');
    }
    /**
    * @description getImageData: This method return section Id base (ImageData) wrapper map  
    */ 
    public static Map<String, ImageData> getImageData(List<Section__c> imageSections, Map<String, Id> productNameBasedProductId){
        Map<String, ImageData> mapToReturn = new Map<String, ImageData>();
        List<Section_Condition__c> sectionRelatedSectionCondition = new List<Section_Condition__c>();
        List<ContentVersion> sectionRelatedFile = new List<ContentVersion>();
        Set<Id> sectionIds = new Set<Id>();
        Set<Id> productIds = new Set<Id>();
        
        if( imageSections!=null ){
            for(Section__c eachSection : imageSections){
                sectionIds.add(eachSection.Id);
            }
        }
        if(sectionIds != null){
            sectionRelatedSectionCondition = [Select Id, Name, Object_Name__c, Field__c, Section__c, Operator__c, Value__c FROM Section_Condition__c WHERE Section__c =: sectionIds ];
        }
        for(Section_Condition__c sc : sectionRelatedSectionCondition){
            productIds.add(productNameBasedProductId.get(sc.Value__c));
        }
        Map<String, String> productImages = getImageUrlByName(productIds);
        Map<String, String> sectionImages = getImageUrlByName(sectionIds);
        
        if(imageSections != null){
            for(Section__c eachSection : imageSections){
                ImageData imageData = new ImageData();
                imageData.imageName = eachSection.Image_Name__c;
                imageData.imageURL = productImages.get(eachSection.Image_Name__c);
                
                if(imageData.imageURL == null){
                    imageData.imageURL = sectionImages.get(eachSection.Image_Name__c);
                }
                imageData.imageWidth = eachSection.Image_Width__c;
                imageData.imageHeight = eachSection.Image_Height__c;
                mapToReturn.put(eachSection.Id, imageData);
            }
        }
        return mapToReturn;
    }
    /**
    * @description getImageWithQRCodeData: This method return section Id base (ImageWithQRCode) wrapper map
    */ 
    public static Map<String, ImageWithQRCode> getImageWithQRCodeData(List<Section__c> imageWithQRCodeSections, Map<String, Id> productNameBasedProductId){
        Map<String, ImageWithQRCode> imageWithQRCodeMapToReturn = new Map<String, ImageWithQRCode>();
        
        List<Section_Condition__c> sectionRelatedSectionCondition = new List<Section_Condition__c>();
        List<ContentVersion> sectionRelatedFile = new List<ContentVersion>();
        Set<Id> sectionIds = new Set<Id>();
        Set<Id> productIds = new Set<Id>();
        
        if( imageWithQRCodeSections!=null ){
            for(Section__c eachSection : imageWithQRCodeSections){
                sectionIds.add(eachSection.Id);
            }
        }
        if(sectionIds != null){
            sectionRelatedSectionCondition = [Select Id, Name, Object_Name__c, Field__c, Section__c, Operator__c, Value__c FROM Section_Condition__c WHERE Section__c =: sectionIds ];
        }
        Map<Id, List<Section_Condition__c>> sectionBySectionCondition = new Map<Id, List<Section_Condition__c>>();
        
        for(Section_Condition__c sc : sectionRelatedSectionCondition){
            List<Section_Condition__c> sectionConditionList = sectionBySectionCondition.get(sc.Section__c);
            if(sectionConditionList == null){
                sectionConditionList = new List<Section_Condition__c>();
            }
            sectionConditionList.add(sc);
            sectionBySectionCondition.put(sc.Section__c, sectionConditionList);
        }
        
        Map<String, Set<Id>> sectionByProductId = new Map<String, Set<Id>>();
        if(imageWithQRCodeSections != null){
            
        for(Section__c eachSection : imageWithQRCodeSections){
            
            Set<Id> eachSectionId = new Set<Id>();
            if(sectionBySectionCondition.get(eachSection.Id) != null){
                for(Section_Condition__c eachSectionCondition : sectionBySectionCondition.get(eachSection.Id)){
                    Set<Id> sectionProductId = sectionByProductId.get(eachSection.Id);
                    if(sectionProductId == null){
                        sectionProductId = new Set<Id>();
                    }
                    sectionProductId.add(productNameBasedProductId.get(eachSectionCondition.Value__c));
                    sectionByProductId.put(eachSection.Id, sectionProductId);
                }
            }
            Map<String, String> productImages = new Map<String, String>();
            if(sectionByProductId.get(eachSection.Id) != null){
            	productImages = getImageUrlByName(sectionByProductId.get(eachSection.Id));
            }
            eachSectionId.add(eachSection.Id);
            Map<String, String> sectionImages = getImageUrlByName(eachSectionId);
            ImageWithQRCode imageWithQrData = new ImageWithQRCode();
            imageWithQrData.normalImageName = eachSection.Image_Name__c;
            imageWithQrData.qrCodeImageName = eachSection.QRCode_Image_Name__c;
            imageWithQrData.normalImageURL = productImages.get(eachSection.Image_Name__c);  
            if(imageWithQrData.normalImageURL == null){
                imageWithQrData.normalImageURL = sectionImages.get(eachSection.Image_Name__c);
            }
            
            imageWithQrData.qrCodeImageURL = productImages.get(eachSection.QRCode_Image_Name__c);
            if(imageWithQrData.qrCodeImageURL == null){
                imageWithQrData.qrCodeImageURL = sectionImages.get(eachSection.QRCode_Image_Name__c);
            }
            imageWithQrData.normalImageWidth = eachSection.Image_Width__c;
            imageWithQrData.normalImageHeight = eachSection.Image_Height__c;
            imageWithQrData.qrCodeImageText = eachSection.Content__c;
            imageWithQRCodeMapToReturn.put(eachSection.Id, imageWithQrData);
        }
        }
        return imageWithQRCodeMapToReturn;
    }
    /**
    * @description getPsOfASectionByPsSequenceAndPsSection: This method return ProductSpecification.Section by list of ProductSpecification
    */ 
    private static Map<String, List<Product_Specification__c>> getPsOfASectionByPsSequenceAndPsSection(List<Product_Specification__c> psList){
        
        Map<String, List<Product_Specification__c>> psMapToReturn = new Map<String, List<Product_Specification__c>>();
        List<Product_Specification__c> psRecordsContainsProductIds = new List<Product_Specification__c>();
        
        for(Product_Specification__c sortedPsRecord : psList){
            
            List<Product_Specification__c> psListBySection = psMapToReturn.get(sortedPsRecord.Section__c);
            
            if(psListBySection == null) {
                psListBySection = new List<Product_Specification__c>();
            }
            psListBySection.add(sortedPsRecord);
            psMapToReturn.put(sortedPsRecord.Section__c, psListBySection);
        }
        return psMapToReturn;
    }
    
    /**
    * @description getSectionBasedDataFromPs: This method return list of SectionBasedData
    */ 
    private static List<SectionBasedData> getSectionBasedDataFromPs(List<Product_Specification__c> psList) {
        List<SectionBasedData> eachSectionList = new List<SectionBasedData>();
        
        if(psList != null){
            for(Product_Specification__c ps: psList) {
                SectionBasedData eachDataWrap = new SectionBasedData();
                eachDataWrap.drive = ps.Subsection1__c;
                eachDataWrap.measurement = ps.Subsection2__c;
                eachDataWrap.battery = ps.Subsection3__c;
                eachDataWrap.sequence = ps.Sequence__c;
                eachDataWrap.isBold = ps.Is_Bold__c;
                eachSectionList.add(eachDataWrap);
            }
        }
        return eachSectionList;
    }
    /**
    * @description getInvoiceData: This method return section by list of list<HeaderWrapper> for creating complete invoice table. 
    */ 
    public static Map<String, List<List<HeaderWrapper>>> getInvoiceData(List<Section__c> invoiceTableSections, Id quoteId, String darkShadeColor, String lightShadeColor, Quote quoteObj){
        system.debug('getInvoiceData enter');
        Map<String, List<List<HeaderWrapper>>> invoiceTableWrapperMapToReturn = new Map<String, List<List<HeaderWrapper>>>();
        Set<Id> sectionIds = new Set<Id>();
        if(invoiceTableSections != null){
            for(Section__c eachSection : invoiceTableSections){
                  system.debug('eachSection:--'+eachSection);
                sectionIds.add(eachSection.Id);
            } 
        }
        
        List<Section_Table__c> sectionTables = [SELECT Id, Name, Section__c, Header_Label__c, QuoteLineItem_Field__c, Column_Display_Order__c, Column_width__c, Type__c, Show_Subtotal__c, Subtotal_Label__c FROM Section_Table__c WHERE Section__c =: sectionIds ORDER BY Column_Display_Order__c];
        Map<Id, List<Section_Table__c>> sectionTableByTableSection = new Map<Id, List<Section_Table__c>>();
        Map<Id, Set<String>> fieldsBySection = new Map<Id, Set<String>>();
        
        for (Section_Table__c tableSection : sectionTables) {
            List<Section_Table__c> secTables = sectionTableByTableSection.get(tableSection.Section__c);
            
            if (secTables == null) {
                secTables = new List<Section_Table__c>();
            }
            secTables.add(tableSection);
            sectionTableByTableSection.put(tableSection.Section__c, secTables);
            
            if (tableSection.Type__c != 'Serial Number') {
                Set<String> fieldsBySec = fieldsBySection.get(tableSection.Section__c);
                if (fieldsBySec == null) {
                    fieldsBySec = new Set<String>();
                    /*fieldsBySec.add('Product2.Component_Type__c');
                    fieldsBySec.add('Include_In_Bundle__c');
                    fieldsBySec.add('Total_Approved_Customer_Discount__c');
                    fieldsBySec.add('Invoice_Table_Order__c');*/
                }
                fieldsBySec.add(tableSection.QuoteLineItem_Field__c);
                fieldsBySection.put(tableSection.Section__c, fieldsBySec);
            }
        }
        if(invoiceTableSections != null){
            for (Section__c section : invoiceTableSections) {
                List<Section_Table__c> sectionTableList = sectionTableByTableSection.get(section.Id);
                if(fieldsBySection.containsKey(section.Id)) {
                    Set<String> quoteLineItemFields = fieldsBySection.get(section.Id);
                    quoteLineItemFields.add(section.Sort_By_Parameter__c);
                    String queryFields = String.join(quoteLineItemFields, ','); 
                
                    List<QuoteLineItem> quoteLineItemsList = null;
                    List<QuoteLineItem> filteredQuoteLineItemes = new List<QuoteLineItem>();
                    QuoteLineItem freightProduct = null;
                    List<List<HeaderWrapper>> rows = new List<List<HeaderWrapper>>();
                
                if(section.Show_Header__c){
                    // invoice table header creation here 
                    rows.add(getHeaderColumnValuesOfTableSection(sectionTableList, darkShadeColor));  
                }
                
                if(quoteLineItemFields.contains('Quantity') && quoteLineItemFields.contains('UnitPrice') && quoteLineItemFields.contains('TotalPrice')){
                    quoteLineItemsList = getInvoiceTableQuoteLineItem(queryFields, section.Table_Object__c , quoteId, section.QuoteLineItem_Filter__c);
                    if(!quoteLineItemsList.isEmpty()) {
                        for (QuoteLineItem item : quoteLineItemsList) {
                            system.debug(item);
                            if (!item.Product2.Name.contains('Freight') && item.Product2.Name != null) {
                                filteredQuoteLineItemes.add(item);
                            }else{
                                freightProduct = item;
                            }
                        }
                    }
                    Map<Decimal, List<QuoteLineItem>> sequenceBasedQuoteLineItem = getQuoteLineItemByProductSequence(filteredQuoteLineItemes);
                    Integer counter = 0;
                    Decimal subTotalOfUnitPrice = 0.0;
                    Decimal subTotalOfQuantity = 0.0;
                    Map<String, String> subTotalValues = new Map<String, String>();
                    
                    Decimal systemTotalDiscount = 0.0;
                    Decimal customTotalDiscount = 0.0;
                    Decimal finalTotalPrice = 0.0;
                    Decimal diffOfPoPriceAndOfferPrice = 0.0;
                    Decimal TotalpriceOfFreight = 0.00;
                    Decimal Total_Approved_Customer_Discount_Of_Freight = 0.00;
                    
                    if(freightProduct != null)
                    {
                        TotalpriceOfFreight = freightProduct.TotalPrice;
                        Total_Approved_Customer_Discount_Of_Freight = freightProduct.Total_Approved_Customer_Discount__c;
                    }
                    
                    
                    if(quoteObj.Offer_Price__c != null && quoteObj.Total_Unit_Basic__c != null && quoteObj.Offer_Price__c > quoteObj.Total_Unit_Basic__c) {
                        	Decimal offerPriceFreightDeduction = quoteObj.Offer_Price__c - TotalpriceOfFreight;
                        	Decimal totalMinPriceFreightDeduction = quoteObj.Total_Unit_Basic__c - TotalpriceOfFreight;
                            diffOfPoPriceAndOfferPrice = offerPriceFreightDeduction - totalMinPriceFreightDeduction;
                        	systemTotalDiscount = quoteObj.Total_Customer_Discount_Formula__c - Total_Approved_Customer_Discount_Of_Freight;
                    }
                    Map<Decimal,Decimal> sequenceBasedDiscountPercentage = new Map<Decimal, Decimal>();
                    Map<Decimal,Decimal> offerPriceDiscountMap = new Map<Decimal, Decimal>();
                    
                    for (Decimal sequence : sequenceBasedQuoteLineItem.keySet()) {
                        List<QuoteLineItem> quoteLineItemsByProductSequence = sequenceBasedQuoteLineItem.get(sequence);
                        Map<String, String> baseProductPrice = getBaseProductPrice(quoteLineItemsByProductSequence);
                        subTotalOfUnitPrice = subTotalOfUnitPrice + Decimal.valueOf(baseProductPrice.get('subTotalOfUnitPrice'));
                        Decimal subTotalOfTotalPrice = Decimal.valueOf(baseProductPrice.get('subTotalOfTotalPrice'));
                        subTotalOfQuantity = subTotalOfQuantity + Decimal.valueOf(baseProductPrice.get('subTotalOfQuantity'));
                        
                        Decimal discountPerSequence = 0.0;
                        Decimal eachSequenceDiscount = 0.0;
                        Decimal netBasicValue = 0.0;
                        String rowLabel = 'Total Basic for';
                        Decimal baseProductQuantity = 0;
                        Decimal offerPriceDiscount = 0.0;
                        
                        Decimal OverrideDiscount = 0.0;
                        
                        // invoice table QuoteLineItem records creation here 
                        for (QuoteLineItem item: quoteLineItemsByProductSequence) {
                            if(item.Product2.Component_Type__c == 'Base Product'){
                                counter = counter + 1;
                                rowLabel = rowLabel+ ' ' +item.Product2.Name;
                                baseProductQuantity = item.Quantity;
                            }
                            eachSequenceDiscount = eachSequenceDiscount + item.Total_Approved_Customer_Discount__c;
                            rows.add(getColumnValuesOfTableSection(item, sectionTableList, counter, baseProductPrice, lightShadeColor));
                        }
                        
                        subTotalValues.put('subTotalOfUnitPrice', String.valueOf(subTotalOfUnitPrice.format()));
                    	subTotalValues.put('subTotalOfTotalPrice', String.valueOf(subTotalOfTotalPrice.format()));
                    	subTotalValues.put('subTotalOfQuantity', String.valueOf(subTotalOfQuantity.format()));
                        
                        if(systemTotalDiscount != 0.0){
                            discountPerSequence = eachSequenceDiscount * 100 / systemTotalDiscount;
                            sequenceBasedDiscountPercentage.put(sequence,discountPerSequence);
                        }
                        
                        offerPriceDiscount = diffOfPoPriceAndOfferPrice * discountPerSequence / 100;
                        offerPriceDiscountMap.put(sequence, offerPriceDiscount);
                        
                        if( offerPriceDiscount > eachSequenceDiscount ){
                       		OverrideDiscount = 0;
                        }else {
                            OverrideDiscount = eachSequenceDiscount - offerPriceDiscount;
                        }
                        
                        
                        boolean showBorder = eachSequenceDiscount == 0 ? true : false;
                        customTotalDiscount = customTotalDiscount + eachSequenceDiscount;
                        rows.add(getHeaderSubTotalColumnValuesOfTableSection(sectionTableList, subTotalValues, rowLabel, showBorder, null, baseProductQuantity));
						
                        if(quoteObj.Offer_Price__c > quoteObj.Total_Unit_Basic__c){
                           if( OverrideDiscount != 0){
                                rows.add(getHeaderSubTotalColumnValuesOfTableSection(sectionTableList, subTotalValues, 'Discount', false, OverrideDiscount, null));
                                
                               	netBasicValue = subTotalOfTotalPrice - OverrideDiscount;
                                rows.add(getHeaderSubTotalColumnValuesOfTableSection(sectionTableList, subTotalValues, 'Net Basic Value', true, netBasicValue, null));
                                finalTotalPrice = finalTotalPrice + netBasicValue;
                           }else{
                               finalTotalPrice = finalTotalPrice + subTotalOfTotalPrice;
                           }
                        }else{
                            if( eachSequenceDiscount != 0){
                                rows.add(getHeaderSubTotalColumnValuesOfTableSection(sectionTableList, subTotalValues, 'Discount', false, eachSequenceDiscount, null));
                                netBasicValue = subTotalOfTotalPrice - eachSequenceDiscount;
                                rows.add(getHeaderSubTotalColumnValuesOfTableSection(sectionTableList, subTotalValues, 'Net Basic Value', true, netBasicValue, null));
                                finalTotalPrice = finalTotalPrice + netBasicValue;
                            }else{
                                finalTotalPrice = finalTotalPrice + subTotalOfTotalPrice;
                            }
                        } 
                    }
                    if(finalTotalPrice != null){
                    	finalBasicAmount(TotalpriceOfFreight, finalTotalPrice);
                    }
                    
                    
                    //subTotalValues.put('subTotalOfUnitPrice', String.valueOf(subTotalOfUnitPrice.format()));
                    //subTotalValues.put('subTotalOfTotalPrice', String.valueOf(subTotalOfTotalPrice.format()));
                    //subTotalValues.put('subTotalOfQuantity', String.valueOf(subTotalOfQuantity.format()));
                    
                    // invoice table subtotal row creation here 
                    //rows.add(getHeaderSubTotalColumnValuesOfTableSection(sectionTableList, subTotalValues));
                }
                invoiceTableWrapperMapToReturn.put(section.Id, rows);
            } 
            }
        }
        return invoiceTableWrapperMapToReturn;
    }
    
    public static void finalBasicAmount(Decimal freAmount, Decimal finalAmount){
        freightAmount = String.valueOf(freAmount.format());
        Decimal finalOfferPrice = finalAmount + freAmount;
        finalBasicAmount = String.valueOf(finalOfferPrice.format());
    }
    /**
    * @description getBaseProductPrice: This method return BaseProduct Unit & Total Price for every sequence 
    */ 
    public static Map<String, String> getBaseProductPrice(List<QuoteLineItem> quoteLineItems) {
        Map<String, String> baseProductPriceValues = new Map<String, String>();
        
        Decimal baseProductQuantity = 0;
        Decimal baseProductPrice = 0.0;
        Decimal baseProductTotalPrice = 0.0;
        Decimal subTotalOfUnitPrice = 0.0;
        Decimal subTotalOfTotalPrice = 0.0;
        Decimal subTotalOfQuantity = 0.0;
        
        for (QuoteLineItem item : quoteLineItems) {
            
            if (item.Product2.Component_Type__c == 'Base Product') {
                baseProductQuantity = item.Quantity;
                baseProductPrice = baseProductPrice + (item.Quantity * item.UnitPrice);  
            } else if (!item.Include_In_Bundle__c) {
                subTotalOfUnitPrice = subTotalOfUnitPrice + item.UnitPrice;
                subTotalOfTotalPrice = subTotalOfTotalPrice + item.TotalPrice;
                subTotalOfQuantity = subTotalOfQuantity + item.Quantity;
            } else if (item.Include_In_Bundle__c) {
                baseProductPrice = baseProductPrice + (item.Quantity * item.UnitPrice);
                subTotalOfQuantity = subTotalOfQuantity + item.Quantity;
            }
        }
        
        
        if(baseProductQuantity != 0){
           baseProductPrice = baseProductPrice / baseProductQuantity;
        }
        
        subTotalOfUnitPrice = subTotalOfUnitPrice + baseProductPrice;
        subTotalOfTotalPrice = subTotalOfTotalPrice + (baseProductPrice * baseProductQuantity);
        subTotalOfQuantity = subTotalOfQuantity + baseProductQuantity;
        baseProductTotalPrice = baseProductPrice * baseProductQuantity;
        baseProductPriceValues.put('baseProductUnitPrice', String.valueOf(baseProductPrice.format()));
        baseProductPriceValues.put('baseProductTotalPrice', String.valueOf(baseProductTotalPrice.format()));
        baseProductPriceValues.put('subTotalOfUnitPrice', String.valueOf(subTotalOfUnitPrice));
        baseProductPriceValues.put('subTotalOfTotalPrice', String.valueOf(subTotalOfTotalPrice));
        baseProductPriceValues.put('subTotalOfQuantity', String.valueOf(subTotalOfQuantity));
        return baseProductPriceValues;
    }
    /**
    * @description getBaseProductPrice: This method group quote line items by productSequence where base product will be first record
    */ 
    private static Map<Decimal, List<QuoteLineItem>> getQuoteLineItemByProductSequence(List<QuoteLineItem> quoteLineItems) {
        
        Map<Decimal, List<QuoteLineItem>> sequenceBasedQliMapToReturn = new Map<Decimal, List<QuoteLineItem>>(); 
        Map<Decimal, List<QuoteLineItem>> sequenceBasedQuoteLineItem = new Map<Decimal, List<QuoteLineItem>>();
        
        for(QuoteLineItem qli : quoteLineItems){
            
            List<QuoteLineItem> sequencedQuoteLineItemsList = sequenceBasedQuoteLineItem.get(qli.Sequence_Number__c);
            if(sequencedQuoteLineItemsList == null){
                sequencedQuoteLineItemsList = new List<QuoteLineItem>();
            }
            
            if (qli.Product2.Component_Type__c == 'Base Product') {
                if (sequencedQuoteLineItemsList.isEmpty()) {
                    sequencedQuoteLineItemsList.add(qli);
                } else {
                    sequencedQuoteLineItemsList.add(0, qli);
                }
            } else {
                sequencedQuoteLineItemsList.add(qli);
            }
            sequenceBasedQuoteLineItem.put(qli.Sequence_Number__c, sequencedQuoteLineItemsList);
        }
        
        
        for(Decimal eachSequence : sequenceBasedQuoteLineItem.keySet()){
            Map<Decimal, List<QuoteLineItem>> invoiceOrderByQli = new Map<Decimal, List<QuoteLineItem>>();
            List<QuoteLineItem> qliListToUpdate = new List<QuoteLineItem>();
            
            for(QuoteLineItem qli : sequenceBasedQuoteLineItem.get(eachSequence)){
                List<QuoteLineItem> qliList = invoiceOrderByQli.get(qli.Invoice_Table_Order__c);
                if(qliList == null){
                    qliList = new List<QuoteLineItem>();
                }
                qliList.add(qli);
                invoiceOrderByQli.put(qli.Invoice_Table_Order__c, qliList);  
            }
            
            
            List<Decimal> sortedQli = new List<Decimal>(invoiceOrderByQli.keySet());
            sortedQli.sort();
            
            for(Decimal eachKey : sortedQli){
                    for(QuoteLineItem qli : invoiceOrderByQli.get(eachKey)){
                        if(qli.Product2.Component_Type__c == 'Base Product'){
                            if(qliListToUpdate.isEmpty()){
                                qliListToUpdate.add(qli);
                            }else{
                                qliListToUpdate.add(0,qli);
                            }
                        }else{
                            qliListToUpdate.add(qli); 
                        }
                    }   
            }           
            
            sequenceBasedQliMapToReturn.put(eachSequence,qliListToUpdate);
        }
        
        return sequenceBasedQliMapToReturn;
    }
    /**
    * @description getBaseProductPrice: This method return the QuoteLineItem records for invoice table
    */ 
    private static List<HeaderWrapper> getColumnValuesOfTableSection(QuoteLineItem quoteLineItem, List<Section_Table__c> sectionTables, Integer serialNumber, Map<String, String> baseProductPrice, String lightShadeColor) {
        
        List<HeaderWrapper> columns = new List<HeaderWrapper>(6);
        for (Section_Table__c secTable : sectionTables) {
            HeaderWrapper column = new HeaderWrapper();
            String value = '';
            Boolean INR_Symbol = False;
            if (secTable.QuoteLineItem_Field__c == 'Product2.Name') {
                column.borderTop = '1px solid rgb(127,127,127)';
            	column.borderBottom = '1px solid rgb(127,127,127)';
                column.borderLeft = '1px solid rgb(127,127,127)';
                value = quoteLineItem.Product2.Name;
                if(quoteLineItem.Product2.Component_Type__c == 'Base Product'){
                    column.backgroundColor = lightShadeColor;
                }
                column.textAlignment = 'Left';
                column.paddingleft = '10px';
            } else if (secTable.QuoteLineItem_Field__c == 'Product2.Commodity_code__c') {
                column.borderTop = '1px solid rgb(127,127,127)';
            	column.borderBottom = '1px solid rgb(127,127,127)';
                if(quoteLineItem.Product2.Component_Type__c == 'Base Product'){
                    value = quoteLineItem.Product2.Commodity_code__c;
					column.backgroundColor = lightShadeColor;                    
                }
            } else if (secTable.QuoteLineItem_Field__c == 'Quantity') {
                column.borderTop = '1px solid rgb(127,127,127)';
            	column.borderBottom = '1px solid rgb(127,127,127)';
                value = String.valueOf(quoteLineItem.Quantity.format());
                if(quoteLineItem.Product2.Component_Type__c == 'Base Product'){
					column.backgroundColor = lightShadeColor;                    
                }
            } else if (secTable.QuoteLineItem_Field__c == 'UnitPrice') {
                column.borderTop = '1px solid rgb(127,127,127)';
            	column.borderBottom = '1px solid rgb(127,127,127)';
                if(quoteLineItem.Product2.Component_Type__c == 'Base Product'){
                    column.backgroundColor = lightShadeColor;
                    column.textAlignment = 'right';
                    value = baseProductPrice.get('baseProductUnitPrice');
                    INR_Symbol = false;
                }else if(quoteLineItem.Include_In_Bundle__c){
                    value = 'Included';
                    column.textAlignment = 'right';
                }else {
                    value = String.valueOf(quoteLineItem.UnitPrice.format());
                    INR_Symbol = false;
                    column.textAlignment = 'right';
                }
                
            } else if (secTable.QuoteLineItem_Field__c == 'TotalPrice') {
                
                column.borderTop = '1px solid rgb(127,127,127)';
            	column.borderBottom = '1px solid rgb(127,127,127)';
                column.borderRight = '1px solid rgb(127,127,127)';
                
                
                if(quoteLineItem.Product2.Component_Type__c == 'Base Product'){
                    column.backgroundColor = lightShadeColor;
                    column.textAlignment = 'right';
                    value = baseProductPrice.get('baseProductTotalPrice');
                    INR_Symbol = false;
                }else if(quoteLineItem.Include_In_Bundle__c){
                    value = 'Included';
                    column.textAlignment = 'right';
                }else {
                    value = String.valueOf(quoteLineItem.TotalPrice.format());
                    INR_Symbol = false;
                    column.textAlignment = 'right';
                }
                
            } else if (secTable.Type__c == 'Serial Number') {
                column.borderLeft = '1px solid rgb(127,127,127)';
                column.borderRight = '1px solid rgb(127,127,127)';
                if(quoteLineItem.Product2.Component_Type__c == 'Base Product'){  
                    value = String.valueOf(serialNumber);
                   column.backgroundColor = lightShadeColor; 
                    column.borderTop = '1px solid rgb(127,127,127)';
                column.borderBottom = '1px solid  rgb(127,127,127)';
                }
            }
            
            column.columnType = secTable.Type__c;
            column.columnWidth = String.valueOf(secTable.Column_width__c) + '%';
            column.headerLabel = value;
            column.isRupeeSymbol = INR_Symbol;
            columns.add(Integer.valueOf(secTable.Column_Display_Order__c), column);
        }
        
        return columns;
    }
    /**
    * @description getHeaderColumnValuesOfTableSection: This method return the invoice table header
    */ 
    private static List<HeaderWrapper> getHeaderColumnValuesOfTableSection(List<Section_Table__c> sectionTables, String darkShadeColor) {
        
        List<HeaderWrapper> columns = new List<HeaderWrapper>(6);        
        Integer columnCounter = 0;
        for (Section_Table__c secTable : sectionTables) {
			columnCounter = columnCounter + 1;            
            HeaderWrapper column = new HeaderWrapper();
            column.columnType = secTable.Type__c;
            column.columnWidth = String.valueOf(secTable.Column_width__c) + '%';
            column.headerLabel = secTable.Header_Label__c;
            column.backgroundColor = darkShadeColor;
            column.color = 'white';
            column.fontSize = '13px';
            column.borderTop = '1px solid rgb(127,127,127)';
            column.borderBottom = '1px solid rgb(127,127,127)';
            if(columnCounter == 1){
            	column.borderLeft = '1px solid rgb(127,127,127)';
            }
            if(columnCounter == sectionTables.size()){
                column.borderRight = '1px solid rgb(127,127,127)';
            }
            if(secTable.Header_Label__c == 'Product Name'){
               column.textAlignment = 'left'; 
            }
            columns.add(Integer.valueOf(secTable.Column_Display_Order__c), column);
        }
        return columns;
    }
    /**
    * @description getHeaderSubTotalColumnValuesOfTableSection: This method return the subtotal row for invoice table 
    */
    private static List<HeaderWrapper> getHeaderSubTotalColumnValuesOfTableSection(List<Section_Table__c> sectionTables, Map<String, String> baseProductPrice, String rowLabel, boolean bottomBorder, Decimal totalColumnValue, Decimal baseProductQuantity) {
        
        List<HeaderWrapper> columns = new List<HeaderWrapper>(6);        
        
        for (Section_Table__c secTable : sectionTables) {
            
            String value = '';
            Boolean INR_Symbol = False;
            HeaderWrapper column = new HeaderWrapper();
            
            if (secTable.QuoteLineItem_Field__c == 'Product2.Name') {
                value = rowLabel; 	
                column.borderTop = '1px solid rgb(127,127,127)';
            	column.borderBottom = '1px solid rgb(127,127,127)';
                column.borderLeft = '1px solid rgb(127,127,127)';
                column.textAlignment = 'right';
            } else if (secTable.QuoteLineItem_Field__c == 'Product2.Commodity_code__c') {
                column.borderTop = '1px solid rgb(127,127,127)';
            	column.borderBottom = '1px solid rgb(127,127,127)';
            } else if (secTable.QuoteLineItem_Field__c == 'Quantity') {
                column.textAlignment = 'center';
                if(baseProductQuantity == null){
                   value = '';
                }else{
                   value = String.valueOf(baseProductQuantity.format()); 
                }
                
                column.borderTop = '1px solid rgb(127,127,127)';
            	column.borderBottom = '1px solid rgb(127,127,127)';
            } else if (secTable.QuoteLineItem_Field__c == 'UnitPrice') {
                value = '';
                INR_Symbol = false;
                column.borderTop = '1px solid rgb(127,127,127)';
            	column.borderBottom = '1px solid rgb(127,127,127)';
                column.textAlignment = 'right';
            } else if (secTable.QuoteLineItem_Field__c == 'TotalPrice' && secTable.Show_Subtotal__c) { 
                column.textAlignment = 'right';
                column.borderRight = '1px solid rgb(127,127,127)';
                column.borderTop = '1px solid rgb(127,127,127)';
            	column.borderBottom = '1px solid rgb(127,127,127)';
                INR_Symbol = false;
                if(totalColumnValue == null){
                    value = baseProductPrice.get('subTotalOfTotalPrice');
                }else {
                    value = String.valueOf(totalColumnValue.format());
                }
                
            } else if(secTable.Type__c == 'Serial Number'){
                column.borderleft = '1px solid rgb(127,127,127)';
                column.borderRight = '1px solid rgb(127,127,127)';
                if(bottomBorder){
                	column.borderBottom = '1px solid rgb(127,127,127)';
                }
            }
            
            
            column.columnType = secTable.Type__c;
            column.columnWidth = String.valueOf(secTable.Column_width__c) + '%';
            column.headerLabel = value;
            column.isRupeeSymbol = INR_Symbol;
            
            
            columns.add(Integer.valueOf(secTable.Column_Display_Order__c), column);
        }
        return columns;
    }
    /**
    * @description getInvoiceTableQuoteLineItem: This method return the QuoteLineItem Records from fields associate with section table
    */
    public static List<QuoteLineItem> getInvoiceTableQuoteLineItem(String queryFields, String ObjectName, Id quoteId, String quoteLineItemFilter){
       // queryFields = queryFields.removeEnd(',');
      
        String query = 'SELECT id  , Quantity ,product2.Name ,LineNumber ,TotalPrice, UnitPrice ,Sequence_Number__c,Invoice_Table_Order__c,Total_Approved_Customer_Discount__c,Include_In_Bundle__c ,product2.Component_Type__c FROM ' + ObjectName + ' WHERE QuoteId =: quoteId'; 
        system.debug(Query);
        return Database.query(query);
    }
 
    /**
    * @description getrelationshipfields: This method return the relationship fields of given object 
    */
    public static string getrelationshipfields(String fieldText){
        string updatedBody = fieldText;
        Pattern p = Pattern.compile('\\{(.*?)[a-zA-Z]+(\\.[a-zA-Z]+)*\\}');
        Matcher summaryQueryMatcher = p.matcher(fieldText);
       
        while(summaryQueryMatcher.find()) {
             if(!summaryQueryMatcher.group().contains('Quote.Owner.')){
            String objectName = summaryQueryMatcher.group().substringAfter('.');
            if (objectName.endsWith('}')) {
                objectName = objectName.substring(0, objectName.length() - 1);
                if(objectName.contains('.')) {
                    String[] relatedObjectFields = objectName.split('\\.');
                    boolean validated=false;
                    string currentobject='Quote';
                    for(Integer i = 0; i < relatedObjectFields.size(); i++) {
                        if(i < relatedObjectFields.size()-1){
                            string relatedObjectField = relatedObjectFields[i];
                            if(!relatedObjectFields[i].contains('__r')){
                                relatedObjectField += 'Id';
                            }
                            else{
                                relatedObjectField = relatedObjectFields[i].replace('__r','__c');
                            }
                            if(sobjecttomfields.containskey(currentobject)){
                                if(sobjecttomfields.get(currentobject).containskey(relatedObjectField)){
                                    List<Schema.sObjectType> objectdetails = sobjecttomfields.get(currentobject).get(relatedObjectField).getdescribe().getReferenceTo();
                                    if(!objectdetails.isempty()){
                                        currentobject=objectdetails[0].getDescribe().getName();
                                        if(!sobjecttomfields.containskey(currentobject)){
                                            sobjecttomfields.put(currentobject,objectdetails[0].getDescribe().fields.getMap()); 
                                        }
                                    }
                                }
                                else{
                                    validated=false;
                                    break;
                                }
                            }
                            else{
                                validated=false;
                                break;
                            }
                        }
                        else{
                            if(sobjecttomfields.containskey(currentobject)){
                                if(sobjecttomfields.get(currentobject).containskey(relatedObjectFields[i])){
                                    validated=true;
                                    currentobject='Quote';
                                }
                                else{
                                    validated=false;
                                    currentobject='Quote';
                                }
                            }
                            else{
                                validated=false;
                                currentobject='Quote';
                            }
                        }
                    }
                    if(validated){
                        relationshipfields.add(objectName);
                    }
                }
            }
        }
        } // while ends here
        return updatedBody;
    }
    
        /**
    * @description getrelationshipfieldsUser: This method return the relationship fields of related owner
    */
    public static string getrelationshipfieldsUser(String fieldText){
        string updatedBody = fieldText;
        Pattern p = Pattern.compile('\\{(.*?)[a-zA-Z]+(\\.[a-zA-Z]+)*\\}');
        Matcher summaryQueryMatcher = p.matcher(fieldText);
        while(summaryQueryMatcher.find()) {
            if(summaryQueryMatcher.group().contains('Quote.Owner.')){
            String objectName = summaryQueryMatcher.group().replace('{!Quote.Owner.','');
            if (objectName.endsWith('}')) {
                objectName = objectName.substring(0, objectName.length() - 1);
                if(objectName.contains('.')) {
                    String[] relatedObjectFields = objectName.split('\\.');
                    boolean validated=false;
                    string currentobject='User';
                    for(Integer i = 0; i < relatedObjectFields.size(); i++) {
                        if(i < relatedObjectFields.size()-1){
                            string relatedObjectField = relatedObjectFields[i];
                            if(!relatedObjectFields[i].contains('__r')){
                                relatedObjectField += 'Id';
                            }
                            else{
                                relatedObjectField = relatedObjectFields[i].replace('__r','__c');
                            }
                            if(sobjecttomfieldsUser.containskey(currentobject)){
                                if(sobjecttomfieldsUser.get(currentobject).containskey(relatedObjectField)){
                                    List<Schema.sObjectType> objectdetails = sobjecttomfieldsUser.get(currentobject).get(relatedObjectField).getdescribe().getReferenceTo();
                                    if(!objectdetails.isempty()){
                                        currentobject=objectdetails[0].getDescribe().getName();
                                        if(!sobjecttomfieldsUser.containskey(currentobject)){
                                            sobjecttomfieldsUser.put(currentobject,objectdetails[0].getDescribe().fields.getMap()); 
                                        }
                                    }
                                }
                                else{
                                    validated=false;
                                    break;
                                }
                            }
                            else{
                                validated=false;
                                break;
                            }
                        }
                        else{
                            if(sobjecttomfieldsUser.containskey(currentobject)){
                                if(sobjecttomfieldsUser.get(currentobject).containskey(relatedObjectFields[i])){
                                    validated=true;
                                    currentobject='User';
                                }
                                else{
                                    validated=false;
                                    currentobject='User';
                                }
                            }
                            else{
                                validated=false;
                                currentobject='User';
                            }
                        }
                    }
                    if(validated){
                        relationshipfieldsUser.add(objectName);
                    }
                }
            }
        }
        } // while ends here
        
        return updatedBody;
    }
    
    
   /**
    * @description replaceUserPlaceholdersWithOwnerValue: This method return owner field value populate as a place holder
    */ 
    public static string replaceUserPlaceholdersWithOwnerValue(String fieldText, User usList){
      string updatedBody = fieldText;
        Pattern p = Pattern.compile('\\{(.*?)[a-zA-Z]+(\\.[a-zA-Z]+)*\\}');
        Matcher summaryQueryMatcher = p.matcher(fieldText);
        while(summaryQueryMatcher.find()) {
            //new code
            if(summaryQueryMatcher.group().contains('Quote.Owner.')){
                String objectName = summaryQueryMatcher.group().replace('{!Quote.Owner.','');
            if (objectName.endsWith('}')) {
                objectName = objectName.substring(0, objectName.length() - 1);
                if(objectName.contains('.') && relationshipfieldsUser.contains(objectName)) {
                    String[] relatedObjectFields = objectName.split('\\.');
                    String objectNameValue;
                    SObject obj = usList;
                    string currentobject='User';
                    for(Integer i = 0; i < relatedObjectFields.size(); i++)
                    { 
                        if(i == relatedObjectFields.size() - 1) {
                            if(sobjecttomfieldsUser.get(currentobject).containskey(relatedObjectFields[i].tolowercase().replace('__r','__c'))){/// to be updated
                                DisplayType dt =sobjecttomfieldsUser.get(currentobject).get(relatedObjectFields[i].tolowercase().replace('__r','__c')).getDescribe().getType();//to be updated
                                if(dt==Schema.DisplayType.Date && obj.get(relatedObjectFields[i])!=null){
                                    date datefieldvalue=(Date)obj.get(relatedObjectFields[i]);
                                    objectNameValue=DateTime.newInstance(datefieldvalue.year(),datefieldvalue.month(),datefieldvalue.day()).format('MMMM dd, yyyy');
                                }
                                else if((dt ==Schema.DisplayType.Double || dt ==Schema.DisplayType.Currency ) && obj.get(relatedObjectFields[i])!=null){
                                    objectNameValue=((decimal)obj.get(relatedObjectFields[i])).format();
                                }
                                else{
                                    objectNameValue = (String)obj.get(relatedObjectFields[i]);
                                }
                            }
                        }
                        else {
                            string relatedObjectField = relatedObjectFields[i];
                            if(!relatedObjectFields[i].contains('__r')){
                                relatedObjectField += 'Id';
                            }
                            else{
                                relatedObjectField = relatedObjectFields[i].replace('__r','__c');
                            }
                            currentobject = sobjecttomfieldsUser.get(currentobject).get(relatedObjectField).getdescribe().getReferenceTo()[0].getDescribe().getName();
                            if(obj.getSobject(relatedObjectFields[i])!=null){
                                obj = obj.getSobject(relatedObjectFields[i]);
                            }
                            else{
                                break;
                            }
                        }
                    }
                    if(objectNameValue != null && summaryQueryMatcher.group()!= null){
                        updatedBody = updatedBody.replace(summaryQueryMatcher.group(), objectNameValue);
                    }
                    else if(objectNameValue == null && summaryQueryMatcher.group()!= null){
                        updatedBody = updatedBody.replace(summaryQueryMatcher.group(), '');
                    }
                }
                else
                {
                    String objectNameValue = '';
                    SObject obj = usList;
                    if(ufields.containskey(objectName.tolowercase())){
                        DisplayType dt =ufields.get(objectName.tolowercase()).getDescribe().getType();
                        if(dt==Schema.DisplayType.Date && obj.get(objectName)!=null){
                            date datefieldvalue=(Date)obj.get(objectName);
                            objectNameValue=DateTime.newInstance(datefieldvalue.year(),datefieldvalue.month(),datefieldvalue.day()).format('MMMM dd, yyyy');
                            
                        }
                        else if((dt ==Schema.DisplayType.Double || dt ==Schema.DisplayType.Currency) && obj.get(objectName)!=null){
                            objectNameValue=((decimal)obj.get(objectName)).format();
                        }
                        else{
                            objectNameValue = (String)obj.get(objectName);
                        }
                    }
                    if(objectNameValue != null && summaryQueryMatcher.group()!= null){
                        updatedBody = updatedBody.replace(summaryQueryMatcher.group(), objectNameValue);
                    }
                    else if(objectNameValue == null && summaryQueryMatcher.group()!= null){
                        updatedBody = updatedBody.replace(summaryQueryMatcher.group(), '');
                    }
                }
            }
            }
        } // while ends here
        return updatedBody;
    }
    
    /**
    * @description replacePlaceholdersWithValue: This method return field value populate as a place holder
    */
    public static string replacePlaceholdersWithValue(String fieldText, Quote qtList){
        string updatedBody = fieldText;
        Pattern p = Pattern.compile('\\{(.*?)[a-zA-Z]+(\\.[a-zA-Z]+)*\\}');
        Matcher summaryQueryMatcher = p.matcher(fieldText);
        while(summaryQueryMatcher.find()) {
            //new code
            String objectName = summaryQueryMatcher.group().substringAfter('.');
            if(!summaryQueryMatcher.group().contains('Quote.Owner.')){
            if (objectName.endsWith('}')) {
                objectName = objectName.substring(0, objectName.length() - 1);
                if(objectName.contains('.') && relationshipfields.contains(objectName)) {
                    String[] relatedObjectFields = objectName.split('\\.');
                    String objectNameValue;
                    SObject obj = qtList;
                    string currentobject='Quote';
                    for(Integer i = 0; i < relatedObjectFields.size(); i++)
                    { 
                        if(i == relatedObjectFields.size() - 1) {
                            if(sobjecttomfields.get(currentobject).containskey(relatedObjectFields[i].tolowercase().replace('__r','__c'))){/// to be updated
                                DisplayType dt =sobjecttomfields.get(currentobject).get(relatedObjectFields[i].tolowercase().replace('__r','__c')).getDescribe().getType();//to be updated
                                if(dt==Schema.DisplayType.Date && obj.get(relatedObjectFields[i])!=null){
                                    date datefieldvalue=(Date)obj.get(relatedObjectFields[i]);
                                    objectNameValue=DateTime.newInstance(datefieldvalue.year(),datefieldvalue.month(),datefieldvalue.day()).format('MMMM dd, yyyy');
                                }
                                else if((dt ==Schema.DisplayType.Double || dt ==Schema.DisplayType.Currency ) && obj.get(relatedObjectFields[i])!=null){
                                    objectNameValue=((decimal)obj.get(relatedObjectFields[i])).format();
                                }
                                else{
                                    objectNameValue = (String)obj.get(relatedObjectFields[i]);
                                }
                            }
                        }
                        else {
                            string relatedObjectField = relatedObjectFields[i];
                            if(!relatedObjectFields[i].contains('__r')){
                                relatedObjectField += 'Id';
                            }
                            else{
                                relatedObjectField = relatedObjectFields[i].replace('__r','__c');
                            }
                            currentobject = sobjecttomfields.get(currentobject).get(relatedObjectField).getdescribe().getReferenceTo()[0].getDescribe().getName();
                            if(obj.getSobject(relatedObjectFields[i])!=null){
                                obj = obj.getSobject(relatedObjectFields[i]);
                            }
                            else{
                                break;
                            }
                        }
                    }
                    if(objectNameValue != null && summaryQueryMatcher.group()!= null){
                        updatedBody = updatedBody.replace(summaryQueryMatcher.group(), objectNameValue);
                    }
                    else if(objectNameValue == null && summaryQueryMatcher.group()!= null){
                        updatedBody = updatedBody.replace(summaryQueryMatcher.group(), '');
                    }
                }
                else
                {
                    String objectNameValue = '';
                    SObject obj = qtList;
                    if(mfields.containskey(objectName.tolowercase())){
                        DisplayType dt =mfields.get(objectName.tolowercase()).getDescribe().getType();
                        if(dt==Schema.DisplayType.Date && obj.get(objectName)!=null){
                            date datefieldvalue=(Date)obj.get(objectName);
                            objectNameValue=DateTime.newInstance(datefieldvalue.year(),datefieldvalue.month(),datefieldvalue.day()).format('MMMM dd, yyyy');
                            
                        }
                        else if((dt ==Schema.DisplayType.Double || dt ==Schema.DisplayType.Currency) && obj.get(objectName)!=null){
                            objectNameValue=((decimal)obj.get(objectName)).format();
                        }
                        else{
                            objectNameValue = (String)obj.get(objectName);
                        }
                    }
                    if(objectNameValue != null && summaryQueryMatcher.group()!= null){
                        updatedBody = updatedBody.replace(summaryQueryMatcher.group(), objectNameValue);
                    }
                    else if(objectNameValue == null && summaryQueryMatcher.group()!= null){
                        updatedBody = updatedBody.replace(summaryQueryMatcher.group(), '');
                    }
                }
            }
            }
        } // while ends here
        return updatedBody;
    }
    /**
    * @description eachSectionContentWrapper: This wrapper class is used to display content on UI 
    */
    public class eachSectionContentWrapper implements Comparable {
        
        public string content {get; set;}
        public Decimal displayOrder {get; set;}
        public boolean isShow {get; set;}
        public String sectionAlignment {get; set;}
        public ImageData imagesData {get; set;}
        public ImageWithTextData imageWithText {get; set;}
        public ImageWithQRCode imageWithQRCodeData {get; set;}
        public String SectionType {get; set;}
        public String PageBreak {get; set;}
        public String annexureValue {get; set;}
        public String contentLineSpacing {get; set;}
        public String psRowSpacing {get; set;}
        public EachRowWrapper[] eachRowWrapData {get; set;}
        public HeaderWrapper[] invoiceTableHeaderData {get; set;}
        public String subtotal {get; set;}
        public List<List<HeaderWrapper>> invoiceTableData {get; set;}
        public boolean show_SI_For_Ps {get; set;}
        public Integer compareTo(Object objToCompare) {
            return Integer.valueOf(displayOrder - ((eachSectionContentWrapper)objToCompare).displayOrder);
        }
        
        
    }
    /**
    * @description ImageData: This wrapper class is used for creating image data 
    */
    public Class ImageData{
        public string imageName {get; set;}
        public String imageURL {get; set;}
        public Decimal imageWidth {get; set;}
        public Decimal imageHeight {get; set;}
    }
    /**
    * @description ImageWithTextData: This wrapper class is used for creating image data with text
    */
    public Class ImageWithTextData{
        public string imageName {get; set;}
        public String imageURL {get; set;}
        public String imageContent {get; set;}
        public Decimal imageWidth {get; set;}
        public Decimal imageHeight {get; set;} 
    }
    /**
    * @description ImageWithQRCode: This wrapper class is used for creating image data with QR Code
    */
    public Class ImageWithQRCode{
        public string normalImageName {get; set;}
        public String normalImageURL {get; set;}
        public Decimal normalImageWidth {get; set;}
        public Decimal normalImageHeight {get; set;}
        public string qrCodeImageName {get; set;}
        public String qrCodeImageURL {get; set;}
        public String qrCodeImageText {get; set;}
    }
    /**
    * @description EachRowWrapper: This wrapper class is used for creating Product Specification Records
    */
    public Class EachRowWrapper{
        public string sectionName {get; set;}
        public id productId {get; set;}
        public SectionBasedData[] rowData {get; set;}
    }
    /**
    * @description SectionBasedData: This wrapper class is used for creating the row data of Product Specification 
    */
    public Class SectionBasedData {
        public string drive {get; set;}
        public string measurement {get; set;}
        public string battery {get; set;}
        public Decimal sequence {get; set;}
        public boolean isBold {get; set;}
    }
    /**
    * @description HeaderWrapper: This wrapper class is used for creating invoice table data
    */
    public Class HeaderWrapper {
        public String headerLabel {get; set;}
        public String columnWidth {get; set;}
        public String fontSize {get; set;}
        public String columnType {get; set;}
        public String backgroundColor {get; set;}
        public String color {get; set;}
        public String textAlignment {get; set;}
        public String paddingleft {get; set;}
        public String borderLeft {get;set;}
        public String borderTop {get;set;}
        public String borderRight {get;set;}
        public String borderBottom {get;set;}
        public Boolean isRupeeSymbol {get; set;}
    }

    
    
}