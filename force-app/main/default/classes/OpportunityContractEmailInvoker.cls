/**
 * Invocable Action to trigger the contract email delivery process.
 * This class acts as a bridge between Flow Builder and the asynchronous 
 * Queueable job responsible for dispatching the contract PDF.
 */
public with sharing class OpportunityContractEmailInvoker {
    public class Request {
        @InvocableVariable(required=true)
        public Id opportunityId;
    }

    @InvocableMethod(label='Enviar contrato por correo'
                     description='Encola el envío del contrato PDF por correo cuando la oportunidad está en Closed Won.')
    public static void enqueueEmail(List<Request> requests) {
        for (Request req : requests) {
            if (req != null && req.opportunityId != null) {
                System.enqueueJob(new OpportunityContractEmailQueueable(req.opportunityId));
            }
        }
    }
}