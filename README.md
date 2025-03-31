# Salesforce Inventory Management

A Lightning Web Component solution for managing inventory items within Salesforce, providing real-time visibility into stock levels with visual indicators and intuitive management tools.

## Project Overview

This project offers a comprehensive inventory management interface that allows users to:

- View current inventory levels for all products in a single interface
- See visual indicators (color-coded) for stock status (In Stock, Low Stock, Out of Stock)
- Filter inventory items by status and search by product name or SKU
- Add new inventory items and update existing records
- Restock inventory items with a dedicated action

The solution is built using Lightning Web Components, providing a responsive and modern user experience directly within Salesforce.

## Features

### Inventory Dashboard
- Tabular view of all inventory items with key information
- Color-coded status indicators:
  - Green: In Stock
  - Yellow: Low Stock
  - Red: Out of Stock
- Filter capabilities by status (All, In Stock, Low Stock, Out of Stock)
- Search functionality for product name or SKU

### Inventory Management
- Add new inventory items with product details
- Edit existing inventory items
- Automatic status calculation based on current quantity vs. reorder point
- Quick action to restock inventory items

### Status Automation
- Automatic calculation of inventory status based on:
  - Current quantity vs. reorder point thresholds
  - Out of Stock: Quantity <= 0
  - Low Stock: Quantity <= Reorder Point
  - In Stock: Quantity > Reorder Point

## Component Structure

### Apex Classes
- `InventoryManagerController.cls`: Provides server-side operations for:
  - Retrieving inventory items
  - Updating inventory status based on current quantities

### Lightning Web Components
- `inventoryManager`: Main component that provides the interface for:
  - Viewing inventory items
  - Filtering and searching
  - Creating and editing inventory records

## Technical Implementation

### Apex Controller

The `InventoryManagerController` class provides two main methods:
1. `getInventoryItems`: Retrieves all inventory items with key fields for display
2. `updateInventoryStatus`: Batch updates status fields based on quantity thresholds

### Lightning Web Component

The inventory manager component:
1. Displays inventory data in a responsive table with color-coded status indicators
2. Provides filtering and searching capabilities
3. Uses a modal interface for adding/editing inventory items
4. Handles record updates with automatic status calculation
5. Refreshes data after updates to ensure accuracy

## Custom Object

This solution relies on a custom object called `Inventory_Item__c` with the following fields:
- `Product_Name__c`: Text field for the product name
- `SKU__c`: Text field for the stock keeping unit
- `Current_Quantity__c`: Number field for the current inventory level
- `Reorder_Point__c`: Number field for the threshold that triggers "Low Stock" status
- `Last_Restock_Date__c`: Date field for tracking when items were last restocked
- `Status__c`: Picklist field with values: "In Stock", "Low Stock", "Out of Stock"
- `Supplier__c`: Text or lookup field for the supplier information

## Installation

### Prerequisites
- Salesforce org with Lightning Experience enabled
- Basic understanding of Salesforce administration
- API version 51.0 or higher recommended

### Deployment Steps

1. First, create the custom object and fields:
   ```
   sfdx force:source:deploy -p force-app/main/default/objects
   ```

2. Deploy the Apex controller:
   ```
   sfdx force:source:deploy -p force-app/main/default/classes
   ```

3. Deploy the Lightning Web Component:
   ```
   sfdx force:source:deploy -p force-app/main/default/lwc
   ```

4. Add the component to relevant Lightning pages:
   - Navigate to Lightning App Builder
   - Edit the desired page
   - Drag the "inventoryManager" component onto the page
   - Save and activate the page

### Configuration

1. Ensure users have access to:
   - The Inventory_Item__c object and fields
   - The InventoryManagerController Apex class

2. Configure field-level security for all Inventory_Item__c fields
3. Set up object and tab visibility in profiles or permission sets

## Usage

### Viewing Inventory
1. Navigate to the page containing the Inventory Manager component
2. View all inventory items in the table
3. Use the status filter to see only items with a specific status
4. Use the search box to find specific products by name or SKU

### Managing Inventory
1. Click "New Item" to add a new inventory item
2. Fill in all required fields and click "Save"
3. Use the row actions menu (dropdown) to edit existing items
4. Use the "Restock" action to quickly update inventory quantities

### Status Management
The system automatically calculates status based on quantities:
- When inventory drops to or below zero, status changes to "Out of Stock"
- When inventory is between 1 and the reorder point, status changes to "Low Stock"
- When inventory exceeds the reorder point, status changes to "In Stock"

## Development Notes

- The component uses `with sharing` to respect Salesforce sharing rules
- Status is calculated automatically during save operations
- The component provides toast notifications for user feedback
- Color-coding provides visual cues for inventory status

## Recommended Enhancements

Potential future enhancements for this project:
- Automated reorder processes when items reach low stock
- Historical tracking of inventory levels
- Reporting and analytics on inventory trends
- Barcode scanning integration for mobile inventory updates
- Integration with order management systems
