/* CASE 06 — Key lookups and covering indexes
   An index on Status finds the rows quickly, but the query also needs
   CustomerId, Principal and DisbursedOn, which are not in that index.
   For each row SQL Server goes back to the clustered index = "Key Lookup". */
USE PerfLab;
SET STATISTICS IO, TIME ON;
GO

-- Make sure the narrow index from case 05 exists
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Loan_Status')
    CREATE NONCLUSTERED INDEX IX_Loan_Status ON dbo.Loan (Status);
GO

-- SLOW: Index Seek + Key Lookup per row (force the narrow index to show it)
SELECT LoanId, CustomerId, Principal, DisbursedOn
FROM dbo.Loan WITH (INDEX(IX_Loan_Status))
WHERE Status = 'Closed';

-- FIX: covering index — all needed columns live in the index
CREATE NONCLUSTERED INDEX IX_Loan_Status_Covering
    ON dbo.Loan (Status) INCLUDE (CustomerId, Principal, DisbursedOn);
GO

-- FAST: Index Seek only, no lookups
SELECT LoanId, CustomerId, Principal, DisbursedOn
FROM dbo.Loan
WHERE Status = 'Closed';

-- The narrow index is now redundant (the covering one has the same key)
DROP INDEX IX_Loan_Status ON dbo.Loan;

/* WHY: Each key lookup is a few page reads. 18,000 rows x ~3 reads = ~54,000 reads.
   The covering index returns everything from one seek + range scan.
   Note: LoanId (the clustered key) is stored in every nonclustered index automatically. */
