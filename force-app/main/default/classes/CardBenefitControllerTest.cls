@IsTest
private class CardBenefitControllerTest {

    @IsTest
    static void testGetCardBenefits_ReturnsOrderedBenefits() {
        Product2 p1 = new Product2(
            Name = 'Visa Infinite',
            IsActive = true
        );
        Product2 p2 = new Product2(
            Name = 'Visa Oro',
            IsActive = true
        );
        insert new List<Product2>{ p1, p2 };

        Card_Benefit__c b1 = new Card_Benefit__c(
            Name = 'Beneficio 1',
            Card_Name__c = 'Visa Infinite',
            Annual_Effective_Rate__c = 24.5,
            Miles_Accumulation__c = '1 milla por cada $1',
            Cashback_Percentage__c = 5,
            Priority__c = 1,
            Annual_Fee__c = 500,
            Product__c = p1.Id
        );

        Card_Benefit__c b2 = new Card_Benefit__c(
            Name = 'Beneficio 2',
            Card_Name__c = 'Visa Oro',
            Annual_Effective_Rate__c = 28,
            Miles_Accumulation__c = '1 milla por cada $2',
            Cashback_Percentage__c = 3,
            Priority__c = 2,
            Annual_Fee__c = 300,
            Product__c = p2.Id
        );

        Card_Benefit__c b3 = new Card_Benefit__c(
            Name = 'Beneficio 3',
            Card_Name__c = 'Visa Plata',
            Annual_Effective_Rate__c = 32,
            Miles_Accumulation__c = '1 milla por cada $3',
            Cashback_Percentage__c = 1,
            Priority__c = 2,
            Annual_Fee__c = 150,
            Product__c = p2.Id
        );

        insert new List<Card_Benefit__c>{ b2, b3, b1 };

        Test.startTest();
        List<Card_Benefit__c> results = CardBenefitController.getCardBenefits();
        Test.stopTest();

        System.assertEquals(3, results.size(), 'Debe devolver los 3 beneficios creados.');

        System.assertEquals('Visa Infinite', results[0].Card_Name__c,
            'El primero debe ser el de prioridad 1.');

        System.assertEquals(1, results[0].Priority__c,
            'La prioridad del primer registro debe ser 1.');

        System.assertEquals(2, results[1].Priority__c,
            'El segundo registro debe tener prioridad 2.');

        System.assertEquals(2, results[2].Priority__c,
            'El tercer registro debe tener prioridad 2.');

        System.assertEquals('Visa Oro', results[1].Card_Name__c,
            'Dentro de la misma prioridad, debe ordenar por nombre de tarjeta ascendente.');

        System.assertEquals('Visa Plata', results[2].Card_Name__c,
            'Dentro de la misma prioridad, debe ordenar por nombre de tarjeta ascendente.');

        System.assertEquals('Visa Infinite', results[0].Product__r.Name,
            'Debe recuperar correctamente el nombre del producto relacionado.');
    }

    @IsTest
    static void testGetCardBenefits_EmptyResult() {
        Test.startTest();
        List<Card_Benefit__c> results = CardBenefitController.getCardBenefits();
        Test.stopTest();

        System.assertEquals(0, results.size(),
            'Si no existen beneficios, debe devolver una lista vacía.');
    }
}