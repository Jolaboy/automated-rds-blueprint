/*2. Isolated Transactional Seeding Script (02_seeding.sql)This PL/pgSQL block guarantees atomic, isolated data seeding. 
If any insertion fails, the entire batch rolls back, keeping production or staging environments clean. */

DO $$
DECLARE
    v_customer_id UUID;
    v_order_id UUID;
    i INT;
BEGIN
    RAISE NOTICE 'Starting isolated transactional seeding...';

    -- Seed Customers and capture IDs dynamically
    FOR i IN 1..100 LOOP
        INSERT INTO customers (first_name, last_name, email)
        VALUES (
            'User_' || i, 
            'Test_' || i, 
            'user_' || i || '@automatedblueprint.internal'
        )
        RETURNING customer_id INTO v_customer_id;

        -- Create a corresponding order for every second customer to simulate real-world data distribution
        IF i % 2 = 0 THEN
            INSERT INTO orders (customer_id, total_amount, status, metadata)
            VALUES (
                v_customer_id, 
                250.50, 
                'Completed', 
                '{"source": "automated_test_suite", "tier": "premium"}'::jsonb
            )
            RETURNING order_id INTO v_order_id;

            -- Seed related multi-table items
            INSERT INTO order_items (order_id, product_sku, quantity, unit_price)
            VALUES 
                (v_order_id, 'SKU-AWS-RDS-01', 2, 100.00),
                (v_order_id, 'SKU-AWS-RDS-02', 1, 50.50);
        END IF;
    END LOOP;

    RAISE NOTICE 'Seeding completed successfully. Committing transaction.';
EXCEPTION
    WHEN OTHERS THEN
        -- Re-raising inside the block ensures the surrounding transaction rolls back.
        -- ROLLBACK is not permitted inside a PL/pgSQL block and would raise 2D000.
        RAISE EXCEPTION 'An error occurred during seeding. Rolling back changes. Error: %', SQLERRM;
END $$;