@isTest
public class InventoryManagerControllerTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test inventory items with different statuses
        List<Inventory_Item__c> inventoryItems = new List<Inventory_Item__c>();
        
        // In Stock item
        inventoryItems.add(new Inventory_Item__c(
            Product_Name__c = 'Test Product 1',
            SKU__c = 'TP-001',
            Current_Quantity__c = 100,
            Reorder_Point__c = 20,
            Status__c = 'In Stock',
            Supplier__c = 'Test Supplier 1',
            Last_Restock_Date__c = Date.today().addDays(-30)
        ));
        
        // Low Stock item
        inventoryItems.add(new Inventory_Item__c(
            Product_Name__c = 'Test Product 2',
            SKU__c = 'TP-002',
            Current_Quantity__c = 15,
            Reorder_Point__c = 25,
            Status__c = 'Low Stock',
            Supplier__c = 'Test Supplier 2',
            Last_Restock_Date__c = Date.today().addDays(-45)
        ));
        
        // Out of Stock item
        inventoryItems.add(new Inventory_Item__c(
            Product_Name__c = 'Test Product 3',
            SKU__c = 'TP-003',
            Current_Quantity__c = 0,
            Reorder_Point__c = 10,
            Status__c = 'Out of Stock',
            Supplier__c = 'Test Supplier 1',
            Last_Restock_Date__c = Date.today().addDays(-60)
        ));
        
        // Item with incorrect status (should be changed during update)
        inventoryItems.add(new Inventory_Item__c(
            Product_Name__c = 'Test Product 4',
            SKU__c = 'TP-004',
            Current_Quantity__c = 5,
            Reorder_Point__c = 15,
            Status__c = 'In Stock', // Incorrect status
            Supplier__c = 'Test Supplier 3',
            Last_Restock_Date__c = Date.today().addDays(-20)
        ));
        
        insert inventoryItems;
    }
    
    @isTest
    static void testGetInventoryItems() {
        // Call the method
        Test.startTest();
        List<Inventory_Item__c> inventoryItems = InventoryManagerController.getInventoryItems();
        Test.stopTest();
        
        // Verify results
        System.assertEquals(4, inventoryItems.size(), 'Should return 4 inventory items');
        
        // Verify sorting by Product_Name__c
        System.assertEquals('Test Product 1', inventoryItems[0].Product_Name__c, 'First item should be Test Product 1');
        System.assertEquals('Test Product 2', inventoryItems[1].Product_Name__c, 'Second item should be Test Product 2');
        System.assertEquals('Test Product 3', inventoryItems[2].Product_Name__c, 'Third item should be Test Product 3');
        System.assertEquals('Test Product 4', inventoryItems[3].Product_Name__c, 'Fourth item should be Test Product 4');
        
        // Verify all fields are returned
        System.assertNotEquals(null, inventoryItems[0].SKU__c, 'SKU field should be included');
        System.assertNotEquals(null, inventoryItems[0].Current_Quantity__c, 'Current Quantity field should be included');
        System.assertNotEquals(null, inventoryItems[0].Reorder_Point__c, 'Reorder Point field should be included');
        System.assertNotEquals(null, inventoryItems[0].Status__c, 'Status field should be included');
        System.assertNotEquals(null, inventoryItems[0].Supplier__c, 'Supplier field should be included');
        System.assertNotEquals(null, inventoryItems[0].Last_Restock_Date__c, 'Last Restock Date field should be included');
    }
    
    @isTest
    static void testUpdateInventoryStatus() {
        // Call the method
        Test.startTest();
        InventoryManagerController.updateInventoryStatus();
        Test.stopTest();
        
        // Query updated records
        List<Inventory_Item__c> updatedItems = [
            SELECT Id, Product_Name__c, Current_Quantity__c, Reorder_Point__c, Status__c
            FROM Inventory_Item__c
            ORDER BY Product_Name__c
        ];
        
        // Verify statuses are correct
        System.assertEquals('In Stock', updatedItems[0].Status__c, 
                           'Item with quantity > reorder point should be In Stock');
        
        System.assertEquals('Low Stock', updatedItems[1].Status__c, 
                           'Item with quantity <= reorder point should be Low Stock');
        
        System.assertEquals('Out of Stock', updatedItems[2].Status__c, 
                           'Item with quantity = 0 should be Out of Stock');
        
        System.assertEquals('Low Stock', updatedItems[3].Status__c, 
                           'Item 4 status should be updated from In Stock to Low Stock');
    }
    
    @isTest
    static void testUpdateInventoryStatusWithNoChanges() {
        // First update to ensure all statuses are correct
        InventoryManagerController.updateInventoryStatus();
        
        // Now call again - should not make any changes
        Test.startTest();
        InventoryManagerController.updateInventoryStatus();
        Test.stopTest();
        
        // Query updated records
        List<Inventory_Item__c> updatedItems = [
            SELECT Id, Product_Name__c, Current_Quantity__c, Reorder_Point__c, Status__c
            FROM Inventory_Item__c
            ORDER BY Product_Name__c
        ];
        
        // Verify statuses are still correct
        System.assertEquals('In Stock', updatedItems[0].Status__c);
        System.assertEquals('Low Stock', updatedItems[1].Status__c);
        System.assertEquals('Out of Stock', updatedItems[2].Status__c);
        System.assertEquals('Low Stock', updatedItems[3].Status__c);
    }
    
    @isTest
    static void testBulkUpdateInventoryStatus() {
        // Create 200 test records to test bulk processing
        List<Inventory_Item__c> bulkItems = new List<Inventory_Item__c>();
        
        for(Integer i = 0; i < 200; i++) {
            Inventory_Item__c item = new Inventory_Item__c(
                Product_Name__c = 'Bulk Product ' + i,
                SKU__c = 'BULK-' + i,
                Current_Quantity__c = (Math.mod(i, 3) == 0) ? 0 : (Math.mod(i, 3) == 1) ? 5 : 50,
                Reorder_Point__c = 10,
                Status__c = 'In Stock', // Intentionally incorrect for some
                Supplier__c = 'Bulk Supplier',
                Last_Restock_Date__c = Date.today()
            );
            bulkItems.add(item);
        }
        
        insert bulkItems;
        
        // Call the method
        Test.startTest();
        InventoryManagerController.updateInventoryStatus();
        Test.stopTest();
        
        // Verify results for different categories
        Integer outOfStockCount = [SELECT COUNT() FROM Inventory_Item__c WHERE Status__c = 'Out of Stock'];
        Integer lowStockCount = [SELECT COUNT() FROM Inventory_Item__c WHERE Status__c = 'Low Stock'];
        Integer inStockCount = [SELECT COUNT() FROM Inventory_Item__c WHERE Status__c = 'In Stock'];
        
        // Initial 4 + bulk items with specific distribution
        Integer expectedOutOfStock = 1 + (200 / 3); // Original + approximately 1/3 of bulk items
        Integer expectedLowStock = 2 + (200 / 3);   // Original + approximately 1/3 of bulk items
        Integer expectedInStock = 1 + (200 / 3);    // Original + approximately 1/3 of bulk items
        
        // Allow for slight variation due to integer division
        System.assert(Math.abs(outOfStockCount - expectedOutOfStock) <= 2, 
                     'Out of Stock count should be approximately ' + expectedOutOfStock);
        System.assert(Math.abs(lowStockCount - expectedLowStock) <= 2, 
                     'Low Stock count should be approximately ' + expectedLowStock);
        System.assert(Math.abs(inStockCount - expectedInStock) <= 2, 
                     'In Stock count should be approximately ' + expectedInStock);
    }
    
    @isTest
    static void testNegativeQuantity() {
        // Create an item with negative quantity to test edge case
        Inventory_Item__c negativeItem = new Inventory_Item__c(
            Product_Name__c = 'Negative Quantity Item',
            SKU__c = 'NEG-001',
            Current_Quantity__c = -10, // Negative quantity
            Reorder_Point__c = 5,
            Status__c = 'In Stock', // Incorrect status
            Supplier__c = 'Test Supplier',
            Last_Restock_Date__c = Date.today()
        );
        
        insert negativeItem;
        
        // Call the method
        Test.startTest();
        InventoryManagerController.updateInventoryStatus();
        Test.stopTest();
        
        // Verify the item was updated to Out of Stock
        Inventory_Item__c updatedItem = [
            SELECT Status__c 
            FROM Inventory_Item__c 
            WHERE SKU__c = 'NEG-001'
        ];
        
        System.assertEquals('Out of Stock', updatedItem.Status__c, 
                           'Negative quantity should be considered Out of Stock');
    }
    
    @isTest
    static void testExactlyAtReorderPoint() {
        // Create an item with quantity exactly at reorder point
        Inventory_Item__c borderlineItem = new Inventory_Item__c(
            Product_Name__c = 'Borderline Item',
            SKU__c = 'BORDER-001',
            Current_Quantity__c = 15, // Equal to reorder point
            Reorder_Point__c = 15,
            Status__c = 'In Stock', // Incorrect status
            Supplier__c = 'Test Supplier',
            Last_Restock_Date__c = Date.today()
        );
        
        insert borderlineItem;
        
        // Call the method
        Test.startTest();
        InventoryManagerController.updateInventoryStatus();
        Test.stopTest();
        
        // Verify the item was updated to Low Stock
        Inventory_Item__c updatedItem = [
            SELECT Status__c 
            FROM Inventory_Item__c 
            WHERE SKU__c = 'BORDER-001'
        ];
        
        System.assertEquals('Low Stock', updatedItem.Status__c, 
                           'Quantity exactly at reorder point should be Low Stock');
    }
}