CREATE DATABASE COVID19;

-- Quick check that the imported columns are what is expected. 
SELECT *
FROM COVID19.dbo.COVID_deaths
ORDER BY 3, 4 DESC;

SELECT *
FROM COVID19.dbo.COVID_vaccines
ORDER BY 
	location
	,date DESC;

--Understanding the data required for the next set of questions. 
SELECT 
	deaths.location
	,deaths.date
	,deaths.total_cases
	,deaths.new_cases
	,deaths.total_deaths
	,vaccine.population
FROM COVID19.dbo.COVID_deaths AS deaths
LEFT OUTER JOIN COVID19.dbo.COVID_vaccines AS vaccine
	ON deaths.location = vaccine.location
	AND deaths.date = vaccine.date
ORDER BY 
	location
	,date;

-- Total Cases vs Total Deaths per location per date. 
-- Shows likelihood of dying if you contract COVID in your country per day.  
SELECT 
	location
	,date
	,total_cases
	,total_deaths
	,(CAST(total_deaths AS float)/CAST(total_cases AS float))*100 AS Death_Percentage
FROM COVID19.dbo.COVID_deaths AS deaths
ORDER BY 
	location
	,date;

-- Same as above but filtered by string United Kingdom. 
SELECT 
	location
	,date
	,total_cases
	,total_deaths
	,(CONVERT(float, total_deaths)/CONVERT(float, total_cases))*100 AS Death_Percentage
FROM COVID19.dbo.COVID_deaths AS deaths
WHERE location LIKE '%united kingdom%'
ORDER BY 
	location
	,date;

-- Looking at Countries with highest infection rate compared to population
SELECT 
	deaths.location
	,vaccine.population
	,MAX(deaths.total_cases) AS Highest_Infection_Count
	,MAX(CAST(deaths.total_cases AS float)/CAST(vaccine.population AS float))*100 AS Infection_Percentage
FROM COVID19.dbo.COVID_deaths AS deaths
LEFT OUTER JOIN COVID19.dbo.COVID_vaccines AS vaccine
	ON deaths.location = vaccine.location
	AND deaths.date = vaccine.date
GROUP BY 
	deaths.location
	,vaccine.population
ORDER BY 
	Infection_Percentage DESC;

-- How many people died from the infection overall?
SELECT 
	deaths.location
	,vaccine.population
	,MAX(CAST(deaths.total_deaths AS int)) AS Highest_Death_Count
	,MAX(CAST(deaths.total_deaths AS FLOAT)/CAST(vaccine.population AS FLOAT)) * 100 AS Percentage_Deaths
FROM COVID19.dbo.COVID_deaths AS deaths
LEFT OUTER JOIN COVID19.dbo.COVID_vaccines AS vaccine
	ON deaths.location = vaccine.location
	AND deaths.date = vaccine.date
GROUP BY 
	deaths.location
	,vaccine.population
ORDER BY 
	Percentage_Deaths DESC;

-- Highest death count per location
SELECT 
	location
	,MAX(total_deaths) AS Total_Deaths
FROM COVID19.dbo.COVID_deaths
WHERE continent IS NOT NULL
GROUP BY 
	location
ORDER BY 
	Total_Deaths DESC;

-- Break things down by continent and country groupings. 
SELECT 
	location
	,MAX(total_deaths) AS Total_Deaths
FROM COVID19.dbo.COVID_deaths
WHERE continent IS NULL
GROUP BY 
	location
ORDER BY 
	Total_Deaths DESC;

-- The WHERE sub-query ensures only continents are pulled from the continent column. 
SELECT 
	location
	,MAX(total_deaths) AS Total_Deaths
FROM COVID19.dbo.COVID_deaths
WHERE location IN (
	SELECT DISTINCT(continent)
	FROM COVID19.dbo.COVID_deaths
	WHERE continent IS NOT NULL)
GROUP BY 
	location
ORDER BY 
	Total_Deaths DESC;

-- Showing the continents with the highest death count
SELECT 
	location
	,MAX(total_deaths) AS Total_Deaths
FROM COVID19.dbo.COVID_deaths
WHERE location IN (
	SELECT DISTINCT(continent)
	FROM COVID19.dbo.COVID_deaths
	WHERE continent IS NOT NULL)
GROUP BY 
	location
ORDER BY 
	Total_Deaths DESC;

-- Global Numbers
-- Total new cases, new deaths and death percentage per day. 
SELECT
	date
	,SUM(CAST(new_cases AS float)) AS sum_new_cases
	,SUM(CAST(new_deaths AS float)) AS sum_new_deaths
	,SUM(CAST(new_deaths AS float))/SUM(CAST(new_cases AS float))*100 AS Death_Percentage
FROM COVID19.dbo.COVID_deaths
WHERE continent IS NOT NULL
	AND new_cases != 0
GROUP BY 
	date
ORDER BY 1, 2;

-- Sum of new cases and new deaths per location for all data. 
SELECT
	location
	,SUM(new_cases) AS sum_new_cases
	,SUM(new_deaths) AS sum_new_deaths
FROM COVID19.dbo.COVID_deaths
GROUP BY 
	location
ORDER BY 
	location;

-- Shows the SUM of all countries. 
SELECT
	SUM(CAST(new_cases AS float)) AS Total_Cases
	,SUM(CAST(new_deaths AS float)) AS Total_Deaths
	,SUM(CAST(new_deaths AS float))/SUM(CAST(new_cases AS float))*100 AS Death_Percentage
FROM COVID19.dbo.COVID_deaths
WHERE continent IS NOT NULL;

-- Shows the total_cases, total_deaths and death_percentage per continent and country category. 
SELECT 
	location
	,SUM(CAST(new_cases AS float)) AS Total_Cases
	,SUM(CAST(new_deaths AS float)) AS Total_Deaths
	,SUM(CAST(new_deaths AS float))/SUM(CAST(new_cases AS float))*100 AS Death_Percentage
FROM COVID19.dbo.COVID_deaths
WHERE continent IS NULL
GROUP BY location
ORDER BY 1;

-- How much of the population was vaccinated per location per day. 
SELECT 
	deaths.date
	,deaths.continent
	,deaths.location
	,vaccine.population
	,vaccine.new_vaccinations
	,SUM(CAST(vaccine.new_vaccinations AS float))/SUM(CAST(vaccine.population AS float))*100 AS Population_Vaccinated
FROM COVID19.dbo.COVID_deaths AS deaths
JOIN COVID19.dbo.COVID_vaccines AS vaccine
	ON deaths.location = vaccine.location
	AND deaths.date = vaccine.date
WHERE deaths.continent IS NOT NULL
GROUP BY 
	deaths.date
	,deaths.continent
	,deaths.location
	,vaccine.population
	,vaccine.new_vaccinations
ORDER BY 
	deaths.location
	,deaths.date;

-- Using CTE (Common Table Expression)		
-- Highest number of vaccinations delivered in a single day per country. 
WITH max_pop_vacc (date, continent, location, population, new_vaccs, population_vaccinated) 
AS (
	SELECT 
		deaths.date
		,deaths.continent
		,deaths.location
		,vaccine.population
		,vaccine.new_vaccinations
		,SUM(CAST(vaccine.new_vaccinations AS float))/SUM(CAST(vaccine.population AS float))*100 AS Population_Vaccinated
	FROM COVID19.dbo.COVID_deaths AS deaths
	JOIN COVID19.dbo.COVID_vaccines AS vaccine
		ON deaths.location = vaccine.location
		AND deaths.date = vaccine.date
	WHERE deaths.continent IS NOT NULL
	GROUP BY 
		deaths.date
		,deaths.continent
		,deaths.location
		,vaccine.population
		,vaccine.new_vaccinations
	ORDER BY 
		location
		,date
)
SELECT 
	continent
	,location
	,population
	,MAX(population_vaccinated)
FROM max_pop_vacc
GROUP BY 
	continent
	,location
	,population;

-- Create a cumlative column summing the total new_vaccinations in order of date, 
-- but restarting the count for each location. 
SELECT 
	deaths.date
	,deaths.continent
	,deaths.location
	,vaccine.population
	,vaccine.new_vaccinations
	,SUM(vaccine.new_vaccinations) OVER (Partition By deaths.location ORDER BY deaths.location, deaths.date) AS rolling_people_vaccinated
FROM COVID19.dbo.COVID_deaths AS deaths
JOIN COVID19.dbo.COVID_vaccines AS vaccine
	ON deaths.location = vaccine.location
	AND deaths.date = vaccine.date
WHERE deaths.continent IS NOT NULL
	AND new_vaccinations IS NOT NULL
ORDER BY 
	location
	,date;

-- After evaluating the output of the above query, it is clear the source data is flawed. 
-- The new_vaccinations column only has a value when total_vaccinations has values two
-- days in a row. The new_vaccinations column is calculated by taking the "today" value
-- of total_vaccinations and subtracting the "yesterday" value.
-- To resolve this, the partition by has been removed and the results below now
-- use the already cumlative column total_vaccinations. 
SELECT 
	deaths.date
	,deaths.continent
	,deaths.location
	,vaccine.population
	,vaccine.total_vaccinations
FROM COVID19.dbo.COVID_deaths AS deaths
JOIN COVID19.dbo.COVID_vaccines AS vaccine
	ON deaths.location = vaccine.location
	AND deaths.date = vaccine.date
WHERE deaths.continent IS NOT NULL
	AND vaccine.total_vaccinations IS NOT NULL
ORDER BY 
	location
	,date;

-- This query shows how many of each location's population has been vaccinated per day. 
SELECT 
	deaths.date
	,deaths.continent
	,deaths.location
	,vaccine.population
	,vaccine.total_vaccinations
	,(CONVERT(float, vaccine.total_vaccinations)/population)*100 AS population_vaccinated
FROM COVID19.dbo.COVID_deaths AS deaths
JOIN COVID19.dbo.COVID_vaccines AS vaccine
	ON deaths.location = vaccine.location
	AND deaths.date = vaccine.date
WHERE vaccine.total_vaccinations IS NOT NULL
	AND deaths.location = 'United Kingdom';

-- Percentage of the population vaccinated per location
SELECT 
	deaths.continent
	,deaths.location
	,vaccine.population
	,MAX((CONVERT(float, vaccine.total_vaccinations)/population)*100) AS population_vaccinated
FROM COVID19.dbo.COVID_deaths AS deaths
JOIN COVID19.dbo.COVID_vaccines AS vaccine
	ON deaths.location = vaccine.location
	AND deaths.date = vaccine.date
WHERE deaths.continent IS NOT NULL
GROUP BY 
	deaths.continent
	,deaths.location
	,vaccine.population
ORDER BY 
	location;

-- With a TEMP Table
DROP TABLE IF EXISTS #temp_PopvsDeaths;
CREATE TABLE #temp_PopvsDeaths 
(
	Date date,
	Continent varchar(50), 
	Location varchar(50), 
	Population int, 
	New_Deaths int, 
	Rolling_People_Deaths float
);

INSERT INTO #temp_PopvsDeaths 
	SELECT 
		deaths.date
		,deaths.continent
		,deaths.location
		,vaccine.population
		,deaths.new_deaths
		,SUM(deaths.new_deaths) OVER (Partition By deaths.location ORDER BY deaths.location, deaths.date) AS rolling_people_deaths
	FROM COVID19.dbo.COVID_deaths AS deaths
	JOIN COVID19.dbo.COVID_vaccines AS vaccine
		ON deaths.location = vaccine.location
		AND deaths.date = vaccine.date
	WHERE deaths.continent IS NOT NULL;

SELECT 
	*
	,(CONVERT(float, rolling_people_deaths)/population)*100 AS population_died
FROM #temp_PopvsDeaths
WHERE location = 'Afghanistan';

-- Creating a VIEW instead of a TEMP TABLE for the query above to store data for later visualisations
DROP VIEW IF EXISTS view_PopvsDeaths;
CREATE VIEW view_PopvsDeaths AS
	SELECT 
		deaths.date
		,deaths.continent
		,deaths.location
		,vaccine.population
		,deaths.new_deaths
		,SUM(deaths.new_deaths) OVER (Partition By deaths.location ORDER BY deaths.location, deaths.date) AS rolling_people_deaths
	FROM COVID19.dbo.COVID_deaths AS deaths
	JOIN COVID19.dbo.COVID_vaccines AS vaccine
		ON deaths.location = vaccine.location
		AND deaths.date = vaccine.date
	WHERE deaths.continent IS NOT NULL;

SELECT 
	*
	,(CONVERT(float, rolling_people_deaths)/population)*100 AS population_died
FROM view_PopvsDeaths
WHERE location = 'Afghanistan';
