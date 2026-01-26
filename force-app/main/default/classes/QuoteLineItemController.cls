public class QuoteLineItemController {
    
    private static final String CLASS_NAME = QuoteLineItemController.class.getName();
    private static final String VALID_CHECK_MESSGAE='';
    static QuoteLineItemHelper QLIHelper= new QuoteLineItemHelper();

    @AuraEnabled public static List<String> getServiceTypes() {
        return QLIHelper.GetServiceTypes();
    }
    @AuraEnabled public static List<String> GetServiceTypeForSupplier(String supplierId) {
        return QLIHelper.GetServiceTypeForSupplier(supplierId);
    }
    
    @AuraEnabled public static List<String> getLocations(String selectedServiceType) {
        return QLIHelper.GetLocations(selectedServiceType);
    }
    @AuraEnabled public static List<String> GetLocationForSupplier(String supplierIdorCode,String mode) {
        return QLIHelper.GetLocationForSupplier(supplierIdorCode,mode);
    }
    @AuraEnabled public static List<String> getServiceDetails(String selectedSupplierName,String selectedServiceType,String selectedLocation) {
        return QLIHelper.GetServiceDetails(selectedSupplierName,selectedServiceType,selectedLocation);
    }

    @AuraEnabled public static List<ServiceLinePassengerWrapper> GetQuotationPassengers(String quotationId) {
        List<ServiceLinePassengerWrapper> result=new List<ServiceLinePassengerWrapper>();
        
        List<Passenger__c> passengers=QLIHelper.GetQuotationPassengers(quotationId);
        for(Passenger__c p:passengers)
        {
            ServiceLinePassengerWrapper w = new ServiceLinePassengerWrapper();
            w.Passenger = p;
            //w.IsSelected = false;
            //Updated as per trello ticket "Ticking the passengers"
            w.IsSelected = true;
            result.add(w);
        }
        return result;
    }

    @AuraEnabled public static List<Quote> GetQuoteById(String quoteId) {
        return DAL_Quote.getAllQuoteById(quoteId);
    }
    
    @AuraEnabled
    public static OPT__c GetOptIdsForServiceLineItem(String selectedServiceType, String selectedLocation, 
                                                     String selectedSupplierName,String selectedServiceDetailbeforeSplit,
                                                     String selectedServiceCommentsAfterSplit)
    {
        return DAL_OPT.GetOptIdsForServiceLineItem(selectedServiceType, selectedLocation, 
                                                   selectedSupplierName,selectedServiceDetailbeforeSplit,
                                                   selectedServiceCommentsAfterSplit);
        
    }

    @AuraEnabled
    public static Map<String,String> getCrmCategoryByCrmCode(String crmCode){
        
        Map<String, Map<String,String>> uniqueRecords = getCrmCategoryMapByCrmCodes(new Set<String>{crmCode});
        if(uniqueRecords.containsKey(crmCode)){
            return uniqueRecords.get(crmCode);
        }
        return new Map<String,String>();

    }

    @AuraEnabled
    public static Map<String,String> getSupplierServiceNotes(String crmCode, String optCode){
        Map<String,String> uniqueRecord = new  Map<String,String>();
        List<NTS__c> ntsOptList = [SELECT
                                    Id,
                                    CATEGORY__c,
                                    MESSAGE_TEXT__c,
                                    CRM_Lookup__c,
                                    CRM_Lookup__r.CODE__c,
                                    OPT_Lookup__c,
                                    OPT_Lookup__r.ExternalId__c
                                    FROM 
                                    NTS__c
                                    WHERE
                                    (OPT_Lookup__r.ExternalId__c = :optCode AND (CATEGORY__c = 'OPI' OR CATEGORY__c = 'OPX' OR CATEGORY__c = 'OIN'))
                                    OR 
                                    (CRM_Lookup__r.CODE__c = :crmCode AND CATEGORY__c = 'SIN')];
         for(NTS__c nts: ntsOptList)
        {
            if(!uniqueRecord.containsKey(nts.CATEGORY__c) 
               && !(uniqueRecord.get(nts.CATEGORY__c) == nts.CATEGORY__c))
            {
                uniqueRecord.put(nts.CATEGORY__c,nts.MESSAGE_TEXT__c);
            }
        }

        return uniqueRecord;

    }

    public static Map<String, Map<String,String>> getCrmCategoryMapByCrmCodes(Set<String> crmCode){
        Map<String,String> uniqueRecord = new  Map<String,String>();
        Map<String, Map<String,String>> uniqueRecords = null;
        List<CRM__c> crms = [SELECT 
                             Id,
                             CODE__c 
                             FROM 
                             CRM__c
                             WHERE 
                             CODE__c IN:crmCode];
        List<Id> crmsIds  = new List<Id>();
        for(CRM__c c:crms)
        {
            crmsIds.add(c.Id);
        }
        
        if(crms != null)
        {
            List<NTS__c> ntsList = [SELECT
                                    Id,
                                    CATEGORY__c,
                                    MESSAGE_TEXT__c,
                                    CRM_Lookup__c,
                                    CRM_Lookup__r.CODE__c
                                    FROM 
                                    NTS__c
                                    WHERE
                                    CRM_Lookup__c IN:crmsIds 
                                    AND
                                    (CATEGORY__c = 'OPI' 
                                     OR 
                                     CATEGORY__c = 'OPX')];
            uniqueRecord = new Map<String,String>();
            uniqueRecords = new  Map<String, Map<String,String>>();
            for(NTS__c nts: ntsList)
            {
                if(!uniqueRecord.containsKey(nts.CATEGORY__c) 
                   && !(uniqueRecord.get(nts.CATEGORY__c) == nts.CATEGORY__c))
                {
                    uniqueRecord.put(nts.CATEGORY__c,nts.MESSAGE_TEXT__c);
                    uniqueRecords.put(nts.CRM_Lookup__r.CODE__c,uniqueRecord);
                }
            }
        }
        return uniqueRecords;
    }

    @AuraEnabled
    public static OPT__c GetOptByExternalId(String externalId){
        return DAL_OPT.getOptByExternalId(externalId);
    }

    @AuraEnabled public static List<String> getServiceStatus() {
        return QLIHelper.GetServiceStatus();
    }

    @AuraEnabled public static List<String> getTicketClassOptions() {
        return QLIHelper.GetTicketClassOptions();
    }

    @AuraEnabled
    public static Map<String,String> getExtraFieldMap(String sourceObject, String targetObject){
        Map<String,String> targetFieldName = new Map<String,String>();
       
        List<Field_Mapping_For_Rate_Calculation__mdt>
                             stayMappings = [SELECT 
                                                    Target_Object__c, 
                                                    Target_Field__c,
                                                    Source_Field__c,
                                                    Source_Object__c
                                            FROM
                                                     Field_Mapping_For_Rate_Calculation__mdt 
                                           WHERE 
                                                    Source_Object__c =:sourceObject
                                               AND 
                                                    Target_Object__c=:targetObject Order By Target_Field__c];
        
        for(Field_Mapping_For_Rate_Calculation__mdt mapping:stayMappings)
        {
            targetFieldName.put(mapping.Target_Field__c, mapping.Source_Field__c);
        }
        
        return targetFieldName;
    }

    @AuraEnabled public static List<String> GetRoomConfiguration(String supplierIdorCode,String mode) {
        return QLIHelper.GetRoomConfiguration(supplierIdorCode,mode);
    }

    @AuraEnabled
    public static SOD__c getSODById(String id){
        List<SOD__c> sodWithPolicyTypes = DAL_SOD.getSODSPolicyType(new Set<Id>{id}).values();
        if(sodWithPolicyTypes.size()>0){
            return sodWithPolicyTypes[0];
        }
        return null;
        
    }

    @AuraEnabled
    public static List<String> saveQuoteLineItem(String serviceLineItemName,String selectedServiceType,
                                                   String selectedLocation,String selectedSupplierName, 
                                                   String selectedSupplierId, String selectedServiceDetail, String selectedServiceDetailDisplayName,
                                                   String quoteLineItemId, String serviceClientNotes, 
                                                   String serviceReservationNumber,
                                                   String serviceSelectServiceStatus, String serviceExpiryDate, 
                                                   Boolean overrideDetails, Boolean overridenSupplierPolicy, String[] selectedPassengers,
                                                   String serviceDate, String numberOfDays,String displayDuration,String quoteId, 
                                                   QuoteLineItemConfigurationWrapper[] roomConfigurations,
                                                   logisticsWrapper logistics,
                                                   FlightWrapper flightDetail,
                                                   ServiceLineChargeTypeWrapper[] oldChargeTypes,
                                                  Boolean keepRatesOnDateChange, String selectedOPT,
                                                  String[] addOns, String serviceInclusionNote, String serviceExclusionNote,  
                                                  String supplierDescription, String serviceDescription) 
    {
        
        System.debug('Inside saveServiceLineItem: oldChargeTypes: '+oldChargeTypes);

        System.debug('QuoteLineItemConfigurationWrapper:::'+roomConfigurations);

        System.debug('addOns:::'+addOns);

        List<String> ErrorMessageList = new List<String>();
        UTIL_LogGenerator logger = new UTIL_LogGenerator();

        if(quoteLineItemId != null){
            List<String> errorList = deleteExistingQuoteLineItems(quoteLineItemId);
            ErrorMessageList.addAll(errorList);
        }

        
       
        //logger.start(CLASS_NAME,'saveServiceLineItem');
        System.debug('serviceDate'+serviceDate);
        String errorMessage ='';
        OPT__c  optId = null;
        List<Passenger__c>  allPassengers =  new List<Passenger__c>();
        try
        {
            System.debug('selectedPassengers'+selectedPassengers);
            allPassengers  = DAL_Passenger.getByIds(new List<String>(selectedPassengers));
            System.debug('allPassengers'+allPassengers);
            List<Passenger__c> adultPassengers = new List<Passenger__c>();
            List<Passenger__c> notAdultPassengers = new List<Passenger__c>();
            for(Passenger__c p:allPassengers)
            {
                if('Adult' == p.PassengerType__c)
                {
                    adultPassengers.add(p);
                }
                if('Child' == p.PassengerType__c ||
                   'Infant' == p.PassengerType__c)
                {
                    notAdultPassengers.add(p);
                }
                if(String.isEmpty(p.PassengerType__c))
                {
                    ErrorMessageList.add(system.label.Passenger_Type_Not_Defined + p.PassengerName__c); 
                    return ErrorMessageList;
                }
                
            }
            
            String selectedServiceDetailbeforeSplit = null;
            String selectedServiceCommentsAfterSplit= null;
            if(selectedServiceDetail.contains('||'))
            {
                selectedServiceDetailbeforeSplit  = selectedServiceDetail.substringBefore('||').trim();
                selectedServiceCommentsAfterSplit = selectedServiceDetail.substringAfter('||').trim();
            }
            else
            {
                selectedServiceDetailbeforeSplit = selectedServiceDetail;
            }
            
            optId  = DAL_OPT.getOptByExternalId(selectedOPT);
            system.debug('@@ optId : '+optId);
            if(optId== null)
            {
                errorMessage = system.label.OPT_Not_Available;
            }
            
            if(!overrideDetails)
            {
                System.debug('Info'+'AllPassengers sorted');
                //bypass validation if override details is true
                string hour = '00';
                string minute = '00';
                string second = '00';
                
                
                String serviceDate1 = serviceDate.substringBefore('-')+'-'+serviceDate.substringAfterLast('-')+'-'+serviceDate.substringBetween('-','-');
                Date startdate = date.valueOf(serviceDate  + ' ' + hour + ':' + minute + ':' + second);
                System.debug('Info'+serviceDate);
                System.debug('Info'+serviceDate1);
                if(String.isBlank(errorMessage))
                {  
                    // if(numberOfDays== null)
                    // {
                    //     numberOfDays ='0';
                    // }
                    // List<String> CriteriaToSODerrorMessage = validateTheCriteriaToSOD(startdate, Integer.valueof(numberOfDays) 
                    //                                                                  ,allPassengers, adultPassengers ,
                    //                                                                  notAdultPassengers,selectedServiceType,
                    //                                                                  optId,roomConfiguration);
                    // System.debug('Info','validateTheCriteriaToSOD End');
                    // if(CriteriaToSODerrorMessage.size() > 0)
                    // {
                    //     //ErrorMessageList.addAll(CriteriaToSODerrorMessage);
                        
                    //     //return ErrorMessageList;
                    //     overrideDetails=true;
                    // }
                }
                
                //createQuoteLineItemsIfMissing(startdate, Integer.valueof(numberOfDays), quoteId);
                
                // System.debug('Info','validateTheCriteriaToSOD witho Error');   
                // Boolean checkDurationIsValid = DbQueries.validateDurationIsValid(startdate,Integer.valueof(numberOfDays), 
                //                                                                  quoteId,selectedServiceType);
                
                // if(!checkDurationIsValid)
                // {
                //     //errorMessage = System.Label.Duration_Check;
                //     //ErrorMessageList.add(errorMessage);
                    
                //     //return ErrorMessageList;
                //     overrideDetails=true;
                // }
                // System.debug('errorMessage',errorMessage);
            }    
            
            if(String.isBlank(errorMessage))
            {
                System.debug('Info'+'Calling Save Method');
                Set<String> errorMessages =  QLIHelper.saveServiceLineItem(serviceLineItemName, selectedServiceType, 
                                                                           selectedLocation, selectedSupplierName, selectedSupplierId,
                                                                           selectedServiceDetail, selectedServiceDetailDisplayName, quoteLineItemId,
                                                                           serviceReservationNumber, 
                                                                           serviceSelectServiceStatus,serviceExpiryDate,
                                                                           overrideDetails, overridenSupplierPolicy, selectedPassengers,serviceDate,numberOfDays,displayDuration,
                                                                           quoteId,optId, roomConfigurations,
                                                                           logistics,
                                                                           flightDetail, oldChargeTypes,addOns,
                                                                           serviceInclusionNote,serviceExclusionNote,
                                                                           supplierDescription,serviceDescription);
                System.debug('@@errorMessages : '+errorMessages);
                ErrorMessageList.addAll(errorMessages);
                
            }
            if(overrideDetails==true){
                ErrorMessageList.add(System.Label.Service_Detail_Override_Message);
            }
            System.debug('ErrorMessageList'+ErrorMessageList);
            
        }
        catch(Exception e){
            System.debug('@@Exception :: '+e.getStackTraceString());
            ErrorMessageList.add(e.getMessage());
        }
        System.debug('@@ErrorMessageList : '+ErrorMessageList);
        return ErrorMessageList;
        
    }

    @AuraEnabled
    public static List<String> updateQuoteLineItem(String quoteLineItemId, logisticsWrapper logistics, FlightWrapper flightDetail,
                                                    String serviceInclusionNote, String serviceExclusionNote,  
                                                    String supplierDescription, String serviceDescription)
    {
        List<String> ErrorMessageList = new List<String>();
        try {
            ErrorMessageList = QLIHelper.updateServiceLineItem(quoteLineItemId, logistics, flightDetail, serviceInclusionNote, serviceExclusionNote, supplierDescription, serviceDescription);
        } catch (Exception e) {
            System.debug('@@Exception :: '+e.getStackTraceString());
            ErrorMessageList.add(e.getMessage());
        }
        return ErrorMessageList;
    }

    @AuraEnabled
    public static List<String> deleteExistingQuoteLineItems(String quoteLineItemId){
        List<String> ErrorMessageList = new List<String>();

        try{        
            List<Service_Line_Item_ChargeType__c> chargeTypes = new List<Service_Line_Item_ChargeType__c>();
            List<Quote_Line_Item_Configuration__c> quoteLineItemConfigs = new List<Quote_Line_Item_Configuration__c>();
            List<QuoteLineItemConfigPassengerMapping__c> qLineItemsPassengerMappings = new List<QuoteLineItemConfigPassengerMapping__c>();
            List<ServiceLineItemPassengersMapping__c> servicelineItemsPassengersMapping = new List<ServiceLineItemPassengersMapping__c>();

            List<QuoteLineItem> allQuoteLineItemsToBeDeleted = DAL_QuoteLineItem.getQuoteLineItemWithChildByParentReference(quoteLineItemId);
            Set<Id> qLineItemIds = new Set<Id>() ;
            for(QuoteLineItem qLineItem : allQuoteLineItemsToBeDeleted){
                if(!qLineItem.Quote_Line_Item_Configurations__r.isEmpty()){
                    quoteLineItemConfigs.addAll(qLineItem.Quote_Line_Item_Configurations__r);
                }
                if(!qLineItem.Service_Line_Item_ChargeTypes__r.isEmpty()){
                    chargeTypes.addAll(qLineItem.Service_Line_Item_ChargeTypes__r);
                }
                if(!qLineItem.ServiceLineItemPassengersMappings__r.isEmpty()){
                    servicelineItemsPassengersMapping.addAll(qLineItem.ServiceLineItemPassengersMappings__r);
                }
            }
            /*for(Service_Line_Item_ChargeType__c chargeType : [SELECT ID FROM Service_Line_Item_ChargeType__c WHERE Quote_Line_Item__r.QuoteId IN: quoteIds]){
                chargeTypes.add(chargeType) ;
            }*/
            Set<Id> qLIConfigIds = new Set<Id>();
            for(Quote_Line_Item_Configuration__c qlic : quoteLineItemConfigs){
                qLIConfigIds.add(qlic.Id);
            }
            qLineItemsPassengerMappings = DAL_QuoteLineItemConfigPassengerMapping.getByParentIds(qLIConfigIds);//[SELECT Id FROM QuoteLineItemConfigPassengerMapping__c WHERE Quote_Line_Item_Configuration__c IN: quoteLineItemConfigs] ;
            
            if(!chargeTypes.isEmpty()){
                delete chargeTypes;
            }
            if(!quoteLineItemConfigs.isEmpty()){
                delete quoteLineItemConfigs;
            }
            if(!servicelineItemsPassengersMapping.isEmpty()){
                delete servicelineItemsPassengersMapping;
            }
            if(!qLineItemsPassengerMappings.isEmpty()){
                delete qLineItemsPassengerMappings;
            }
            if(!allQuoteLineItemsToBeDeleted.isEmpty()){
                delete allQuoteLineItemsToBeDeleted;
            }
        }catch(Exception e){
            ErrorMessageList.add(e.getMessage());
        }
        return ErrorMessageList;
    }   

    @AuraEnabled
    public static CostMarkupMainWrapper getCostMarkups(String QuoteLineItemId){
       return QLIHelper.getCostMarkups(QuoteLineItemId);
    }

    @AuraEnabled
    public static QuoteLineItem getQuoteLineItemDetail(String quoteLineItemId){
        return QLIHelper.getQuoteLineItemDetail(quoteLineItemId);
    }

    @AuraEnabled
    public static CRM__c getSelectedSupplierByCode(String code){
        return QLIHelper.getSelectedSupplierByCode(code);
    }

    @AuraEnabled
    public static List<QuoteLineItemConfigurationWrapper> getQLIConfigurations(String quoteLineItemId){
        return QLIHelper.getQLIConfigurations(quoteLineItemId);
    }

    @AuraEnabled public static List<String> getTimeList() {
        List<String> options = new List<String>();
        
        for(Integer hour=0;hour<24;hour++)
        {
            String timeStr ='';
            if(hour <10)
            {
                timeStr ='0'+hour + ':';
            }
            else
            {
                timeStr =hour+':';
            }
            options.add(timeStr+'00');
            options.add(timeStr+'05');
            options.add(timeStr+ 10);
            options.add(timeStr+ 15);
            options.add(timeStr+ 20);
            options.add(timeStr+ 25);
            options.add(timeStr+ 30);
            options.add(timeStr+ 35);
            options.add(timeStr+ 40);
            options.add(timeStr+ 45);
            options.add(timeStr+ 50);
            options.add(timeStr+ 55);
        }
        return options;
    }

    @AuraEnabled
    public static string validateServiceByDay(String selectedOPT, String serviceType, String serviceDate, String duration){
        OPT__c opt = DAL_OPT.getOptByExternalId(selectedOPT);
        string hour = '00';
        string minute = '00';
        string second = '00';
        Date sDate = date.valueOf(serviceDate  + ' ' + hour + ':' + minute + ':' + second); 
        Integer serviceDuration = Integer.valueOf(duration);
        return QLIHelper.validateSerivceByDay(opt, serviceType, sDate, serviceDuration);   
    }

    @AuraEnabled
    public static Service_Type_Configuration__mdt getServiceTypeConfigurationByLabel(String serviceType){
        return QLIHelper.getServiceTypeConfigurationByLabel(serviceType);   
    }

    @AuraEnabled
    public static Day_Configurator__c getDayConfiguratorByDate(String serviceDate, String quoteId){
        serviceDate = serviceDate.replaceAll('-', '/');
        Date sDate = Date.parse(serviceDate);
        return DAL_Day_Configurator.getDayConfiguratorByDate(sDate,quoteId);

    }

    @AuraEnabled
    public static List<QuoteLineItem> getQuoteLineItemByParentRef(String parentQuoteLineItemId){
        return DAL_QuoteLineItem.getQuoteLineItemListByParent(parentQuoteLineItemId);
    }

    @AuraEnabled
    public static String getREEmailAddresses(String code){
        Set<String> addresses = DAL_CRM.getREEmailListByCRMCode(code);
        return String.join(addresses, ',');
    }

    /*
     serviceLineItemName, selectedServiceType, 
     selectedLocation, selectedSupplierName, selectedSupplierId,
                                                                           selectedServiceDetail, selectedServiceDetailDisplayName, quoteLineItemId,
                                                                           serviceReservationNumber, 
                                                                           serviceSelectServiceStatus,serviceExpiryDate,
                                                                           overrideDetails,selectedPassengers,serviceDate,numberOfDays,duration,
                                                                           quoteId,optId, roomConfigurations,
                                                                           logistics,
                                                                           flightDetail, oldChargeTypes,addOns,
                                                                           serviceInclusionNote,serviceExclusionNote,
                                                                           supplierDescription,serviceDescription                                                                      
    
    */
    @future
    @AuraEnabled
    public static void careteExtraServices(String quoteId){
        Quote quote = DAL_Quote.getAllQuote(new List<Id>{quoteId})[0];
        CRM__c safari365 = DAL_CRM.getByCode('SAF365')[0];
        CRM__c safari365USD = DAL_CRM.getByCode('SAF366')[0];
        List<Opt__c> safari365ServiceList = DAL_OPT.getByCRMCode('SAF365');
        List<Opt__c> safari365ServiceListUSD = DAL_OPT.getByCRMCode('SAF366');

        OPT__c charityService;
        OPT__c photobookService;
        List<PassengerQuotationMapping__c> allPassengers = DAL_Passenger.getAllPassengerQuotation(new List<Id>{quoteId});
        System.debug('Quote Currency:::'+quote.Currency__c);
        System.debug('Quote Photobook Currency:::'+quote.Opportunity.Photobook_Currency__c);
        /*for(OPT__c opt :safari365ServiceList){
            System.debug('OPT Code:::'+opt.Code__c);
            if(quote.Currency__c == 'ZAR' && opt.Code__c == 'CHARZA'){
                charityService = opt;
            }else if(quote.Currency__c == 'USD' && opt.Code__c == 'CHARI'){
                charityService = opt;
            }else if(quote.Opportunity.Photobook_Currency__c == 'USD' && opt.Code__c == 'PHOTOC'){
                photobookService = opt;
            }else if(quote.Opportunity.Photobook_Currency__c == 'ZAR' && opt.Code__c == 'PHOTZA'){
                photobookService = opt;
            }
        }*/

        //"Ubuntu For Change" Charity Initiative	
        if(quote.Currency__c == 'USD'){
            for(OPT__c opt :safari365ServiceListUSD){
                if(opt.Code__c == 'SACHAU'){
                    charityService = opt;
                }
            }
        }
        else if(quote.Currency__c == 'ZAR'){
            for(OPT__c opt :safari365ServiceList){
                if(opt.Code__c == 'SACHAR'){
                    charityService = opt;
                }
            }
        }

        //Complimentary Photobook(s)
        if(quote.Opportunity.Photobook_Currency__c == 'USD'){
            for(OPT__c opt :safari365ServiceListUSD){
                if(opt.Code__c == 'COPHOU'){
                    photobookService = opt;
                }
            }
        }
        else if(quote.Opportunity.Photobook_Currency__c == 'ZAR'){
            for(OPT__c opt :safari365ServiceList){
                if(opt.Code__c == 'COMPHO'){
                    photobookService = opt;
                }
            }
        }


        List<QuoteLineItemConfigurationWrapper> serviceConfigList = new List<QuoteLineItemConfigurationWrapper>();
        Integer count = 1;
        for(PassengerQuotationMapping__c pax :allPassengers){
            QuoteLineItemConfigurationWrapper qlicw = new QuoteLineItemConfigurationWrapper();
            qlicw.serviceType = 'Extra';
            qlicw.serviceSubtype = '';
            qlicw.adults = '0';
            qlicw.children = '0';
            qlicw.infants = '0';
            if(pax.Passenger__r.PassengerType__c == 'Adult')
                qlicw.adults = '1';
            else if(pax.Passenger__r.PassengerType__c == 'Child')
                qlicw.children = '1';
            else if(pax.Passenger__r.PassengerType__c == 'Infant')
                qlicw.infants = '1';
            qlicw.order = String.valueOf(count);
            count++;
            serviceConfigList.add(qlicw);

        }
        List<String> errorMessages =  new List<String>();
        List<String> addOns =  new List<String>();
        /* Service - "Ubuntu For Change" Charity Initiative */
        if(charityService != null){
           
            CRM__c crmRecord = quote.Currency__c == 'ZAR' ? safari365 : safari365USD;
            errorMessages = saveQuoteLineItem(crmRecord.Name__c, charityService.SRV_Name__c, charityService.LOC_Name__c, crmRecord.NAME__c,
            crmRecord.Id, charityService.Description__c, charityService.Description__c,
                                                            null,null,'N/A','No Booking Required', null,
                                                            false,false,null,String.valueOf(quote.TravelStartDate__c),'1','0',quote.Id,
                                                            serviceConfigList,null,null,null,false,charityService.ExternalId__c,
                                                            addOns,null,null,null,null);
        }

        /* Service - Complimentary Photobook(s) */
        if(photobookService != null){

            CRM__c crmRecord = quote.Opportunity.Photobook_Currency__c == 'ZAR' ? safari365 : safari365USD;
            errorMessages = saveQuoteLineItem(crmRecord.Name__c, photobookService.SRV_Name__c, photobookService.LOC_Name__c, crmRecord.NAME__c,
                                                            crmRecord.Id, photobookService.Description__c, photobookService.Description__c,
                                                            null,null,'N/A','No Booking Required', null,
                                                            false,false,null,String.valueOf(quote.TravelStartDate__c),'1','0',quote.Id,
                                                            serviceConfigList,null,null,null,false,photobookService.ExternalId__c,
                                                            addOns,null,null,null,null);
        }        
    }
    
    @AuraEnabled
    public static List<String> updateQuoteLineItemWithRateStatus(String quoteLineItemId, String rateStatus){

        List<String> errorMessageList = new List<String>();
        try{
            QuoteLineItem qli = new QuoteLineItem();
            qli.Id = quoteLineItemId;
            qli.Rate_Acceptance_Status__c = rateStatus;
            
            update qli;
    
            if(rateStatus == 'Accepted'){
                //
            }
            else if(rateStatus == 'Rejected'){
                //updating all service charge types with 0 rate
                List<Service_Line_Item_ChargeType__c> chargeTypes = DAL_ServiceLineItemChargeType.getChargeTypeListByQuoteLineItemId(quoteLineItemId);
                if(chargeTypes.size() > 0){
                    for(Service_Line_Item_ChargeType__c chargeType : chargeTypes){
                        chargeType.GP__c = 0;
                        chargeType.Nett_Cost__c =  0;
                        chargeType.Total__c = 0;
                        chargeType.Nett_Cost_CC__c = 0;
                        chargeType.Sale_CC__c = 0;
                    }
                    update chargeTypes;
                }
            }
        }catch(Exception e){
            errorMessageList.add(e.getMessage());
        }
        return errorMessageList;
    }

    @AuraEnabled
    public static List<String> updateLogistics(String quoteLineItemId, LogisticsWrapper logistics){
        List<String> errorMessageList = new List<String>();
        try {
            errorMessageList = QLIHelper.updateLogistics(quoteLineItemId, logistics);
        } catch (Exception e) {
            errorMessageList.add(e.getMessage());
        }
        return errorMessageList;
    }
}