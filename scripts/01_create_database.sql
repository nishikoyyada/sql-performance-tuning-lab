-- Creates the lab database and tables.
-- Tables have only primary keys at first, so the "slow" cases are really slow.

IF DB_ID('PerfLab') IS NOT NULL
BEGIN
    ALTER DATABASE PerfLab SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE PerfLab;
END
GO
CREATE DATABASE PerfLab;
GO
USE PerfLab;
GO

CREATE TABLE dbo.Branch (
    BranchId   INT IDENTITY(1,1) PRIMARY KEY,
    BranchName VARCHAR(100) NOT NULL,
    City       VARCHAR(50)  NOT NULL
);

CREATE TABLE dbo.Customer (
    CustomerId  INT IDENTITY(1,1) PRIMARY KEY,
    FullName    VARCHAR(100) NOT NULL,
    PanNumber   VARCHAR(10)  NOT NULL,   -- VARCHAR on purpose (used in case 03)
    Mobile      VARCHAR(15)  NOT NULL,
    City        VARCHAR(50)  NOT NULL,
    CreatedOn   DATETIME2(0) NOT NULL
);

CREATE TABLE dbo.Loan (
    LoanId        INT IDENTITY(1,1) PRIMARY KEY,
    CustomerId    INT NOT NULL REFERENCES dbo.Customer(CustomerId),
    BranchId      INT NOT NULL REFERENCES dbo.Branch(BranchId),
    Principal     DECIMAL(18,2) NOT NULL,
    InterestRate  DECIMAL(5,2)  NOT NULL,
    TenureMonths  INT NOT NULL,
    Status        VARCHAR(20)   NOT NULL,  -- Active / Closed / Overdue
    DisbursedOn   DATE NOT NULL,
    RiskCategory  VARCHAR(10)   NULL
);

CREATE TABLE dbo.Repayment (
    RepaymentId   BIGINT IDENTITY(1,1) PRIMARY KEY,
    LoanId        INT NOT NULL REFERENCES dbo.Loan(LoanId),
    DueDate       DATE NOT NULL,
    PaidDate      DATE NULL,
    AmountDue     DECIMAL(18,2) NOT NULL,
    AmountPaid    DECIMAL(18,2) NULL,
    PenaltyAmount DECIMAL(18,2) NOT NULL DEFAULT 0
);
GO
