public with sharing class OpportunityContractService {
    /**
     * Genera el contrato PDF de una oportunidad en etapa Contrato,
     * lo almacena en Salesforce Files y lo vincula a la Oportunidad y a la Cuenta.
     *
     * @param opportunityId Id de la oportunidad
     * @return Id del ContentDocument generado
     */
    @AuraEnabled
    public static Id generateContract(Id opportunityId) {
        if (opportunityId == null) {
            throw new AuraHandledException('El Id de la oportunidad es obligatorio.');
        }

        Opportunity opp = [
            SELECT Id,
                   Name,
                   StageName,
                   AccountId,
                   Approved_Amount__c,
                   Interest_Rate__c,
                   Payment_Day__c,
                   Financial_Product__c,
                   Contract_Generated__c,
                   Contract_Generation_Date__c,
                   Contract_Content_Document_Id__c
            FROM Opportunity
            WHERE Id = :opportunityId
            LIMIT 1
        ];

        if (opp.StageName != 'Contrato') {
            throw new AuraHandledException(
                'El contrato solo puede generarse cuando la oportunidad está en la etapa Contrato.'
            );
        }

        if (opp.Contract_Generated__c == true) {
            throw new AuraHandledException(
                'El contrato ya fue generado para esta oportunidad.'
            );
        }

        List<String> missingFields = new List<String>();

        if (opp.Approved_Amount__c == null) {
            missingFields.add('Monto Aprobado');
        }
        if (opp.Interest_Rate__c == null) {
            missingFields.add('Tasa de Interés');
        }
        if (opp.Payment_Day__c == null) {
            missingFields.add('Día de Pago');
        }
        if (opp.Financial_Product__c == null) {
            missingFields.add('Producto Financiero');
        }

        if (!missingFields.isEmpty()) {
            throw new AuraHandledException(
                'No se puede generar el contrato. Faltan los siguientes campos: ' 
                + String.join(missingFields, ', ')
            );
        }

        PageReference contractPage = Page.OpportunityContractPdf;
        contractPage.getParameters().put('id', opp.Id);

        Blob pdfBlob;
        try {
            pdfBlob = Test.isRunningTest()
                ? Blob.valueOf('PDF de prueba')
                : contractPage.getContentAsPDF();
        } catch (Exception e) {
            throw new AuraHandledException(
                'No se pudo generar el PDF del contrato: ' + e.getMessage()
            );
        }

        ContentVersion contentVersion = new ContentVersion();
        contentVersion.Title = 'Contrato - ' + opp.Name;
        contentVersion.PathOnClient = 'Contrato_' + opp.Name + '.pdf';
        contentVersion.VersionData = pdfBlob;
        contentVersion.IsMajorVersion = true;
        insert contentVersion;

        contentVersion = [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            WHERE Id = :contentVersion.Id
            LIMIT 1
        ];

        List<ContentDocumentLink> linksToInsert = new List<ContentDocumentLink>();

        ContentDocumentLink oppLink = new ContentDocumentLink();
        oppLink.ContentDocumentId = contentVersion.ContentDocumentId;
        oppLink.LinkedEntityId = opp.Id;
        oppLink.ShareType = 'V';
        oppLink.Visibility = 'AllUsers';
        linksToInsert.add(oppLink);

        if (opp.AccountId != null) {
            ContentDocumentLink accountLink = new ContentDocumentLink();
            accountLink.ContentDocumentId = contentVersion.ContentDocumentId;
            accountLink.LinkedEntityId = opp.AccountId;
            accountLink.ShareType = 'V';
            accountLink.Visibility = 'AllUsers';
            linksToInsert.add(accountLink);
        }

        insert linksToInsert;

        opp.Contract_Generated__c = true;
        opp.Contract_Generation_Date__c = System.now();
        opp.Contract_Content_Document_Id__c = contentVersion.ContentDocumentId;
        update opp;

        return contentVersion.ContentDocumentId;
    }
}