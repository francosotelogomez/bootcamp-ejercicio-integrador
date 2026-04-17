/**
 * Invocable Action to trigger the case resolution notification process.
 * Acts as a bridge between Flow Builder and the asynchronous Queueable job 
 * responsible for notifying customers about their closed cases.
 */
public with sharing class CaseResolutionEmailInvoker {
    public class Request {
        @InvocableVariable(required=true)
        public Id caseId;
    }

    @InvocableMethod(
        label='Enviar notificación de resolución de caso'
        description='Encola el envío del correo de resolución cuando el caso se cierra.'
    )
    public static void enqueueEmail(List<Request> requests) {
        for (Request req : requests) {
            if (req != null && req.caseId != null) {
                System.enqueueJob(new CaseResolutionEmailQueueable(req.caseId));
            }
        }
    }
}