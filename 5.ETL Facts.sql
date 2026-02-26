-- =============================================================================
-- ETL - FACT TABLE LOADS  
-- =============================================================================

-- Fact_Order_Line
-- Grain   : one row per order_line.line_id
-- Date key: YYYYMMDD integer derived from cust_order.order_date
-- Time key: defaulted to @DefaultTimeKey (00:00:00) - no time in OLTP source
-- Qty     : defaulted to 1 (column not present in OLTP order_line table)
-- Ship_Method_Cost : copied from Dim_Ship_Method.Cost at load time (denormalized)
-- Total_Price      : (Price x Qty) + Ship_Method_Cost
-- ===========================================================================

DECLARE @DefaultTimeKey INT = 0;
-- NOTE: Set @DefaultTimeKey to match the TimeSK value for 00:00:00
--       in your DimTime table after you populate it.

INSERT INTO BookstoreDWH.dbo.Fact_Order_Line
       (Order_Line_BK,Order_id_BK , FK_Book, FK_Customer,FK_Address,FK_Ship_Method, FK_Date, FK_Time,
        Ship_Method_Cost, Price, Qty, Total_Price
        )
SELECT
    ol.line_id,
    co.order_id,
    b.Book_Key_PK,
    c.Customer_PK,
    co.dest_address_id,
    co.shipping_method_id,
    dd.DateSK,
    dt.TimeSK,
    sm.Cost,                                               -- Ship_Method_Cost from Dim_Ship_Method
    ol.price,                                              -- Unit price
    1,                                                     -- Qty defaulted to 1
    (ol.price * 1) + sm.Cost                             -- Total_Price = (Price x Qty) + Ship_Method_Cost
FROM   gravity_books.dbo.order_line  AS ol
JOIN   gravity_books.dbo.cust_order  AS co  
    ON co.order_id = ol.order_id
JOIN   BookstoreDWH.dbo.Dim_Book     AS b   
    ON b.Book_ID_BK = ol.book_id 
JOIN   BookstoreDWH.dbo.Dim_Customer AS c   
    ON c.Customer_BK = co.customer_id      
JOIN   BookstoreDWH.dbo.Dim_Ship_Method sm  
    ON sm.Method_ID_BK = co.shipping_method_id 
JOIN   BookstoreDWH.dbo.Dim_Address ad  
    ON ad.Address_BK = co.dest_address_id 
JOIN   BookstoreDWH.dbo.DimDate dd  
    ON CAST(dd.order_date AS DATE) = CAST(co.order_date AS DATE)
JOIN   BookstoreDWH.dbo.DimTime dt  
    ON CAST(dt.order_time AS TIME(0)) = CAST(co.order_date AS TIME(0))
    

-- ===========================================================================
-- Fact_Order_Life_Cycle
-- Grain   : one row per cust_order.order_id

--   'Order Received'       -> FK_Date/Time_Ordered_Received
--   'Pending'              -> FK_Date/Time_Pending
--   'Delivery In Progress' -> FK_Date/Time_Delivery_In_Progress
--   'Delivered'            -> FK_Date/Time_Delivered
--   'Cancelled'            -> FK_Date/Time_Cancelled
--   'Returned'             -> FK_Date/Time_Returned
-- ===========================================================================
INSERT INTO Fact_Order_Life_Cycle
(
    Order_BK,
    FK_Customer,
    FK_Shipping_Method,
    FK_Date_Ordered_Received,
    FK_Time_Ordered_Received
)
SELECT
    co.order_id AS Order_BK,

    dc.Customer_PK,
    ds.Method_Key_PK,

    d.DateSK,
    t.TimeSK

FROM gravity_books.dbo.cust_order co
-- Lookup Customer
JOIN Dim_Customer dc
    ON co.customer_id = dc.Customer_BK
-- Lookup Shipping
JOIN Dim_Ship_Method ds
    ON co.shipping_method_id = ds.Method_ID_BK
-- Get Ordered status only
JOIN gravity_books.dbo.order_history oh
    ON co.order_id = oh.order_id AND oh.status_id = 1
-- Date Lookup
JOIN DimDate d
    ON CAST(oh.status_date AS DATE ) = d.order_date
-- Time Lookup
JOIN DimTime t
    ON CAST(oh.status_date AS TIME(0)) = t.order_time
-- Prevent duplicates
WHERE NOT EXISTS (
    SELECT 1
    FROM Fact_Order_Life_Cycle f
    WHERE f.Order_BK = co.order_id
);

UPDATE f
SET
    f.FK_Date_Pending = d.DateSK,
    f.FK_Time_Pending = t.TimeSK

FROM Fact_Order_Life_Cycle f
JOIN gravity_books.dbo.order_history oh
    ON f.Order_BK = oh.order_id AND oh.status_id = 2
JOIN DimDate d
    ON CAST(oh.status_date AS DATE) = d.order_date
JOIN DimTime t
    ON CAST(oh.status_date AS TIME(0)) = t.order_time
WHERE f.FK_Date_Pending IS NULL;


UPDATE f
SET
    f.FK_Date_Delivery_In_Progress = d.DateSK,
    f.FK_Time_Delivery_In_Progress = t.TimeSK

FROM Fact_Order_Life_Cycle f
JOIN gravity_books.dbo.order_history oh
    ON f.Order_BK = oh.order_id AND oh.status_id = 3
JOIN DimDate d
    ON CAST(oh.status_date AS DATE) = d.order_date
JOIN DimTime t
    ON CAST(oh.status_date AS TIME(0)) = t.order_time
WHERE f.FK_Date_Delivery_In_Progress IS NULL;


UPDATE f
SET
    f.FK_Date_Delivered = d.DateSK,
    f.FK_Time_Delivered = t.TimeSK

FROM Fact_Order_Life_Cycle f
JOIN gravity_books.dbo.order_history oh
    ON f.Order_BK = oh.order_id AND oh.status_id = 4
JOIN DimDate d
    ON CAST(oh.status_date AS DATE) = d.order_date
JOIN DimTime t
    ON CAST(oh.status_date AS TIME(0)) = t.order_time
WHERE f.FK_Time_Delivered IS NULL;


UPDATE f
SET
    f.FK_Date_Cancelled = d.DateSK,
    f.FK_Time_Cancelled = t.TimeSK

FROM Fact_Order_Life_Cycle f
JOIN gravity_books.dbo.order_history oh
    ON f.Order_BK = oh.order_id AND oh.status_id = 5
JOIN DimDate d
    ON CAST(oh.status_date AS DATE) = d.order_date
JOIN DimTime t
    ON CAST(oh.status_date AS TIME(0)) = t.order_time
WHERE f.FK_Date_Cancelled IS NULL;


UPDATE f
SET
    f.FK_Date_Returned = d.DateSK,
    f.FK_Time_Returned = t.TimeSK

FROM Fact_Order_Life_Cycle f
JOIN gravity_books.dbo.order_history oh
    ON f.Order_BK = oh.order_id AND oh.status_id = 6
JOIN DimDate d
    ON CAST(oh.status_date AS DATE) = d.order_date
JOIN DimTime t
    ON CAST(oh.status_date AS TIME(0)) = t.order_time
WHERE f.FK_Date_Returned IS NULL;


