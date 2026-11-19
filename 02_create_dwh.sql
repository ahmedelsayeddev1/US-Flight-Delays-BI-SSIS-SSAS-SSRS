/* =====================================================================
   02_create_dwh.sql
   Creates the Flights_DWH star schema: 4 dimensions + Fact_Flights.
   Grain of the fact table: one row per flight.
   ===================================================================== */

USE master;
GO
DROP DATABASE IF EXISTS Flights_DWH;
GO
CREATE DATABASE Flights_DWH;
GO
USE Flights_DWH;
GO

-- ============================ DIMENSIONS ============================

CREATE TABLE Dim_Date (
    DateKey     INT PRIMARY KEY,          -- YYYYMMDD, e.g. 20150101
    FullDate    DATE NOT NULL,
    [Year]      INT,
    [Quarter]   INT,
    [Month]     INT,
    MonthName   NVARCHAR(20),
    [Day]       INT,
    DayOfWeek   INT,
    DayName     NVARCHAR(20),
    IsWeekend   BIT
);

CREATE TABLE Dim_Airline (
    AirlineKey  INT IDENTITY(1,1) PRIMARY KEY,
    AirlineCode NVARCHAR(10) NOT NULL,
    AirlineName NVARCHAR(200)
);

-- Used twice by the fact table (origin and destination): role-playing dimension
CREATE TABLE Dim_Airport (
    AirportKey  INT IDENTITY(1,1) PRIMARY KEY,
    AirportCode NVARCHAR(10) NOT NULL,
    AirportName NVARCHAR(300),
    City        NVARCHAR(200),
    [State]     NVARCHAR(10),
    Country     NVARCHAR(50),
    Latitude    DECIMAL(9,5) NULL,
    Longitude   DECIMAL(9,5) NULL
);

CREATE TABLE Dim_CancelReason (
    CancelReasonKey  INT PRIMARY KEY,
    ReasonCode       NVARCHAR(10),
    ReasonName       NVARCHAR(50)
);
GO

-- ============================== FACT ================================

CREATE TABLE Fact_Flights (
    FlightKey            BIGINT IDENTITY(1,1) PRIMARY KEY,
    DateKey              INT NOT NULL,
    AirlineKey           INT NOT NULL,
    OriginAirportKey     INT NOT NULL,
    DestAirportKey       INT NOT NULL,
    CancelReasonKey      INT NOT NULL,
    FlightNumber         INT NULL,
    TailNumber           NVARCHAR(20) NULL,
    ScheduledDepMin      INT NULL,   -- minutes after midnight
    ScheduledArrMin      INT NULL,   -- minutes after midnight
    DepartureDelay       INT NULL,
    ArrivalDelay         INT NULL,
    TaxiOut              INT NULL,
    TaxiIn               INT NULL,
    AirTime              INT NULL,
    ElapsedTime          INT NULL,
    Distance             INT NULL,
    IsCancelled          BIT NOT NULL,
    IsDiverted           BIT NOT NULL,
    IsDelayed15          BIT NULL,   -- arrival delay of 15 minutes or more
    AirSystemDelay       INT NULL,
    SecurityDelay        INT NULL,
    AirlineDelay         INT NULL,
    LateAircraftDelay    INT NULL,
    WeatherDelay         INT NULL,
    CONSTRAINT FK_F_Date    FOREIGN KEY (DateKey)          REFERENCES Dim_Date(DateKey),
    CONSTRAINT FK_F_Airline FOREIGN KEY (AirlineKey)       REFERENCES Dim_Airline(AirlineKey),
    CONSTRAINT FK_F_Origin  FOREIGN KEY (OriginAirportKey) REFERENCES Dim_Airport(AirportKey),
    CONSTRAINT FK_F_Dest    FOREIGN KEY (DestAirportKey)   REFERENCES Dim_Airport(AirportKey),
    CONSTRAINT FK_F_Cancel  FOREIGN KEY (CancelReasonKey)  REFERENCES Dim_CancelReason(CancelReasonKey)
);
GO

-- Expected: Dim_Airline, Dim_Airport, Dim_CancelReason, Dim_Date, Fact_Flights
SELECT name FROM sys.tables ORDER BY name;
