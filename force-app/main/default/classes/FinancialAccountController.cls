/**
 * Controller class for the Financial Account Manager Lightning Web Component.
 * Provides Aura-enabled methods for CRUD operations and product retrieval 
 * to support the bank's financial asset management interface.
 */
public with sharing class FinancialAccountController {

    @AuraEnabled(cacheable=true)
    public static List<Financial_Account__c> getFinancialAccounts(Id accountId) {
        if (accountId == null) return new List<Financial_Account__c>();

        return [
            SELECT Id, Name, Card_Type__c, Approved_Credit_Limit__c, 
                   Issue_Date__c, Card_Status__c, Last_4_Digits__c, 
                   Product__c, Product__r.Name, Cliente__c
            FROM Financial_Account__c
            WHERE Cliente__c = :accountId
            ORDER BY CreatedDate DESC
        ];
    }

    @AuraEnabled
    public static void createFinancialAccount(Financial_Account__c accountRecord) {
        validateFinancialAccount(accountRecord);
        insert accountRecord;
    }

    @AuraEnabled
    public static void updateFinancialAccount(Financial_Account__c accountRecord) {
        if (accountRecord.Id == null) {
            throw new AuraHandledException('El Id es obligatorio para actualizar.');
        }
        validateFinancialAccount(accountRecord);
        update accountRecord;
    }

    @AuraEnabled
    public static void deleteFinancialAccount(Id recordId) {
        delete [SELECT Id FROM Financial_Account__c WHERE Id = :recordId LIMIT 1];
    }

    @AuraEnabled(cacheable=true)
    public static List<Product2> getActiveProducts() {
        return [SELECT Id, Name FROM Product2 WHERE IsActive = true ORDER BY Name];
    }

    private static void validateFinancialAccount(Financial_Account__c r) {
        if (r.Cliente__c == null || String.isBlank(r.Card_Type__c) || 
            r.Approved_Credit_Limit__c == null || r.Product__c == null) {
            throw new AuraHandledException('Faltan campos obligatorios para procesar la cuenta.');
        }
    }
}