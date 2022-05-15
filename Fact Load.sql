Use Database IMT577_DW_SAMAN_ATEEQ;

--Creating and Inserting Fact_SalesActual
Drop Table Fact_SalesActual
CREATE OR REPLACE TABLE Fact_SalesActual(
     DimProductID INTEGER CONSTRAINT FK_FactSalesActual_ProductID FOREIGN KEY REFERENCES Dim_Product(DimProductID) Not Null
    ,DimStoreID INTEGER CONSTRAINT FK_FactSalesActual_StoreID FOREIGN KEY REFERENCES Dim_Store(DimStoreID) Not Null
    ,DimResellerID INTEGER CONSTRAINT FK_FactSalesActual_ResellerID FOREIGN KEY REFERENCES Dim_Reseller(DimResellerID) Not Null
    ,DimCustomerID INTEGER CONSTRAINT FK_FactSalesActual_CustomerID FOREIGN KEY REFERENCES Dim_Customer(DimCustomerID) Not Null
    ,DimChannelID INTEGER CONSTRAINT FK_FactSalesActual_ChannelID FOREIGN KEY REFERENCES Dim_Channel(DimChannelID) Not Null
    ,DimSaleDateID NUMBER(9) CONSTRAINT FK_FactSalesActual_DateID FOREIGN KEY REFERENCES Dim_Date(Date_PKEY) Not Null
    ,DimLocationID INTEGER CONSTRAINT FK_FactSalesActual_LocationID FOREIGN KEY REFERENCES Dim_Location(DimLocationID) Not Null
	,SourceSalesHeaderID INTEGER 
    ,SourceSalesDetailID  INTEGER 
    ,SalesAmount FLOAT
    ,SalesQuantity INTEGER  
    ,SalesUnitPrice FLOAT 
    ,SalesExtendedCost FLOAT 
    ,SalesTotalProfit FLOAT 
   
);

INSERT INTO Fact_SalesActual (
     DimProductID 
    ,DimStoreID 
    ,DimResellerID 
    ,DimCustomerID 
    ,DimChannelID 
    ,DimSaleDateID 
    ,DimLocationID 
	,SourceSalesHeaderID 
    ,SourceSalesDetailID  
    ,SalesAmount 
    ,SalesQuantity 
    ,SalesUnitPrice 
    ,SalesExtendedCost 
    ,SalesTotalProfit 
)
SELECT 
    NVL(dp.DimProductID, -1),
    NVL(ds.DimStoreID, -1),
    NVL(dr.DimResellerID,-1),
    NVL(dc.DimCustomerID,-1),
    NVL(dch.DimChannelID,-1),
   // NVL(dd.DATE_PKEY,-1),
    CAST(REPLACE(REPLACE(CAST(ssh.date AS DATE), '00', '20'), '-', '') AS NUMBER(9)) AS DATE_PKEY,
    NVL(dl.DimLocationID,-1),
    NVL(ssh.SalesHeaderID,-1),
    NVL(ssd.SalesDetailID,-1),
    ssd.SalesAmount,
    ssd.SalesQuantity,
    (ssd.SalesAmount/ssd.SalesQuantity) AS "SalesUnitPrice",
    (dp.ProductCost*ssd.SalesQuantity) AS "SalesExtendedCost",
    (ssd.SalesAmount- (dp.ProductCost*ssd.SalesQuantity)) AS "SalesTotalProfit"
FROM 
   STAGE_SalesDetail ssd left outer join STAGE_SalesHeader ssh  on ssd.SalesHeaderID = ssh.SalesHeaderID
   left outer join DIM_Product dp on  ssd.ProductID= dp.SourceProductID
   left outer join DIM_Store ds on ssh.storeID=ds.SourceStoreID
   left outer join DIM_Reseller dr on ssh.ResellerID= dr.SourceResellerID
   left outer join DIM_Customer dc on ssh.CustomerID=dc.SourceCustomerID
   left outer join DIM_Channel dch on ssh.ChannelID= dch.SourceChannelID 
   left outer join DIM_Date dd on ssh.Date= dd.Date 
   left outer join DIM_Location dl on ssh.StoreID=Try_Cast(dl.SourceLocationID as Integer)  or ssh.CustomerID= dl.SourceLocationID or ssh.ResellerID = dl.SourceLocationID
 
select * from Fact_SalesActual

--Creating and Inserting Fact_SRCSalesTarget
CREATE OR REPLACE TABLE Fact_SRCSalesTarget(
     DimStoreID INTEGER CONSTRAINT FK_FactSRCSalesTarget_StoreID FOREIGN KEY REFERENCES Dim_Store(DimStoreID) Not Null
    ,DimResellerID INTEGER CONSTRAINT FK_FactSRCSalesTarget_ResellerID FOREIGN KEY REFERENCES Dim_Reseller(DimResellerID) Not Null
    ,DimChannelID INTEGER CONSTRAINT FK_FactSRCSalesTarget_ChannelID FOREIGN KEY REFERENCES Dim_Channel(DimChannelID) Not Null
    ,DimTargetDateID NUMBER(9) CONSTRAINT FK_FactSRCSalesTarget_DateID FOREIGN KEY REFERENCES Dim_Date(Date_PKEY) Not Null
	,SalesTargetAmount NUMERIC(38,0)
   
);

Insert into Fact_SRCSalesTarget
(
     DimStoreID 
    ,DimResellerID 
    ,DimChannelID 
    ,DimTargetDateID 
	,SalesTargetAmount 
)
Select 
NVL(ds.DimStoreID,-1),
NVL(dr.DimResellerID,-1),
NVL(dch.DimChannelID,-1),
dd.DATE_PKEY,
stcs.TargetSalesAmount As "SalesTargetAmount"
From
STAGE_TARGETDATA_CHANNELRESELLER_STORE stcs 
left join Dim_Channel dch  on dch.ChannelName = (case when stcs.ChannelName= 'Online' then 'On-line' else stcs.ChannelName End) 
left join Dim_Store ds on ds.StoreNumber = (case 
when stcs.TargetName= 'Store Number 5' then 5 
when stcs.TargetName= 'Store Number 8' then 8
when stcs.TargetName= 'Store Number 10' then 10
when stcs.TargetName= 'Store Number 21' then 21
when stcs.TargetName= 'Store Number 34' then 34
else 39 end)
left join Dim_Reseller dr on dr.ResellerName= (case when stcs.TargetName= 'Mississippi Distributors' then 'Mississipi Distributors'
else stcs.TargetName end)
left join Dim_Date dd on stcs.Year=dd.Year 
 
Select * from Fact_SRCSalesTarget

--Creating and Inserting Fact_ProductSalesTarget

CREATE OR REPLACE TABLE  Fact_ProductSalesTarget(
   DimProductID INTEGER CONSTRAINT FK_FactProductSalesTarget_ProductID FOREIGN KEY REFERENCES Dim_Product(DimProductID) Not Null
  ,DimTargetDateID NUMBER(9) CONSTRAINT FK_FactProductSalesTarget_DateID FOREIGN KEY REFERENCES Dim_Date(Date_PKEY) Not Null
  ,ProductTargetSalesQuantity NUMBER(38,0)
)


Insert into Fact_ProductSalesTarget
(
  DimProductID,
  DimTargetDateID,
  ProductTargetSalesQuantity
)
Select 
   dp.DimProductID,
   dd.DATE_PKEY,
   stdp.SALESQUANTITYTARGET AS "ProductTargetSalesQuantity"
From
   STAGE_TARGETDATA_PRODUCT stdp left join  Dim_Product dp on stdp.ProductID= dp.SourceProductID
   left join DIM_Date dd on stdp.Year= dd.Year

select * from Fact_ProductSalesTarget