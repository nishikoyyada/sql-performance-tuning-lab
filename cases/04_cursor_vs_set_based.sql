/* CASE 04 — Row-by-row (cursor) vs set-based
   Task: set RiskCategory for every loan based on its unpaid repayments. */
USE PerfLab;
SET NOCOUNT ON;
GO
UPDATE dbo.Loan SET RiskCategory = NULL;
GO

-- SLOW: cursor processes 200,000 loans one at a time
DECLARE @start DATETIME2 = SYSDATETIME();
DECLARE @LoanId INT, @Unpaid INT;
DECLARE loan_cur CURSOR LOCAL FAST_FORWARD FOR SELECT LoanId FROM dbo.Loan;
OPEN loan_cur;
FETCH NEXT FROM loan_cur INTO @LoanId;
WHILE @@FETCH_STATUS = 0
BEGIN
    SELECT @Unpaid = COUNT(*) FROM dbo.Repayment WHERE LoanId = @LoanId AND PaidDate IS NULL;
    UPDATE dbo.Loan
       SET RiskCategory = CASE WHEN @Unpaid >= 2 THEN 'High' WHEN @Unpaid = 1 THEN 'Medium' ELSE 'Low' END
     WHERE LoanId = @LoanId;
    FETCH NEXT FROM loan_cur INTO @LoanId;
END
CLOSE loan_cur; DEALLOCATE loan_cur;
PRINT CONCAT('Cursor: ', DATEDIFF(MILLISECOND, @start, SYSDATETIME()), ' ms');
GO

UPDATE dbo.Loan SET RiskCategory = NULL;
GO

-- FAST: one set-based UPDATE
DECLARE @start DATETIME2 = SYSDATETIME();
UPDATE l
   SET RiskCategory = CASE WHEN ISNULL(r.Unpaid, 0) >= 2 THEN 'High'
                           WHEN r.Unpaid = 1 THEN 'Medium' ELSE 'Low' END
FROM dbo.Loan l
LEFT JOIN (
    SELECT LoanId, COUNT(*) AS Unpaid
    FROM dbo.Repayment
    WHERE PaidDate IS NULL
    GROUP BY LoanId
) r ON r.LoanId = l.LoanId;
PRINT CONCAT('Set-based: ', DATEDIFF(MILLISECOND, @start, SYSDATETIME()), ' ms');
GO

/* WHY: The cursor runs 400,000 small statements (one SELECT + one UPDATE per loan),
   each with its own overhead and log writes. The set-based version reads Repayment
   once, groups it, and updates all loans in a single statement.
   (Run case 01 first if you want the cursor version to be "only" slow, not very slow.) */
