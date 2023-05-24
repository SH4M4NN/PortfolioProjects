SELECT * FROM `practical-cider-383010.PortfolioProject.CovidDeaths` 
WHERE continent IS NOT NULL
ORDER BY 3,4

-- SELECT * FROM `practical-cider-383010.PortfolioProject.CovidVaccinations` 
-- ORDER BY 3,4


-- Select Data that we are going to be using

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM `practical-cider-383010.PortfolioProject.CovidDeaths` 
ORDER BY 1,2


-- Looking at Total Cases vs Total Deaths in Denmark
-- Shows likelihood of dying if you contact Covid-19 in Denmark

SELECT location, date, total_cases, total_deaths,(total_deaths/total_cases)*100 AS DeathPercentage
FROM `practical-cider-383010.PortfolioProject.CovidDeaths` 
WHERE location LIKE 'Denmark' AND continent IS NOT NULL
ORDER BY 1,2



-- Looking at Total Cases vs Population
-- Shows what percentage of population got Covid-19

SELECT location, date, population, total_cases, (total_cases/population)*100 AS PercentPopulationInfected
FROM `practical-cider-383010.PortfolioProject.CovidDeaths` 
--WHERE location LIKE 'Denmark' AND continent IS NOT NULL
ORDER BY 1,2



-- What country has the highest infection rate compared to population.

SELECT location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM `practical-cider-383010.PortfolioProject.CovidDeaths` 
--WHERE location LIKE 'Denmark' AND continent IS NOT NULL
GROUP BY Location, Population
ORDER BY PercentPopulationInfected DESC



--Showing countries with Highest Death Count per Population

SELECT location, MAX(total_deaths) as TotalDeathcount
FROM `practical-cider-383010.PortfolioProject.CovidDeaths` 
--WHERE location LIKE 'Denmark' 
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC



--BREAK THINGS DOWN BY CONTINENT



-- Continents with the highest death count per population

SELECT location, MAX(total_deaths) as TotalDeathcount
FROM `practical-cider-383010.PortfolioProject.CovidDeaths` 
--WHERE location LIKE 'Denmark' 
WHERE continent IS NULL
GROUP BY location
ORDER BY TotalDeathCount DESC


-----------------------------

-- Total Death Count per Continents 

SELECT continent, MAX(total_deaths) as TotalDeathcount
FROM `practical-cider-383010.PortfolioProject.CovidDeaths` 
--WHERE location LIKE 'Denmark' 
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC



--GLOBAL NUMBERS 

SELECT SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, SUM(new_deaths)/SUM(new_cases)*100 AS DeathPercentage
FROM `practical-cider-383010.PortfolioProject.CovidDeaths` 
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1,2



--In Denmark

SELECT SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, SUM(new_deaths)/SUM(new_cases)*100 AS DeathPercentage
FROM `practical-cider-383010.PortfolioProject.CovidDeaths` 
WHERE location LIKE 'Denmark' 
--GROUP BY date
--ORDER BY 1,2



--Looking at Total Population vs Vaccination

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
    SUM(vac.new_vaccinations) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS           RollingPeopleVaccinated, --(RollingPeopleVaccinated/population)*100
FROM practical-cider-383010.PortfolioProject.CovidDeaths dea
JOIN practical-cider-383010.PortfolioProject.CovidVaccinations vac 
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 
ORDER BY 2,3


-- USE CTE
WITH PopvsVac AS (
  SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
  FROM
    practical-cider-383010.PortfolioProject.CovidDeaths dea
    JOIN practical-cider-383010.PortfolioProject.CovidVaccinations vac
      ON dea.location = vac.location
        AND dea.date = vac.date
  WHERE
    dea.continent IS NOT NULL
--ORDER BY 2,3
)
SELECT *, (RollingPeopleVaccinated/Population)*100
FROM PopvsVac
ORDER BY 2, 3;



--TEMP TABLE DOESNT WORK ON BigQuery 

CREATE TABLE #PercentPopulationVaccinated
(
Continent NVARCHAR(255),
Location NVARCHAR(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
  SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
  FROM
    practical-cider-383010.PortfolioProject.CovidDeaths dea
    JOIN practical-cider-383010.PortfolioProject.CovidVaccinations vac
      ON dea.location = vac.location
        AND dea.date = vac.date
  WHERE
    dea.continent IS NOT NULL

SELECT *, (RollingPeopleVaccinated/Population)*100
FROM #PercentPopulationVaccinated


--------WORKAROUND FOR BigQuery

WITH PercentPopulationVaccinated AS (
  SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
  FROM
    `practical-cider-383010.PortfolioProject.CovidDeaths` dea
    JOIN `practical-cider-383010.PortfolioProject.CovidVaccinations` vac
      ON dea.location = vac.location
        AND dea.date = vac.date
  WHERE
    dea.continent IS NOT NULL
)

SELECT *, (RollingPeopleVaccinated/Population)*100
FROM PercentPopulationVaccinated;



--Created Permanent table and used in the query 

CREATE TABLE PortfolioProject.PercentPopulationVaccinated
AS
SELECT
  dea.continent,
  dea.location,
  dea.date,
  dea.population,
  vac.new_vaccinations,
  SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM
  PortfolioProject.CovidDeaths dea
  JOIN PortfolioProject.CovidVaccinations vac
    ON dea.location = vac.location
      AND dea.date = vac.date
WHERE
  dea.continent IS NOT NULL;


SELECT 
    *, (RollingPeopleVaccinated / Population) * 100
FROM
    PortfolioProject.PercentPopulationVaccinated;


-- Creating View to store data for later visualizations 

CREATE VIEW PortfolioProject.PercentPopulationVaccinatedView AS
SELECT
  dea.continent,
  dea.location,
  dea.date,
  dea.population,
  vac.new_vaccinations,
  (SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) / dea.population) * 100 AS RollingPercentVaccinated
FROM
  PortfolioProject.CovidDeaths dea
  JOIN PortfolioProject.CovidVaccinations vac
    ON dea.location = vac.location
      AND dea.date = vac.date
WHERE
  dea.continent IS NOT NULL;


SELECT 
    *
FROM
    PortfolioProject.PercentPopulationVaccinated














