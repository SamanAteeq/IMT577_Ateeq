Use Database IMT577_DW_SAMAN_ATEEQ;


/*1. Give an overall assessment of stores number 10 and 21’s sales.*/

/*How are they performing compared to target? Will they meet their 2014 target?*/
Create or Replace Secure View vw_SalesvsTarget_YearandStore as 
(select ds.StoreNumber, dd.Date, dd.YEAR,dd.MONTH_ABBREV,
 fsst.SalesTargetAmount as Target, sum(fsa.SalesAmount) as TotalSales
from Fact_SalesActual fsa 
join Dim_Date dd on fsa.DimSaleDateID = dd.DATE_PKEY
join Dim_Store ds on fsa.DimStoreID = ds.DimStoreID
join Fact_SrcSalesTarget fsst on fsst.DimStoreID = ds.DimStoreID and fsst.DimTargetDateID = dd.DATE_PKEY
where ds.StoreNumber in (10,21) group by ds.StoreNumber,dd.Date,  dd.Year, dd.MONTH_ABBREV, Target)


/*Should either store be closed? Why or why not?*/
Create or replace secure View vw_Profit_YearandStore as
select ds.StoreNumber, dd.Date, dd.YEAR,dd.MONTH_ABBREV, sum(fsa.SalesTotalProfit) as TotalProfit
from Fact_SalesActual fsa 
join Dim_Date dd on fsa.DimSaleDateID = dd.DATE_PKEY
join Dim_Store ds on fsa.DimStoreID = ds.DimStoreID
where ds.StoreNumber in (10,21) group by ds.StoreNumber, dd.Date, dd.Year, dd.MONTH_ABBREV

/*2. Recommend 2013 bonus amounts for each store if the total bonus pool is $2,000,000 
using a comparison of 2013 actual sales vs. 2013 sales targets as the basis for the recommendation..*/

Create or replace secure View vw_BonusAmount as
with basedata as
(select ds.StoreNumber, dd.YEAR, dd.MONTH_ABBREV, dd.DATE, fsst.SalesTargetAmount as Target, sum(fsa.SalesAmount) as TotalSales, (TotalSales/Target)*100 as Ratio
from Fact_SalesActual fsa
join Dim_Date dd on fsa.DimSaleDateID = dd.DATE_PKEY
join Dim_Store ds on fsa.DimStoreID = ds.DimStoreID
join Fact_SrcSalesTarget fsst on fsst.DimStoreID = ds.DimStoreID and fsst.DimTargetDateID = dd.DATE_PKEY
where ds.StoreNumber <> -1 and dd.YEAR= 2013 group by ds.StoreNumber, dd.YEAR, dd.DATE, dd.MONTH_ABBREV,Target)
select bd.StoreNumber , bd.YEAR, MONTH_ABBREV, Target, TotalSales, bd.Ratio, ((bd.Ratio/(select sum(ratio) from basedata)) *2000000) as BonusAmount from basedata bd
/* 3. Assess product sales by day of the week at stores 10 and 21. What can we learn about sales trends?*/

Create or replace secure View vw_ProductSales_DayOfWeek as
select dd.Year, dd.DAY_ABBREV, dp.ProductCategory, dp.ProductType, dp.ProductName,ds.StoreNumber,
sum(fsa.SalesTotalProfit) as TotalProfit, sum(fsa.SalesAmount) as TotalSales, sum(fsa.SalesQuantity) as TotalQuantity
from Fact_SalesActual fsa 
join Dim_Date dd on fsa.DimSaleDateID = dd.DATE_PKEY
join Dim_Product dp on fsa.DimProductID = dp.DimProductID
join Dim_Store ds on fsa.DimStoreID = ds.DimStoreID
where ds.StoreNumber in (10,21)
group by dd.Year, dd.DAY_ABBREV, dp.ProductCategory, dp.ProductType, dp.ProductName, ds.StoreNumber

/* 4. Should any new stores be opened? Include all stores in your analysis if necessary. If so, where? Why or why not?*/

Create or replace secure View vw_SalesandProfit_Store as
select ds.StoreNumber, dd.Year, dd.MONTH_ABBREV, dl.Region, sum(fsa.SalesAmount) as TotalSales, sum(fsa.SalesTotalProfit) as TotalProfit
from Fact_SalesActual fsa 
join Dim_Date dd on fsa.DimSaleDateID = dd.DATE_PKEY
join Dim_Store ds on fsa.DimStoreID = ds.DimStoreID
join Dim_Location dl on dl.DimLocationID = fsa.DimLocationID
where ds.StoreNumber <> -1
group by ds.StoreNumber, dd.Year,dd.MONTH_ABBREV, dl.Region 
--SQL "pass-through" views

Create or replace secure View vw_Dim_Channel AS
(
Select DIMCHANNELID, SOURCECHANNELID, SOURCECHANNELCATEGORYID, CHANNELNAME, CHANNELCATEGORY
From DIM_CHANNEL
);

Create or replace secure View vw_Dim_Customer AS
(
Select DIMCUSTOMERID, DIMLOCATIONID, SOURCECUSTOMERID, FULLNAME, FIRSTNAME, LASTNAME, GENDER, EMAILADDRESS, PHONENUMBER
From DIM_CUSTOMER  
);

Create or replace secure View vw_Dim_Location AS
(
Select DIMLOCATIONID,SOURCELOCATIONID ADDRESS, CITY, POSTALCODE, REGION, COUNTRY
From DIM_LOCATION 
);

Create or replace secure View vw_Dim_Product AS
(
Select DIMPRODUCTID, SOURCEPRODUCTID, SOURCEPRODUCTTYPEID, SOURCEPRODUCTCATEGORYID, PRODUCTNAME, PRODUCTTYPE, PRODUCTCATEGORY,
  PRODUCTRETAILPRICE, PRODUCTWHOLESALEPRICE, PRODUCTCOST, PRODUCTRETAILPROFIT, PRODUCTWHOLESALEUNITPRICE,
  PRODUCTPROFITMARGINUNITPERCENT	
From DIM_PRODUCT
);

Create or replace secure View vw_Dim_Reseller AS
(
Select DIMRESELLERID, DIMLOCATIONID, SOURCERESELLERID, RESELLERNAME, CONTACTNAME, PHONENUMBER, EMAIL
From DIM_RESELLER
);

Create or replace secure View vw_Dim_Store AS
(
Select DIMSTOREID,DIMLOCATIONID, SOURCESTOREID, STORENUMBER, STOREMANAGER
From DIM_STORE
);

Create or replace secure View vw_Fact_Sales AS
(
Select DIMPRODUCTID,DIMSTOREID,DIMRESELLERID,DIMCUSTOMERID,DIMCHANNELID,DIMSALEDATEID, DIMLOCATIONID,SOURCESALESHEADERID,SOURCESALESDETAILID
SALESAMOUNT,SALESQUANTITY,SALESUNITPRICE,SALESEXTENDEDCOST, SALESTOTALPROFIT  
From FACT_SALESACTUAL
);

Create or replace secure View vw_Fact_Product_Target AS
(
Select DIMPRODUCTID, DIMTARGETDATEID, PRODUCTTARGETSALESQUANTITY	
From FACT_PRODUCTSALESTARGET
);

Create or replace secure View vw_Fact_SRC_Target AS
(
Select DIMCHANNELID, DIMSTOREID, DIMRESELLERID, DIMTARGETDATEID, SALESTARGETAMOUNT
From FACT_SRCSALESTARGET
);

Create or replace secure View vw_DimDate AS
(
  Select DATE_PKEY, DATE, FULL_DATE_DESC, DAY_NUM_IN_WEEK, DAY_NUM_IN_MONTH,DAY_NUM_IN_YEAR,DAY_NAME, DAY_ABBREV,
  WEEKDAY_IND, US_HOLIDAY_IND,_HOLIDAY_IND,MONTH_END_IND,WEEK_BEGIN_DATE_NKEY, WEEK_BEGIN_DATE,WEEK_END_DATE_NKEY,
  WEEK_END_DATE, WEEK_NUM_IN_YEAR, MONTH_NAME, MONTH_ABBREV, MONTH_NUM_IN_YEAR, YEARMONTH, QUARTER, YEARQUARTER, YEAR,
  FISCAL_WEEK_NUM,FISCAL_MONTH_NUM,FISCAL_YEARMONTH,FISCAL_QUARTER,FISCAL_YEARQUARTER, FISCAL_HALFYEAR,FISCAL_YEAR, SQL_TIMESTAMP,
  CURRENT_ROW_IND, EFFECTIVE_DATE, EXPIRATION_DATE 
  from DIM_DATE
)