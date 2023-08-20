select * from PortfolioProject..CovidVaccinations
WHERE continent is not null
order by 3,4

select * from PortfolioProject..CovidDeaths
WHERE continent is not null
order by 3, 4

-- select data that we are going to use

select location, date, total_cases, new_cases, total_deaths, population
from PortfolioProject..CovidDeaths
WHERE continent is not null
order by 1,2

-- two ways to get the datatypes of columns in SQL
exec sp_help covidDeaths
-- OR
SELECT *
FROM INFORMATION_SCHEMA.COLUMNS
WHERE table_name = 'coviddeaths'

-- changing the type of the column
Alter table covid_deaths alter column total_cases_per_million float
Alter table covid_deaths alter column population float


-- Looking at Total Cases vs Total Deaths - shows the likelihood of the dying if you contract covid
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from PortfolioProject..CovidDeaths
-- where location like '%states'
WHERE continent is not null
order by 1,2

-- Looking at total cases vs population - shows what percentage of population got covid
select location, date, total_cases, population, (total_cases/population)*100 as PercentPopulationInfected
from PortfolioProject..CovidDeaths
WHERE continent is not null
--where location like '%states'
order by 1,2

-- Looking at countries with Highest Infection Rate compared to Population 
select location, max(total_cases) as HighestInfectionCount, population,
(max(total_cases)/population)*100 as PercentPopulationInfected
from PortfolioProject..CovidDeaths
WHERE continent is not null
--where location like '%states'
group by location,population
order by PercentPopulationInfected desc


-- Showing countries with Highest Death Count per population 
select location, max(cast(total_deaths as INT)) as TotalDeathCount
from PortfolioProject..CovidDeaths
WHERE continent is not null
group by location
order by TotalDeathCount desc


-- Removing the continents from location
SELECT *
FROM CovidDeaths
WHERE continent is not null
ORDER BY 3,4 

-- Breaking down by continent
select continent, max(cast(total_deaths as INT)) as TotalDeathCount
from PortfolioProject..CovidDeaths
WHERE continent is  not null
group by continent
order by TotalDeathCount desc

-- Global numbers by day
select date, sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths, sum(cast(new_deaths as int))/sum(new_cases)*100 as DeathPercentage
from PortfolioProject..CovidDeaths
WHERE continent is not null
group by date
order by 1,2

-- Global number overall
select sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths, sum(cast(new_deaths as int))/sum(new_cases)*100 as DeathPercentage
from PortfolioProject..CovidDeaths
WHERE continent is not null
order by 1,2


select *
from CovidDeaths dea
join CovidVaccinations vac
on dea.location = vac.location
and dea.date = vac.date

-- looking at total population vs vaccinations 
with PopulationVsVaccination (Continent, Location, Date, Population, new_vaccinations, rolling_people_vaccinated)
as
(
select dea.continent, dea.location,dea.date, dea.population, vac.new_vaccinations,
sum(cast(vac.new_vaccinations as int)) over (partition by dea.location order by dea.location,
dea.date) as rolling_people_vaccinated
from CovidDeaths dea
join CovidVaccinations vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
)
-- use cte
select *, (rolling_people_vaccinated/population)*100
from
PopulationVsVaccination


--- TEMP TABLE
-- we are creating the table PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_people_vaccinated numeric
)

-- we are inserting the values to the table PercentPopulationVaccinated
INSERT INTO #PercentPopulationVaccinated
select dea.continent, dea.location,dea.date, dea.population, vac.new_vaccinations,
sum(cast(vac.new_vaccinations as int)) over (partition by dea.location order by dea.location,
dea.date) as rolling_people_vaccinated
from CovidDeaths dea
join CovidVaccinations vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null

Select *, (rolling_people_vaccinated/population)*100 
from #PercentPopulationVaccinated

-- create views to store data for later visualizations
create view PercentPopulationVaccinated as
select dea.continent, dea.location,dea.date, dea.population, vac.new_vaccinations,
sum(cast(vac.new_vaccinations as int)) over (partition by dea.location order by dea.location,
dea.date) as rolling_people_vaccinated
from CovidDeaths dea
join CovidVaccinations vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null