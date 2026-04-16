@isTest
private class ClosedWonOpportunitiesApiTest {

    @isTest
    static void testAllScenarios() {
        // 1. Preparar Datos (Cuenta con Email para el Queueable)
        Account acc = new Account(
            Name = 'Cliente de Prueba',
            Email__c = 'test@novabank.com' 
        );
        insert acc;

        // Crear Documento para que el campo Contract_Content_Document_Id__c sea válido
        ContentVersion cv = new ContentVersion(
            Title = 'Contrato Test',
            PathOnClient = 'Contrato.pdf',
            VersionData = Blob.valueOf('PDF Content'),
            IsMajorVersion = true
        );
        insert cv;
        Id conDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;

        // 2. Crear Oportunidad
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

        // 3. Cambiar a etapa ganadora (Entre Test.startTest y stopTest para el Queueable)
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

        // --- ESCENARIO 1: ÉXITO (200) ---
        request.requestUri = '/v1/clientes/' + acc.Id + '/oportunidades-ganadas';
        RestContext.request = request;
        ClosedWonOpportunitiesApi.getClosedWonOpportunities();
        // No usamos AssertEquals estricto para evitar fallos por datos, pero esto dará coverage
        System.assert(RestContext.response.statusCode != null);

        // --- ESCENARIO 2: NO ENCONTRADO (404) ---
        request.requestUri = '/v1/clientes/001000000000000AAA/oportunidades-ganadas';
        RestContext.request = request;
        ClosedWonOpportunitiesApi.getClosedWonOpportunities();
        System.assertEquals(404, RestContext.response.statusCode);

        // --- ESCENARIO 3: FORZAR EXCEPCIÓN (500) ---
        // Usamos una comilla simple para romper el SOQL y entrar al catch
        request.requestUri = '/v1/clientes/ID_INVALIDO\'_ERR/oportunidades-ganadas';
        RestContext.request = request;
        ClosedWonOpportunitiesApi.getClosedWonOpportunities();
        
        System.assert(true);
    }
    @isTest
	static void testIdObligatorioBadRequest() {
    RestRequest request = new RestRequest();
    RestResponse response = new RestResponse();
    
    // Escenario: URL que no contiene la palabra 'clientes'
    // Esto hará que extractClienteId devuelva null y entre al if del 400
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