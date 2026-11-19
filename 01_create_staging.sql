/* =====================================================================
   01_create_staging.sql
   Creates the Flights_Staging database. All columns are NVARCHAR so the
   SSIS load never fails on type or code page mismatches. Typing and
   cleaning happen later, in the warehouse load (03_load_dwh.sql).
   ===================================================================== */

USE master;
GO
DROP DATABASE IF EXISTS Flights_Staging;
GO
CREATE DATABASE Flights_Staging;
GO
USE Flights_Staging;
GO

CREATE TABLE airlines (
    IATA_CODE NVARCHAR(10),
    AIRLINE   NVARCHAR(200)
);

CREATE TABLE airports (
    IATA_CODE NVARCHAR(10),
    AIRPORT   NVARCHAR(300),
    CITY      NVARCHAR(200),
    STATE     NVARCHAR(10),
    COUNTRY   NVARCHAR(50),
    LATITUDE  NVARCHAR(50),
    LONGITUDE NVARCHAR(50)
);

CREATE TABLE flights (
    YEAR                NVARCHAR(10),
    MONTH               NVARCHAR(10),
    DAY                 NVARCHAR(10),
    DAY_OF_WEEK         NVARCHAR(10),
    AIRLINE             NVARCHAR(10),
    FLIGHT_NUMBER       NVARCHAR(20),
    TAIL_NUMBER         NVARCHAR(20),
    ORIGIN_AIRPORT      NVARCHAR(10),
    DESTINATION_AIRPORT NVARCHAR(10),
    SCHEDULED_DEPARTURE NVARCHAR(10),
    DEPARTURE_TIME      NVARCHAR(10),
    DEPARTURE_DELAY     NVARCHAR(20),
    TAXI_OUT            NVARCHAR(20),
    WHEELS_OFF          NVARCHAR(10),
    SCHEDULED_TIME      NVARCHAR(20),
    ELAPSED_TIME        NVARCHAR(20),
    AIR_TIME            NVARCHAR(20),
    DISTANCE            NVARCHAR(20),
    WHEELS_ON           NVARCHAR(10),
    TAXI_IN             NVARCHAR(20),
    SCHEDULED_ARRIVAL   NVARCHAR(10),
    ARRIVAL_TIME        NVARCHAR(10),
    ARRIVAL_DELAY       NVARCHAR(20),
    DIVERTED            NVARCHAR(10),
    CANCELLED           NVARCHAR(10),
    CANCELLATION_REASON NVARCHAR(10),
    AIR_SYSTEM_DELAY    NVARCHAR(20),
    SECURITY_DELAY      NVARCHAR(20),
    AIRLINE_DELAY       NVARCHAR(20),
    LATE_AIRCRAFT_DELAY NVARCHAR(20),
    WEATHER_DELAY       NVARCHAR(20)
);
GO

-- Expected: airlines, airports, flights
SELECT name FROM sys.tables ORDER BY name;

/* NEXT STEP: run the SSIS package (Flights_ETL) to load the three CSV files,
   then run 04_validation.sql section A to confirm the row counts. */
