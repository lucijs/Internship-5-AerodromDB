--type determines whether the ticket is bussines or economy
--role determines if employe is a pilot or stewardess
--state determines the airplane state, is it active, on sale,...
CREATE TABLE Cities(
	CityId SERIAL PRIMARY KEY,
	Latitude FLOAT NOT NULL,
	Longitude FLOAT NOT NULL,
	Name VARCHAR
);
ALTER TABLE Cities
	ADD CONSTRAINT NameNotNull CHECK(LENGTH(Name)>0);
	
CREATE TABLE Types(
	TypeId SERIAL PRIMARY KEY,
	Name VARCHAR
);
CREATE TABLE Roles (
	RoleId SERIAL PRIMARY KEY,
	Name VARCHAR
);
CREATE TABLE States(
	StateId SERIAL PRIMARY KEY,
	Name VARCHAR NOT NULL
);
CREATE TABLE Users(
	UserId SERIAL PRIMARY KEY,
	Name VARCHAR NOT NULL,
	Surname VARCHAR NOT NULL
);
CREATE TABLE Airports(	
	AirportId SERIAL PRIMARY KEY,
	Name VARCHAR NOT NULL,
	CityId  INT REFERENCES Cities(CityId),
	CapacityOfAirstrip INT,
	CapacityOfHangar INT
);
ALTER TABLE Airports
	ADD CONSTRAINT UniqueName Unique(Name,CityId);
	
CREATE TABLE Companies(
	CompanyId SERIAL PRIMARY KEY,
	Name VARCHAR NOT NULL
);
-----------------------------------------------------
CREATE TABLE Airplanes(
	AirplaneId SERIAL PRIMARY KEY,
	Name VARCHAR NOT NULL,
	Produced TIMESTAMP,
	Model VARCHAR NOT NULL,
	Capacity INT,
	CompanyId INT REFERENCES Companies(CompanyId),
	StateId INT REFERENCES States(StateId)
);
--------------------------------------------------------
CREATE TABLE Flights(
	AirplaneId INT REFERENCES Airplanes(AirplaneId),
	CapacityB INT,
	CapacityE INT,
	Number INT NOT NULL,
	WhereFrom INT REFERENCES Airports(AirportId),
	WhereTo INT REFERENCES Airports(AirportId),
	Departure TIMESTAMP,
	Duration TIME,
	FlightId SERIAL PRIMARY KEY
);
--------------------------------------------------------
CREATE TABLE Tickets(
	UserId INT REFERENCES Users(UserId),
	FlightId INT REFERENCES Flights(FlightId),
	TickectId SERIAL PRIMARY KEY,
	Name VARCHAR NOT NULL,
	Price FLOAT,
	SeatNumber INT NOT NULL,
	Type INT REFERENCES Types(TypeId)
);
CREATE TABLE Grade(
	TicketId INT REFERENCES Tickets(TickectId),
	Comment VARCHAR,
	Number INT NOT NULL,
	GradeId SERIAL PRIMARY KEY
);
CREATE TABLE Loyalties(
	UserId INT REFERENCES Users(UserId),
	LoyaltyId SERIAL PRIMARY KEY,
	ExpirationDate TIMESTAMP
);
CREATE TABLE Employes(
	Id SERIAL PRIMARY KEY,
	Name VARCHAR NOT NULL,
	Surname VARCHAR NOT NULL,
	Gender VARCHAR NOT NULL,
	Birthday TIMESTAMP,
	Role INT REFERENCES Roles(RoleId)
);
--------------------------------------------------------
CREATE TABLE EmployesOnAFlight(
	FlightId INT REFERENCES Flights(FlightId),
	EmployeId INT REFERENCES Employes(Id),
	Id SERIAL PRIMARY KEY
);
--------------------------------------------------------
--adding constraints and triggers
--------------------------------------------------------
CREATE FUNCTION getAirplaneCapacity (id INT)
	RETURNS INT
	LANGUAGE plpgsql
	AS
	$$
	DECLARE 
		cap INT;
	BEGIN
		SELECT capacity
		INTO cap
		FROM Airplane
		WHERE AirplaneId = id;
		
		RETURN cap;
	END;
	$$
--------------------------------------------------------
CREATE FUNCTION getAirplaneCompany(id INT)
	RETURNS INT
	LANGUAGE plpgsql
	AS
	$$
	DECLARE 
		comp INT;
	BEGIN
		SELECT CompanyId
		INTO comp
		FROM Airplane
		WHERE AirplaneId = id;
		
		RETURN comp;
	END;
	$$
--------------------------------------------------------
CREATE FUNCTION getAirportAirstripCapacity(id INT)
	RETURNS INT
	LANGUAGE plpgsql
	AS
	$$
	DECLARE 
		cap INT;
	BEGIN
		SELECT CapacityOfAirstri
		INTO cap
		FROM Airports
		WHERE AirplaneId = id;
		
		RETURN cap;
	END;
	$$
--------------------------------------------------------
CREATE FUNCTION getAirportHangarCapacity(id INT)
	RETURNS INT
	LANGUAGE plpgsql
	AS
	$$
	DECLARE 
		cap INT;
	BEGIN
		SELECT CapacityOfHangar
		INTO cap
		FROM Airports
		WHERE AirplaneId = id;
		
		RETURN cap;
	END;
	$$
--------------------------------------------------------
CREATE OR REPLACE FUNCTION add_flight()
RETURNS TRIGGER 
LANGUAGE plpgsql
AS $$
BEGIN
	IF NEW.CapacityE+NEW.CapacityB > getAirplaneCapacity(NEW.Airplainid) 
		THEN NEW.CapacityB = getAirplaneCapacity(NEW.Airplainid);
	End IF;
	IF EXISTS(SELECT NEW.Number FROM FLights WHERE getAirplaneCompany(AirplaneId)=getAirplaneCompany(NEW.AirplaneId)) THEN
		RAISE EXCEPTION 'Insert prevented: the flight number has to be unique.';
	END IF;
	IF (SELECT State FROM Airplane WHERE AirplaneId = NEW.AirplaneId) != 2 THEN
		RAISE EXCEPTION 'Insert prevented: the airplane has to be active.';
	END IF;
	IF (SELECT COUNT(*) FROM Flights WHERE WhereFrom = NEW.WhereFrom 
		and Departure-NEW.Departure<'00:30' and Departure-NEW.Departure>'-00:30')=getAirportAirstripCapacity(NEW.WhereFrom) THEN
			RAISE EXCEPTION 'Insert prevented: there is no available place on the airstrip.';
	END IF;
	IF (SELECT COUNT(*) FROM Flights WHERE WhereFrom = NEW.WhereTo
		and Departure-(NEW.Departure::timestamp+ NEW.Duration)>'00:30')=getAirportAirstripCapacity(NEW.WhereFrom) THEN
			RAISE EXCEPTION 'Insert prevented: there is no available place on the airstrip.';
	END iF;
	RETURN NEW;
END; $$
--------------------------------------------------------
CREATE TRIGGER trigger_check_capacity
BEFORE INSERT ON  Flights
FOR EACH ROW
EXECUTE FUNCTION add_flight();
--------------------------------------------------------
CREATE FUNCTION numberOfFlights(id INT)
RETURNS INT
	LANGUAGE plpgsql
	AS
	$$
	DECLARE 
		num INT;
	BEGIN
		SELECT COUNT(*)
		INTO num
		FROM Tickets
		WHERE UserId = id;
		
		RETURN num;
	END;
	$$
--------------------------------------------------------
CREATE FUNCTION prevent_insert_into_Loyalty()
RETURNS TRIGGER AS $$
BEGIN
	IF numberOfFlights(NEW.UserId)<10 THEN
		RAISE EXCEPTION 'Insert prevented: user needs to have at least 10 bought tickets.';
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
--------------------------------------------------------
CREATE TRIGGER trigger_prevent_insert_into_loyalty
BEFORE INSERT ON Loyalties
FOR EACH ROW
EXECUTE FUNCTION prevent_insert_into_Loyalty();
--------------------------------------------------------
CREATE FUNCTION getFlightCapacityB (id INT)
	RETURNS INT
	LANGUAGE plpgsql
	AS
	$$
	DECLARE 
		cap INT;
	BEGIN
		SELECT CapacityB
		INTO cap
		FROM Flights
		WHERE FlightsId = id;
		
		RETURN cap;
	END;
	$$
--------------------------------------------------------	
CREATE FUNCTION getFlightCapacityE (id INT)
	RETURNS INT
	LANGUAGE plpgsql
	AS
	$$
	DECLARE 
		cap INT;
	BEGIN
		SELECT CapacityE
		INTO cap
		FROM Flights
		WHERE FlightsId = id;
		
		RETURN cap;
	END;
	$$
--------------------------------------------------------
CREATE FUNCTION buy_ticket()
RETURNS TRIGGER 
LANGUAGE plpgsql
AS $$
BEGIN
	IF EXISTS(SELECT NEW.SeatNumber FROM Tickets WHERE FlightId=NEW.FlightId) THEN
		RAISE EXCEPTION 'Insert prevented: there is another ticket with that seat number.';
	END IF;
	IF NEW.Type = 1 AND (SELECT COUNT(*) FROM Tickets WHERE Type = 1 AND FlightId=NEW.FlightId)=getFlightCapacityB(NEW.Flight) THEN
		RAISE EXCEPTION 'Insert prevented: Bussines class is full on this flight.';
	END IF;
	IF NEW.Type = 2 AND (SELECT COUNT(*) FROM Tickets WHERE Type = 2 AND FlightId=NEW.FlightId)=getFlightCapacityE(NEW.Flight) THEN
		RAISE EXCEPTION 'Insert prevented: Economy class is full on this flight.';
	END IF;
	RETURN NEW;
END; $$
--------------------------------------------------------
CREATE TRIGGER trigger_check_capacity_on_flight
BEFORE INSERT ON  Tickets
FOR EACH ROW
EXECUTE FUNCTION buy_ticket();
--------------------------------------------------------
CREATE FUNCTION add_pilot()
RETURNS TRIGGER 
LANGUAGE plpgsql
AS $$
BEGIN
	IF NEW.Role=1 and (NOW()-NEW.Birthday<20*365.25 or NOW()-NEW.Birthday>60*365.25) THEN
		RAISE EXCEPTION 'Insert prevented: the pilot has to be at least 20 and at most 60 years old.';
	END IF;
	RETURN NEW;
END; $$
--------------------------------------------------------
CREATE TRIGGER trigger_check_pilots_age
BEFORE INSERT ON  Employes
FOR EACH ROW
EXECUTE FUNCTION add_pilot();
--------------------------------------------------------	
CREATE FUNCTION getFlightDeparture (id INT)
	RETURNS INT
	LANGUAGE plpgsql
	AS
	$$
	DECLARE 
		dep TIMESTAMP;
	BEGIN
		SELECT Departure
		INTO dep
		FROM Flights
		WHERE FlightsId = id;
		
		RETURN dep;
	END;
	$$
--------------------------------------------------------
CREATE FUNCTION getFlightArrival(id INT)
	RETURNS INT
	LANGUAGE plpgsql
	AS
	$$
	DECLARE 
		ariv TIMESTAMP;
	BEGIN
		SELECT Departure::timestamp+interval Duration
		INTO ariv
		FROM Flights
		WHERE FlightsId = id;
		
		RETURN ariv;
	END;
	$$
--------------------------------------------------------
CREATE FUNCTION add_employe()
RETURNS TRIGGER 
LANGUAGE plpgsql
AS $$
BEGIN
	IF (SELECT COUNT(*) FROM EmployesOnAFlight WHERE EmployeId=NEW.Id and FlightId IN ((SELECT FlightId FROM Flights 
		WHERE Departure-getFlightArrival(NEW.FlightId)<'00:00' and
		getFlightArrival(FlightId)-getFlightDeparture(NEW.FlightId)<'00:00' )))>0 THEN
		RAISE EXCEPTION 'Insert prevented: one person can not be at two places at once.';
	END IF;
	RETURN NEW;
END; $$
--------------------------------------------------------
CREATE TRIGGER trigger_check_employes
BEFORE INSERT ON  EmployesOnAFlight
FOR EACH ROW
EXECUTE FUNCTION add_employe();
--------------------------------------------------------
CREATE FUNCTION add_airplane()
RETURNS TRIGGER 
LANGUAGE plpgsql
AS $$
BEGIN
	IF NEW.Status=1 THEN
		NEW.Copmapny =NULL;
	END IF;
	RETURN NEW;
END; $$
--------------------------------------------------------
CREATE TRIGGER trigger_check_airplane_status
BEFORE INSERT ON  Airplanes
FOR EACH ROW
EXECUTE FUNCTION add_airplane();