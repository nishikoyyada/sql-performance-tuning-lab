/* CASE 05 — Parameter sniffing
   Status values are skewed: Active ~90%, Closed ~9%, Overdue ~1%.
   A stored procedure compiles its plan using the FIRST parameter value it sees,
   then reuses that plan for every other value. */
USE PerfLab;
SET STATISTICS IO, TIME ON;
GO

CREATE NONCLUSTERED INDEX IX_Loan_Status ON dbo.Loan (Status);
GO
CREATE OR ALTER PROCEDURE dbo.usp_GetLoansByStatus @Status VARCHAR(20)
AS
BEGIN
    SELECT LoanId, CustomerId, Principal, DisbursedOn
    FROM dbo.Loan WHERE Status = @Status;
END
GO

-- First call with a RARE value -> plan = Index Seek + Key Lookup (good for ~2,000 rows)
EXEC sp_recompile 'dbo.usp_GetLoansByStatus';
EXEC dbo.usp_GetLoansByStatus @Status = 'Overdue';

-- SLOW: same plan reused for a COMMON value -> ~180,000 key lookups
EXEC dbo.usp_GetLoansByStatus @Status = 'Active';
GO

-- FIX option A: recompile each time (small CPU cost, always the right plan)
CREATE OR ALTER PROCEDURE dbo.usp_GetLoansByStatus_Fixed @Status VARCHAR(20)
AS
BEGIN
    SELECT LoanId, CustomerId, Principal, DisbursedOn
    FROM dbo.Loan WHERE Status = @Status
    OPTION (RECOMPILE);
END
GO
EXEC dbo.usp_GetLoansByStatus_Fixed @Status = 'Overdue';  -- seek
EXEC dbo.usp_GetLoansByStatus_Fixed @Status = 'Active';   -- scan (right choice for 90% of rows)
GO

/* Other options:
   B) OPTION (OPTIMIZE FOR (@Status = 'Active'))  -- tune for the most common value
   C) OPTION (OPTIMIZE FOR UNKNOWN)               -- use average statistics
   D) A covering index (see case 06) so both values get a good plan
   E) SQL Server 2022: Parameter Sensitive Plan optimization can keep several plans

   WHY: Neither plan is "wrong" — each is right for one kind of value.
   The problem is reusing one plan for very different row counts. */
