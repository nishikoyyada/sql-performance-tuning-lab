-- Removes everything the cases created, so you can run them again from the start.
USE PerfLab;
GO
DROP INDEX IF EXISTS IX_Repayment_LoanId_Incl  ON dbo.Repayment;
DROP INDEX IF EXISTS IX_Repayment_DueDate_Incl ON dbo.Repayment;
DROP INDEX IF EXISTS IX_Customer_PanNumber     ON dbo.Customer;
DROP INDEX IF EXISTS IX_Loan_Status            ON dbo.Loan;
DROP INDEX IF EXISTS IX_Loan_Status_Covering   ON dbo.Loan;
DROP INDEX IF EXISTS IX_Loan_Branch_LoanId     ON dbo.Loan;
DROP FUNCTION  IF EXISTS dbo.fn_LoanOutstanding;
DROP FUNCTION  IF EXISTS dbo.itvf_LoanOutstanding;
DROP PROCEDURE IF EXISTS dbo.usp_GetLoansByStatus;
DROP PROCEDURE IF EXISTS dbo.usp_GetLoansByStatus_Fixed;
UPDATE dbo.Loan SET RiskCategory = NULL;
GO
