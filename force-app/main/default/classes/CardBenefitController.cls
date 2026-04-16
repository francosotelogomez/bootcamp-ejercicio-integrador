public with sharing class CardBenefitController {
    /**
     * Obtiene la lista de beneficios de tarjeta ordenados por prioridad
     * y nombre de tarjeta.
     *
     * @return Lista de beneficios de tarjeta
     */
    @AuraEnabled(cacheable=true)
    public static List<Card_Benefit__c> getCardBenefits() {
        return [
            SELECT Id,
                   Name,
                   Card_Name__c,
                   Annual_Effective_Rate__c,
                   Miles_Accumulation__c,
                   Cashback_Percentage__c,
                   Priority__c,
                   Annual_Fee__c,
                   Product__c,
                   Product__r.Name
            FROM Card_Benefit__c
            ORDER BY Priority__c ASC, Card_Name__c ASC
        ];
    }
}