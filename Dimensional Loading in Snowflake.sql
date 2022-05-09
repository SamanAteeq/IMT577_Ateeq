Use Database IMT577_DW_SAMAN_ATEEQ;


--Create Dim_Product
CREATE OR REPLACE TABLE Dim_Product(
     DimProductID INTEGER IDENTITY(1,1) CONSTRAINT PK_DimProductID PRIMARY KEY NOT NULL --Surrogate Key
	,SourceProductID INTEGER 
    ,SourceProductTypeID INTEGER 
    ,SourceProductCategoryID INTEGER
    ,ProductName VARCHAR(255)     --Natural Key
    ,ProductType VARCHAR(255) 
    ,ProductCategory VARCHAR(255) 
    ,ProductRetailPrice FLOAT 
    ,ProductWholesalePrice FLOAT 
    ,ProductCost FLOAT 
    ,ProductRetailProfit FLOAT 
    ,ProductWholesaleUnitPrice FLOAT
    ,ProductProfitMarginUnitPercent FLOAT
);


--Loading Unknown Numbers || Dim_Product
INSERT INTO Dim_Product
(
     DimProductID 
	,SourceProductID 
    ,SourceProductTypeID 
    ,SourceProductCategoryID 
    ,ProductName 
    ,ProductType 
    ,ProductCategory 
    ,ProductRetailPrice
    ,ProductWholesalePrice 
    ,ProductCost 
    ,ProductRetailProfit
    ,ProductWholesaleUnitPrice 
    ,ProductProfitMarginUnitPercent
)
VALUES
( 
     -1
    ,-1
    ,-1
    ,-1
    ,'Unknown' 
    ,'Unknown'
    ,'Unknown'
    ,0
    ,0
    ,0
    ,0
    ,0
    ,0
);

INSERT INTO Dim_Product
(
    
	 SourceProductID 
    ,SourceProductTypeID 
    ,SourceProductCategoryID 
    ,ProductName 
    ,ProductType 
    ,ProductCategory 
    ,ProductRetailPrice
    ,ProductWholesalePrice 
    ,ProductCost 
    ,ProductRetailProfit
    ,ProductWholesaleUnitPrice 
    ,ProductProfitMarginUnitPercent
)
	SELECT 
	  sp.ProductID,
      sp.ProductTypeID,
      spc.ProductCategoryID,
      sp.Product,
      spt.ProductType,
      spc.ProductCategory,
      sp.Price,
      sp.WholesalePrice,
      sp.Cost,
     (sp.Price - sp.Cost) AS "ProductRetailProfit",
	 (sp.WholesalePrice - sp.Cost) AS "ProductWholesaleUnitProfit",
	((sp.WholesalePrice - sp.Cost) / sp.WholesalePrice) * 100 AS "ProductProfitMarginUnitPercent"      
FROM
	STAGE_PRODUCT sp,
	STAGE_PRODUCTTYPE spt,
	STAGE_PRODUCTCATEGORY spc
WHERE
	sp.PRODUCTTYPEID = spt.PRODUCTTYPEID
	AND spt.PRODUCTCATEGORYID = spc.PRODUCTCATEGORYID;


--Performing SELECT query on Dim_Product
SELECT * FROM Dim_Product


-- Create Dim_Location
CREATE OR REPLACE TABLE Dim_Location(
     DimLocationID INT IDENTITY(1,1) CONSTRAINT PK_Dim_Location PRIMARY KEY NOT NULL --Surrogate Key
    ,SourceLocationID VARCHAR(255)  --Natural Key
    ,PostalCode VARCHAR(255) 
    ,Address VARCHAR(255) 
    ,City VARCHAR(255) 
    ,Region VARCHAR(255) 
    ,Country VARCHAR(255) 
   );


--Loading Unknown Members || Dim_Location
INSERT INTO Dim_Location
(
     DimLocationID
    ,SourceLocationID 
    ,PostalCode
    ,Address 
    ,City
    ,Region 
    ,Country
)
VALUES
( 
     -1
    ,'Unknown' 
    ,'Unknown' 
    ,'Unknown' 
    ,'Unknown' 
    ,'Unknown' 
    ,'Unknown' 
);

INSERT INTO Dim_Location
(
     
     SourceLocationID 
    ,PostalCode
    ,Address 
    ,City
    ,Region 
    ,Country
) 
( SELECT 
     CustomerID as "SourceLocationID",
     PostalCode,
     Address,
     City,
     StateProvince,
     Country
  FROM
  STAGE_Customer
  Union 
   SELECT
     StoreID as "SourceLocationID",
     PostalCode,
     Address,
     City,
     StateProvince,
     Country
  FROM 
  STAGE_Store
  Union
   SELECT 
     ResellerID as "SourceLocationID",
     PostalCode,
     Address,
     City,
     StateProvince,
     Country
   FROM 
   STAGE_Reseller);


--Performing SELECT query on Dim_Location
SELECT * FROM Dim_Location


--Create Dim_Store 
CREATE OR REPLACE TABLE Dim_Store(
     DimStoreID INT IDENTITY(1,1) CONSTRAINT PK_Dim_Store PRIMARY KEY NOT NULL --Surrogate Key
	,DimLocationID INTEGER CONSTRAINT FK_DimStore_Location FOREIGN KEY REFERENCES Dim_Location(DimLocationID) Not Null
    ,SourceStoreID INTEGER  
    ,StoreNumber INTEGER    --Natural Key
    ,StoreManager VARCHAR(255) 
);


--Loading Unknown Members || Dim_Store
INSERT INTO Dim_Store
(
     DimStoreID
	,DimLocationID
    ,SourceStoreID 
    ,StoreNumber 
    ,StoreManager 
)
VALUES
( 
     -1
    ,-1
    ,-1
    ,-1
    ,'Unknown'
);

INSERT INTO Dim_Store
(
     
     DimLocationID
    ,SourceStoreID 
    ,StoreNumber 
    ,StoreManager
)  
SELECT 
     dl.DimLocationID,
     ss.StoreID,
     ss.StoreNumber,
     ss.StoreManager

FROM STAGE_Store ss, Dim_Location dl
WHERE ss.StoreID= dl.SourceLocationID


--Performing SELECT query on Dim_Store
SELECT * FROM Dim_Store


-- Create Dim_Reseller
CREATE OR REPLACE TABLE Dim_Reseller(
     DimResellerID INT IDENTITY(1,1) CONSTRAINT PK_Dim_Reseller PRIMARY KEY NOT NULL --Surrogate Key
	,DimLocationID INT CONSTRAINT FK_DimReseller_Location FOREIGN KEY REFERENCES Dim_Location(DimLocationID) Not Null
    ,SourceResellerID VARCHAR(255) 
    ,ResellerName VARCHAR(255)      --Natural Key
    ,ContactName VARCHAR(255) 
    ,PhoneNumber VARCHAR(255) 
    ,Email VARCHAR(255) 
);


--Loading Unknown Members || Dim_Reseller
INSERT INTO Dim_Reseller
(
     DimResellerID
	,DimLocationID
    ,SourceResellerID
    ,ResellerName
    ,ContactName
    ,PhoneNumber
    ,Email
)
VALUES
( 
     -1
    ,-1
    ,'Unknown' 
    ,'Unknown' 
    ,'Unknown'
    ,'Unknown' 
    ,'Unknown' 
);

INSERT INTO Dim_Reseller
(   
     DimLocationID
    ,SourceResellerID
    ,ResellerName
    ,ContactName
    ,PhoneNumber
    ,Email
)
SELECT 
     dl.DimLocationID,
     sr.ResellerID,
     sr.ResellerName,
     sr.Contact,
     sr.PhoneNumber,
     sr.EmailAddress

FROM STAGE_Reseller sr, Dim_Location dl
WHERE sr.ResellerID= dl.SourceLocationID


--Performing SELECT query 
SELECT * FROM Dim_Reseller


-- Create Dim_Customer
CREATE OR REPLACE TABLE Dim_Customer(
     DimCustomerID INT IDENTITY(1,1) CONSTRAINT PK_Dim_Customer PRIMARY KEY NOT NULL --Surrogate Key
	,DimLocationID INTEGER CONSTRAINT FK_DimCustomer_Location FOREIGN KEY REFERENCES Dim_Location(DimLocationID) Not Null
    ,SourceCustomerID VARCHAR(255)  --Natural Key
    ,FullName VARCHAR(255) 
    ,FirstName VARCHAR(255)  
    ,LastName VARCHAR(255) 
    ,Gender VARCHAR(255) 
    ,EmailAddress VARCHAR(255) 
    ,PhoneNumber VARCHAR(255) 
);


--Loading Unknown Members || Dim_Reseller
INSERT INTO Dim_Customer
(
     DimCustomerID 
	,DimLocationID 
    ,SourceCustomerID 
    ,FullName
    ,FirstName 
    ,LastName
    ,Gender
    ,EmailAddress 
    ,PhoneNumber 
)
VALUES
( 
     -1
    ,-1
    ,'Unknown'
    ,'Unknown'
    ,'Unknown' 
    ,'Unknown' 
    ,'Unknown'
    ,'Unknown' 
    ,'Unknown' 
);

INSERT INTO Dim_Customer
(
     DimLocationID 
    ,SourceCustomerID 
    ,FullName
    ,FirstName 
    ,LastName
    ,Gender
    ,EmailAddress 
    ,PhoneNumber  
)
SELECT 
    dl.DimLocationID,
    sc.CustomerID,
    sc.FirstName || ' ' || sc.LastName,
    sc.FirstName,
    sc.LastName,
    sc.Gender,
    sc.EmailAddress,
    sc.PhoneNumber
FROM STAGE_Customer sc, Dim_Location dl
WHERE sc.CustomerID= dl.SourceLocationID


--Performing SELECT query on Dim_Customer
SELECT * FROM Dim_Customer


-- Create Dim_Channel
CREATE OR REPLACE TABLE Dim_Channel(
     DimChannelID INT IDENTITY(1,1) CONSTRAINT PK_Dim_Channel PRIMARY KEY NOT NULL --Surrogate Key
    ,SourceChannelID INTEGER  --Natural Key
    ,SourceChannelCategoryID INTEGER 
    ,ChannelName VARCHAR(255) 
    ,ChannelCategory VARCHAR(255)

   );


--Loading Unknown Members || Dim_Channel
INSERT INTO Dim_Channel
(
     DimChannelID 
    ,SourceChannelID 
    ,SourceChannelCategoryID 
    ,ChannelName 
    ,ChannelCategory
)
VALUES
( 
     -1
    ,-1
    ,-1
    ,'Unknown'
    ,'Unknown'
);

INSERT INTO Dim_Channel
(
     SourceChannelID 
    ,SourceChannelCategoryID 
    ,ChannelName 
    ,ChannelCategory
)
SELECT 
     sc.ChannelID,
     sc.ChannelCategoryID,
     sc.Channel,
     scc.ChannelCategory

FROM STAGE_CHANNEL sc, STAGE_ChannelCategory  scc
WHERE sc.ChannelCategoryID = scc.ChannelCategoryID


--Performing SELECT query on Dim_Channel
SELECT * FROM Dim_Channel
