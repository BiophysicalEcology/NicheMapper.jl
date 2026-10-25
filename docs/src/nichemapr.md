# For NicheMapR users

The ecosystem splits [NicheMapR](https://github.com/mrke/NicheMapR)'s functionality into
separate packages, so each part can be used, tested and replaced on its own.

| NicheMapR | Julia |
|---|---|
| `micro_global`, `micro_era5`, `micro_aust`, `micro_ncep` and other `micro_*` functions | MicroclimateMapper.jl, with the data set as a keyword |
| `microclimate` (the microclimate model itself) | Microclimate.jl |
| `WETAIR`, `DRYAIR`, `VAPPRS` | FluidProperties.jl |
| `SOLRAD` and the solar options of `micro_*` | SolarRadiation.jl |
| `ectotherm` heat budget, `endoR`, `leaf_temperature` | HeatExchange.jl, with shapes from BiophysicalGeometry.jl and allometric ones from BiologicalScaling.jl |
| thermoregulation and activity in `ectotherm` and `endoR` | BiophysicalBehaviour.jl |
| `DEB` options of `ectotherm` | DEBtool_J.jl |
| `ectotherm` as a whole | AnimalMapper.jl (planned) |
| `plantgro` | PlantMapper.jl (planned) |

See [History](background.md) for how the models developed from the 1970s to NicheMapR.
