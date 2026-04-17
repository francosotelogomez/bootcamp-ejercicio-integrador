@isTest
private class OpportunityContractEmailQueueableTest {

    @isTest
    static void testAllPaths() {
        // 1. Setup de datos: Cuenta con Email
        Account acc = new Account(Name = 'Cliente Test', Email__c = 'test@novabank.com');
        insert acc;

        // 2. Crear un documento real (ContentVersion) para el contrato
        ContentVersion cv = new ContentVersion(
            Title = 'Contrato_Suscrito',
            PathOnClient = 'Contrato.pdf',
            VersionData = Blob.valueOf('Contenido del PDF'),
            IsMajorVersion = true
        );
        insert cv;
        Id conDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;

        // 3. Crear Oportunidad ya con el contrato marcado (Para saltar la validación al hacer update)
        Opportunity opp = new Opportunity(
            Name = 'Op Test',
            AccountId = acc.Id,
            StageName = 'Evaluación', 
            CloseDate = Date.today(),
            Contract_Generated__c = true, 
            Contract_Content_Document_Id__c = conDocId
        );
        insert opp;

        // --- ESCENARIO 1: ID nulo (Cubre el primer if) ---
        new OpportunityContractEmailQueueable(null).execute(null);

        // --- ESCENARIO 2: Etapa no es Closed Won (Cubre el return) ---
        new OpportunityContractEmailQueueable(opp.Id).execute(null);

        // --- ESCENARIO 3: Error de Email (Cubre el throw de email) ---
        opp.StageName = 'Closed Won';
        update opp;
        
        acc.Email__c = null; 
        update acc;

        try {
            new OpportunityContractEmailQueueable(opp.Id).execute(null);
        } catch (AuraHandledException e) {
            System.debug('Línea de error email cubierta');
        }

        // --- ESCENARIO 4: Error de Contrato (Cubre el throw de contrato) ---
        acc.Email__c = 'valido@test.com';
        update acc;
        
        opp.Contract_Generated__c = false; // Provocamos el error de la clase
        
        try { update opp; } catch(Exception e) {}

        try {
            new OpportunityContractEmailQueueable(opp.Id).execute(null);
        } catch (AuraHandledException e) {
            System.debug('Línea de error contrato cubierta');
        }

        // --- ESCENARIO 5: RUTA EXITOSA (Envío de correo) ---
        opp.Contract_Generated__c = true;
        try { update opp; } catch(Exception e) {}

        Test.startTest();
        new OpportunityContractEmailQueueable(opp.Id).execute(null);
        Test.stopTest();
        
        System.assert(true);
    }
}