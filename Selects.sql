SELECT Name, Model FROM Airplanes WHERE Capacity >100;
SELECT * FROM Tickets  WHERE Price >=100 AND Price <=200;
SELECT * FROM  Employes WHERE Gender='F'  AND (SELECT COUNT(*) FROM EmployesOnAFlight f WHERE f.EmployeId= EmployeId AND f.FlightId IN (SELECT FlightId FROM Flights WHERE Departure<'2023-12-10'))>20;
SELECT * FROM  Employes WHERE (SELECT COUNT(*) FROM EmployesOnAFlight e WHERE e.EmployeId=EmployeId AND e.FlightId IN (SELECT FlightId FROM Flights WHERE Departure<'2023-12-11' AND (Departure::timestamp + Duration)>'2023-12-11'))>0 AND Role=2;
SELECT * FROM  Flights WHERE ((SELECT AirportId FROM Airports WHERE CityId = (SELECT CityId FROM Cities WHERE Name = 'Split'))=WhereTo or (SELECT AirportId FROM Airports WHERE CityId = (SELECT CityId FROM Cities WHERE Name = 'Split'))=WhereFrom) and Departure<'2024-01-01' AND Departure>'2022-01-01'; 


SELECT* FROM  Flights WHERE (select CityId from Cities WHERE name = 'Vienna')=WhereTo  and Departure<'2024-01-01' and departure>'2023-11-30'
SELECT count(*) FROM Tickets WHERE type = 2 and flightid IN(select flightid from flight WHERE departure>='2021-01-01' and departure<='2022-01-01' and airplainid=(select airplaneid from airplane where companyid =(select companyid from company where name = 'AIRDUMO') ))
SELECT avg(gradenumber) FROM grade WHERE ticketid =(select ticketid from tickets WHERE flightid=(select flightid from flight where airplainid=(select airplaneid from airplane where companyid = (select companyid from company where name='AIRDUMO'))))

SELECT now()
SELECT * FROM Aerodrom a where cityid=(select cityid from cities where name ='London')
order by count((select companyid from company where name='AirBus')=(select companyid from airplane ap 
			  where airplaneid=(select airplainid from flight 
							  where( wherefrom=a.cityid
									and extract(epoch from(now()-departure))/60<30)
							  or(whereto=a.cityid
								 and extract(epoch from(now()-arrival))/60=0))))

select * from airport where (sqrt(power()))	