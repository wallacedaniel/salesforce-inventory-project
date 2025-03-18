public with sharing class InventoryManagerController {
    @AuraEnabled(cacheable=true)
    public static List<Inventory_Item__c> getInventoryItems() {
        return [
            SELECT Id, Product_Name__c, SKU__c, Current_Quantity__c, 
                   Reorder_Point__c, Last_Restock_Date__c, Status__c, Supplier__c
            FROM Inventory_Item__c
            ORDER BY Product_Name__c ASC
        ];
    }
    
    @AuraEnabled
    public static void updateInventoryStatus() {
        List<Inventory_Item__c> itemsToUpdate = new List<Inventory_Item__c>();
        
        for(Inventory_Item__c item : [
            SELECT Id, Current_Quantity__c, Reorder_Point__c, Status__c
            FROM Inventory_Item__c
        ]) {
            String newStatus;
            
            if(item.Current_Quantity__c <= 0) {
                newStatus = 'Out of Stock';
            } else if(item.Current_Quantity__c <= item.Reorder_Point__c) {
                newStatus = 'Low Stock';
            } else {
                newStatus = 'In Stock';
            }
            
            if(item.Status__c != newStatus) {
                item.Status__c = newStatus;
                itemsToUpdate.add(item);
            }
        }
        
        if(!itemsToUpdate.isEmpty()) {
            update itemsToUpdate;
        }
    }
}