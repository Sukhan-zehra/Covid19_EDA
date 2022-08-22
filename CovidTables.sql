/*
Project: Covid 19 Data Tables for Tableau Dashboard Visualizations
Details: Based on EDA Project 
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
Date: 2022-05-20
*/


--Table 1. 
--Global numbers on cases, deaths, death percentage, and people fully vaccinated
WITH world_summary AS(
	SELECT 
		dea.location, 
		SUM(dea.new_cases) AS total_cases,
		SUM(cast(dea.new_deaths as int)) AS total_deaths, --new_deaths is invarchart and needs to be changed to int to do aggregate functions
		MAX(cast(vac.people_fully_vaccinated as bigint)) AS total_vaccinated 
	FROM PortfolioProject..CovidDeaths dea  --alias for death dataaset 
	JOIN PortfolioProject..CovidVaccinations vac --alias for vac dataset 
		On dea.location = vac.location
		and dea.date = vac.date
	WHERE dea.continent is not null -- this will remove rows of data looking at continents rather than countries
		and dea.location not in ('World', 'European Union', 'International')
		and dea.location not like '%income%' --this will remove 'Upper middle income', 'High income', 'Lower middle income', 'Low income'
	GROUP BY dea.location
	)
SELECT 
	SUM(total_cases) AS world_total_cases,
	SUM(total_deaths) AS world_total_deaths,
	SUM(total_deaths)/SUM(total_cases)*100 AS world_death_percentage,
	SUM(total_vaccinated) AS total_fully_vaccinated
FROM world_summary


--Table 2. 
-- Showing Highest Death Count and Number of Cases by Continent 
--Note: Change data-type for total_deaths to int using CAST() function
SELECT location, 
	MAX(cast(total_deaths as int)) AS TotalDeathCount,
	MAX(CAST(total_cases as int)) AS TotalCases
FROM PortfolioProject..CovidDeaths
WHERE continent is null -- this will remove rows of data looking at continents rather than countries
	and location not in ('World', 'European Union', 'International') 
	and location not like '%income%' --this will remove 'Upper middle income', 'High income', 'Lower middle income', 'Low income'
GROUP BY location
ORDER BY TotalDeathCount DESC


--Table 3.
---- Looking at Countires with Highest Infection Rate Compared to Population 
SELECT location, population, 
	MAX(total_cases) AS HighestInfectionCount,
	MAX((total_cases/population))*100 AS PercentPopulationInfected  
FROM PortfolioProject..CovidDeaths
WHERE continent is not null -- this will remove rows of data looking at continents rather than countries
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC


--Table 4. 
---- Looking at Countires with Highest Infection Rate Compared to Population by date
SELECT location, population, date,
	MAX(total_cases) AS HighestInfectionCount,
	MAX((total_cases/population))*100 AS PercentPopulationInfected  
FROM PortfolioProject..CovidDeaths
WHERE continent is not null -- this will remove rows of data looking at continents rather than countries
GROUP BY location, population, date
ORDER BY location, date


--Table 5.
-- Number of people fully vaccinated by country --
SELECT 
		dea.location, 
		MAX(cast(vac.people_fully_vaccinated as bigint)) AS total_vaccinated,
		MAX((vac.people_fully_vaccinated/dea.population))*100 AS PercentPopulationVaccinated
FROM PortfolioProject..CovidDeaths dea  --alias for death dataaset 
JOIN PortfolioProject..CovidVaccinations vac --alias for vac dataset 
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.location not in ('World', 'European Union', 'International')
	and dea.location not like '%income%' --this will remove 'Upper middle income', 'High income', 'Lower middle income', 'Low income'
	and dea.continent is not null -- this will remove rows of data looking at continents rather than countries
GROUP BY dea.location
ORDER BY 1

--Table 6. 
--Looking at Percentage of Population vaccinated, fully vaccinated, and recieved booster by Date and Country    
	--total_vaccinations = doses given out that day
	--rolling_total_doses = total doses given out so far 
	--people_vaccinated = at least 1 dose 
DROP TABLE if exists vacRates
CREATE TABLE vacRates (
	continent nvarchar(255),
	location nvarchar(255),
	date datetime, 
	population numeric,
	daily_doses_given numeric,
	rolling_total_doses numeric,
	people_vaccinated numeric,
	people_fully_vaccinated numeric,
	total_boosters numeric
)

INSERT INTO vacRates
SELECT dea.continent, dea.location, dea.date, dea.population,
		vac.total_vaccinations AS daily_doses_given,
		SUM(CONVERT(bigint,vac.total_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_total_doses,
		vac.people_vaccinated,
		vac.people_fully_vaccinated,
		vac.total_boosters
FROM PortfolioProject..CovidDeaths dea  --alias as deathChart
JOIN PortfolioProject..CovidVaccinations vac --alias as vacChart
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null -- this will remove rows of data looking at continents rather than countries
	and dea.location not in ('World', 'European Union', 'International') 
	and dea.location not like '%income%' --this will remove 'Upper middle income', 'High income', 'Lower middle income', 'Low income'
ORDER BY 2,3

--Set NULL values to 0 for all dates before 2020-04-01 (i.e. at the begining of the pandemic) 
--This will allow the next set of code to work where were replace NULL values with the number right before. 
UPDATE vacRates
SET 
	people_vaccinated = 0,
	people_fully_vaccinated = 0,
	total_boosters = 0
WHERE date <= '2020-04-01 00:00:00.000'

--Fixing NULL values
--vaccination information is rolling numbers, but there are NULLs in some rows
--if there is a null, this code chunk will replace with the value in the preceeding row

-- for people_vaccinated column 
DECLARE @n_vac numeric; 
UPDATE vacRates
SET 
	@n_vac = COALESCE(people_vaccinated, @n_vac),
    people_vaccinated = COALESCE(people_vaccinated, @n_vac) 
-- for people_fully_vaccinated column 
DECLARE @n_fullvac numeric; 
UPDATE vacRates
SET 
	@n_fullvac = COALESCE(people_fully_vaccinated, @n_fullvac),
    people_fully_vaccinated = COALESCE(people_fully_vaccinated, @n_fullvac) 
-- for total_boosters column 
DECLARE @n_booster numeric; 
UPDATE vacRates
SET 
	@n_booster = COALESCE(total_boosters, @n_booster),
    total_boosters = COALESCE(total_boosters, @n_booster) 


--Looking at Percentage of Population vaccinated, fully vaccinated, and recieved booster    
--Will use previously created temp. table (vacRates) for this 
SELECT continent, location, date, population, daily_doses_given, rolling_total_doses,
		(CONVERT(bigint, people_vaccinated)/population)*100 AS percent_vaccinated,
		(CONVERT(bigint, people_fully_vaccinated)/population)*100 AS percent_fully_vaccinated,
		(CONVERT(bigint, total_boosters)/population)*100 AS percent_boostered
FROM vacRates
WHERE location like '%Canada%'
ORDER BY 2,3


