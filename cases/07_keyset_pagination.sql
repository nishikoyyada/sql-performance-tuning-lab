/* CASE 07 — OFFSET pagination vs keyset (seek) pagination
   Screens with "page 1, 2, 3..." often use OFFSET/FETCH.
   Deep pages get slower because SQL Server must read and throw away all earlier rows. */
USE PerfLab;
SET STATISTICS IO, TIME ON;
GO

-- SLOW on deep pages: reads 900,050 rows to return 50
SELECT RepaymentId, LoanId, DueDate, AmountDue
FROM dbo.Repayment
ORDER BY RepaymentId
OFFSET 900000 ROWS FETCH NEXT 50 ROWS ONLY;

-- FAST: remember the last key the client saw and seek past it
DECLARE @LastRepaymentId BIGINT = 900000;
SELECT TOP (50) RepaymentId, LoanId, DueDate, AmountDue
FROM dbo.Repayment
WHERE RepaymentId > @LastRepaymentId
ORDER BY RepaymentId;

/* WHY: Keyset pagination seeks directly to the next key, so every page costs the same.
   Trade-off: you can't jump to "page 18,000" directly — it suits "Next / Load more"
   and infinite scroll. For sorting by non-unique columns, use (SortColumn, Id) as the key:
       WHERE (DueDate > @LastDue) OR (DueDate = @LastDue AND RepaymentId > @LastId) */
