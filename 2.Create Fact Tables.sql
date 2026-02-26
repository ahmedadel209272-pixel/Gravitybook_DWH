-- =============================================================================
-- [3] FACT TABLE DDL
-- =============================================================================

-- Fact_Order_Line
-- Grain: one row per order (line_id & order_id)
-- -----------------------------------------------------------------------------
IF OBJECT_ID('dbo.Fact_Order_Line', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Fact_Order_Line (
        Sales_Order_PK      INT            NOT NULL IDENTITY(1,1),
        Order_line_BK       INT            NOT NULL,   -- NK: order_line.line_id
        Order_id_BK         INT            NOT NULL,
        FK_Book             INT            NOT NULL,
        FK_Customer         INT            NOT NULL,
        FK_Address          INT            NOT NULL,
        FK_Ship_Method      INT            NOT NULL,
        FK_Date             INT            NOT NULL,
        FK_Time             INT            NOT NULL,
        Ship_Method_Cost    DECIMAL(10,2)  NOT NULL,   -- Denormalized from Dim_Ship_Method at load time
        Price               DECIMAL(10,2)  NOT NULL,   -- Unit price from order_line
        Qty                 SMALLINT       NOT NULL DEFAULT 1,  -- Defaulted to 1 (not in OLTP source)
        Total_Price         DECIMAL(10,2)  NOT NULL,   -- Calculated: (Price x Qty) + Ship_Method_Cost

        CONSTRAINT PK_Fact_Order_Line   PRIMARY KEY CLUSTERED (Sales_Order_PK),
        CONSTRAINT FK_Book          FOREIGN KEY (FK_Book)     REFERENCES dbo.Dim_Book     (Book_Key_PK),
        CONSTRAINT FK_Address       FOREIGN KEY (FK_Address)  REFERENCES dbo.Dim_Address  (Address_PK),
        CONSTRAINT FK_Ship_Method   FOREIGN KEY (FK_Ship_Method) REFERENCES dbo.Dim_Ship_Method  (Method_Key_PK),
        CONSTRAINT FK_Customer      FOREIGN KEY (FK_Customer) REFERENCES dbo.Dim_Customer (Customer_PK),
        CONSTRAINT FK_Date          FOREIGN KEY (FK_Date)     REFERENCES dbo.DimDate     (DateSK),
        CONSTRAINT FK_Time          FOREIGN KEY (FK_Time)     REFERENCES dbo.DimTime     (TimeSK),
        CONSTRAINT UQ_Order         UNIQUE (Order_line_BK,Order_id_BK)    -- Grain enforcement
    );
END
GO

-- -----------------------------------------------------------------------------
-- Fact_Order_Life_Cycle
-- Grain: one row per order 
-- Status timestamp pairs are nullable - NULL means that milestone not yet reached
-- -----------------------------------------------------------------------------
IF OBJECT_ID('dbo.Fact_Order_Life_Cycle', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Fact_Order_Life_Cycle (
        Order_PK                        INT      NOT NULL IDENTITY(1,1),
        Order_BK                        INT      NOT NULL,   -- NK: cust_order.order_id

        FK_Customer                     INT      NOT NULL,
        FK_Shipping_Method              INT      NOT NULL,

        FK_Date_Ordered_Received        INT      NOT NULL,
        FK_Time_Ordered_Received        INT      NOT NULL,

        FK_Date_Pending                 INT      NULL,
        FK_Time_Pending                 INT      NULL,

        FK_Date_Delivery_In_Progress    INT      NULL,
        FK_Time_Delivery_In_Progress    INT      NULL,

        FK_Date_Delivered               INT      NULL,
        FK_Time_Delivered               INT      NULL,

        FK_Date_Cancelled               INT      NULL,
        FK_Time_Cancelled               INT      NULL,

        FK_Date_Returned                INT      NULL,
        FK_Time_Returned                INT      NULL,

        CONSTRAINT PK_Fact_OLC              PRIMARY KEY CLUSTERED (Order_PK),
        CONSTRAINT FK_OLC_Customer          FOREIGN KEY (FK_Customer)                       REFERENCES dbo.Dim_Customer   (Customer_PK),
        CONSTRAINT FK_OLC_ShipMethod        FOREIGN KEY (FK_Shipping_Method)                REFERENCES dbo.Dim_Ship_Method(Method_Key_PK),
        CONSTRAINT FK_OLC_DateOrdered       FOREIGN KEY (FK_Date_Ordered_Received)          REFERENCES dbo.DimDate(DateSK),
        CONSTRAINT FK_OLC_TimeOrdered       FOREIGN KEY (FK_Time_Ordered_Received)          REFERENCES dbo.DimTime(TimeSK),
        CONSTRAINT FK_OLC_DatePending       FOREIGN KEY (FK_Date_Pending)                   REFERENCES dbo.DimDate(DateSK),
        CONSTRAINT FK_OLC_TimePending       FOREIGN KEY (FK_Time_Pending)                   REFERENCES dbo.DimTime(TimeSK),
        CONSTRAINT FK_OLC_DateDIP           FOREIGN KEY (FK_Date_Delivery_In_Progress)      REFERENCES dbo.DimDate(DateSK),
        CONSTRAINT FK_OLC_TimeDIP           FOREIGN KEY (FK_Time_Delivery_In_Progress)      REFERENCES dbo.DimTime(TimeSK),
        CONSTRAINT FK_OLC_DateDelivered     FOREIGN KEY (FK_Date_Delivered)                 REFERENCES dbo.DimDate(DateSK),
        CONSTRAINT FK_OLC_TimeDelivered     FOREIGN KEY (FK_Time_Delivered)                 REFERENCES dbo.DimTime(TimeSK),
        CONSTRAINT FK_OLC_DateCancelled     FOREIGN KEY (FK_Date_Cancelled)                 REFERENCES dbo.DimDate(DateSK),
        CONSTRAINT FK_OLC_TimeCancelled     FOREIGN KEY (FK_Time_Cancelled)                 REFERENCES dbo.DimTime(TimeSK),
        CONSTRAINT FK_OLC_DateReturned      FOREIGN KEY (FK_Date_Returned)                  REFERENCES dbo.DimDate(DateSK),
        CONSTRAINT FK_OLC_TimeReturned      FOREIGN KEY (FK_Time_Returned)                  REFERENCES dbo.DimTime(TimeSK),
        CONSTRAINT UQ_OLC_OrderBK           UNIQUE (Order_BK)   -- Grain enforcement
    );
END
GO
