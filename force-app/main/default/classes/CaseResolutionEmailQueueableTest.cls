/**
 * Test class for CaseResolutionEmailQueueable.
 * Validates the asynchronous email notification process for resolved cases,
 * ensuring business rules and error handling are correctly enforced.
 */
@IsTest
private class CaseResolutionEmailQueueableTest {

    @IsTest
    static void testExecute_WithNullCaseId() {
        Test.startTest();
        System.enqueueJob(new CaseResolutionEmailQueueable(null));
        Test.stopTest();

        System.assert(true,
            'No debe fallar cuando el caseId es nulo.');
    }

    @IsTest
    static void testExecute_IgnoresCaseNotClosed() {
        Account acc = new Account(
            Name = 'Cliente Test',
            Email__c = 'cliente@test.com'
        );
        insert acc;

        Case c = new Case(
            Subject = 'Caso abierto',
            Status = 'New',
            AccountId = acc.Id,
            Final_Resolution__c = 'Resolución de prueba',
            Notification_Sent__c = false
        );
        insert c;

        Test.startTest();
        System.enqueueJob(new CaseResolutionEmailQueueable(c.Id));
        Test.stopTest();

        Case updatedCase = [
            SELECT Notification_Sent__c
            FROM Case
            WHERE Id = :c.Id
        ];

        System.assertEquals(false, updatedCase.Notification_Sent__c,
            'No debe marcar notificación enviada si el caso no está cerrado.');
    }

    @IsTest
    static void testExecute_IgnoresAlreadyNotifiedCase() {
        Account acc = new Account(
            Name = 'Cliente Notificado',
            Email__c = 'cliente2@test.com'
        );
        insert acc;

        Case c = new Case(
            Subject = 'Caso ya notificado',
            Status = 'Closed',
            AccountId = acc.Id,
            Final_Resolution__c = 'Resolución previa',
            Notification_Sent__c = true
        );
        insert c;

        Test.startTest();
        System.enqueueJob(new CaseResolutionEmailQueueable(c.Id));
        Test.stopTest();

        Case updatedCase = [
            SELECT Notification_Sent__c
            FROM Case
            WHERE Id = :c.Id
        ];

        System.assertEquals(true, updatedCase.Notification_Sent__c,
            'Debe mantener el valor true cuando el caso ya fue notificado.');
    }

    @IsTest
    static void testExecute_ThrowsWhenAccountHasNoEmail() {
        Account acc = new Account(
            Name = 'Cliente Sin Email'
        );
        insert acc;

        Case c = new Case(
            Subject = 'Caso sin correo',
            Status = 'Closed',
            AccountId = acc.Id,
            Final_Resolution__c = 'Resolución final',
            Notification_Sent__c = false
        );
        insert c;

        Test.startTest();
        try {
            System.enqueueJob(new CaseResolutionEmailQueueable(c.Id));
            Test.stopTest();
            System.assert(false,
                'Debió lanzar excepción cuando la cuenta no tiene correo.');
        } catch (Exception e) {
            System.assert(
                e.getMessage().contains('correo electrónico configurado'),
                'Debe indicar que falta correo en la cuenta.'
            );
        }
    }

    @IsTest
    static void testExecute_ThrowsWhenCaseHasNoResolution() {
        Account acc = new Account(
            Name = 'Cliente Sin Resolucion',
            Email__c = 'cliente3@test.com'
        );
        insert acc;

        Case c = new Case(
            Subject = 'Caso sin resolución',
            Status = 'Closed',
            AccountId = acc.Id,
            Final_Resolution__c = null,
            Notification_Sent__c = false
        );
        insert c;

        Test.startTest();
        try {
            System.enqueueJob(new CaseResolutionEmailQueueable(c.Id));
            Test.stopTest();
            System.assert(false,
                'Debió lanzar excepción cuando falta la resolución final.');
        } catch (Exception e) {
            System.assert(
                e.getMessage().contains('resolución final'),
                'Debe indicar que falta la resolución final.'
            );
        }
    }

    @IsTest
    static void testExecute_SendsEmailAndMarksNotificationSent() {
        Account acc = new Account(
            Name = 'Cliente Válido',
            Email__c = 'cliente4@test.com'
        );
        insert acc;

        Case c = new Case(
            Subject = 'Caso válido',
            Status = 'Closed',
            AccountId = acc.Id,
            Final_Resolution__c = 'Se resolvió el reclamo satisfactoriamente.',
            Notification_Sent__c = false
        );
        insert c;

        Test.startTest();
        System.enqueueJob(new CaseResolutionEmailQueueable(c.Id));
        Test.stopTest();

        Case updatedCase = [
            SELECT Notification_Sent__c
            FROM Case
            WHERE Id = :c.Id
        ];

        System.assertEquals(true, updatedCase.Notification_Sent__c,
            'Debe marcar el caso como notificado luego del envío.');
    }
}