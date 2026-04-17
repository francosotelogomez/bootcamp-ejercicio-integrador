/**
 * Test class for FinancialAccountManager LWC controller.
 * Validates CRUD operations, record retrieval logic, and product filtering 
 * for the financial account management interface.
 */
@isTest
private class FinancialAccountControllerTest {

    @testSetup
    static void setupData() {
        Account acc = new Account(Name = 'Cliente Test');
        insert acc;

        Product2 prod = new Product2(Name = 'Visa Oro', IsActive = true);
        insert prod;

        Financial_Account__c fa = new Financial_Account__c(
            Name = 'FA-001',
            Cliente__c = acc.Id,
            Product__c = prod.Id,
            Card_Type__c = 'Visa',
            Approved_Credit_Limit__c = 5000,
            Last_4_Digits__c = '1234'
        );
        insert fa;
    }

    @isTest
    static void testGetFinancialAccounts() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        Test.startTest();
        List<Financial_Account__c> results = FinancialAccountController.getFinancialAccounts(acc.Id);
        List<Financial_Account__c> emptyResults = FinancialAccountController.getFinancialAccounts(null);
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Debe retornar 1 cuenta financiera');
        System.assertEquals(0, emptyResults.size(), 'Debe retornar lista vacía si el ID es null');
    }

    @isTest
    static void testCreateFinancialAccountSuccess() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];

        Financial_Account__c newFA = new Financial_Account__c(
            Cliente__c = acc.Id,
            Product__c = prod.Id,
            Card_Type__c = 'Visa',
            Approved_Credit_Limit__c = 1000
        );

        Test.startTest();
        FinancialAccountController.createFinancialAccount(newFA);
        Test.stopTest();

        System.assertNotEquals(null, newFA.Id, 'La cuenta financiera debería tener un Id tras la inserción');
    }

    @isTest
    static void testCreateFinancialAccountError() {
        // Objeto vacío para disparar validación
        Financial_Account__c emptyFA = new Financial_Account__c();

        Test.startTest();
        try {
            FinancialAccountController.createFinancialAccount(emptyFA);
            System.assert(false, 'Debería haber lanzado una excepción');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Faltan campos obligatorios'), 'El mensaje de error no es el esperado');
        }
        Test.stopTest();
    }

    @isTest
    static void testUpdateFinancialAccountSuccess() {
        Financial_Account__c fa = [SELECT Id, Approved_Credit_Limit__c, Cliente__c, Card_Type__c, Product__c 
                                   FROM Financial_Account__c LIMIT 1];
        fa.Approved_Credit_Limit__c = 9999;

        Test.startTest();
        FinancialAccountController.updateFinancialAccount(fa);
        Test.stopTest();

        Financial_Account__c updatedFA = [SELECT Approved_Credit_Limit__c FROM Financial_Account__c WHERE Id = :fa.Id];
        System.assertEquals(9999, updatedFA.Approved_Credit_Limit__c);
    }

    @isTest
    static void testUpdateFinancialAccountError() {
        Financial_Account__c faNoId = new Financial_Account__c(Card_Type__c = 'Test');
        
        Test.startTest();
        try {
            FinancialAccountController.updateFinancialAccount(faNoId);
            System.assert(false);
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Id es obligatorio'));
        }
        Test.stopTest();
    }

    @isTest
    static void testDeleteFinancialAccount() {
        Financial_Account__c fa = [SELECT Id FROM Financial_Account__c LIMIT 1];

        Test.startTest();
        FinancialAccountController.deleteFinancialAccount(fa.Id);
        Test.stopTest();

        Integer count = [SELECT COUNT() FROM Financial_Account__c WHERE Id = :fa.Id];
        System.assertEquals(0, count, 'El registro debería haber sido eliminado');
    }

    @isTest
    static void testGetActiveProducts() {
        Test.startTest();
        List<Product2> prods = FinancialAccountController.getActiveProducts();
        Test.stopTest();

        System.assert(prods.size() > 0, 'Debe retornar al menos el producto creado en setup');
    }
}