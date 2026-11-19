/* =====================================================================
   04_validation.sql
   Row-count and sanity checks for every layer.
   Run section A after the SSIS load, and sections B to D after 03_load_dwh.sql.
   ===================================================================== */

-- ===================== A. Staging row counts =====================
-- Expected: airlines 14, airports 322, flights 5,819,079
USE Flights_Staging;
GO
SELECT 'airlines' AS tbl, COUNT(*) AS cnt FROM airlines
UNION ALL SELECT 'airports', COUNT(*) FROM airports
UNION ALL SELECT 'flights',  COUNT(*) FROM flights;

-- Empty fields must be real NULLs (EmptyDelay should be 0)
SELECT
  SUM(CASE WHEN CANCELLED = '1'     THEN 1 ELSE 0 END) AS Cancelled,      -- about 89,884
  SUM(CASE WHEN AIRLINE_DELAY IS NULL THEN 1 ELSE 0 END) AS NullDelay,
  SUM(CASE WHEN AIRLINE_DELAY = ''    THEN 1 ELSE 0 END) AS EmptyDelay    -- expected 0
FROM flights;

SELECT TOP 5 * FROM flights;
GO

-- ===================== B. Warehouse counts ========================
-- Expected: Dim_Airline 14, Dim_Airport 323 (322 + Unknown),
--           Dim_CancelReason 5, Dim_Date 365, Fact_Flights 5,819,079
USE Flights_DWH;
GO
SELECT 'Dim_Airline' AS tbl, COUNT(*) AS cnt FROM Dim_Airline
UNION ALL SELECT 'Dim_Airport',      COUNT(*) FROM Dim_Airport
UNION ALL SELECT 'Dim_CancelReason', COUNT(*) FROM Dim_CancelReason
UNION ALL SELECT 'Dim_Date',         COUNT(*) FROM Dim_Date
UNION ALL SELECT 'Fact_Flights',     COUNT(*) FROM Fact_Flights;

-- ===================== C. Fact table checks =======================
-- Expected: Cancelled 89,884 | Diverted 15,187 | UnknownOrigin 486,165
SELECT SUM(CAST(IsCancelled AS INT)) AS Cancelled,
       SUM(CAST(IsDiverted  AS INT)) AS Diverted,
       SUM(CASE WHEN OriginAirportKey = -1 THEN 1 ELSE 0 END) AS UnknownOrigin
FROM Fact_Flights;

-- Fact rows must equal staging rows (no rows lost in the joins)
SELECT (SELECT COUNT(*) FROM Flights_Staging.dbo.flights) AS StagingRows,
       (SELECT COUNT(*) FROM Fact_Flights)                AS FactRows;

-- ===================== D. Business sanity checks ==================
-- Top airlines by volume (Southwest should lead with 1,261,855 flights)
SELECT TOP 5 al.AirlineName, COUNT(*) AS Flights, AVG(1.0 * ArrivalDelay) AS AvgArrDelay
FROM Fact_Flights f
JOIN Dim_Airline al ON f.AirlineKey = al.AirlineKey
GROUP BY al.AirlineName
ORDER BY Flights DESC;

-- Overall average arrival delay (about 4.4 minutes)
SELECT AVG(1.0 * ArrivalDelay) AS AvgArrivalDelay FROM Fact_Flights;
