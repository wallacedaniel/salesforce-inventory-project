import { LightningElement, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getInventoryItems from '@salesforce/apex/InventoryManagerController.getInventoryItems';
import updateInventoryStatus from '@salesforce/apex/InventoryManagerController.updateInventoryStatus';

const COLUMNS = [
    { label: 'Product Name', fieldName: 'Product_Name__c' },
    { label: 'SKU', fieldName: 'SKU__c' },
    { 
        label: 'Current Quantity', 
        fieldName: 'Current_Quantity__c', 
        type: 'number' 
    },
    { 
        label: 'Status', 
        fieldName: 'Status__c',
        type: 'text',
        cellAttributes: {
            class: { fieldName: 'statusClass' }
        }
    },
    {
        label: 'Reorder Point',
        fieldName: 'Reorder_Point__c',
        type: 'number'
    },
    {
        label: 'Last Restock Date',
        fieldName: 'Last_Restock_Date__c',
        type: 'date'
    },
    {
        type: 'action',
        typeAttributes: {
            rowActions: [
                { label: 'Edit', name: 'edit' },
                { label: 'Restock', name: 'restock' }
            ]
        }
    }
];

export default class InventoryManager extends LightningElement {
    @track inventoryItems = [];
    @track error;
    @track isModalOpen = false;
    @track currentRecordId;
    @track modalTitle = 'New Inventory Item';
    @track statusFilter = 'All';
    @track searchTerm = '';
    
    wiredInventoryResult;
    
    columns = COLUMNS;
    
    get statusOptions() {
        return [
            { label: 'All', value: 'All' },
            { label: 'In Stock', value: 'In Stock' },
            { label: 'Low Stock', value: 'Low Stock' },
            { label: 'Out of Stock', value: 'Out of Stock' }
        ];
    }
    
    @wire(getInventoryItems)
    wiredInventory(result) {
        this.wiredInventoryResult = result;
        if (result.data) {
            this.inventoryItems = result.data.map(item => {
                return {
                    ...item,
                    statusClass: this.getStatusClass(item.Status__c)
                };
            });
            this.error = undefined;
        } else if (result.error) {
            this.error = result.error;
            this.inventoryItems = [];
        }
    }
    
    get filteredInventoryItems() {
        let filteredItems = [...this.inventoryItems];
        
        if (this.statusFilter !== 'All') {
            filteredItems = filteredItems.filter(item => item.Status__c === this.statusFilter);
        }
        
        if (this.searchTerm) {
            const term = this.searchTerm.toLowerCase();
            filteredItems = filteredItems.filter(item => 
                item.Product_Name__c.toLowerCase().includes(term) || 
                item.SKU__c.toLowerCase().includes(term)
            );
        }
        
        return filteredItems;
    }
    
    getStatusClass(status) {
        switch(status) {
            case 'In Stock':
                return 'slds-text-color_success';
            case 'Low Stock':
                return 'slds-text-color_warning';
            case 'Out of Stock':
                return 'slds-text-color_error';
            default:
                return '';
        }
    }
    
    handleStatusFilterChange(event) {
        this.statusFilter = event.detail.value;
    }
    
    handleSearchChange(event) {
        this.searchTerm = event.detail.value;
    }
    
    handleRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;
        
        switch (action.name) {
            case 'edit':
                this.editRecord(row.Id);
                break;
            case 'restock':
                this.openRestockModal(row);
                break;
            default:
        }
    }
    
    editRecord(recordId) {
        this.currentRecordId = recordId;
        this.modalTitle = 'Edit Inventory Item';
        this.isModalOpen = true;
    }
    
    openNewItemModal() {
        this.currentRecordId = undefined;
        this.modalTitle = 'New Inventory Item';
        this.isModalOpen = true;
    }
    
    closeModal() {
        this.isModalOpen = false;
    }
    
    handleSubmit(event) {
        event.preventDefault();
        const fields = event.detail.fields;
        
        // Auto-calculate status based on quantity vs reorder point
        const currentQty = parseFloat(fields.Current_Quantity__c);
        const reorderPoint = parseFloat(fields.Reorder_Point__c);
        
        if (currentQty <= 0) {
            fields.Status__c = 'Out of Stock';
        } else if (currentQty <= reorderPoint) {
            fields.Status__c = 'Low Stock';
        } else {
            fields.Status__c = 'In Stock';
        }
        
        this.template.querySelector('lightning-record-edit-form').submit(fields);
    }
    
    handleSuccess() {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: 'Inventory updated successfully',
                variant: 'success'
            })
        );
        this.isModalOpen = false;
        
        // Refresh the inventory list
        return refreshApex(this.wiredInventoryResult);
    }
}