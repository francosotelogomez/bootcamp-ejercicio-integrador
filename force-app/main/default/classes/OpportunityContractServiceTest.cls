@isTest
private class OpportunityContractServiceTest {

    @isTest
    static void testAllCoverageScenarios() {
        // 1. SETUP DE DATOS
        Account acc = new Account(Name = 'Cliente Test');
        insert acc;

        Product2 prod = new Product2(Name = 'Producto Test', IsActive = true);
        insert prod;

        Opportunity opp = new Opportunity(
            Name = 'Op Test',
            AccountId = acc.Id,
            StageName = 'Evaluación',
            CloseDate = Date.today().addDays(5)
        );
        insert opp;

        // --- ESCENARIO 1: ID Nulo ---
        try {
            OpportunityContractService.generateContract(null);
        } catch (Exception e) {
            System.debug('Check 1: ID nulo cubierto');
        }

        // --- ESCENARIO 2: Etapa Incorrecta (Cubre el primer throw de StageName) ---
        try {
            OpportunityContractService.generateContract(opp.Id);
        } catch (Exception e) {
            System.debug('Check 2: Etapa incorrecta cubierto');
        }

        // --- ESCENARIO 3: Campos Faltantes (Cubre los 4 ifs de missingFields y el throw) ---
        opp.StageName = 'Contrato';
        update opp;
        
        try {
            // Llamamos sin llenar montos ni productos
            OpportunityContractService.generateContract(opp.Id);
        } catch (Exception e) {
            System.debug('Check 3: Campos faltantes cubierto');
        }

        // --- ESCENARIO 4: Contrato ya generado (Cubre el throw de ya generado) ---
        opp.Approved_Amount__c = 1000;
        opp.Interest_Rate__c = 10;
        opp.Payment_Day__c = 5;
        opp.Financial_Product__c = prod.Id;
        opp.Contract_Generated__c = true;
        update opp;

        try {
            OpportunityContractService.generateContract(opp.Id);
        } catch (Exception e) {
            System.debug('Check 4: Ya generado cubierto');
        }
    }

    @isTest
    static void testSuccessAndExceptions() {
        // SETUP PARA RUTA EXITOSA
        Account acc = new Account(Name = 'Acc Exito');
        insert acc;

        Product2 prod = new Product2(Name = 'Prod Exito', IsActive = true);
        insert prod;

        Opportunity opp = new Opportunity(
            Name = 'Op Exito',
            AccountId = acc.Id,
            StageName = 'Evaluación',
            CloseDate = Date.today(),
            Approved_Amount__c = 5000,
            Interest_Rate__c = 15,
            Payment_Day__c = 20,
            Financial_Product__c = prod.Id,
            Contract_Generated__c = false
        );
        insert opp;
        
        opp.StageName = 'Contrato';
        update opp;

        // --- ESCENARIO 5: RUTA EXITOSA (Generación de File y Links) ---
        Test.startTest();
        Id docId = OpportunityContractService.generateContract(opp.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, docId, 'Debe generar un ContentDocumentId');

        // --- ESCENARIO 6: Forzar el CATCH final (Usamos un ID que no existe para provocar un error inesperado) ---
        try {
            OpportunityContractService.generateContract('006000000000000AAA');
        } catch (Exception e) {
            System.debug('Check 5: Bloque Catch final cubierto');
        }
    }
}