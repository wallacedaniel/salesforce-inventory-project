public class InventoryStatusUpdater implements Schedulable {
    public void execute(SchedulableContext ctx) {
        InventoryManagerController.updateInventoryStatus();
    }
}