-- =============================================================================
-- [2] DIMENSION TABLE DDL
-- =============================================================================

-- DimDate  (populated by user)

-- DimTime  (populated by user)

-- script will be attached !!

-- -----------------------------------------------------------------------------
-- Dim_Ship_Method 
-- -----------------------------------------------------------------------------
IF OBJECT_ID('dbo.Dim_Ship_Method', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Dim_Ship_Method (
        Method_Key_PK   INT            NOT NULL IDENTITY(1,1),
        Method_ID_BK    INT            NOT NULL,   -- NK: shipping_method.method_id
        Method_Name     NVARCHAR(100)  NOT NULL,
        Cost            DECIMAL(10,2)  NOT NULL,
        CONSTRAINT PK_Dim_Ship_Method PRIMARY KEY CLUSTERED (Method_Key_PK)
    );
END
GO

-- -----------------------------------------------------------------------------
-- Dim_Address  ( country_name denormalized in)
-- -----------------------------------------------------------------------------
IF OBJECT_ID('dbo.Dim_Address', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Dim_Address (
        Address_PK      INT            NOT NULL IDENTITY(1,1),
        Address_BK      INT            NOT NULL UNIQUE ,   -- NK: address.address_id
        Street_Number   NVARCHAR(20)   NOT NULL,
        Street_Name     NVARCHAR(150)  NOT NULL,
        City            NVARCHAR(100)  NOT NULL,
        Country_ID      INT            NOT NULL,
        Country_Name    NVARCHAR(100)  NOT NULL,   -- Denormalized from country table
        CONSTRAINT PK_Dim_Address PRIMARY KEY CLUSTERED (Address_PK)
    );
END
GO

-- -----------------------------------------------------------------------------
-- Dim_Cust_Add  ( resolves customer-address relationship)
-- -----------------------------------------------------------------------------
IF OBJECT_ID('dbo.Dim_Cust_Add', 'U') IS NULL
BEGIN
        Create TABLE dbo.Dim_Cust_Add (
        Cust_Add_PK     INT          NOT NULL IDENTITY(1,1),
        Customer_ID     INT          NOT NULL UNIQUE,   -- NK: customer_address.customer_id
        Address_ID      INT          NOT NULL UNIQUE,   -- NK: customer_address.address_id
        Status_ID_BK    INT          NOT NULL,   -- Renamed: BK for address_status.status_id
        Address_Status  NVARCHAR(50) NOT NULL,
        CONSTRAINT PK_Dim_Cust_Add PRIMARY KEY CLUSTERED (Cust_Add_PK),
        CONSTRAINT UQ_Cust_Address UNIQUE (Customer_ID, Address_ID),
        CONSTRAINT FK_CUST  FOREIGN KEY (Customer_ID)   REFERENCES dbo.Dim_Customer (Customer_BK),
        CONSTRAINT FK_ADD   FOREIGN KEY (Address_ID)   REFERENCES dbo.Dim_Address  (Address_BK)
        );
END
GO

-- -----------------------------------------------------------------------------
-- Dim_Customer  
-- NOTE: address_id and status_id retained per updated schema 
--       Full address detail lives in Dim_Cust_Add; these are FK references only
-- -----------------------------------------------------------------------------
IF OBJECT_ID('dbo.Dim_Customer', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Dim_Customer (
        Customer_PK     INT            NOT NULL IDENTITY(1,1),
        Customer_BK     INT            NOT NULL,   -- NK: customer.customer_id
        First_Name      NVARCHAR(100)  NOT NULL,
        Last_Name       NVARCHAR(100)  NOT NULL,
        Email           NVARCHAR(200)  NOT NULL,
        Address_ID      INT            NULL,        -- FK ref: customer_address.address_id
        Status_ID       INT            NULL,        -- FK ref: address_status.status_id
        SSC             INT            NULL
        CONSTRAINT PK_Dim_Customer PRIMARY KEY CLUSTERED (Customer_PK),
        CONSTRAINT UQ_Customer_ID UNIQUE (Customer_BK)
    );
END
GO
-- -----------------------------------------------------------------------------
-- Dim_Author 
-- -----------------------------------------------------------------------------
IF OBJECT_ID('dbo.Dim_Author', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Dim_Author (
        Author_PK       INT            NOT NULL IDENTITY(1,1),
        Author_BK       INT            NOT NULL,   -- NK: author.author_id
        Author_Name     NVARCHAR(200)  NOT NULL,
        CONSTRAINT PK_Dim_Author PRIMARY KEY CLUSTERED (Author_PK)
    );
END
GO

-- -----------------------------------------------------------------------------
-- Dim_Book  (publisher_name and language denormalized in)
-- -----------------------------------------------------------------------------
IF OBJECT_ID('dbo.Dim_Book', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Dim_Book (
        Book_Key_PK      INT            NOT NULL IDENTITY(1,1),
        Book_ID_BK       INT            NOT NULL,   -- NK: book.book_id
        Title            NVARCHAR(500)  NOT NULL,
        ISBN13           NVARCHAR(20)   NULL,
        Language_ID      INT            NOT NULL,
        Language_Code    NCHAR(8)       NOT NULL,
        Language_Name    NVARCHAR(100)  NOT NULL,
        Num_Pages        SMALLINT       NULL,
        Publication_Date DATE           NULL,
        Publisher_ID     INT            NOT NULL,
        Publisher_Name   NVARCHAR(200)  NOT NULL,   -- Denormalized from publisher table
        CONSTRAINT PK_Dim_Book PRIMARY KEY CLUSTERED (Book_Key_PK)
    );
END
GO

-- -----------------------------------------------------------------------------
-- Dim_Book_Author  (Bridge Table - resolves M:M between Dim_Book and Dim_Author)
-- WeightingFactor distributes analytical credit equally across authors per book
-- -----------------------------------------------------------------------------
IF OBJECT_ID('dbo.Dim_Book_Author', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Dim_Book_Author (
        Book_Author_PK    INT           NOT NULL IDENTITY(1,1),
        Book_Key_FK       INT           NOT NULL,   -- -> Dim_Book.Book_Key_PK (IsCurrent=1)
        Author_Key_FK     INT           NOT NULL,   -- -> Dim_Author.Author_PK  (IsCurrent=1)
        Book_BK           INT           NOT NULL,   -- Denormalized BK for ETL convenience
        Author_BK         INT           NOT NULL,
        WeightingFactor   DECIMAL(3,2)  NOT NULL DEFAULT 1.00,
        DWH_InsertDate    DATETIME      NOT NULL DEFAULT GETDATE(),
        CONSTRAINT PK_Dim_Book_Author   PRIMARY KEY CLUSTERED (Book_Author_PK),
        CONSTRAINT FK_BookAuthor_Book   FOREIGN KEY (Book_Key_FK)   REFERENCES dbo.Dim_Book   (Book_Key_PK),
        CONSTRAINT FK_BookAuthor_Author FOREIGN KEY (Author_Key_FK) REFERENCES dbo.Dim_Author (Author_PK),
        CONSTRAINT UQ_BookAuthor        UNIQUE (Book_Key_FK, Author_Key_FK)
    );
END
GO
