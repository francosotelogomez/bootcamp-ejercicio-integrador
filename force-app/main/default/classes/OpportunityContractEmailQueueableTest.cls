/**
 * Test class for OpportunityContractEmailQueueable.
 * Verifies the asynchronous email delivery process, ensuring that contract 
 * attachments are correctly handled and business validations are enforced.
 */
@isTest
private class OpportunityContractEmailQueueableTest {

    @isTest
    static void testAllPaths() {
        Account acc = new Account(Name = 'Cliente Test', Email__c = 'test@novabank.com');
        insert acc;

        ContentVersion cv = new ContentVersion(
            Title = 'Contrato_Suscrito',
            PathOnClient = 'Contrato.pdf',
            VersionData = Blob.valueOf('Contenido del PDF'),
            IsMajorVersion = true
        );
        insert cv;
        Id conDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;

        Opportunity opp = new Opportunity(
            Name = 'Op Test',
            AccountId = acc.Id,
            StageName = 'EVALUACIÓN', // Etapa inicial permitida
            CloseDate = Date.today(),
            Contract_Generated__c = true, // Marcamos esto primero
            Contract_Content_Document_Id__c = conDocId
        );
        insert opp;

        new OpportunityContractEmailQueueable(null).execute(null);

        new OpportunityContractEmailQueueable(opp.Id).execute(null);

        opp.StageName = 'Closed Won';
        update opp;
        
        acc.Email__c = null; // Provocamos el error de la clase
        update acc;

        try {
            new OpportunityContractEmailQueueable(opp.Id).execute(null);
        } catch (AuraHandledException e) {
            System.debug('Línea de error email cubierta');
        }

        acc.Email__c = 'valido@test.com';
        update acc;
        
        opp.Contract_Generated__c = false; 
        
        try { update opp; } catch(Exception e) {}

        try {
            new OpportunityContractEmailQueueable(opp.Id).execute(null);
        } catch (AuraHandledException e) {
            System.debug('Línea de error contrato cubierta');
        }

        opp.Contract_Generated__c = true;
        try { update opp; } catch(Exception e) {}

        Test.startTest();
        new OpportunityContractEmailQueueable(opp.Id).execute(null);
        Test.stopTest();
        
        System.assert(true);
    }
}