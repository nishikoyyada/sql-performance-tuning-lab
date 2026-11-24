/* CASE 03 — Implicit conversion
   PanNumber is VARCHAR(10). .NET sends strings as NVARCHAR by default
   (e.g. AddWithValue("@pan", "...")). The type mismatch can turn a seek into a scan. */
USE PerfLab;
SET STATISTICS IO, TIME ON;
GO

CREATE NONCLUSTERED INDEX IX_Customer_PanNumber ON dbo.Customer (PanNumber);
GO

-- SLOW: NVARCHAR parameter vs VARCHAR column.
-- Look for the CONVERT_IMPLICIT warning (yellow triangle) in the actual plan.
DECLARE @panN NVARCHAR(20) = N'BBCDE0001A';
SELECT CustomerId, FullName FROM dbo.Customer WHERE PanNumber = @panN;

-- FAST: matching type -> clean Index Seek
DECLARE @pan VARCHAR(10) = 'BBCDE0001A';
SELECT CustomerId, FullName FROM dbo.Customer WHERE PanNumber = @pan;

/* WHY: NVARCHAR has higher type precedence, so SQL Server converts the COLUMN
   (every row) to NVARCHAR instead of converting the parameter once.
   With a SQL collation (e.g. SQL_Latin1_General_CP1_CI_AS) this becomes a full scan.
   With a Windows collation SQL Server can still seek, but the plan is more expensive.

   Fix in C# / ADO.NET — set the type and size explicitly:
       cmd.Parameters.Add("@pan", SqlDbType.VarChar, 10).Value = pan;
   instead of:
       cmd.Parameters.AddWithValue("@pan", pan);   // sends NVARCHAR */
