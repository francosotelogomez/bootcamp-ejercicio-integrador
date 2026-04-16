@RestResource(urlMapping='/v1/clientes/*/oportunidades-ganadas')
global with sharing class ClosedWonOpportunitiesApi {

    // Clases de estructura para la respuesta
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
        public String mensaje; // Campo opcional para errores o estados
    }

    @HttpGet
    global static ApiResponse getClosedWonOpportunities() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        ApiResponse responseBody = new ApiResponse();

        try {
            String clienteId = extractClienteId(req.requestURI);

            // 1. Validación de ID presente
            if (String.isBlank(clienteId)) {
                res.statusCode = 400;
                responseBody.mensaje = 'El clienteId es obligatorio en la URL.';
                return responseBody;
            }

            // 2. Consulta de la Cuenta
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

            // 3. Consulta de Oportunidades Ganadas
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

            // 4. Mapeo de resultados
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
            // Manejo de errores inesperados (ej. ID mal formado que rompe el SOQL)
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
            // Buscamos la posición después de 'clientes'
            if (parts[i].equalsIgnoreCase('clientes') && i + 1 < parts.size()) {
                return parts[i + 1];
            }
        }

        return null;
    }
}