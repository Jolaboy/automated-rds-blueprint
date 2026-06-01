/*3. Database Tuning & Multi-Table Indexing (03_tuning.sql)
For secure, high-throughput cloud environments, standard indexes aren't enough.
We need to optimize for write-concurrency and target multi-table join paths.*/

-- 1. Foreign Key Indexes (Crucial for preventing sequential scans during JOINs)
CREATE INDEX idx_orders_customer_id ON orders(customer_id);
CREATE INDEX idx_order_items_order_id ON order_items(order_id);

-- 2. Composite Index for High-Throughput Range Queries
-- Optimizes queries looking for orders by a specific customer within a date range
CREATE INDEX idx_orders_customer_date ON orders(customer_id, order_date DESC);

-- 3. Partial Indexing for Performance Tuning
-- Indexing only active transactions slims down the index size dramatically on RDS
CREATE INDEX idx_orders_active_status ON orders(status) 
WHERE status IN ('Pending', 'Processing');

-- 4. Expression / JSONB Indexing
-- Optimizes lookups inside the JSONB metadata field without scanning the entire table
CREATE INDEX idx_orders_metadata_source ON orders USING gin ((metadata -> 'source'));