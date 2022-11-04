select * 
from PortfoliioProject.dbo.[covid death]
order by 3,4

--select * 
--from PortfoliioProject.dbo.[covid Vaccinations]
--order by 3,4


--=======================================================================
-- Select Data that we are going to be starting with
select Location,date,total_cases,new_cases,total_deaths,population
from PortfoliioProject.dbo.[covid death]
order by 1,2
--=======================================================================
-- Total Case per total death, shows likelyhood of dying from covid if positive
select Location,date,total_cases,total_deaths,(total_deaths/total_cases)*100 as Death_Percentage
from PortfoliioProject.dbo.[covid death]
where location like '%states%'
--and continent is not NULL
order by 1,2

--=======================================================================
-- total case per population

select Location,date,total_cases,population,round((total_cases/population)*100,3) as Percentage_of_Covid_Per_Population
from PortfoliioProject.dbo.[covid death]
where location like '%states%' and continent is not null
order by 1,2

--=======================================================================
-- Total case per population
select Location,date,total_deaths,population,round((total_deaths/population)*100,3) as Percentage_of_Covid_death_Population
from PortfoliioProject.dbo.[covid death]
where location like '%states%' and continent is not NULL
order by 1,2

--=======================================================================
-- Total infection rate
select Location, population, MAX(total_cases) as Highest_Infection_Count, MAX(round((total_cases/population)*100,2)) as Percentage_of_Infection_Per_Population
from PortfoliioProject.dbo.[covid death]
--where location like '%states%' and continent is not NULL
group by Location,population
order by Percentage_of_Infection_Per_Population desc

--=======================================================================
-- Total death rate per country
select Location, MAX(cast(total_deaths as int)) as Highest_Death_Count, MAX(round(((cast(total_deaths as int))/population)*100,4)) as Percentage_of_Death_Per_Population
from PortfoliioProject.dbo.[covid death]
where continent is not NULL
group by Location
order by Highest_Death_Count desc

--=======================================================================
-- Total death rate per continent
select Location, MAX(cast(total_deaths as int)) as Highest_Death_Count
from PortfoliioProject.dbo.[covid death]
where continent is  NULL
group by Location
order by Highest_Death_Count desc

--=======================================================================
-- Total death rate per country in a continent
select Location, MAX(cast(total_deaths as int)) as Highest_Death_Count
from PortfoliioProject.dbo.[covid death]
where continent  like '%Africa%'
group by Location
order by Highest_Death_Count desc


--=======================================================================
-- TGLOBAL NUMBERS
=========================================================================
-- total case per total death
select date,sum(total_cases) as Total_Cases,total_deaths as Total_Death,round((total_deaths/population)*100,3) as Percentage_of_Covid_death_Population
from PortfoliioProject.dbo.[covid death]
-- where location like '%states%' and 
where continent is not null
group by date,total_deaths,population
order by date asc

=========================================================================
-- total case per total death
select dea.continent, dea.location,dea.date,dea.population,vac.new_vaccinations,SUM(cast(vac.new_vaccinations as int)) 
     over (partition by dea.location order by dea.location,dea.date) as Rolling_vaccination
from PortfoliioProject.dbo.[covid death] dea
join PortfoliioProject.dbo.[covid vaccinations] vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3

=========================================================================
-- total case per total death
with PoppulationVsVaccinaiton (continent,Location,Date,population,new_vaccination,Rolling_vaccination)
as(
select dea.continent, dea.location,dea.date,dea.population,vac.new_vaccinations,SUM(cast(vac.new_vaccinations as int)) 
     over (partition by dea.location order by dea.location,dea.date) as Rolling_vaccination
from PortfoliioProject.dbo.[covid death] dea
join PortfoliioProject.dbo.[covid vaccinations] vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3
)
select *, (round((Rolling_vaccination/population)*100, 3)) 
from PoppulationVsVaccinaiton

=========================================================================
-- total population vs vaccination
select dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations
from PortfoliioProject.dbo.[covid death] dea
join PortfoliioProject.dbo.[covid vaccinations] vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3

=========================================================================
-- total population vs rulling vaccination
select dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations
	,SUM(cast(vac.new_vaccinations as int)) OVER(PARTITION BY dea.location order by dea.location,dea.date) as RollingVaccinationCount
from PortfoliioProject.dbo.[covid death] dea
join PortfoliioProject.dbo.[covid vaccinations] vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3

=========================================================================
-- total population vs rulling vaccination with percentage
method 1 - CTE
with PopvsVac (Continent,Location,Date,Population,New_Vaccinaiton, RollingVaccinationCount)
as
(
select dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations
	,SUM(convert(int,vac.new_vaccinations)) OVER(PARTITION BY dea.location order by dea.location,dea.date) as RollingVaccinationCount
from PortfoliioProject.dbo.[covid death] dea
join PortfoliioProject.dbo.[covid vaccinations] vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
)
select *, (RollingVaccinationCount/population)*100 as Percentage_of_Total_Vaccinated
from PopvsVac
where location like '%states%' and location not like '%Virgin%'
order by 2,3
==============================================================================================
method 2 - TEMP TABLE

drop table if exists #PercentPopulationVaccinated
CREATE Table #PercentPopulationVaccinated
(
continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RollingVaccinationCount numeric
)

INSERT INTO #PercentPopulationVaccinated

select dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations
	,SUM(convert(bigint,vac.new_vaccinations)) OVER(PARTITION BY dea.location order by dea.location,dea.date) as RollingVaccinationCount
from PortfoliioProject.dbo.[covid death] dea
join PortfoliioProject.dbo.[covid vaccinations] vac
	on dea.location = vac.location
	and dea.date = vac.date
-- where dea.continent is not null

select *, (RollingVaccinationCount/Population)*100 as Percentage_of_Total_Vaccinated
from #PercentPopulationVaccinated
where location like '%states%' and location not like '%Virgin%'
order by 2,3
===========================================================================================
===========================================================================================
===========================================================================================
-- CREATE VIEW to store data for later visualizaiton


create view PercentageOfPopulationVaccinated as
select dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations
	,SUM(cast(vac.new_vaccinations as int)) OVER(PARTITION BY dea.location order by dea.location,dea.date) as RollingVaccinationCount
from PortfoliioProject.dbo.[covid death] dea
join PortfoliioProject.dbo.[covid vaccinations] vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3

select * from PercentageOfPopulationVaccinated
