USE `mintclassics`;
SELECT * FROM customers
LIMIT 20;

SELECT * FROM orders
LIMIT 20;

SELECT * FROM products
LIMIT 20;

SELECT * FROM payments
LIMIT 20;

SELECT * FROM warehouses
LIMIT 20;

SELECT * FROM productlines
LIMIT 20;

SELECT distinct COUNT(*) FROM customers;

SELECT distinct COUNT(*) FROM products;

SELECT distinct COUNT(*) as ordercount FROM orders;

SELECT COUNT(*) as orders FROM orders x, orderdetails y
WHERE x.orderNumber = y.orderNumber;

SELECT p.productName, p.productCode, y.orderNumber, y.quantityOrdered ,y.priceEach as unitPrice, (y.quantityOrdered * y.priceEach) as revenue
FROM orderdetails y ,products p
WHERE  p.productCode = y.productCode
order by 3;

-- NUMBER OF PRODUCTS IN EACH ORDER
SELECT o.orderNumber, count(distinct o.productCode)
FROM /*products p ,*/ orderdetails o
/*where p.productCode =o.productCode*/
group by 1
order by 2 desc;

-- revenue by highest distinct product code
SELECT orderNumber, count(distinct productCode), sum((quantityOrdered * priceEach)) as revenue
FROM orderdetails 
group by 1
order by 3 desc;

-- Products sold in each high revenue order
SELECT orderNumber, sum((quantityOrdered * priceEach)) as revenue
FROM orderdetails
group by 1
order by 2 desc
limit 10;

SELECT p.productCode, z.orderNumber, p.productName, p.productLine
FROM products p ,orderdetails y,(SELECT orderNumber, sum((quantityOrdered * priceEach)) as revenue
FROM orderdetails
group by 1
order by 2 desc
limit 10) as z 
WHERE p.productCode = y.productCode
AND y.orderNumber = z.orderNumber;

-- productsTYPE stored in each warehouse
SELECT distinct p.warehouseCode, p.productLine
FROM products p
order by 1;

SELECT distinct p.warehouseCode, p.productLine, sum(p.quantityInStock)
FROM products p
group by 2
order by 3 desc,1;

-- revenue by warehouse based on products ordered
SELECT o.productCode, o.quantityOrdered, o.priceEach,(o.quantityOrdered * o.priceEach) as Revenue, p.productName, p.warehouseCode
FROM orderdetails o, products p
WHERE o.productCode = p.productCode
order by 4 desc;

SELECT p.warehouseCode,sum((o.quantityOrdered * o.priceEach)) as totalRevenue
FROM orderdetails o, products p
WHERE o.productCode = p.productCode
group by 1;

-- Products that sold the most based on quantity
SELECT o.productCode, p.productName , o.quantityOrdered, p.warehouseCode
from orderdetails o, products p
WHERE o.productCode = p.productCode
order by 3 desc;

-- Price of Products sold (no direct correllation to sales)
SELECT o.productCode , o.quantityOrdered, o.priceEach
from orderdetails o
order by 3 desc;

-- quantity ordered for each product 
SELECT o.productCode , sum(o.quantityOrdered), p.warehouseCode
FROM orderdetails o, products p
where o.productCode = p.productCode
group by 1;

-- quantity of each product in stock
SELECT productName, quantityInStock, warehouseCode
from products;

SELECT p.productName, p.quantityInStock, p.warehouseCode, w.warehousePctCap
from products p, warehouses w
where p.warehouseCode = w.warehouseCode;

SELECT  p.warehouseCode, sum(p.quantityInStock), w.warehousePctCap
from products p, warehouses w
where p.warehouseCode = w.warehouseCode
group by 1;

-- warehouse capacity utilization
SELECT p.warehouseCode, sum(p.quantityInstock), w.warehousePctCap
FROM products p
INNER JOIN warehouses w
		ON p.warehouseCode = w.warehouseCode
GROUP BY 1;

SELECT p.warehouseCode, sum(o.quantityOrdered)
FROM products p
INNER JOIN orderdetails o
		ON p.productCode = o.productCode
GROUP BY 1;

SELECT a.warehouseCode,
		a.QuantityInStock,
        b.QuantityOrdered,
        a.warehousePctCap
FROM (SELECT p.warehouseCode, sum(p.quantityInstock) as QuantityInStock, w.warehousePctCap
FROM products p
INNER JOIN warehouses w
		ON p.warehouseCode = w.warehouseCode
GROUP BY 1) a 
INNER JOIN ( SELECT p.warehouseCode, sum(o.quantityOrdered) as QuantityOrdered
FROM products p
INNER JOIN orderdetails o
		ON p.productCode = o.productCode
GROUP BY 1) b 	
		ON a.warehouseCode = b.warehouseCode;
        
SELECT a.warehouseCode,
		a.QuantityInStock,
        b.QuantityOrdered,
        ROUND(((b.QuantityOrdered/a.QuantityInStock) * 100), 2) as UtilizationPct,
        a.warehousePctCap
FROM (SELECT p.warehouseCode, sum(p.quantityInstock) as QuantityInStock, w.warehousePctCap
FROM products p
INNER JOIN warehouses w
		ON p.warehouseCode = w.warehouseCode
GROUP BY 1) a 
INNER JOIN ( SELECT p.warehouseCode, sum(o.quantityOrdered) as QuantityOrdered
FROM products p
INNER JOIN orderdetails o
		ON p.productCode = o.productCode
GROUP BY 1) b 	
		ON a.warehouseCode = b.warehouseCode;


-- Revenue per warehouse vs cost  
SELECT p.warehouseCode,
	sum((o.quantityOrdered * o.priceEach)) as totalRevenue, 
    sum((o.quantityOrdered * p.buyPrice)) as totalCost
FROM products p
INNER JOIN orderdetails o
		ON p.productCode = o.productCode
GROUP BY 1;

SELECT p.warehouseCode,
	sum((o.quantityOrdered * o.priceEach)) as totalRevenue, 
    sum((o.quantityOrdered * p.buyPrice)) as totalCost,
    (sum((o.quantityOrdered * o.priceEach)) - sum((o.quantityOrdered * p.buyPrice))) as Profit
FROM products p
INNER JOIN orderdetails o
		ON p.productCode = o.productCode
GROUP BY 1
ORDER BY 4 DESC;

SELECT warehouseCode, 
	totalCost, 
    totalRevenue, 
    Profit, 
    ROUND(((Profit/totalCost)*100), 2) as profitPct
FROM(
SELECT p.warehouseCode,
	sum((o.quantityOrdered * o.priceEach)) as totalRevenue, 
    sum((o.quantityOrdered * p.buyPrice)) as totalCost,
    (sum((o.quantityOrdered * o.priceEach)) - sum((o.quantityOrdered * p.buyPrice))) as Profit
FROM products p
INNER JOIN orderdetails o
		ON p.productCode = o.productCode
GROUP BY 1
ORDER BY 4 DESC) sub;

-- lets investigate revenue and cost based on MSRP
SELECT p.warehouseCode,
		sum((o.quantityOrdered * p.MSRP)) as suggestedRevenue, 
        sum((o.quantityOrdered * p.buyPrice)) as totalCost,
        w.warehousePctCap
from orderdetails o, products p, warehouses w
where o.productCode = p.productCode 
and p.warehouseCode = w.warehouseCode
group by 1;

SELECT p.warehouseCode,
		sum((o.quantityOrdered * p.MSRP)) as suggestedRevenue, 
        sum((o.quantityOrdered * p.buyPrice)) as totalCost,
		(sum((o.quantityOrdered * p.MSRP)) - sum((o.quantityOrdered * p.buyPrice))) as suggestedProfit
from orderdetails o, products p
where o.productCode = p.productCode 
group by 1
order by 4 desc;

SELECT p.warehouseCode, 
		sum((o.quantityOrdered * p.buyPrice)) as totalCost,
        sum((o.quantityOrdered * o.priceEach)) as totalRevenue, 
		sum((o.quantityOrdered * p.MSRP)) as suggestedRevenue,
		(sum((o.quantityOrdered * o.priceEach)) - sum((o.quantityOrdered * p.buyPrice))) as Profit,
		(sum((o.quantityOrdered * p.MSRP)) - sum((o.quantityOrdered * p.buyPrice))) as suggestedProfit
from orderdetails o, products p
where o.productCode = p.productCode 
group by 1
order by 5,6 desc;

-- Average price of producttype
SELECT p.productLine,
		ROUND(AVG(o.priceEach), 2) as AveragePrice
FROM products p 
INNER JOIN orderdetails o
		ON p.productCode = o.productCode
GROUP BY 1
ORDER BY 2 DESC;

-- PRODUCTS SOLD 
SELECT p.productLine,
		sum(o.quantityOrdered),
        sum((o.quantityOrdered * o.priceEach)) as revenue
FROM products p 
INNER JOIN orderdetails o
		ON p.productCode = o.productCode
GROUP BY 1;

SELECT p.productLine, sum(p.quantityInStock)
FROM products p
GROUP BY 1;

SELECT a.productLine,
		a.QuantityOrdered,
        b.QuantityInStock,
        a.revenue
FROM (SELECT p.productLine,
		sum(o.quantityOrdered) as QuantityOrdered,
        sum((o.quantityOrdered * o.priceEach)) as revenue
FROM products p 
INNER JOIN orderdetails o
		ON p.productCode = o.productCode
GROUP BY 1) a
INNER JOIN   (SELECT p.productLine, sum(p.quantityInStock) as QuantityInStock
FROM products p
GROUP BY 1) b
		ON a.productLine = b.productLine;

SELECT p.productLine, 
		sum(o.quantityOrdered),
        sum((o.quantityOrdered * p.buyPrice)) as Cost,
		sum((o.quantityOrdered * o.priceEach)) as revenue
FROM products p 
INNER JOIN orderdetails o
		ON p.productCode = o.productCode
GROUP BY 1;

SELECT p.productLine, 
		sum(o.quantityOrdered),
        sum((o.quantityOrdered * p.buyPrice)) as Cost,
		sum((o.quantityOrdered * o.priceEach)) as revenue,
        (sum((o.quantityOrdered * o.priceEach))-sum((o.quantityOrdered * p.buyPrice))) as Profit
FROM products p 
INNER JOIN orderdetails o
		ON p.productCode = o.productCode
GROUP BY 1;

SELECT productLine,
		Cost,
        revenue,
        Profit,
        ROUND(((Profit/Cost)*100),2) as ProfitPct
FROM (
SELECT p.productLine, 
		sum(o.quantityOrdered),
        sum((o.quantityOrdered * p.buyPrice)) as Cost,
		sum((o.quantityOrdered * o.priceEach)) as revenue,
        (sum((o.quantityOrdered * o.priceEach))-sum((o.quantityOrdered * p.buyPrice))) as Profit
FROM products p 
INNER JOIN orderdetails o
		ON p.productCode = o.productCode
GROUP BY 1) sub;

-- Purchase Frequency
SELECT p.productLine, 
		count(distinct od.customerNumber) as UniqueCust,
        count(p.productCode) as purchases,
        ROUND(COUNT(p.productCode) / COUNT(DISTINCT od.customerNumber), 2) purchase_per_user,
        ROUND(AVG(o.priceEach), 2) AS avg_purchase_revenue,
        sum((o.quantityOrdered * o.priceEach)) as Revenue
FROM products p
INNER JOIN orderdetails o
		ON p.productCode = o.productCode
INNER JOIN orders od
		ON o.orderNumber = od.orderNumber
GROUP BY 1
ORDER BY 6 DESC;