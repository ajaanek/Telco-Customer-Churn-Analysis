SELECT *
  FROM [dbo].[Customer-Churn];

-- Data Cleaning

-- Create staging table
SELECT *
INTO customerChurn_staging
FROM [dbo].[Customer-Churn];

-- 1. Remove duplicates
DELETE T
FROM
(
SELECT *, 
DupRank = ROW_NUMBER() OVER (
			  PARTITION BY customerID
			  ORDER BY tenure
			)
FROM customerChurn_staging
) AS T
WHERE DupRank > 1;

SELECT * 
FROM customerChurn_staging;

-- 2. Standardize data
-- Checking to see the categorical or binary columns have the correct expected of distinct values
-- Partner, Dependents, PhoneService, MultipleLines, InternetService, OnlineSecurity, OnlineBackup, DeviceProtection, TechSupport, StreamingTV, StreamingMovies, Contract, PaperlessBilling, PaymentMethod, Churn

SELECT DISTINCT Churn
FROM customerChurn_staging;

-- They have the expected values (no typos or alternative values) so no corrections needed

-- Types: SeniorCitizen is a binary value (0 or 1) to indicate whether the customer falls into that category. Currently it is stored as an integer.
-- I will be converting it into a BIT type
ALTER TABLE customerChurn_staging
ALTER COLUMN SeniorCitizen BIT;

-- The following columns are binary values (either Yes or No). Currently they are stored as a nvarchar: Partner, Dependents, PhoneService, PaperlessBilling, Churn
-- I will be converting them into a BIT type. I will avoid direct conversions as that is not supported in SQL Server
-- 1) Add new BIT columns
ALTER TABLE customerChurn_staging ADD Partner_Bit BIT;
ALTER TABLE customerChurn_staging ADD Dependents_Bit BIT;
ALTER TABLE customerChurn_staging ADD PhoneService_Bit BIT;
ALTER TABLE customerChurn_staging ADD PaperlessBilling_Bit BIT;
ALTER TABLE customerChurn_staging ADD Churn_Bit BIT;

-- 2) Update BIT columns: 'Yes' -> 1, 'No' -> 0
UPDATE customerChurn_staging
SET Partner_Bit = CASE WHEN Partner = 'Yes' THEN 1 ELSE 0 END,
    Dependents_Bit = CASE WHEN Dependents = 'Yes' THEN 1 ELSE 0 END,
    PhoneService_Bit = CASE WHEN PhoneService = 'Yes' THEN 1 ELSE 0 END,
    PaperlessBilling_Bit = CASE WHEN PaperlessBilling = 'Yes' THEN 1 ELSE 0 END,
    Churn_Bit = CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END;

-- 3) Drop old NVARCHAR columns
ALTER TABLE customerChurn_staging DROP COLUMN Partner;
ALTER TABLE customerChurn_staging DROP COLUMN Dependents;
ALTER TABLE customerChurn_staging DROP COLUMN PhoneService;
ALTER TABLE customerChurn_staging DROP COLUMN PaperlessBilling;
ALTER TABLE customerChurn_staging DROP COLUMN Churn;

-- 4) Rename new BIT columns to match original names
EXEC sp_rename 'customerChurn_staging.Partner_Bit', 'Partner', 'COLUMN';
EXEC sp_rename 'customerChurn_staging.Dependents_Bit', 'Dependents', 'COLUMN';
EXEC sp_rename 'customerChurn_staging.PhoneService_Bit', 'PhoneService', 'COLUMN';
EXEC sp_rename 'customerChurn_staging.PaperlessBilling_Bit', 'PaperlessBilling', 'COLUMN';
EXEC sp_rename 'customerChurn_staging.Churn_Bit', 'Churn', 'COLUMN';

SELECT *
FROM customerChurn_staging;

-- 3. Filter out null/blank rows
DELETE
FROM customerChurn_staging
WHERE ((customerID IS NULL OR customerID = '') OR (gender IS NULL OR gender = '')) OR (tenure IS NULL or tenure = '')
OR churn IS NULL OR ((MonthlyCharges IS NULL OR TotalCharges IS NULL));

-- INITIAL EXPLORATORY ANALYSIS

-- Get basic statistics (Min, Max, Avg) for key numeric columns
SELECT 
    MIN(tenure) AS MinTenure, MAX(tenure) AS MaxTenure, AVG(tenure) AS AvgTenure,
    MIN(MonthlyCharges) AS MinMonthlyCharges, MAX(MonthlyCharges) AS MaxMonthlyCharges, AVG(MonthlyCharges) AS AvgMonthlyCharges,
    MIN(TotalCharges) AS MinTotalCharges, MAX(TotalCharges) AS MaxTotalCharges, AVG(TotalCharges) AS AvgTotalCharges
FROM customerChurn_staging;
-- There is a wide range in how long customers stay, with some leaving after just one month. This suggests that early churn could be a key issue worth investigating.
--  Some customers have only paid a small total amount, indicating they churned early. 
-- Comparing Total Charges vs. Tenure could help identify whether early cancellations are a major churn factor.

-- How many churners are there?
SELECT Churn, COUNT(*) AS Count, 
       COUNT(*) * 100.0 / SUM(COUNT(*)) OVER () AS Percentage
FROM customerChurn_staging
GROUP BY Churn;

-- Tenure vs churns
SELECT tenure, COUNT(*) AS Count, 
       SUM(CASE WHEN Churn = 1 THEN 1 ELSE 0 END) AS ChurnCount,
       SUM(CASE WHEN Churn = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS ChurnRate
FROM customerChurn_staging
GROUP BY tenure
ORDER BY ChurnRate DESC;
-- Generally the lower the tenure, the higher the churn rate


-- How many of the customers that left were male compare to female?
SELECT gender, 
       COUNT(*) AS TotalCustomers, COUNT(*) * 100.0 / SUM(COUNT(*)) OVER () AS GenderPercentage,
       SUM(CASE WHEN Churn = 1 THEN 1 ELSE 0 END) AS Churners,
       SUM(CASE WHEN Churn = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS ChurnRate
FROM customerChurn_staging
GROUP BY gender;
-- Both genders have similar churn rates


-- Check churn by payment method. Do automatic payments have lower churn rates than manual payments?
SELECT PaymentMethod, COUNT(*) AS TotalCustomers,
       SUM(CASE WHEN Churn = 1 THEN 1 ELSE 0 END) AS Churners,
       SUM(CASE WHEN Churn = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS ChurnRate
FROM customerChurn_staging
GROUP BY PaymentMethod
ORDER BY ChurnRate DESC;
-- Customers who pay with electronic check have the highest churn rate at 45.3%. This rate is significantly reduced for the remaining 3 payment
-- methods, mailed check, bank transfer (automatic), and credit card (automatic). Find ways to encourage customers to choose automatic payment methods.

-- Are customers on month-to-month contracts churning more than those with long-term contracts?
SELECT Contract, COUNT(*) AS TotalCustomers,
       SUM(CASE WHEN Churn = 1 THEN 1 ELSE 0 END) AS Churners,
       SUM(CASE WHEN Churn = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS ChurnRate
FROM customerChurn_staging
GROUP BY Contract
ORDER BY ChurnRate DESC;
-- Unsurprisingly, the shortest contract period, month-to-month is most common amongst churners. 

-- Senior citizens vs. churn
SELECT SeniorCitizen, 
       COUNT(*) AS TotalCustomers, COUNT(*) * 100.0 / SUM(COUNT(*)) OVER () AS SeniorPercentage,
       SUM(CASE WHEN Churn = 1 THEN 1 ELSE 0 END) AS Churners,
       SUM(CASE WHEN Churn = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS ChurnRate
FROM customerChurn_staging
GROUP BY SeniorCitizen;
-- Senior citizens have a somewhat high churn rate compared to those who are specified as non-senior citizens

-- Total Charges vs. Churn
SELECT 
    TotalChargeCategory, 
    COUNT(*) AS CustomerCount,
	SUM(CASE WHEN Churn = 1 THEN 1 ELSE 0 END) AS Churners,
    SUM(CASE WHEN Churn = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS ChurnRate,
    AVG(tenure) AS AvgTenure
FROM (
    SELECT 
        tenure,
		Churn,
        TotalCharges,
        CASE 
            WHEN TotalCharges < 1000 THEN 'Low'
            WHEN TotalCharges BETWEEN 1000 AND 3000 THEN 'Medium'
            WHEN TotalCharges BETWEEN 3000 AND 6000 THEN 'High'
            ELSE 'Very High'
        END AS TotalChargeCategory
    FROM customerChurn_staging
) AS BinnedData
GROUP BY TotalChargeCategory
ORDER BY ChurnRate DESC;
-- A significant portion of customers (~37%) fall into the Low category and leave within a year. 
-- The company may need to analyze why early churn happens (e.g., pricing issues, service dissatisfaction).
-- The Very High category has fewer customers (692) but stays the longest, making them valuable for long-term revenue. Retention efforts should focus on this group.

-- Check churn rates by tenure: Do most churners leave within the first few months?
SELECT 
    tenureCategory, 
    AVG(tenure) AS AvgTenure,
	SUM(CASE WHEN Churn = 1 THEN 1 ELSE 0 END) AS Churners,
    SUM(CASE WHEN Churn = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS ChurnRate
FROM (
    SELECT 
        tenure,
        churn,
        CASE 
            WHEN tenure < 26 THEN 'Low'
            WHEN tenure BETWEEN 26 AND 50 THEN 'Medium'
            WHEN tenure BETWEEN 51 AND 75 THEN 'High'
            ELSE 'Very High'
        END AS tenureCategory
    FROM customerChurn_staging
) AS BinnedData
GROUP BY tenureCategory
ORDER BY AvgTenure DESC;
-- The low tenure group (0 - 25 months) has the highest churn rate at 41.3% - meaning nearly half of these customers leave within two years.
-- Churn rate drops to half that at 19.8% at the medium tenure group (26 - 50 months) and even more to 8.9% at the high tenure group (> 51 months)
-- Early-stage churn is the biggest issue. Since most churn happens within the first two years, focusing retention strategies on new customers is critical.
-- New customer onboarding & engagement should be a priority. Offering discounts, better customer support, or loyalty incentives within the first year 
-- could reduce churn.

-- Are high-paying customers more or less likely to churn?
SELECT 
    MonthlyChargeCategory, 
    COUNT(*) AS CustomerCount,
    SUM(CASE WHEN Churn = 1 THEN 1 ELSE 0 END) AS Churners,
    SUM(CASE WHEN Churn = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS ChurnRate
FROM (
    SELECT 
        Churn,
        MonthlyCharges,
        CASE 
            WHEN MonthlyCharges < 41 THEN 'Low'
            WHEN MonthlyCharges BETWEEN 41 AND 80 THEN 'Medium'
            WHEN MonthlyCharges BETWEEN 81 AND 120 THEN 'High'
            ELSE 'Very High'
        END AS MonthlyChargeCategory
    FROM customerChurn_staging
) AS BinnedData
GROUP BY MonthlyChargeCategory
ORDER BY ChurnRate DESC;
-- The results indicate a strong correlation between higher monthly charges and increased churn rates.
-- Customers in the Very High Monthly Charge category ($~120+) churn at the highest rate of 37.3%.
-- The High Monthly Charge group ($80-120) follows closely with a 33.8% churn rate.
-- The Medium Monthly Charge group ($40-80) has a lower churn rate of 29.6%, but it's still significant.
-- In contrast, the Low Monthly Charge group ($<40) has the lowest churn rate at only 12%, showing that low-cost customers are far more likely to stay.
-- Customers with higher bills may feel the financial strain, making them more likely to cancel services.
-- If customers paying premium prices don't feel they're getting enough value, they might churn in favor of cheaper competitors.
-- Focus on retention strategies for high-paying customers like loyalty discounts or bundled perks to make premium plans feel more valuable
-- Investigate low-charge customers. Are they getting fewer services or just better pricing?


SELECT 
    SeniorCitizen, 
    Partner, 
    Dependents, 
    MonthlyChargeCategory, 
    COUNT(*) AS CustomerCount, 
    SUM(CASE WHEN Churn = 1 THEN 1 ELSE 0 END) AS Churners,
    SUM(CASE WHEN Churn = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS ChurnRate
FROM (
    SELECT 
		SeniorCitizen, 
		Partner, 
		Dependents,
        Churn,
        MonthlyCharges,
        CASE 
            WHEN MonthlyCharges < 41 THEN 'Low'
            WHEN MonthlyCharges BETWEEN 41 AND 80 THEN 'Medium'
            WHEN MonthlyCharges BETWEEN 81 AND 120 THEN 'High'
            ELSE 'Very High'
        END AS MonthlyChargeCategory
    FROM customerChurn_staging
) AS BinnedData
GROUP BY SeniorCitizen, Partner, Dependents, MonthlyChargeCategory
ORDER BY ChurnRate DESC;
-- Senior citizens without a partner/dependents and those with high monthly charges are the biggest churn risks.
-- Lowering prices or offering better value for high-paying customers can help reduce churn.
-- Encouraging partner/family engagement stabilizes retention.


-- Look at service usage. Are certain features (e.g., streaming, online security) correlated with retention?
SELECT 
    Feature,
    SUM(CASE WHEN HasFeature = 1 AND Churn = 1 THEN 1 ELSE 0 END) AS Churners,
    SUM(CASE WHEN HasFeature = 1 THEN 1 ELSE 0 END) AS TotalUsersWithFeature,
    (SUM(CASE WHEN HasFeature = 1 AND Churn = 1 THEN 1 ELSE 0 END) * 100.0 /
     NULLIF(SUM(CASE WHEN HasFeature = 1 THEN 1 ELSE 0 END), 0)) AS ChurnRate_WithFeature,
    SUM(CASE WHEN HasFeature = 0 AND Churn = 1 THEN 1 ELSE 0 END) AS Churners_WithoutFeature,
    SUM(CASE WHEN HasFeature = 0 THEN 1 ELSE 0 END) AS TotalUsersWithoutFeature,
    (SUM(CASE WHEN HasFeature = 0 AND Churn = 1 THEN 1 ELSE 0 END) * 100.0 /
     NULLIF(SUM(CASE WHEN HasFeature = 0 THEN 1 ELSE 0 END), 0)) AS ChurnRate_WithoutFeature
FROM (
    SELECT 
        Churn,
        -- Convert 'Yes' to 1 and 'No'/'No internet service' to 0
        CASE WHEN OnlineSecurity = 'Yes' THEN 1 ELSE 0 END AS HasFeature, 
        'Online Security' AS Feature
    FROM customerChurn_staging
    UNION ALL
    SELECT 
        Churn,
        CASE WHEN OnlineBackup = 'Yes' THEN 1 ELSE 0 END, 
        'Online Backup'
    FROM customerChurn_staging
    UNION ALL
    SELECT 
        Churn,
        CASE WHEN DeviceProtection = 'Yes' THEN 1 ELSE 0 END, 
        'Device Protection'
    FROM customerChurn_staging
    UNION ALL
    SELECT 
        Churn,
        CASE WHEN TechSupport = 'Yes' THEN 1 ELSE 0 END, 
        'Tech Support'
    FROM customerChurn_staging
    UNION ALL
    SELECT 
        Churn,
        CASE WHEN StreamingTV = 'Yes' THEN 1 ELSE 0 END, 
        'Streaming TV'
    FROM customerChurn_staging
    UNION ALL
    SELECT 
        Churn,
        CASE WHEN StreamingMovies = 'Yes' THEN 1 ELSE 0 END, 
        'Streaming Movies'
    FROM customerChurn_staging
) AS FeaturesAnalysis
GROUP BY Feature
ORDER BY ChurnRate_WithFeature DESC;
-- Streaming services correlate with higher churn. Customers with Streaming TV/Movies churn ~5.5% more than those without.
-- Streaming services might be seen as optional add-ons that don’t increase customer stickiness. Customers might cancel when they find alternative platforms or better deals.
-- Strategy: Bundle streaming with contracts or offer retention deals.

-- Tech Support & Security drastically reduce churn. Churn drops from ~31% to ~15% with these services.
-- These services increase customer reliance on the provider, making them less likely to switch.
-- Strategy: Upsell security & support services to at-risk customers.

-- Device Protection & Online Backup help reduce churn, but to a lesser extent. Churn drops by 6–7% for customers with these services.
-- Customers with backup & protection services churn less, though the effect isn’t as strong as Tech Support/Security.
-- Strategy: Offer discounted first 3 months for these services to increase adoption.

exec sp_rename 'customerChurn_staging', 'customerChurn_cleaned'

SELECT * 
from customerChurn_cleaned;