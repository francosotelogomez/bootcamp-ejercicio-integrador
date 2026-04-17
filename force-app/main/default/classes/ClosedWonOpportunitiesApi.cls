/**
 * REST Resource to expose Closed Won Opportunities for a specific Customer.
 * Provides a structured response including financial details and sales ownership information.
 */
@RestResource(urlMapping='/v1/clientes/*/oportunidades-ganadas')
global with sharing class ClosedWonOpportunitiesApi {

    global class OpportunityItem {
        public String oportunidadId;
        public String producto;
        public Decimal montoAprobado;
        public Decimal lineaCredito;
        public Decimal tasaInteres;
        public String fechaCierre;
        public String canalOrigen;
        public String ejecutivo;
    }

    global class ApiResponse {
        public String clienteId;
        public String nombreCliente;
        public List<OpportunityItem> oportunidadesGanadas;
        public Integer totalOportunidades;
        public String mensaje; 
    }

    @HttpGet
    global static ApiResponse getClosedWonOpportunities() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        ApiResponse responseBody = new ApiResponse();

        try {
            String clienteId = extractClienteId(req.requestURI);

            if (String.isBlank(clienteId)) {
                res.statusCode = 400;
                responseBody.mensaje = 'El clienteId es obligatorio en la URL.';
                return responseBody;
            }

            List<Account> accounts = [
                SELECT Id, Name
                FROM Account
                WHERE Id = :clienteId
                LIMIT 1
            ];

            if (accounts.isEmpty()) {
                res.statusCode = 404;
                responseBody.mensaje = 'Cliente no encontrado con el ID: ' + clienteId;
                return responseBody;
            }

            Account acc = accounts[0];

            List<Opportunity> opps = [
                SELECT Id,
                       CloseDate,
                       Owner.Name,
                       Financial_Product__r.Name,
                       Approved_Amount__c,
                       Requested_Credit_Limit__c,
                       Interest_Rate__c,
                       Origin_Channel__c
                FROM Opportunity
                WHERE AccountId = :clienteId
                  AND StageName = 'Closed Won'
                ORDER BY CloseDate DESC
            ];

            responseBody.clienteId = acc.Id;
            responseBody.nombreCliente = acc.Name;
            responseBody.oportunidadesGanadas = new List<OpportunityItem>();

            for (Opportunity opp : opps) {
                OpportunityItem item = new OpportunityItem();
                item.oportunidadId = opp.Id;
                item.producto = opp.Financial_Product__r != null ? opp.Financial_Product__r.Name : null;
                item.montoAprobado = opp.Approved_Amount__c;
                item.lineaCredito = opp.Requested_Credit_Limit__c;
                item.tasaInteres = opp.Interest_Rate__c;
                item.fechaCierre = opp.CloseDate != null ? String.valueOf(opp.CloseDate) : null;
                item.canalOrigen = opp.Origin_Channel__c;
                item.ejecutivo = opp.Owner != null ? opp.Owner.Name : null;

                responseBody.oportunidadesGanadas.add(item);
            }

            responseBody.totalOportunidades = responseBody.oportunidadesGanadas.size();
            res.statusCode = 200;

        } catch (Exception e) {
            res.statusCode = 500;
            responseBody.mensaje = 'Error interno: ' + e.getMessage();
        }

        return responseBody;
    }

    /**
     * Extrae el clienteId desde una URL como:
     * /services/apexrest/v1/clientes/001XXXXXXXXXXXX/oportunidades-ganadas
     */
    private static String extractClienteId(String requestUri) {
        if (String.isBlank(requestUri)) {
            return null;
        }

        List<String> parts = requestUri.split('/');

        for (Integer i = 0; i < parts.size(); i++) {
            if (parts[i].equalsIgnoreCase('clientes') && i + 1 < parts.size()) {
                return parts[i + 1];
            }
        }

        return null;
    }
}