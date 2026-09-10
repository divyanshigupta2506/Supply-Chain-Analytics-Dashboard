SELECT 
    chain_supply.product.`Product type`,
    SUM(chain_supply.revenue.`Revenue generated`) AS total_revenue
FROM chain_supply.product
INNER JOIN chain_supply.revenue
ON chain_supply.product.SKU = chain_supply.revenue.SKU
GROUP BY chain_supply.product.`Product type`
ORDER BY total_revenue DESC;

/* Q2 Top 10 products (SKUs) that generated the highest revenue.*/
SELECT chain_supply.revenue.`Revenue generated` , chain_supply.revenue.SKU
FROM chain_supply.revenue
ORDER BY chain_supply.revenue.`Revenue generated` DESC
LIMIT 10 ;

/*Q3 Which customer demographic generated the highest total revenue?*/

SELECT  chain_supply.revenue.`Customer demographics`,
      SUM(chain_supply.revenue.`Revenue generated` ) AS Total_Revenue
FROM chain_supply.revenue
GROUP BY chain_supply.revenue.`Customer demographics` 
ORDER BY Total_Revenue DESC;

/*Q4 all products whose revenue is above the average revenue of all products*/

SELECT chain_supply.revenue.SKU,
       chain_supply.revenue.`Revenue generated`
FROM chain_supply.revenue
WHERE  chain_supply.revenue.`Revenue generated`  > (
                          SELECT AVG(chain_supply.revenue.`Revenue generated`) AS Total_revenue 
						  FROM chain_supply.revenue
 );                         
					
/*Q5 "Within each Product Category, the Top 3 highest revenue products."*/

WITH revenue_products AS (
    SELECT 
        chain_supply.product.`Product type`,
        chain_supply.revenue.`Revenue generated`,
        chain_supply.product.SKU,
        ROW_NUMBER() OVER (
            PARTITION BY chain_supply.product.`Product type`
            ORDER BY chain_supply.revenue.`Revenue generated` DESC
        ) AS revenue_rank
    FROM chain_supply.product
    INNER JOIN chain_supply.revenue
        ON chain_supply.product.SKU = chain_supply.revenue.SKU
)

SELECT 
    `Product type`,
    `Revenue generated`,
    SKU,
    revenue_rank
FROM revenue_products
WHERE revenue_rank <= 3
ORDER BY `Product type`, revenue_rank;

/* Q6 Classify every SKU according to its revenue:

Revenue greater than 8,000 → High Revenue
Revenue between 5,000 and 8,000 → Medium Revenue
Revenue below 5,000 → Low Revenue  */

SELECT  chain_supply.revenue.SKU,
        chain_supply.revenue.`Revenue generated`,
        CASE 
            WHEN chain_supply.revenue.`Revenue generated` > 8000 THEN "High_Revenue"
            WHEN chain_supply.revenue.`Revenue generated` BETWEEN 5000 AND 8000 THEN "Medium_Revenue"
            ELSE "Low_Revenue"
		END AS Revenue_Category
FROM chain_supply.revenue;

/* Q7 How many products fall into each revenue category?*/
SELECT  
        COUNT(SKU),
        
        CASE 
            WHEN chain_supply.revenue.`Revenue generated` > 8000 THEN "High_Revenue"
            WHEN chain_supply.revenue.`Revenue generated` BETWEEN 5000 AND 8000 THEN "Medium_Revenue"
            ELSE "Low_Revenue"
		END AS Revenue_Category
FROM chain_supply.revenue
GROUP BY Revenue_Category;

/*Q8 Rank  SKUs from highest to lowest revenue.*/

SELECT chain_supply.revenue.`Revenue generated` , SKU,
      RANK() OVER( ORDER BY chain_supply.revenue.`Revenue generated`DESC ) AS Revenue_Rank
FROM chain_supply.revenue;

/*Q9 Compare each product's revenue with the previous product when sorted by revenue?*/

SELECT SKU,chain_supply.revenue.`Revenue generated`, 
        LAG( chain_supply.revenue.`Revenue generated`) OVER(ORDER BY  chain_supply.revenue.`Revenue generated` DESC) AS Previous_Revenue,
        chain_supply.revenue.`Revenue generated`- LAG( chain_supply.revenue.`Revenue generated`) 
        OVER(ORDER BY  chain_supply.revenue.`Revenue generated` DESC) AS Revenue_Difference
FROM chain_supply.revenue;

/* Q10  SKUs whose revenue is higher than the average revenue, and how much higher they are than the average.*/
WITH  higher_revenue AS (
SELECT 
       AVG(chain_supply.revenue.`Revenue generated`) AS average_revenue
FROM chain_supply.revenue 
)
SELECT chain_supply.revenue.`Revenue generated` , SKU, average_revenue,
       chain_supply.revenue.`Revenue generated`- average_revenue AS above_average_amount
FROM chain_supply.revenue 
CROSS JOIN higher_revenue 
WHERE chain_supply.revenue.`Revenue generated` > average_revenue
ORDER BY above_average_amount DESC;

/*Q11 "For each Product Type, show  the SKU that has the highest stock level*/
WITH stock_rank  AS (
SELECT chain_supply.product.`product type`,
       SKU ,
         chain_supply.product.`Stock levels`,
        ROW_NUMBER() OVER (
            PARTITION BY chain_supply.product.`Product type`
            ORDER BY chain_supply.product.`Stock levels`  DESC
        ) AS stock_rank
FROM chain_supply.product
)
SELECT `product type`,
       SKU ,
         `Stock levels`
FROM stock_rank
WHERE stock_rank=1 ;

/* Q12 Find products that have high demand but low stock and classify their inventory risk.*/
SELECT chain_supply.product.`product type`,
       chain_supply.product.SKU ,
	   chain_supply.product.`Stock levels`,
      chain_supply.revenue. `Number of products sold`,
      CASE 
           WHEN chain_supply.revenue. `Number of products sold` > 700 AND chain_supply.product.`Stock levels`< 30 THEN  "Critical_Risk"
           WHEN chain_supply.revenue. `Number of products sold` > 500 AND chain_supply.product.`Stock levels`< 50 THEN  "Moderate_Risk"
           ELSE "Normal"
        END AS 'Inventory_risk'
FROM chain_supply.product
INNER JOIN chain_supply.revenue
ON chain_supply.product.SKU=chain_supply.revenue.SKU ;

/* Q13 products whose manufacturing cost is higher than the average manufacturing cost of their own product type.*/
SELECT 
    p.SKU,
    p.`Product type`,
    m.`Manufacturing costs`
FROM chain_supply.product AS p
INNER JOIN chain_supply.manfucturing AS m
    ON p.SKU = m.SKU
WHERE m.`Manufacturing costs` > (
    SELECT AVG(m2.`Manufacturing costs`)
    FROM chain_supply.product AS p2
    INNER JOIN chain_supply.manfucturing AS m2
        ON p2.SKU = m2.SKU
    WHERE p2.`Product type` = p.`Product type`
)
ORDER BY p.`Product type`, m.`Manufacturing costs` DESC;


/*Q14 Show  the cumulative (running) revenue for products when they are ordered from highest revenue to lowest revenue.*/

SELECT  SKU, chain_supply.revenue.`Revenue generated` ,
        SUM(chain_supply.revenue.`Revenue generated`)OVER ( ORDER BY chain_supply.revenue.`Revenue generated` DESC) AS Running_Revenue
FROM chain_supply.revenue;

/*Q15 Find the difference between the current product's stock level and the next product's stock level
 when ordered from highest stock to lowest stock.*/

SELECT  SKU , chain_supply.product.`Stock levels`,
        LEAD(chain_supply.product.`Stock levels`) OVER (ORDER BY chain_supply.product.`Stock levels` DESC) AS Next_Stock,
         chain_supply.product.`Stock levels`- 
         LEAD(chain_supply.product.`Stock levels`)
         OVER 
              (ORDER BY chain_supply.product.`Stock levels` DESC
              ) Stock_Difference
FROM  chain_supply.product;

/* Q16  For each product type, show the average stock level and 
return only those SKUs whose stock level is above the average stock level of their own product type.*/

SELECT p.SKU , 
	  p.`product type` ,
      p.`Stock levels`
FROM chain_supply.product p
WHERE p.`Stock levels` >  (
                              SELECT AVG(p2.`Stock levels`) AS average_stock_level
                              FROM chain_supply.product p2
                               WHERE p2.`Product type` = p.`Product type`
);
        

/*Q17 Within each Product Type, show the second highest revenue-generating SKU.*/
WITH highest AS(
SELECT  chain_supply.product.`product type`,
         chain_supply.revenue.`Revenue generated`,
         chain_supply.product.SKU,
		 ROW_NUMBER() OVER
         (PARTITION BY chain_supply.product.`product type` ORDER BY chain_supply.revenue.`Revenue generated` DESC
         ) AS highest_revenue_generating
FROM chain_supply.product
INNER JOIN chain_supply.revenue
ON chain_supply.product.SKU=chain_supply.revenue.SKU
)

SELECT 
    `Product type`,
    `Revenue generated`,
    SKU,
     highest_revenue_generating
FROM highest
WHERE  highest_revenue_generating =2
ORDER BY `Product type`;

/* Q18 "For every Product Type, calculate the average revenue and show how much each SKU is above or below that average."*/
SELECT  chain_supply.product.`product type`,
         chain_supply.revenue.`Revenue generated`,
         chain_supply.product.SKU,
         AVG(chain_supply.revenue.`Revenue generated`) OVER
         (partition by  chain_supply.product.`product type`
         ) AS Category_Avg_Revenue,
         chain_supply.revenue.`Revenue generated` -  AVG(chain_supply.revenue.`Revenue generated`) OVER
         (partition by  chain_supply.product.`product type`
         ) AS Category_Avg_Revenue
FROM chain_supply.product
INNER JOIN chain_supply.revenue
ON chain_supply.product.SKU=chain_supply.revenue.SKU;

/* Q19 Within each Product Type, rank products based on revenue.*/
SELECT   chain_supply.product.SKU, 
		 chain_supply.product.`product type`,
         chain_supply.revenue.`Revenue generated`,
          DENSE_RANK() 
          OVER( PARTITION BY chain_supply.product.`product type` ORDER BY chain_supply.revenue.`Revenue generated` DESC
          ) AS Revenue_Rank
FROM chain_supply.product
INNER JOIN chain_supply.revenue
ON chain_supply.product.SKU=chain_supply.revenue.SKU;	
        
/*Q20 all products that have never generated any revenue.*/

SELECT   chain_supply.product.SKU, 
		 chain_supply.product.`product type`,
         chain_supply.revenue.`Revenue generated`
FROM chain_supply.product
LEFT JOIN chain_supply.revenue
ON chain_supply.product.SKU=chain_supply.revenue.SKU
WHERE  chain_supply.revenue.`Revenue generated` IS NULL;

/*Q21  the supplier(s) whose manufacturing cost is the highest within their own Product Type? */
WITH manufacturing_ranked AS (
    SELECT 
        p.`Product type`,
        p.SKU,
        m.`Supplier name`,
        m.`Manufacturing costs`,
        DENSE_RANK() OVER (
            PARTITION BY p.`Product type`
            ORDER BY m.`Manufacturing costs` DESC
        ) AS Manufacturing_Rank
    FROM chain_supply.product AS p
    INNER JOIN chain_supply.manfucturing AS m
        ON p.SKU = m.SKU
)

SELECT
    `Product type`,
    SKU,
    `Supplier name`,
    `Manufacturing costs`,
    Manufacturing_Rank
FROM manufacturing_ranked
WHERE Manufacturing_Rank = 1;

/* Q22 Show those Product Types whose total revenue is greater than 180,000.*/
SELECT   chain_supply.product.`product type`,
         SUM(chain_supply.revenue.`Revenue generated`) AS Total_Revenue
FROM chain_supply.product
INNER JOIN chain_supply.revenue
ON chain_supply.product.SKU=chain_supply.revenue.SKU
GROUP BY chain_supply.product.`product type`
HAVING  Total_Revenue >180000;

/* Q23 Find the Top Revenue SKU of each Product Type and also calculate what percentage of that Product Type's total revenue it contributes.*/

WITH revenues AS (
    SELECT
        p.SKU,
        p.`Product type`,
        r.`Revenue generated`,
        
        SUM(r.`Revenue generated`) OVER (
            PARTITION BY p.`Product type`
        ) AS category_revenue,
        
        DENSE_RANK() OVER (
            PARTITION BY p.`Product type`
            ORDER BY r.`Revenue generated` DESC
        ) AS revenue_rank

    FROM chain_supply.product AS p
    INNER JOIN chain_supply.revenue AS r
        ON p.SKU = r.SKU
)

SELECT
    `Product type`,
    SKU,
    `Revenue generated`,
    category_revenue,
    ROUND(
        (`Revenue generated` / category_revenue) * 100,
        2
    ) AS contribution_percentage

FROM revenues
WHERE revenue_rank = 1;

/* Q24 Find suppliers whose average manufacturing cost is higher than the overall average manufacturing cost.*/

SELECT chain_supply.manfucturing.`Supplier name`,
       AVG(chain_supply.manfucturing.`Manufacturing costs`) AS average_manufacturing_cost
FROM chain_supply.manfucturing
GROUP BY chain_supply.manfucturing.`Supplier name`
HAVING AVG(chain_supply.manfucturing.`Manufacturing costs`) > (
                         SELECT  AVG(chain_supply.manfucturing.`Manufacturing costs`) AS average_manufacturing_cost
                         FROM chain_supply.manfucturing
);

/* Q25 For every SKU, show its revenue as a percentage of the highest revenue within its Product Type.*/
SELECT 
    p.SKU,
    p.`Product type`,
    r.`Revenue generated`,

    MAX(r.`Revenue generated`) OVER (
        PARTITION BY p.`Product type`
    ) AS highest_revenue,

    ROUND(
        r.`Revenue generated`
        /
        MAX(r.`Revenue generated`) OVER (
            PARTITION BY p.`Product type`
        ) * 100,
        2
    ) AS percentage_of_highest

FROM chain_supply.product AS p
INNER JOIN chain_supply.revenue AS r
    ON p.SKU = r.SKU;


/* Q26"For each Product Type, tell me how many products are High Revenue, Medium Revenue, and Low Revenue.".*/
 
SELECT  chain_supply.product.`product type` ,
          COUNT( CASE WHEN chain_supply.revenue.`Revenue generated` > 8000 THEN 1  END) AS  "high_revenue",
           COUNT(CASE WHEN chain_supply.revenue.`Revenue generated` BETWEEN 5000 AND 8000 THEN 1 END) AS "Medium_Revenue",
		COUNT(CASE WHEN chain_supply.revenue.`Revenue generated` < 5000 THEN 1 END) AS "Low_Revenue" 
FROM chain_supply.product
INNER JOIN chain_supply.revenue
ON chain_supply.product.SKU=chain_supply.revenue.SKU
GROUP BY  chain_supply.product.`product type`;

/* Q27 Find the supplier who supplies the maximum number of products.*/

WITH supplier_products AS (
    SELECT
        m.`Supplier name`,
        COUNT(m.SKU) AS total_products,
        RANK() OVER (
            ORDER BY COUNT(m.SKU) DESC
        ) AS supplier_rank
    FROM chain_supply.manfucturing m
    GROUP BY m.`Supplier name`
)
SELECT
    `Supplier name`,
    total_products
FROM supplier_products
WHERE supplier_rank = 1;

/* Q28 each supplier's manufacturing cost along  with the previous supplier's manufacturing cost when suppliers are ordered by manufacturing cost.*/

SELECT  m.`Supplier name`, m.`Manufacturing costs`,
        LAG (m.`Manufacturing costs`) OVER( ORDER BY m.`Manufacturing costs` DESC) AS  previous_manufacturing_cost,
        m.`Manufacturing costs`-LAG (m.`Manufacturing costs`) OVER( ORDER BY m.`Manufacturing costs` DESC)  AS cost_difference
FROM chain_supply.manfucturing m;

/*Q29 Find Product Types whose average stock level is below the overall average stock level.*/
SELECT chain_supply.product.`product type`,
	    AVG(chain_supply.product.`Stock levels`) AS AVG_Stock_level
FROM  chain_supply.product
GROUP BY  chain_supply.product.`product type`
HAVING AVG(chain_supply.product.`Stock levels`) <(
              SELECT AVG(chain_supply.product.`Stock levels`)
              FROM chain_supply.product);
              
/* Q30 For each Product Type, show the SKU with the lowest revenue.*/
WITH lowest_revenue AS (
    SELECT
        p.`Product type`,
        p.SKU,
        r.`Revenue generated`,
        DENSE_RANK() OVER (
            PARTITION BY p.`Product type`
            ORDER BY r.`Revenue generated` ASC
        ) AS revenue_rank
    FROM chain_supply.product AS p
    INNER JOIN chain_supply.revenue AS r
        ON p.SKU = r.SKU
)

SELECT
    `Product type`,
    SKU,
    `Revenue generated`
FROM lowest_revenue
WHERE revenue_rank = 1
ORDER BY `Product type`;

/* Q31 "For every Supplier, calculate the total manufacturing cost and show the percentage contribution of each  supplier to the overall manufacturing cost."*/

WITH overall_manu AS (
    SELECT
        m.`Supplier name`,
        SUM(m.`Manufacturing costs`) AS Total_Cost
    FROM chain_supply.manfucturing AS m
    GROUP BY m.`Supplier name`
)

SELECT
    `Supplier name`,
    Total_Cost,
    SUM(Total_Cost) OVER () AS Overall_Manufacturing_Cost,
    ROUND(
        Total_Cost / SUM(Total_Cost) OVER () * 100,
        2
    ) AS Contribution_Percentage
FROM overall_manu
ORDER BY Contribution_Percentage DESC;


/*Q32 Show all products that have never been manufactured.*/

SELECT   chain_supply.product.SKU, 
		 chain_supply.product.`product type`,
         chain_supply.manfucturing.`Manufacturing costs`
FROM chain_supply.product
LEFT JOIN  chain_supply.manfucturing
ON chain_supply.product.SKU= chain_supply.manfucturing.SKU
WHERE chain_supply.manfucturing.`Manufacturing costs`  IS NULL;

/*Q33 "Find the Top 2 suppliers based on total manufacturing cost."*/ 
WITH supplier_cost AS (
    SELECT
        `Supplier name`,
        SUM(`Manufacturing costs`) AS Total_Manufacturing_Cost
    FROM chain_supply.manfucturing
    GROUP BY `Supplier name`
),

supplier_rank AS (
    SELECT
        `Supplier name`,
        Total_Manufacturing_Cost,
        DENSE_RANK() OVER (
            ORDER BY Total_Manufacturing_Cost DESC
        ) AS Supplier_Rank
    FROM supplier_cost
)

SELECT
    `Supplier name`,
    Total_Manufacturing_Cost,
    Supplier_Rank
FROM supplier_rank
WHERE Supplier_Rank <= 2;

/*Q34 For each Product Type, identify the supplier who has generated the highest total manufacturing cost? */

WITH supplier_cost AS (
    SELECT
        chain_supply.manfucturing.`Supplier name`,
        chain_supply.product.`product type`,
        SUM(`Manufacturing costs`) AS Total_Manufacturing_Cost
    FROM chain_supply.manfucturing
	INNER JOIN chain_supply.product
    ON chain_supply.manfucturing.SKU=chain_supply.product.SKU
    GROUP BY chain_supply.manfucturing.`Supplier name`,
             chain_supply.product.`product type`
),
supplier_rank AS (
SELECT
         `Supplier name`,
         `product type`,
          Total_Manufacturing_Cost,
         dense_rank() OVER(PARTITION BY `product type`
                           ORDER BY Total_Manufacturing_Cost DESC) AS Highest
	FROM supplier_cost
)
SELECT
    `Supplier name`,
    `Product type`,
    Total_Manufacturing_Cost
FROM supplier_rank
WHERE Highest = 1;

/*Q35 For every Product Type, identify whether it is Overstocked, Balanced, or Understocked. */
SELECT  `Product type`,
    AVG(`Stock levels`) AS Average_Stock,
    CASE
        WHEN AVG(`Stock levels`) > 70 THEN 'Overstocked'
        WHEN AVG(`Stock levels`) BETWEEN 40 AND 70 THEN 'Balanced'
        ELSE 'Understocked'
    END AS Inventory_Status
FROM chain_supply.product
GROUP BY `Product type`;

