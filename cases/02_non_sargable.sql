/* CASE 02 — Non-SARGable filter
   SARGable = "Search ARGument-able": the filter can use an index seek.
   Wrapping a column in a function (YEAR(), CONVERT(), ISNULL()...) usually breaks this. */
USE PerfLab;
SET STATISTICS IO, TIME ON;
GO

CREATE NONCLUSTERED INDEX IX_Repayment_DueDate_Incl
    ON dbo.Repayment (DueDate) INCLUDE (LoanId, AmountDue, AmountPaid);
GO

-- SLOW: index exists, but YEAR()/MONTH() on the column forces a scan
SELECT COUNT(*), SUM(AmountDue)
FROM dbo.Repayment
WHERE YEAR(DueDate) = 2025 AND MONTH(DueDate) = 3;

-- FAST: same logic as a range on the raw column -> Index Seek
SELECT COUNT(*), SUM(AmountDue)
FROM dbo.Repayment
WHERE DueDate >= '2025-03-01' AND DueDate < '2025-04-01';

/* WHY: The index is sorted by DueDate, not by YEAR(DueDate). SQL Server cannot know
   where YEAR(...) = 2025 starts without calculating it for every row.
   A range on the raw column lets it seek to 2025-03-01 and stop at 2025-04-01.
   Use ">= start AND < next start" so it works for any time portion too. */
