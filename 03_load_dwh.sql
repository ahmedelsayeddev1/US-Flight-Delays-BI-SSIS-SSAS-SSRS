/* =====================================================================
   03_load_dwh.sql
   Loads Flights_DWH from Flights_Staging (same SQL Server instance).
   Run after the SSIS staging load is complete.
   Order matters: dimensions first, then the fact table.
   ===================================================================== */

USE Flights_DWH;
GO

-- ------------------------- Dim_Airline -------------------------
INSERT INTO Dim_Airline (AirlineCode, AirlineName)
SELECT IATA_CODE, AIRLINE
FROM Flights_Staging.dbo.airlines;

-- ------------------------- Dim_Airport -------------------------
-- Unknown member (key = -1) keeps flights whose airport code is numeric
-- or missing from airports.csv, so no fact rows are lost in the join.
SET IDENTITY_INSERT Dim_Airport ON;
INSERT INTO Dim_Airport (AirportKey, AirportCode, AirportName, City, [State], Country)
VALUES (-1, 'UNK', 'Unknown Airport', 'Unknown', 'NA', 'Unknown');
SET IDENTITY_INSERT Dim_Airport OFF;

INSERT INTO Dim_Airport (AirportCode, AirportName, City, [State], Country, Latitude, Longitude)
SELECT IATA_CODE, AIRPORT, CITY, STATE, COUNTRY,
       TRY_CAST(LATITUDE  AS DECIMAL(9,5)),
       TRY_CAST(LONGITUDE AS DECIMAL(9,5))
FROM Flights_Staging.dbo.airports;

-- ----------------------- Dim_CancelReason ----------------------
INSERT INTO Dim_CancelReason (CancelReasonKey, ReasonCode, ReasonName) VALUES
 (0, 'N', 'Not Cancelled'),
 (1, 'A', 'Airline/Carrier'),
 (2, 'B', 'Weather'),
 (3, 'C', 'National Air System'),
 (4, 'D', 'Security');

-- --------------------------- Dim_Date --------------------------
-- All of 2015 (365 rows)
DECLARE @d DATE = '2015-01-01';
WHILE @d <= '2015-12-31'
BEGIN
    INSERT INTO Dim_Date (DateKey, FullDate, [Year], [Quarter], [Month], MonthName, [Day], DayOfWeek, DayName, IsWeekend)
    VALUES (CONVERT(INT, FORMAT(@d,'yyyyMMdd')), @d, YEAR(@d), DATEPART(QUARTER,@d), MONTH(@d),
            DATENAME(MONTH,@d), DAY(@d), DATEPART(WEEKDAY,@d), DATENAME(WEEKDAY,@d),
            CASE WHEN DATENAME(WEEKDAY,@d) IN ('Saturday','Sunday') THEN 1 ELSE 0 END);
    SET @d = DATEADD(DAY,1,@d);
END;
GO

-- -------------------------- Fact_Flights -----------------------
-- TRY_CAST turns bad or empty values into NULL instead of failing the load.
-- HHMM times are converted to minutes after midnight (2400 becomes 0).
-- Expected duration: 1 to 5 minutes for about 5.8 million rows.
INSERT INTO Fact_Flights (
    DateKey, AirlineKey, OriginAirportKey, DestAirportKey, CancelReasonKey,
    FlightNumber, TailNumber, ScheduledDepMin, ScheduledArrMin,
    DepartureDelay, ArrivalDelay, TaxiOut, TaxiIn, AirTime, ElapsedTime, Distance,
    IsCancelled, IsDiverted, IsDelayed15,
    AirSystemDelay, SecurityDelay, AirlineDelay, LateAircraftDelay, WeatherDelay)
SELECT
    d.DateKey,
    a.AirlineKey,
    ISNULL(o.AirportKey, -1),
    ISNULL(ds.AirportKey, -1),
    CASE f.CANCELLATION_REASON WHEN 'A' THEN 1 WHEN 'B' THEN 2 WHEN 'C' THEN 3 WHEN 'D' THEN 4 ELSE 0 END,
    TRY_CAST(f.FLIGHT_NUMBER AS INT),
    f.TAIL_NUMBER,
    (TRY_CAST(f.SCHEDULED_DEPARTURE AS INT) / 100 % 24) * 60 + TRY_CAST(f.SCHEDULED_DEPARTURE AS INT) % 100,
    (TRY_CAST(f.SCHEDULED_ARRIVAL   AS INT) / 100 % 24) * 60 + TRY_CAST(f.SCHEDULED_ARRIVAL   AS INT) % 100,
    TRY_CAST(f.DEPARTURE_DELAY AS INT),
    TRY_CAST(f.ARRIVAL_DELAY   AS INT),
    TRY_CAST(f.TAXI_OUT AS INT),
    TRY_CAST(f.TAXI_IN  AS INT),
    TRY_CAST(f.AIR_TIME AS INT),
    TRY_CAST(f.ELAPSED_TIME AS INT),
    TRY_CAST(f.DISTANCE AS INT),
    CAST(TRY_CAST(f.CANCELLED AS INT) AS BIT),
    CAST(TRY_CAST(f.DIVERTED  AS INT) AS BIT),
    CASE WHEN TRY_CAST(f.ARRIVAL_DELAY AS INT) IS NULL THEN NULL
         WHEN TRY_CAST(f.ARRIVAL_DELAY AS INT) >= 15 THEN 1 ELSE 0 END,
    TRY_CAST(f.AIR_SYSTEM_DELAY AS INT),
    TRY_CAST(f.SECURITY_DELAY AS INT),
    TRY_CAST(f.AIRLINE_DELAY AS INT),
    TRY_CAST(f.LATE_AIRCRAFT_DELAY AS INT),
    TRY_CAST(f.WEATHER_DELAY AS INT)
FROM Flights_Staging.dbo.flights f
JOIN Dim_Date    d  ON d.DateKey = TRY_CAST(f.YEAR AS INT)*10000 + TRY_CAST(f.MONTH AS INT)*100 + TRY_CAST(f.DAY AS INT)
JOIN Dim_Airline a  ON a.AirlineCode = f.AIRLINE
LEFT JOIN Dim_Airport o  ON o.AirportCode  = f.ORIGIN_AIRPORT
LEFT JOIN Dim_Airport ds ON ds.AirportCode = f.DESTINATION_AIRPORT;
GO
