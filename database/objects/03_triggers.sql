-- ============================================================
-- SupplyChainIQ
-- Automated Inventory Reorder Alert
-- ============================================================

USE supply_chain;

DELIMITER $$

CREATE TRIGGER trg_inventory_low_stock
AFTER UPDATE ON inventory
FOR EACH ROW
BEGIN

    IF NEW.quantity_on_hand <= NEW.reorder_level
       AND OLD.quantity_on_hand > OLD.reorder_level THEN

        INSERT INTO reorder_alerts
        (
            product_id,
            warehouse_id,
            quantity_on_hand,
            reorder_level
        )
        VALUES
        (
            NEW.product_id,
            NEW.warehouse_id,
            NEW.quantity_on_hand,
            NEW.reorder_level
        );

    END IF;

END$$

DELIMITER ;