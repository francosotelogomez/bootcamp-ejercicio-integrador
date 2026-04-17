/**
 * Test class for OpportunityContractController.
 * Validates the retrieval and formatting of opportunity data used in 
 * Visualforce-based contract generation, ensuring correct data presentation.
 */
@isTest
private class OpportunityContractControllerTest {

    @isTest
    static void testControllerFullFlow() {
        Account acc = new Account(Name = 'Cliente NovaBank');
        insert acc;

        Product2 prod = new Product2(Name = 'Tarjeta de Crédito Platinium', IsActive = true);
        insert prod;

        Opportunity opp = new Opportunity(
            Name = 'Oportunidad Contrato Test',
            AccountId = acc.Id,
            StageName = 'EVALUACIÓN', 
            CloseDate = Date.today().addDays(10),
            Approved_Amount__c = 1200.50,
            Interest_Rate__c = 15.5,
            Payment_Day__c = 5,
            Financial_Product__c = prod.Id
        );
        insert opp;

        ApexPages.StandardController sc = new ApexPages.StandardController(opp);
        
        Test.startTest();
        OpportunityContractController controller = new OpportunityContractController(sc);
        
        String aName = controller.getAccountName();
        String oName = controller.getOpportunityName();
        String pName = controller.getProductName();
        String amount = controller.getApprovedAmountFormatted();
        String rate = controller.getInterestRateFormatted();
        String pDay = controller.getPaymentDayFormatted();
        String gDate = controller.getGeneratedDateFormatted();
        Test.stopTest();

        System.assertEquals('Cliente NovaBank', aName);
        System.assertEquals('Oportunidad Contrato Test', oName);
        System.assertEquals('Tarjeta de Crédito Platinium', pName);
        
        System.assert(amount.contains('1200.5'), 'El monto formateado es incorrecto: ' + amount);
        System.assert(rate.contains('15.5'), 'La tasa es incorrecta: ' + rate);
        
        System.assertEquals('5', pDay);
        System.assert(gDate.contains(Datetime.now().format('dd/MM/yyyy')));
    }

    @isTest
    static void testControllerWithNulls() {
        Account acc = new Account(Name = 'Cliente Mínimo');
        insert acc;

        Opportunity oppMin = new Opportunity(
            Name = 'Op Vacía',
            AccountId = acc.Id,
            StageName = 'INICIO',
            CloseDate = Date.today()
        );
        insert oppMin;

        ApexPages.StandardController sc = new ApexPages.StandardController(oppMin);
        
        Test.startTest();
        OpportunityContractController controller = new OpportunityContractController(sc);
        Test.stopTest();

        System.assertEquals('S/ 0', controller.getApprovedAmountFormatted());
        System.assertEquals('0%', controller.getInterestRateFormatted());
        System.assertEquals('', controller.getPaymentDayFormatted());
        System.assertEquals('', controller.getProductName());
    }
}