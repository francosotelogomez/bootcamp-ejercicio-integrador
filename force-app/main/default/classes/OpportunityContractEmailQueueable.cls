/**
 * Asynchronous job to handle the delivery of credit card contracts via email.
 * This class retrieves the latest contract version and sends it as a PDF attachment
 * once the Opportunity reaches the Closed Won stage.
 */
public with sharing class OpportunityContractEmailQueueable implements Queueable {
    private Id opportunityId;

    public OpportunityContractEmailQueueable(Id opportunityId) {
        this.opportunityId = opportunityId;
    }

    public void execute(QueueableContext context) {
        if (opportunityId == null) {
            return;
        }

        Opportunity opp = [
            SELECT Id,
                   Name,
                   StageName,
                   AccountId,
                   Account.Name,
                   Account.Email__c,
                   Contract_Generated__c,
                   Contract_Content_Document_Id__c
            FROM Opportunity
            WHERE Id = :opportunityId
            LIMIT 1
        ];

        if (opp.StageName != 'Closed Won') {
            return;
        }

        if (opp.AccountId == null || String.isBlank(opp.Account.Email__c)) {
            throw new AuraHandledException('La oportunidad no tiene una cuenta con correo electrónico configurado.');
        }

        if (!opp.Contract_Generated__c || String.isBlank(opp.Contract_Content_Document_Id__c)) {
            throw new AuraHandledException('La oportunidad no tiene un contrato generado para enviar.');
        }

        ContentVersion latestVersion = [
            SELECT Id,
                   Title,
                   VersionData,
                   FileExtension
            FROM ContentVersion
            WHERE ContentDocumentId = :opp.Contract_Content_Document_Id__c
            AND IsLatest = true
            LIMIT 1
        ];

        Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
        attachment.setFileName(latestVersion.Title + '.pdf');
        attachment.setBody(latestVersion.VersionData);
        attachment.setContentType('application/pdf');

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new List<String>{ opp.Account.Email__c });
        email.setSubject('Confirmación de emisión de tarjeta de crédito');
        email.setPlainTextBody(
            'Estimado/a ' + opp.Account.Name + ',\n\n' +
            'Le confirmamos que su tarjeta de crédito ha sido emitida correctamente.\n' +
            'Adjuntamos el contrato correspondiente a su producto financiero para su revisión.\n\n' +
            'Atentamente,\nNovaBank'
        );
        email.setFileAttachments(new List<Messaging.EmailFileAttachment>{ attachment });
        email.setSaveAsActivity(true);

        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
    }
}