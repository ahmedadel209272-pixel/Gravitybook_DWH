-- =============================================================================
-- [4] INDEXES
-- =============================================================================

-- Dim_Customer - fast BK lookup for ETL joins
CREATE NONCLUSTERED INDEX IX_Dim_Customer_BK
    ON dbo.Dim_Customer (Customer_BK );
GO

-- Dim_Book
CREATE NONCLUSTERED INDEX IX_Dim_Book_BK
    ON dbo.Dim_Book (Book_ID_BK);
GO

-- Dim_Author
CREATE NONCLUSTERED INDEX IX_Dim_Author_BK
    ON dbo.Dim_Author (Author_BK);
GO

-- Dim_Address
CREATE NONCLUSTERED INDEX IX_Dim_Address_BK
    ON dbo.Dim_Address (Address_BK);
GO

-- Dim_Ship_Method
CREATE NONCLUSTERED INDEX IX_Dim_ShipMethod_BK
    ON dbo.Dim_Ship_Method (Method_ID_BK);
GO

-- Dim_Cust_Add - composite for customer+address lookup
CREATE NONCLUSTERED INDEX IX_Dim_CustAdd
    ON dbo.Dim_Cust_Add (Customer_ID, Address_ID);
GO

-- Dim_Book_Author bridge - both directions
CREATE NONCLUSTERED INDEX IX_BookAuthor_BookKey
    ON dbo.Dim_Book_Author (Book_Key_FK);
GO