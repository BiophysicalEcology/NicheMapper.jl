# NicheMapper.jl

[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://BiophysicalEcology.github.io/NicheMapper.jl/dev)
[![Documentation](https://github.com/BiophysicalEcology/NicheMapper.jl/actions/workflows/Documentation.yml/badge.svg)](https://github.com/BiophysicalEcology/NicheMapper.jl/actions/workflows/Documentation.yml)
[![CI](https://github.com/BiophysicalEcology/NicheMapper.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/BiophysicalEcology/NicheMapper.jl/actions/workflows/CI.yml)

A Julia ecosystem for mechanistic niche modelling of plants, animals, and microbes —
the Julia successor to [NicheMapR](https://github.com/mrke/NicheMapR).

## Packages

```
NicheMapper.jl              ← meta package
PlantMapper.jl              ← plant niche simulation (photosynthesis, stomata, growth)
AnimalMapper.jl             ← animal niche simulation (thermoregulation, energy budget)
MicrobeMapper.jl            ← microbial niche simulation (deferred)
MicroclimateMapper.jl       ← physical environment (forcing data, terrain, microclimate)
```

Installing `NicheMapper` pulls the full ecosystem. Each sub-package can also be installed
independently.

## Architecture

The full design rationale and interface specifications are in:
[docs/src/architecture/mechanistic_niche_modelling_framework.md](docs/src/architecture/mechanistic_niche_modelling_framework.md)

## Status

Early design stage. See [docs/src/architecture/](docs/src/architecture/) for the current design
and open [Issues](issues) to discuss architecture decisions.

## Development

Part of the [BiophysicalEcology](https://github.com/BiophysicalEcology) organisation.
