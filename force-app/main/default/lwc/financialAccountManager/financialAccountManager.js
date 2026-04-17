import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

import getFinancialAccounts from '@salesforce/apex/FinancialAccountController.getFinancialAccounts';
import createFinancialAccount from '@salesforce/apex/FinancialAccountController.createFinancialAccount';
import updateFinancialAccount from '@salesforce/apex/FinancialAccountController.updateFinancialAccount';
import deleteFinancialAccount from '@salesforce/apex/FinancialAccountController.deleteFinancialAccount';
import getActiveProducts from '@salesforce/apex/FinancialAccountController.getActiveProducts';

export default class FinancialAccountManager extends LightningElement {
    @api recordId;

    @track financialAccounts = [];
    @track productOptions = [];
    @track showModal = false;
    @track isLoading = false;
    
    wiredAccountsResult;
    editingId = null;

    // Inicializamos con valores vacíos
    @track formData = {
        Card_Type__c: '',
        Approved_Credit_Limit__c: null,
        Issue_Date__c: '',
        Card_Status__c: '',
        Product__c: ''
    };

    columns = [
        { label: 'Tipo', fieldName: 'Card_Type__c' },
        { label: 'Línea', fieldName: 'Approved_Credit_Limit__c', type: 'currency' },
        { label: 'Estado', fieldName: 'Card_Status__c' },
        { label: 'Últimos 4', fieldName: 'Last_4_Digits__c' },
        { label: 'Producto', fieldName: 'productName' },
        {
            type: 'action',
            typeAttributes: {
                rowActions: [
                    { label: 'Editar', name: 'edit' },
                    { label: 'Eliminar', name: 'delete' }
                ]
            }
        }
    ];

    cardTypeOptions = [{ label: 'Visa', value: 'Visa' }];
    
    cardStatusOptions = [
        { label: 'Activa', value: 'Activa' }, 
        { label: 'Bloqueada', value: 'Bloqueada' },
        { label: 'Cancelada', value: 'Cancelada' }
    ];
    get modalTitle() {
        return this.editingId ? 'Editar Cuenta Financiera' : 'Nueva Cuenta Financiera';
    }
    @wire(getFinancialAccounts, { accountId: '$recordId' })
    wiredAccounts(result) {
        this.wiredAccountsResult = result;
        if (result.data) {
            this.financialAccounts = result.data.map(a => ({
                ...a,
                productName: a.Product__r ? a.Product__r.Name : ''
            }));
        }
    }

    async connectedCallback() {
        try {
            const products = await getActiveProducts();
            this.productOptions = products.map(p => ({ label: p.Name, value: p.Id }));
        } catch (error) {
            console.error(error);
        }
    }

    // EXPLICACIÓN: Aquí limpiamos todo para que el Crear salga vacío
    openNewModal() {
        this.editingId = null;
        this.formData = {
            Card_Type__c: '',
            Approved_Credit_Limit__c: null,
            Issue_Date__c: '',
            Card_Status__c: '',
            Product__c: ''
        };
        this.showModal = true;
    }

    closeModal() {
        this.showModal = false;
        this.editingId = null;
    }

    handleInputChange(event) {
        const field = event.target.dataset.field;
        this.formData = { ...this.formData, [field]: event.target.value };
    }

    handleRowAction(event) {
        const row = event.detail.row;
        if (event.detail.action.name === 'edit') {
            this.editingId = row.Id;
            // Al editar, sí cargamos los valores de la fila
            this.formData = {
                Card_Type__c: row.Card_Type__c,
                Approved_Credit_Limit__c: row.Approved_Credit_Limit__c,
                Issue_Date__c: row.Issue_Date__c,
                Card_Status__c: row.Card_Status__c,
                Product__c: row.Product__c
            };
            this.showModal = true;
        } else if (event.detail.action.name === 'delete') {
            this.deleteRecord(row.Id);
        }
    }

    async saveFinancialAccount() {
        this.isLoading = true;
        try {
            const payload = {
                sobjectType: 'Financial_Account__c',
                Cliente__c: this.recordId,
                Card_Type__c: this.formData.Card_Type__c,
                Approved_Credit_Limit__c: Number(this.formData.Approved_Credit_Limit__c),
                Issue_Date__c: this.formData.Issue_Date__c,
                Card_Status__c: this.formData.Card_Status__c,
                Product__c: this.formData.Product__c
            };

            if (this.editingId) {
                payload.Id = this.editingId;
                await updateFinancialAccount({ accountRecord: payload });
            } else {
                await createFinancialAccount({ accountRecord: payload });
            }

            this.showToast('Éxito', 'Registro guardado', 'success');
            this.closeModal();
            await refreshApex(this.wiredAccountsResult);
        } catch (e) {
            this.showError(e);
        } finally {
            this.isLoading = false;
        }
    }

    async deleteRecord(id) {
        this.isLoading = true;
        try {
            await deleteFinancialAccount({ recordId: id });
            this.showToast('Éxito', 'Registro eliminado', 'success');
            await refreshApex(this.wiredAccountsResult);
        } catch (e) {
            this.showError(e);
        } finally {
            this.isLoading = false;
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    showError(e) {
        let message = e.body?.message || e.message || 'Error';
        this.showToast('Error', message, 'error');
    }
}