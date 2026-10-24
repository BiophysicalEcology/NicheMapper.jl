```@raw html
---
# https://vitepress.dev/reference/default-theme-home-page
layout: home

hero:
  name: "NicheMapper.jl"
  text: "Mechanistic niche modelling"
  tagline: "where and when organisms can persist, from the conservation of energy and mass. The Julia successor to NicheMapR."
  actions:
    - theme: brand
      text: The packages
      link: /packages
    - theme: alt
      text: View on Github
      link: https://github.com/BiophysicalEcology/NicheMapper.jl
    - theme: alt
      text: Architecture
      link: /architecture/mechanistic_niche_modelling_framework

features:
  - title: 🌦️ Microclimates
    details: Soil, surface and air conditions from <a class="highlight-link">Microclimate.jl</a>, run over points and grids from any forcing data set with <a class="highlight-link">MicroclimateMapper.jl</a>.
    link: /packages#Physical-environment
  - title: 🌬️ Physics of the environment
    details: Properties of air and water from <a class="highlight-link">FluidProperties.jl</a>, and clear-sky solar radiation from <a class="highlight-link">SolarRadiation.jl</a>.
    link: /packages#Physical-environment
  - title: 🔥 Heat and water exchange
    details: Body and leaf temperatures from <a class="highlight-link">HeatExchange.jl</a>, for shapes and insulation from <a class="highlight-link">BiophysicalGeometry.jl</a>.
    link: /packages#Organisms
  - title: 🦎 Behaviour and physiology
    details: Thermoregulation and activity with <a class="highlight-link">BiophysicalBehaviour.jl</a>, thermal performance with <a class="highlight-link">ThermalPhysiology.jl</a>.
    link: /packages#Organisms
  - title: ⚖️ Metabolism and scaling
    details: Dynamic Energy Budget life cycles with <a class="highlight-link">DEBtool_J.jl</a>, and allometry with <a class="highlight-link">BiologicalScaling.jl</a>.
    link: /packages#Metabolism
  - title: 🗺️ Animals, plants and microbes
    details: The <a class="highlight-link">AnimalMapper</a>, <a class="highlight-link">PlantMapper</a> and <a class="highlight-link">MicrobeMapper</a> packages (planned) put organisms into mapped microclimates.
    link: /packages#Mapper-packages
  - title: 📏 Units, dispatch and speed
    details: Every package uses <a class="highlight-link">Unitful.jl</a>, swaps sub-models by passing a type, and aims to be type-stable, non-allocating and differentiable.
    link: /architecture/extending_with_dispatch
---
```

## How to install NicheMapper.jl?

NicheMapper.jl is a meta-package: installing it pulls in the whole ecosystem. It is not yet
registered, so install it from GitHub:

```julia
julia> using Pkg
julia> Pkg.add(url = "https://github.com/BiophysicalEcology/NicheMapper.jl")
```

Each package can also be installed on its own; see [The packages](packages.md) for where to
start for a given problem, and [For NicheMapR users](nichemapr.md) for where NicheMapR's
functions now live.

## Status

The physics and biology packages are in use; the Mapper packages for animals, plants and
microbes are at the design stage. The [Architecture overview](architecture/mechanistic_niche_modelling_framework.md)
sets out the design, the use cases it serves and the build order.
