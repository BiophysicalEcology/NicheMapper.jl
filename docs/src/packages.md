# The packages

The ecosystem separates the problem by discipline: physics packages for the environment,
organism-level packages for heat exchange, behaviour and metabolism, and Mapper packages that
run them over forcing data at points or across landscapes. The
[dependency graph](architecture/mechanistic_niche_modelling_framework.md#Dependencies)
shows how they build on each other.

## Physical environment

| Package | What it provides | Docs |
|---|---|---|
| Microclimate.jl | Soil, surface, snow and canopy energy and water balance; hourly microclimate profiles for one site | [docs](https://biophysicalecology.github.io/Microclimate.jl/dev/) |
| MicroclimateMapper.jl | Microclimate.jl over points and grids, from weather, terrain, soil and land cover data sets | [docs](https://biophysicalecology.github.io/MicroclimateMapper.jl/dev/) |
| SolarRadiation.jl | Solar geometry and spectral direct, diffuse and global irradiance | [repo](https://github.com/BiophysicalEcology/SolarRadiation.jl) |
| FluidProperties.jl | Properties of air, water vapour and liquid water | [docs](https://biophysicalecology.github.io/FluidProperties.jl/dev/) |

## Organisms

| Package | What it provides | Docs |
|---|---|---|
| HeatExchange.jl | Heat and water budgets of organisms (radiation, convection, evaporation, conduction); body and leaf temperature | [repo](https://github.com/BiophysicalEcology/HeatExchange.jl) |
| BiophysicalGeometry.jl | Body shapes and insulation (fur, feathers, fat) | [docs](https://biophysicalecology.github.io/BiophysicalGeometry.jl/previews/PR20/) |
| BiophysicalBehaviour.jl | Thermoregulation of ectotherms, endotherms and heterotherms; activity; optimal control | [repo](https://github.com/BiophysicalEcology/BiophysicalBehaviour.jl) |
| ThermalPhysiology.jl | Thermal performance curves, temperature corrections, thermal death time and tolerance landscapes | [docs](https://biophysicalecology.github.io/ThermalPhysiology.jl/dev/) |

## Metabolism

| Package | What it provides | Docs |
|---|---|---|
| DEBtool_J.jl | Dynamic Energy Budget models of full life cycles, from the Add-my-Pet collection | [docs](https://add-my-pet.github.io/DEBtool_J.jl/) |
| BiologicalScaling.jl | Allometry of metabolic rate, geometry and life history across taxa | [docs](https://biophysicalecology.github.io/BiologicalScaling.jl/dev/) |

## Mapper packages

| Package | What it provides | Status |
|---|---|---|
| AnimalMapper.jl | Animal heat budgets, behaviour and metabolism over mapped microclimates | planned |
| PlantMapper.jl | Plant heat and water budgets, photosynthesis and growth, coupled to the microclimate | planned |
| MicrobeMapper.jl | Microbial growth driven by soil temperature and moisture | planned |
| NicheMapper.jl | Installs the whole ecosystem | this package |

BiophysicalEcologyBase.jl holds the abstract types the packages share.

## Where to start

| I want to… | Start with |
|---|---|
| map microclimates, or derive gridded predictors for distribution models | MicroclimateMapper.jl |
| run a detailed microclimate at one site, or test its physics | Microclimate.jl |
| compute the temperature of an animal or leaf in a given environment | HeatExchange.jl |
| interpret body temperature, metabolic or water-loss data | HeatExchange.jl, ThermalPhysiology.jl |
| simulate thermoregulation and activity | BiophysicalBehaviour.jl |
| simulate growth, reproduction and life history | DEBtool_J.jl |

The [Architecture overview](architecture/mechanistic_niche_modelling_framework.md#Use-cases)
lists the use cases the ecosystem is designed around.
