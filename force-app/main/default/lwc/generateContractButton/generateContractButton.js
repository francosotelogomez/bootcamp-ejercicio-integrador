import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';
import generateContract from '@salesforce/apex/OpportunityContractService.generateContract';

const FIELDS = [
    'Opportunity.StageName',
    'Opportunity.Contract_Generated__c'
];
export default class GenerateContractButton extends LightningElement {
    @api recordId;
    stageName;

   contractGenerated = false;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredOpportunity({ error, data }) {
        if (data) {
            this.stageName = data.fields.StageName.value;
            this.contractGenerated = data.fields.Contract_Generated__c.value;
        } else if (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'No se pudo obtener la oportunidad.',
                    variant: 'error'
                })
            );
        }
    }

    get isDisabled() {
        return this.stageName !== 'Contrato' || this.contractGenerated;
    }
    
    async handleGenerate() {
        try {
            await generateContract({ opportunityId: this.recordId });

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Éxito',
                    message: 'El contrato fue generado y almacenado correctamente.',
                    variant: 'success'
                })
            );
        } catch (error) {
            console.error(JSON.stringify(error));
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: error?.body?.message || 'No se pudo generar el contrato.',
                    variant: 'error'
                })
            );
        }
    }
}