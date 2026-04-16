@IsTest
private class CaseResolutionEmailInvokerTest {

    @IsTest
    static void testEnqueueEmail_WithValidCaseId() {
        Account acc = new Account(Name = 'Cliente Test');
        insert acc;

        Case c = new Case(
            Subject = 'Caso de prueba',
            Status = 'New',
            AccountId = acc.Id
        );
        insert c;

        CaseResolutionEmailInvoker.Request req = new CaseResolutionEmailInvoker.Request();
        req.caseId = c.Id;

        List<CaseResolutionEmailInvoker.Request> requests =
            new List<CaseResolutionEmailInvoker.Request>{ req };

        Integer jobsBefore = Limits.getQueueableJobs();

        Test.startTest();
        CaseResolutionEmailInvoker.enqueueEmail(requests);
        Integer jobsAfter = Limits.getQueueableJobs();
        Test.stopTest();

        System.assertEquals(
            jobsBefore + 1,
            jobsAfter,
            'Debe encolar un Queueable cuando el caseId es válido.'
        );
    }

    @IsTest
    static void testEnqueueEmail_IgnoresNullRequest() {
        List<CaseResolutionEmailInvoker.Request> requests =
            new List<CaseResolutionEmailInvoker.Request>{ null };

        Integer jobsBefore = Limits.getQueueableJobs();

        Test.startTest();
        CaseResolutionEmailInvoker.enqueueEmail(requests);
        Integer jobsAfter = Limits.getQueueableJobs();
        Test.stopTest();

        System.assertEquals(
            jobsBefore,
            jobsAfter,
            'No debe encolar jobs cuando el request es nulo.'
        );
    }

    @IsTest
    static void testEnqueueEmail_IgnoresNullCaseId() {
        CaseResolutionEmailInvoker.Request req = new CaseResolutionEmailInvoker.Request();
        req.caseId = null;

        List<CaseResolutionEmailInvoker.Request> requests =
            new List<CaseResolutionEmailInvoker.Request>{ req };

        Integer jobsBefore = Limits.getQueueableJobs();

        Test.startTest();
        CaseResolutionEmailInvoker.enqueueEmail(requests);
        Integer jobsAfter = Limits.getQueueableJobs();
        Test.stopTest();

        System.assertEquals(
            jobsBefore,
            jobsAfter,
            'No debe encolar jobs cuando el caseId es nulo.'
        );
    }

    @IsTest
    static void testEnqueueEmail_MixedRequests() {
        Account acc = new Account(Name = 'Cliente Mixto');
        insert acc;

        Case c = new Case(
            Subject = 'Caso mixto',
            Status = 'New',
            AccountId = acc.Id
        );
        insert c;

        CaseResolutionEmailInvoker.Request validReq = new CaseResolutionEmailInvoker.Request();
        validReq.caseId = c.Id;

        CaseResolutionEmailInvoker.Request nullIdReq = new CaseResolutionEmailInvoker.Request();
        nullIdReq.caseId = null;

        List<CaseResolutionEmailInvoker.Request> requests =
            new List<CaseResolutionEmailInvoker.Request>{
                validReq,
                null,
                nullIdReq
            };

        Integer jobsBefore = Limits.getQueueableJobs();

        Test.startTest();
        CaseResolutionEmailInvoker.enqueueEmail(requests);
        Integer jobsAfter = Limits.getQueueableJobs();
        Test.stopTest();

        System.assertEquals(
            jobsBefore + 1,
            jobsAfter,
            'Solo debe encolar un job por el request válido.'
        );
    }
}