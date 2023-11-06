SELECT *
FROM model..CovidDeaths
WHERE continent is NOT NULL
ORDER BY 3,4

--Select Data that we are going to be using
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM model..CovidDeaths
WHERE continent is NOT NULL
ORDER BY 1,2

--Total Cases vs Total Deaths
--Show the death possibility if you contact Covid-19 in your country
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 DeathPercentage
FROM model..CovidDeaths
WHERE location like 'Viet%'
    AND continent is NOT NULL
ORDER BY 1,2

--Total Cases vs Population
--Show the percentage of people infected by Covid-19
SELECT location, date, total_cases, population, (total_cases/population)*100 PercentPeopleInfected
FROM model..CovidDeaths
-- WHERE location like 'Viet%'
ORDER BY 1,2

--Countries with Highest Infecion Rate compared to population
SELECT location, population, MAX(total_cases) HighestInfectionCounted, MAX((total_cases/population)*100) PercentagePopulationInfected
FROM model..CovidDeaths
-- WHERE location like 'Viet%'
WHERE continent is NOT NULL
GROUP BY location, population
ORDER BY PercentagePopulationInfected DESC

--Countries with Highest Death Count per Population
SELECT location, MAX(CAST(total_deaths AS int)) HighestTotalDeathCounted_l
FROM model..CovidDeaths
WHERE continent is NOT NULL
GROUP BY location
ORDER BY HighestTotalDeathCounted_l DESC

--CONTINENT NUMBERS
--Continents with Highest Death Count per population
SELECT continent, MAX(CAST(total_deaths AS int)) HighestTotalDeathCounted_c
FROM model..CovidDeaths
WHERE continent is NOT NULL
GROUP BY continent
ORDER BY HighestTotalDeathCounted_c DESC

--GLOBAL NUMBERS
SELECT date, SUM(new_cases) NewCases, SUM(total_deaths) TotalDeaths, (SUM(total_deaths)/SUM(total_cases))*100 DeathPercentage
FROM model..CovidDeaths
-- WHERE location LIKE 'Viet%'
WHERE continent is NOT NULL
GROUP BY date
ORDER BY 1,2

--Total Population vs Total Vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(VAC.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date ) PeopleVaccinatedByDay
FROM model..CovidDeaths dea
    JOIN model..CovidVaccinations vac
    ON dea.location = vac.location
        AND dea.date = vac.date
WHERE dea.continent is NOT NULL
ORDER BY 2,3

--Use CTE to perform Calculation on Partition By in previous query
--Percentage of Population received at least one Covid_19 Vaccine
WITH POPVACC(continent, location, date, population, new_vaccinations, PeopleVaccinatedByDay)
    AS
    (
        SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
        , SUM(VAC.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date ) PeopleVaccinatedByDay
        FROM model..CovidDeaths dea
            JOIN model..CovidVaccinations vac
            ON dea.location = vac.location
                AND dea.date = vac.date
        WHERE dea.continent is NOT NULL
    )
SELECT *, (PeopleVaccinatedByDay/population)*100 PercentagePopulationVaccinated
FROM POPVACC
ORDER BY 2,3

--TEMP TABLE
--Use Temp Table to perform Calculation on Partition By in previous query
DROP TABLE IF exists #PopulationVaccinatedFigure
CREATE TABLE #PopulationVaccinatedFigure
(
    continent VARCHAR(255),
    location VARCHAR(255),
    date DATETIME,
    population NUMERIC,
    new_vaccinations NUMERIC,
    PeopleVaccinatedByDay NUMERIC
)

INSERT INTO #PopulationVaccinatedFigure
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(VAC.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date ) PeopleVaccinatedByDay
FROM model..CovidDeaths dea
    JOIN model..CovidVaccinations vac
    ON dea.location = vac.location
        AND dea.date = vac.date
WHERE dea.continent is NOT NULL

SELECT * 
FROM #PopulationVaccinatedFigure
ORDER BY 2,3

-- Create View to store data for later visualizations
CREATE VIEW PopulationVaccinatedFigure AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(VAC.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date ) PeopleVaccinatedByDay
FROM model..CovidDeaths dea
    JOIN model..CovidVaccinations vac
    ON dea.location = vac.location
        AND dea.date = vac.date
WHERE dea.continent is NOT NULL
