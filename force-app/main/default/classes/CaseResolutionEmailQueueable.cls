public with sharing class CaseResolutionEmailQueueable implements Queueable {
    private Id caseId;

    public CaseResolutionEmailQueueable(Id caseId) {
        this.caseId = caseId;
    }

    public void execute(QueueableContext context) {
        if (caseId == null) {
            return;
        }

        Case caseRecord = [
            SELECT Id,
                   CaseNumber,
                   Status,
                   Subject,
                   AccountId,
                   Account.Name,
                   Account.Email__c,
                   Final_Resolution__c,
                   Notification_Sent__c
            FROM Case
            WHERE Id = :caseId
            LIMIT 1
        ];

        if (caseRecord.Status != 'Closed') {
            return;
        }

        if (caseRecord.Notification_Sent__c) {
            return;
        }

        if (caseRecord.AccountId == null || String.isBlank(caseRecord.Account.Email__c)) {
            throw new AuraHandledException('El caso no tiene una cuenta con correo electrónico configurado.');
        }

        if (String.isBlank(caseRecord.Final_Resolution__c)) {
            throw new AuraHandledException('El caso no tiene una resolución final para notificar.');
        }

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new List<String>{ caseRecord.Account.Email__c });
        email.setSubject('Resolución de su caso ' + caseRecord.CaseNumber);
        email.setPlainTextBody(
            'Estimado/a ' + caseRecord.Account.Name + ',\n\n' +
            'Le informamos que su caso ' + caseRecord.CaseNumber + ' ha sido cerrado.\n\n' +
            'Resolución:\n' + caseRecord.Final_Resolution__c + '\n\n' +
            'Atentamente,\nNovaBank'
        );
        email.setSaveAsActivity(true);

        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });

        caseRecord.Notification_Sent__c = true;
        update caseRecord;
    }
}