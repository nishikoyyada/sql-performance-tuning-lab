-- Loads test data with set-based inserts (no loops).
-- 50 branches, 100,000 customers, 200,000 loans, 1,000,000 repayments.
USE PerfLab;
GO
SET NOCOUNT ON;

-- Numbers helper (1 .. 1,000,000)
;WITH n AS (
    SELECT TOP (1000000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
)
SELECT n INTO #Numbers FROM n;
CREATE UNIQUE CLUSTERED INDEX IX_N ON #Numbers(n);

DECLARE @cities TABLE (Id INT, City VARCHAR(50));
INSERT @cities VALUES (0,'Hyderabad'),(1,'Bengaluru'),(2,'Chennai'),(3,'Pune'),(4,'Mumbai'),
                      (5,'Delhi'),(6,'Kolkata'),(7,'Warangal'),(8,'Vijayawada'),(9,'Kochi');

INSERT dbo.Branch (BranchName, City)
SELECT CONCAT('Branch ', n), c.City
FROM #Numbers JOIN @cities c ON c.Id = n % 10
WHERE n <= 50;

INSERT dbo.Customer (FullName, PanNumber, Mobile, City, CreatedOn)
SELECT CONCAT('Customer ', n),
       CONCAT(CHAR(65 + n % 26), 'BCDE', RIGHT(CONCAT('0000', n % 10000), 4), CHAR(65 + (n / 26) % 26)),
       CONCAT('9', RIGHT(CONCAT('000000000', n), 9)),
       c.City,
       DATEADD(DAY, -(n % 2000), '2026-01-01')
FROM #Numbers JOIN @cities c ON c.Id = n % 10
WHERE n <= 100000;

-- Skewed status distribution (important for parameter sniffing in case 05):
-- ~90% Active, ~9% Closed, ~1% Overdue
INSERT dbo.Loan (CustomerId, BranchId, Principal, InterestRate, TenureMonths, Status, DisbursedOn)
SELECT 1 + (n % 100000),
       1 + (n % 50),
       50000 + (n % 50) * 10000,
       10 + (n % 8),
       CASE n % 3 WHEN 0 THEN 12 WHEN 1 THEN 24 ELSE 36 END,
       CASE WHEN n % 100 = 0 THEN 'Overdue' WHEN n % 100 < 10 THEN 'Closed' ELSE 'Active' END,
       DATEADD(DAY, -(n % 1500), '2026-06-30')
FROM #Numbers WHERE n <= 200000;

-- 5 repayments per loan = 1,000,000 rows
INSERT dbo.Repayment (LoanId, DueDate, PaidDate, AmountDue, AmountPaid, PenaltyAmount)
SELECT l.LoanId,
       DATEADD(MONTH, k.k, l.DisbursedOn),
       CASE WHEN (l.LoanId + k.k) % 7 = 0 THEN NULL
            ELSE DATEADD(DAY, (l.LoanId + k.k) % 10, DATEADD(MONTH, k.k, l.DisbursedOn)) END,
       l.Principal / l.TenureMonths,
       CASE WHEN (l.LoanId + k.k) % 7 = 0 THEN NULL ELSE l.Principal / l.TenureMonths END,
       0
FROM dbo.Loan l
CROSS JOIN (VALUES (1),(2),(3),(4),(5)) k(k);

DROP TABLE #Numbers;

SELECT 'Branch' AS TableName, COUNT(*) AS RowsLoaded FROM dbo.Branch UNION ALL
SELECT 'Customer', COUNT(*) FROM dbo.Customer UNION ALL
SELECT 'Loan', COUNT(*) FROM dbo.Loan UNION ALL
SELECT 'Repayment', COUNT(*) FROM dbo.Repayment;
GO
