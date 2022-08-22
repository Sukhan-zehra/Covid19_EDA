/*
Project: Covid-19 Exploratory Data Analysis 
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
Date: 2022-05-20
*/

----Setting Up----
--Bring up data set on Covid Deaths 
SELECT *
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent is not null -- this will remove rows of data looking at continents rather than countries
ORDER BY 3,4

--Making sure the second set of data was uploaded correctly
SELECT *
FROM PortfolioProject.dbo.CovidVaccinations
ORDER BY 3,4

-- Select Data that will be used and organize by location and date 
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE continent is not null -- this will remove rows of data looking at continents rather than countries
ORDER BY 1,2

---- Looking at the Total Cases VS Total Deaths ----
-- Let's investigate the number of deaths compared to the number of people getting infected
-- Shows likelihood of dying if you contract COVID in your country
SELECT location, date, total_cases, total_deaths,
	(total_deaths/total_cases)*100 AS DeathPercentage 
FROM PortfolioProject..CovidDeaths
WHERE location like '%Canada%'
and continent is not null -- this will remove rows of data looking at continents rather than countries
ORDER BY 1,2


-- Looking at Total Cases VS Population --
-- Shows what percentage of population got COVID
SELECT location, date, total_cases, population, 
	(total_cases/population)*100 AS InfectedPercentage  
FROM PortfolioProject..CovidDeaths
--WHERE location like '%Canada%'
WHERE continent is not null -- this will remove rows of data looking at continents rather than countries
ORDER BY 1,2;


-- Looking at Countires' Highest Infection Rate Compared to Population --
SELECT location, population, 
	MAX(total_cases) AS HighestInfectionCount,
	MAX((total_cases/population))*100 AS PercentPopulationInfected  
FROM PortfolioProject..CovidDeaths
WHERE continent is not null -- this will remove rows of data looking at continents rather than countries
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC


-- Showing Countries' Highest Death Count per Population--
--Note: Change data-type for total_deaths to int using CAST() function
SELECT location, 
	MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is not null -- this will remove rows of data looking at continents rather than countries
GROUP BY location
ORDER BY TotalDeathCount DESC

-- Showing Highest Death Count by Continent (correct numbers)--
--Note: Change data-type for total_deaths to int using CAST() function
SELECT location, 
	MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is null -- this will remove rows of data looking at continents rather than countries
GROUP BY location
ORDER BY TotalDeathCount DESC


-- Showing Highest Death Count by Continent (Incorrect numbers)--
--Note: Change data-type for total_deaths to int using CAST() function
-- These numbers are not correct (eg. North America only shows count for USA, doesn't include CA or MX)
SELECT continent, 
	MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is not null -- this will remove rows of data looking at continents rather than countries
GROUP BY continent
ORDER BY TotalDeathCount DESC


-- Number of people fully vaccinated by country --
SELECT location,
	MAX(cast(people_fully_vaccinated as bigint)) AS total_vaccinated 
FROM PortfolioProject.dbo.CovidVaccinations
WHERE continent is not null -- this will remove rows of data looking at continents rather than countries
	and location not in ('World', 'European Union', 'International', 'Upper middle income', 'High income', 'Lower middle income', 'Low income')
GROUP BY location
ORDER BY 1 



---- Global Numbers ----
--Number of cases, deaths, and death percentage worldwide on a daily basis--
SELECT date, 
	SUM(new_cases) AS total_cases,
	SUM(cast(new_deaths as int)) AS total_deaths, --new_deaths is invarchart and needs to be changed to int to do aggregate functions
	SUM(cast(new_deaths as int))/SUM(new_cases)*100 AS DeathPercentage 
FROM PortfolioProject..CovidDeaths
WHERE continent is not null -- this will remove rows of data looking at continents rather than countries
GROUP BY date
ORDER BY 1,2


--Number of cases, deaths, and death percentage worldwide-- 
SELECT 
	SUM(new_cases) AS total_cases,
	SUM(cast(new_deaths as int)) AS total_deaths, --new_deaths is invarchart and needs to be changed to int to do aggregate functions
	SUM(cast(new_deaths as int))/SUM(new_cases)*100 AS DeathPercentage 
FROM PortfolioProject..CovidDeaths
WHERE continent is not null -- this will remove rows of data looking at continents rather than countries
ORDER BY 1,2


--Number of fully vaccinated People worldwide-- 
WITH world_vac AS(
	SELECT location,
		MAX(cast(people_fully_vaccinated as bigint)) AS total_vaccinated 
	FROM PortfolioProject.dbo.CovidVaccinations
	WHERE location not in ('World', 'European Union', 'International', 'Upper middle income', 'High income', 'Lower middle income', 'Low income')
	and continent is not null -- this will remove rows of data looking at continents rather than countries
	GROUP BY location
	)
SELECT 
	SUM(total_vaccinated) AS total_fully_vaccinated
FROM world_vac 



---- Socio Economic Status Numbers ----
SELECT *
FROM PortfolioProject..CovidDeaths
WHERE location like '%income%'

SELECT *
FROM PortfolioProject..CovidVaccinations
WHERE location like '%income%'
--Number of cases, deaths, and death percentage by income status on a daily basis--
SELECT location, date, 
	SUM(cast(new_cases as int)) AS total_cases,
	SUM(cast(new_deaths as int)) AS total_deaths, --new_deaths is invarchart and needs to be changed to int to do aggregate functions
	SUM(cast(new_deaths as int))/SUM(cast(new_cases as int))*100 AS DeathPercentage 
FROM PortfolioProject..CovidDeaths
WHERE location like '%income%'
GROUP BY date, location
ORDER BY 1,2


--Number of cases, deaths, and death percentage by income status--
SELECT location,
	SUM(new_cases) AS total_cases,
	SUM(cast(new_deaths as int)) AS total_deaths, --new_deaths is invarchart and needs to be changed to int to do aggregate functions
	SUM(cast(new_deaths as int))/SUM(new_cases)*100 AS DeathPercentage 
FROM PortfolioProject..CovidDeaths
WHERE location like '%income%'
GROUP BY location
ORDER BY 1,2



---- Joining the two datasets together ----
SELECT *
FROM PortfolioProject..CovidDeaths dea  --alias for death dataaset 
JOIN PortfolioProject..CovidVaccinations vac --alias for vac dataset 
	On dea.location = vac.location
	and dea.date = vac.date


--Total Population vs Vaccinations Given out--
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea  --alias as deathChart
JOIN PortfolioProject..CovidVaccinations vac --alias as vacChart
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null -- this will remove rows of data looking at continents rather than countries
ORDER BY 2,3


--Total Population vs. People Fully Vaccinated--
SELECT dea.continent, dea.location, dea.date, dea.population, vac.people_fully_vaccinated,
	SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS People_fully_vaccinated
FROM PortfolioProject..CovidDeaths dea  --alias as deathChart
JOIN PortfolioProject..CovidVaccinations vac --alias as vacChart
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null -- this will remove rows of data looking at continents rather than countries
ORDER BY 2,3


--People Fully Vaccinated by Country--
SELECT location,
	MAX(cast(people_fully_vaccinated as bigint)) AS total_vaccinated 
FROM PortfolioProject.dbo.CovidVaccinations
WHERE location not in ('World', 'European Union', 'International', 'Upper middle income', 'High income', 'Lower middle income', 'Low income')
	and location not like '%income%' --this will remove 'Upper middle income', 'High income', 'Lower middle income', 'Low income'
GROUP BY location
ORDER BY 1 


--Next, would want to see how much of the total population is vaccinated, day by day (i.e. rolling number)--
--But to do this, you need to use RollingPeopleVaccinated/population. Can't do that with a column you just created.
--For this to work a temp. table will need to be created. 2 ways: CTE or temp table


-- USE CTE 
WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS (
	SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
		SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
	FROM PortfolioProject..CovidDeaths dea  --alias as deathChart
	JOIN PortfolioProject..CovidVaccinations vac --alias as vacChart
		On dea.location = vac.location
		and dea.date = vac.date
	WHERE dea.continent is not null -- this will remove rows of data looking at continents rather than countries
	ORDER BY 2,3
)
SELECT *,
	(RollingPeopleVaccinated/population)*100 AS TotalPercentVaccinated 
FROM PopvsVac


-- TEMP TABLE 
DROP TABLE if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated (
	continent nvarchar(255),
	location nvarchar(255),
	date datetime, 
	population numeric,
	new_vaccinations numeric,
	RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
		SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea  --alias as deathChart
JOIN PortfolioProject..CovidVaccinations vac --alias as vacChart
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null -- this will remove rows of data looking at continents rather than countries
ORDER BY 2,3

SELECT *,
(RollingPeopleVaccinated/population)*100 AS TotalPercentVaccinated 
FROM #PercentPopulationVaccinated


--Number of vaccination doses given out, people fully vaccinated and total booster doses Per date and country --
	--total_vaccinations = doses given out that day
	--rolling_total_doses = total doses given out so far 
	--people_vaccinated = at least 1 dose 
	--There are NULLs that need to be addressed, otherwise this data is inaccurate 
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
	--and dea.location ='Canada'
ORDER BY 2,3



--Looking at Percentage of Population vaccinated, fully vaccinated, and recieved booster--    
	--total_vaccinations = doses given out that day
	--rolling_total_doses = total doses given out so far 
	--people_vaccinated = at least 1 dose 
--BUT there are NULLS which leads to inaccurate daily points. 
SELECT dea.continent, dea.location, dea.date, dea.population, 
		vac.total_vaccinations AS daily_doses_given,
		--SUM(CONVERT(bigint,vac.total_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_total_doses,
		(CONVERT(bigint, vac.people_vaccinated)/dea.population)*100 AS percent_vaccinated,
		(CONVERT(bigint, vac.people_fully_vaccinated)/dea.population)*100 AS percent_fully_vaccinated,
		(CONVERT(bigint, vac.total_boosters)/dea.population)*100 AS percent_boostered
FROM PortfolioProject..CovidDeaths dea  --alias as deathChart
JOIN PortfolioProject..CovidVaccinations vac --alias as vacChart
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null -- this will remove rows of data looking at continents rather than countries
	and dea.location not in ('World', 'European Union', 'International') 
	and dea.location not like '%income%' --this will remove 'Upper middle income', 'High income', 'Lower middle income', 'Low income'
ORDER BY 2,3


--Addressing NULLS while lookings at vaccination rates--
--The following steps could be done on the dataset itself, but temp. table was created to be used again for code chunk later on
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

SELECT *
FROM vacRates

--Set NULL values to 0 for all dates before 2020-04-01 (i.e. at the begining of the pandemic) 
--This will allow the next set of code to work where were replace NULL values with the number right before. 
UPDATE vacRates
SET 
	people_vaccinated = 0,
	people_fully_vaccinated = 0,
	total_boosters = 0
WHERE date <= '2020-04-01 00:00:00.000'

SELECT *
FROM vacRates

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


SELECT *
FROM vacRates


--Looking at Percentage of Population vaccinated, fully vaccinated, and recieved booster--    
	--total_vaccinations = doses given out that day
	--rolling_total_doses = total doses given out so far 
	--people_vaccinated = at least 1 dose 
--Will use previously created temp. table (vacRates) for this 
SELECT continent, location, date, population, daily_doses_given, rolling_total_doses,
		(CONVERT(bigint, people_vaccinated)/population)*100 AS percent_vaccinated,
		(CONVERT(bigint, people_fully_vaccinated)/population)*100 AS percent_fully_vaccinated,
		(CONVERT(bigint, total_boosters)/population)*100 AS percent_boostered
FROM vacRates
ORDER BY 2,3



--Looking at TOTAL Percentage of Population vaccinated, fully vaccinated, and recieved booster--   
	--total_vaccinations = doses given out that day
	--rolling_total_doses = total doses given out so far 
	--people_vaccinated = at least 1 dose 
--Will use previously created temp. table (vacRates) for this 
WITH vac_percentage AS(
	SELECT continent, location, population, date,
		MAX(people_vaccinated) AS people_vaccinated,
		MAX(people_fully_vaccinated) AS people_fully_vaccinated,
		MAX(total_boosters) AS total_boosters
	FROM vacRates
	WHERE population > people_vaccinated --This removes countries that seem to have incorrect data 
	GROUP BY continent, location, population, date
	--ORDER BY 2
	)
SELECT 
	 continent, location, population, date,
	(people_vaccinated/population)*100 AS percent_vaccinated,
	(people_fully_vaccinated/population)*100 AS percent_fully_vaccinated,
	(total_boosters/population)*100 AS percent_boostered
FROM vac_percentage 
ORDER BY 2,4



---- Creating VIEW to store data for later visualizations ----
CREATE View PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
		SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea  --alias as deathChart
JOIN PortfolioProject..CovidVaccinations vac --alias as vacChart
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null -- this will remove rows of data looking at continents rather than countries
--ORDER BY 2,3

SELECT *
FROM PercentPopulationVaccinated
