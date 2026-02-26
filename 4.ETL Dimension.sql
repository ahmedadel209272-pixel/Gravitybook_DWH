-- =============================================================================
--    ETL - DIMENSION LOADS  

--    EXECUTION ORDER:
--    Dim_Ship_Method -> Dim_Address -> Dim_Cust_Add
--    -> Dim_Customer -> Dim_Author -> Dim_Book -> Dim_Book_Author (bridge)
-- =============================================================================
-- ETL-1 : Dim_Ship_Method
-- ===========================================================================
INSERT INTO BookstoreDWH.dbo.Dim_Ship_Method
       (Method_ID_BK, Method_Name, Cost )
SELECT src.method_id,
       src.method_name,
       src.cost
FROM   gravity_books.dbo.shipping_method src

-- ===========================================================================
-- ETL-2 : Dim_Address
-- ===========================================================================
INSERT INTO BookstoreDWH.dbo.Dim_Address
       (Address_BK, Street_Number, Street_Name, City,
        Country_ID, Country_Name )
SELECT src.address_id,
       src.street_number,
       src.street_name,
       src.city,
       ctr.country_id,
       ctr.country_name
FROM   gravity_books.dbo.address   src
JOIN   gravity_books.dbo.country   ctr 
ON ctr.country_id = src.country_id
-- ===========================================================================
-- ETL-3 : Dim_Cust_Add
-- ===========================================================================
INSERT INTO BookstoreDWH.dbo.Dim_Cust_Add
       (Customer_ID, Address_ID, Status_ID, Address_Status)
SELECT ca.customer_id,
       ca.address_id,
       ca.status_id,       -- maps to Status_ID_BK
       ads.address_status
FROM   gravity_books.dbo.customer_address  AS ca
JOIN   gravity_books.dbo.address_status    AS ads 
    ON ads.status_id = ca.status_id

-- ===========================================================================
-- ETL-4 : Dim_Customer
-- ===========================================================================
INSERT INTO BookstoreDWH.dbo.Dim_Customer
       (Customer_BK, First_Name, Last_Name, Email )
SELECT src.customer_id,
       src.first_name,
       src.last_name,
       src.email
FROM   gravity_books.dbo.customer  src

-- ===========================================================================
-- ETL-5 : Dim_Author
-- ===========================================================================
INSERT INTO BookstoreDWH.dbo.Dim_Author
       (Author_BK, Author_Name)
SELECT src.author_id,
       src.author_name
FROM   gravity_books.dbo.author src

GO

-- ===========================================================================
-- ETL-6 : Dim_Book  (publisher_name + language denormalized in)
-- ===========================================================================
INSERT INTO BookstoreDWH.dbo.Dim_Book
       (Book_ID_BK, Title, ISBN13, Language_ID, Language_Code, Language_Name,
        Num_Pages, Publication_Date, Publisher_ID, Publisher_Name )
SELECT src.book_id,
       src.title,
       src.isbn13,
       lng.language_id,
       lng.language_code,
       lng.language_name,
       src.num_pages,
       src.publication_date,
       pub.publisher_id,
       pub.publisher_name
FROM   gravity_books.dbo.book              AS   src
JOIN   gravity_books.dbo.publisher         AS   pub 
    ON pub.publisher_id = src.publisher_id
JOIN   gravity_books.dbo.book_language     AS lng 
    ON lng.language_id  = src.language_id
GO

-- ===========================================================================
-- ETL-7 : Dim_Book_Author  (Bridge - must run AFTER Dim_Book and Dim_Author)
-- Weighting = 1 / number of authors on that book (equal credit split)
-- ===========================================================================
-- Insert new book-author combinations (using current surrogate keys)
INSERT INTO BookstoreDWH.dbo.Dim_Book_Author
       (Book_Key_FK, Author_Key_FK, Book_BK, Author_BK, WeightingFactor)
SELECT
    b.Book_Key_PK,
    a.Author_PK,
    src.book_id,
    src.author_id,
    CAST(1.0 / COUNT(*) OVER (PARTITION BY src.book_id) AS DECIMAL(5,4))
FROM   gravity_books.dbo.book_author  src
JOIN   BookstoreDWH.dbo.Dim_Book    AS  b  
    ON b.Book_ID_BK = src.book_id  
JOIN   BookstoreDWH.dbo.Dim_Author  AS  a  
    ON a.Author_BK  = src.author_id 
GO

