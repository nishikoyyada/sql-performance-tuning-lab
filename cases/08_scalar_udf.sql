/* CASE 08 — Scalar user-defined function vs inline table-valued function
   Scalar UDFs run once per row and (before SQL Server 2019) block parallel plans. */
USE PerfLab;
SET STATISTICS IO, TIME ON;
GO

CREATE OR ALTER FUNCTION dbo.fn_LoanOutstanding (@LoanId INT)
RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @Out DECIMAL(18,2);
    SELECT @Out = SUM(AmountDue - ISNULL(AmountPaid, 0))
    FROM dbo.Repayment WHERE LoanId = @LoanId;
    RETURN ISNULL(@Out, 0);
END
GO

CREATE OR ALTER FUNCTION dbo.itvf_LoanOutstanding (@LoanId INT)
RETURNS TABLE
AS RETURN
    SELECT ISNULL(SUM(AmountDue - ISNULL(AmountPaid, 0)), 0) AS Outstanding
    FROM dbo.Repayment WHERE LoanId = @LoanId;
GO

-- SLOW: function body runs once per loan.
-- TSQL_SCALAR_UDF_INLINING is turned off here so you see the classic behaviour
-- even on SQL Server 2019+ (where the engine may inline simple scalar UDFs).
SELECT TOP (20000) l.LoanId, dbo.fn_LoanOutstanding(l.LoanId) AS Outstanding
FROM dbo.Loan l
ORDER BY l.LoanId
OPTION (USE HINT('DISABLE_TSQL_SCALAR_UDF_INLINING'));

-- FAST: inline TVF is expanded into the main query -> one join plan
SELECT TOP (20000) l.LoanId, o.Outstanding
FROM dbo.Loan l
CROSS APPLY dbo.itvf_LoanOutstanding(l.LoanId) o
ORDER BY l.LoanId;

/* WHY: The optimizer treats a scalar UDF as a black box: it can't see inside,
   estimates 1 row, and calls it row by row. An inline TVF is just a parameterized
   view — the optimizer merges it into the outer query and can pick a hash or merge join.
   Tip: SET STATISTICS IO does NOT show the reads inside a scalar UDF, so it can look
   cheap in IO stats while being slow. Check elapsed time, or use Extended Events. */
