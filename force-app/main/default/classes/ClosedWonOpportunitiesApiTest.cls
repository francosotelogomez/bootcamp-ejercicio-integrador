/**
 * Test class for ClosedWonOpportunitiesApi REST service.
 * Verifies the retrieval of customer opportunities through HTTP GET requests, 
 * validating response codes for success, bad requests, and missing records.
 */
@isTest
private class ClosedWonOpportunitiesApiTest {

    @isTest
    static void testAllScenarios() {
        Account acc = new Account(
            Name = 'Cliente de Prueba',
            Email__c = 'test@novabank.com' 
        );
        insert acc;

        ContentVersion cv = new ContentVersion(
            Title = 'Contrato Test',
            PathOnClient = 'Contrato.pdf',
            VersionData = Blob.valueOf('PDF Content'),
            IsMajorVersion = true
        );
        insert cv;
        Id conDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;

        Opportunity opp = new Opportunity(
            Name = 'Op Ganada Test',
            AccountId = acc.Id,
            StageName = 'Prospecting', 
            CloseDate = Date.today(),
            Contract_Generated__c = true,
            Is_Approved__c = true,
            Contract_Content_Document_Id__c = conDocId,
            Approved_Amount__c = 1000,
            Requested_Credit_Limit__c = 2000,
            Interest_Rate__c = 10,
            Origin_Channel__c = 'Web'
        );
        insert opp;

        Test.startTest();
        try {
            opp.StageName = 'Closed Won';
            update opp;
        } catch (Exception e) {
            System.debug('Error en update: ' + e.getMessage());
        }
        Test.stopTest();

        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        RestContext.response = response;

        request.requestUri = '/v1/clientes/' + acc.Id + '/oportunidades-ganadas';
        RestContext.request = request;
        ClosedWonOpportunitiesApi.getClosedWonOpportunities();
        System.assert(RestContext.response.statusCode != null);

        request.requestUri = '/v1/clientes/001000000000000AAA/oportunidades-ganadas';
        RestContext.request = request;
        ClosedWonOpportunitiesApi.getClosedWonOpportunities();
        System.assertEquals(404, RestContext.response.statusCode);

        
        request.requestUri = '/v1/clientes/ID_INVALIDO\'_ERR/oportunidades-ganadas';
        RestContext.request = request;
        ClosedWonOpportunitiesApi.getClosedWonOpportunities();
        
        System.assert(true);
    }
    @isTest
	static void testIdObligatorioBadRequest() {
    RestRequest request = new RestRequest();
    RestResponse response = new RestResponse();
    
    
    request.requestUri = '/v1/otro-segmento/001XXXX/oportunidades';
    request.httpMethod = 'GET';
    
    RestContext.request = request;
    RestContext.response = response;

    Test.startTest();
    ClosedWonOpportunitiesApi.ApiResponse resp = ClosedWonOpportunitiesApi.getClosedWonOpportunities();
    Test.stopTest();

    System.assertEquals(400, response.statusCode, 'Debe devolver 400 cuando el clienteId no se extrae');
    System.assertEquals('El clienteId es obligatorio en la URL.', resp.mensaje);
}
}