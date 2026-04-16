public with sharing class OpportunityContractController {
    private Opportunity opp;

    public OpportunityContractController(ApexPages.StandardController controller) {
        Id opportunityId = controller.getId();

        opp = [
            SELECT Id,
                   Name,
                   StageName,
                   AccountId,
                   Account.Name,
                   Approved_Amount__c,
                   Interest_Rate__c,
                   Payment_Day__c,
                   Financial_Product__c,
                   Financial_Product__r.Name
            FROM Opportunity
            WHERE Id = :opportunityId
            LIMIT 1
        ];
    }

    public String getAccountName() {
        return opp.Account != null ? opp.Account.Name : '';
    }

    public String getOpportunityName() {
        return opp.Name;
    }

    public String getProductName() {
        return opp.Financial_Product__r != null ? opp.Financial_Product__r.Name : '';
    }

    public String getApprovedAmountFormatted() {
        return opp.Approved_Amount__c != null ? 'S/ ' + String.valueOf(opp.Approved_Amount__c) : 'S/ 0';
    }

    public String getInterestRateFormatted() {
        return opp.Interest_Rate__c != null ? String.valueOf(opp.Interest_Rate__c) + '%' : '0%';
    }

    public String getPaymentDayFormatted() {
        return opp.Payment_Day__c != null ? String.valueOf(opp.Payment_Day__c) : '';
    }

    public String getGeneratedDateFormatted() {
        return Datetime.now().format('dd/MM/yyyy HH:mm');
    }
}