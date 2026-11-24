/* CASE 01 — Missing index
   Problem: find all repayments for one loan. Repayment has 1,000,000 rows and
   no index on LoanId, so SQL Server must scan the whole table. */
USE PerfLab;
SET STATISTICS IO, TIME ON;
GO

-- SLOW: Clustered Index Scan over all rows
SELECT RepaymentId, DueDate, AmountDue, AmountPaid
FROM dbo.Repayment
WHERE LoanId = 12345;

-- FIX: index on the filter column, INCLUDE the selected columns
CREATE NONCLUSTERED INDEX IX_Repayment_LoanId_Incl
    ON dbo.Repayment (LoanId)
    INCLUDE (DueDate, AmountDue, AmountPaid, PaidDate);
GO

-- FAST: Index Seek, only a few pages read
SELECT RepaymentId, DueDate, AmountDue, AmountPaid
FROM dbo.Repayment
WHERE LoanId = 12345;

/* WHY: Without an index, the only way to find LoanId = 12345 is to read every row.
   The new index is sorted by LoanId, so SQL Server jumps straight to the 5 matching rows.
   INCLUDE stores the other columns in the index, so no extra lookup is needed.
   Trade-off: every INSERT/UPDATE on Repayment now also updates this index. */
