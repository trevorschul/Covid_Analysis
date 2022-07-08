

-- Select data to use

select location, date, total_cases, new_cases, total_deaths, population
from Portfolio_Project..CovidDeaths
order by 1,2 asc

-- looking at total cases vs total deaths
-- Infection Death Rate

select location, convert(date, date) as date, total_cases, total_deaths, convert(float, total_deaths)/nullif(convert(float,total_cases), 0) * 100 as DeathPercentage
from Portfolio_Project..CovidDeaths
where location like '%states%'
order by 1,2

--Total case vs pop

select location, convert(date, date) as date, total_cases, population, convert(float, total_cases)/nullif(convert(float,population), 0) * 100 as InfectionPercent
from Portfolio_Project..CovidDeaths
where location like '%states%'
order by 1,2

-- infection rates

select location, population, max(total_cases) as InfectionCount, max(convert(float, total_cases)/nullif(convert(float,population), 0) * 100) as InfectionPercent
from Portfolio_Project..CovidDeaths
group by location, population
order by InfectionPercent desc

-- death rate per capita

select location, max(total_deaths) as DeathCount, max(convert(float, total_deaths)/nullif(convert(float,population), 0) * 100) as DeathPercent
from Portfolio_Project..CovidDeaths
group by location
order by DeathPercent desc

-- Global

select convert(date, date) as date, sum(convert(float, new_cases)) as Cases, sum(convert(float,new_deaths)) as Deaths, sum(convert(float,nullif(new_deaths, 0))) / sum(convert(float, nullif(new_cases, 0))) * 100 as DeathRate
from Portfolio_Project..CovidDeaths
where continent is not null
group by date
order by 1,2

-- total pop vs vax
;with PopvsVac(continent, location, date, population, new_vaccinations, total_vax)
as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(cast(vac.new_vaccinations as float)) over (partition by dea.location order by dea.date, dea.location) as total_vax
from Portfolio_Project..CovidDeaths dea
join Portfolio_Project..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where vac.continent is not null
)
select *, (cast(total_vax as float)/nullif(cast(population as float),0)) * 100
from PopvsVac

-- Temp table for calculations on previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population float,
New_vaccinations float,
total_vax float
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as total_vax
From Portfolio_Project..CovidDeaths dea
Join Portfolio_Project..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date

Select *, (total_vax/nullif(Population, 0))*100
From #PercentPopulationVaccinated
