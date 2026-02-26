/*
================================================================================

  EXECUTION ORDER:
    1. Section [1]  - Create BookstoreDWH database
    2. Section [2]  - Create all Dimension tables
    3. Section [3]  - Create Fact tables
    4. Section [4]  - Create Indexes
    5. YOUR SCRIPTS - Populate DimDate and DimTime
    6. Section [5]  - Load Dimensions (run in this order):
                        ETL-1  Dim_Status
                        ETL-2  Dim_Ship_Method
                        ETL-3  Dim_Address
                        ETL-4  Dim_Cust_Add
                        ETL-5  Dim_Customer
                        ETL-6  Dim_Author
                        ETL-7  Dim_Book
                        ETL-8  Dim_Book_Author (bridge - must be last)
    7. Section [6]  - Load Facts:
                        ETL-9   Fact_Order_Line
                        ETL-10  Fact_Order_Life_Cycle (Step A then Step B)

  KEY DESIGN DECISIONS:
    - All dims use SCD Type 1: (Overwrite) No historical tracking for attribute changes.
    - Grain enforced via UNIQUE constraints: Order_Line_BK and Order_BK
    - Dim_Book_Author uses equal-weight distribution (1 / author count per book)
    - Dim_Customer retains Address_ID + Status_ID 
      These are sourced from the most recent customer_address record per customer
    - Fact_Order_Line new measures (per updated schema):
        Qty              = defaulted to 1 (not present in OLTP order_line)
        Ship_Method_Cost = denormalized from Dim_Ship_Method.Cost at load time
        Total_Price      = (Price x Qty) + Ship_Method_Cost
    - Country_Name and Publisher_Name are denormalized into their parent dims
      following standard DWH best practice (avoids snowflaking)

================================================================================
*/

-- =============================================================================
-- [1] CREATE DATABASE
-- =============================================================================

USE master;
GO

IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'BookstoreDWH')
BEGIN
    CREATE DATABASE BookstoreDWH;
END
GO

USE BookstoreDWH;
GO


