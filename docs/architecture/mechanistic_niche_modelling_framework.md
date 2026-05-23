# Package Plan: Full BiophysicalEcology Ecosystem

---

## Ecosystem Overview

Package ecosystem under github.com/BiophysicalEcology:

```
NicheMapper.jl              ← meta re-export: installs full ecosystem; also defines shared
       ↑                       semantic contracts (AbstractForcing, AbstractSimulationEngine)
PlantMapper.jl  AnimalMapper.jl  ← MicrobeMapper.jl (deferred)
    ↑           ↑
MicroclimateMapper.jl       ← physical environment: forcing data, terrain, microclimate
                               (MicroResult <: AbstractForcing), lateral physics (e.g. cold air drainage, water drainage)
```

**Grid processing** technical only, no science (chunking, warm-starts, windowing). To be developed by Raf Schouten, name and package boundaries TBD. Not in scope for this plan.

**Installing NicheMapper** pulls the full ecosystem. Installing only PlantMapper gives
microclimate + plant simulation without animal deps. Installing only MicroclimateMapper gives
just the physical environment layer.

**Goals:**
- Simulate organism niches (plants, animals, microbes) with full biophysical feedbacks
- Cover both point and gridded use-cases (grid layer via grid processing package)
- Encourage community contributions — open interfaces

**Existing code to migrate into MicroclimateMapper.jl** (porting from c:/git/BiophysicalGrids.jl, led by Raf):
| Old file | Destination | Action |
|---|---|---|
| `src/WeatherDataSources/TerraClimate.jl` | MicroclimateMapper `ForcingData/TerraClimate.jl` | Port |
| `src/WeatherDataSources/ERA5.jl` | MicroclimateMapper `ForcingData/ERA5.jl` | Port |
| `src/WeatherDataSources/GRIDMET.jl` | MicroclimateMapper `ForcingData/GRIDMET.jl` | Port |
| `src/WeatherDataSources/climate_scenarios.jl` | MicroclimateMapper `ForcingData/climate_scenarios.jl` | Port |
| `src/WeatherDataSources/common.jl` (simulate_microclimate) | MicroclimateMapper `Microclimate/simulate.jl` | Port |
| `src/Mesoclimate/` | MicroclimateMapper `ForcingData/mesoclimate.jl` | Port |
| `src/Atmosphere/aerosol.jl` | MicroclimateMapper `ForcingData/aerosol.jl` | Port |
| existing simple transpiration in Microclimate.jl | MicroclimateMapper `Plant/simple_transpiration.jl` | Extract + formalise |
| (new) | MicroclimateMapper `Plant/abstract_plant.jl` | New — AbstractPlantModel interface |
| (new) | MicroclimateMapper `Microclimate/environment_bridge.jl` | New — MicroResult → EnvironmentalVars |
| (new) | NicheMapper.jl (entire package) | New — semantic contracts + meta re-export |

---

## Conceptual Framework: Mechanistic Niche Modelling

Mechanistic niche modelling uses physical principles to compute the exchange of heat and
water between organisms and their environment (biophysics), coupled with a metabolic engine
that tracks the uptake of substrates and their allocation to growth, development, maintenance,
and reproduction. Behaviour — thermoregulation, foraging, dormancy — is the control algorithm
mediating between environment and physiology. Dynamic Energy Budget (DEB) theory makes this
maximally thermodynamically explicit: energy and mass are tracked in a framework consistent
with thermodynamic laws. Empirical metabolic approaches are accommodated via abstract
interfaces, allowing simpler models where DEB complexity is not warranted.

The software embodies this concept through a layered architecture:
- **HeatExchange.jl** — biophysical heat and water exchange (instantaneous physics)
- **BiophysicalBehaviour.jl** — behavioural control algorithms (thermoregulation, microhabitat)
- **MicroclimateMapper.jl** — environmental forcing time series; `MicroResult <: AbstractForcing`
- **NicheMapper.jl** — shared semantic contracts (abstract types, accessor interfaces)
- **AnimalMapper.jl / PlantMapper.jl / MicrobeMapper.jl** — organism-specific niche pipelines

---

## Architecture Justification: Why These Packages?

The separation into AnimalMapper / PlantMapper / MicrobeMapper / MicroclimateMapper is not
justified by biology alone — it is justified by the computational structure of each system.
Each package corresponds to a fundamentally different **model class** with different state
representations, update rules, solver topologies, and coupling structures.

### The real axis of separation: "what is the evolving state?"

All models follow `state_{t+1} = F(state_t, forcing_t, interactions)`, but the structure
of `state` is qualitatively different:

**Animals — mobile, decision-driven agents (hybrid control systems)**
State: position, body temperature, energy reserves, hydration, behavioural mode, digestive state.
Update rule: `(state, forcing) → behavioural decision → new state`
Animals are control systems embedded in physics. State evolution is **policy-driven**:
discrete activity states (rest/bask/feed), optimisation loops coupling heat budget to
digestion and movement, event-driven transitions. This is a hybrid discrete-continuous
dynamical system with a decision graph — not just ODE physics.

**Plants — sessile, distributed physiological systems (coupled nonlinear solvers)**
State: LAI, root density profile, carbon pools, water potential gradients, stomatal state.
Update rule: continuous implicit coupling across compartments — stomatal conductance ↔
photosynthesis ↔ leaf temperature ↔ root uptake ↔ soil ψ. Plants have no discrete
behavioural policy. State evolution requires **fixed-point iteration and implicit solvers**
because internal feedbacks create simultaneous equations. Growth modifies geometry, which
modifies the physics next step. No equivalent of "making a decision."

**Microbes — population-level reactive kinetics (explicit ODE systems)**
State: biomass density and substrate concentration per soil node.
Update rule: `dN/dt = f(N, S, f_T, f_ψ)` — local, memoryless, monotonic kinetics.
No individual identity, no transport decisions, no morphology, no structural feedback.
Computationally: pure kinetic systems with environmental modulation — forward-integrated
ODE/reaction-diffusion, not agent-based and not requiring implicit solvers.

**Microclimate — exogenous physical forcing field generator**
State: radiation, temperature profiles, humidity, wind, soil moisture/thermal diffusion.
Evolves independently of organisms in the current design. Computationally: a physical
field solver (PDE-based), not a biological system.

### Substrate uptake forces the split structurally

| System | Uptake type | Computational form |
|---|---|---|
| Animal | Discrete ingestion events — event-based, behaviour-limited | Point process over time |
| Plant | Continuous spatial flux — gradient-driven, hydraulically constrained | Field-coupled flux system |
| Microbe | Concentration-driven local consumption — no transport limitation | Reaction term in ODE |

Combining these into one API would force overloaded types, conditional branching everywhere,
and incompatible solver semantics. The separation is **numerically necessary**, not aesthetic.

### Why merging would be wrong

Forcing animal + plant + microbe into one package would require:
- `AbstractOrganism` that is simultaneously an agent, a nonlinear coupled field system, and an ODE
- `AbstractEnergyBudget` that handles both discrete food intake events and continuous CO₂ flux
- Solver machinery for all three paradigms in one package
- Impossible interface stability as any of the three domains evolves

### What NicheMapper.jl actually unifies

NicheMapper.jl does **not** unify biology — it unifies the **coupling interfaces between
heterogeneous dynamical systems**:
1. **Forcing access** — consistent environmental field accessors for all consumers
2. **Exchange semantics** — a common contract for energy/water/substrate interactions
3. **Simulation protocol** — `step!(engine, forcing, dt)` time-stepping contract
4. **Capability traits** — what kind of dynamical system is this? (not what organism?)

NicheMapper is a **systems integration layer**, not a biological abstraction layer.

---

## NicheMapper.jl — Shared Semantic Layer + Meta-Package

NicheMapper.jl serves two roles:
1. **Semantic contracts** — abstract types and accessor functions shared across all packages
2. **Meta re-export umbrella** — `using NicheMapper` installs and re-exports the full ecosystem

```julia
module NicheMapper
  using Reexport
  # (semantic contract definitions below)
  @reexport using MicroclimateMapper
  @reexport using PlantMapper
  @reexport using AnimalMapper
  # spatial/grid package re-exported once grid package is named and registered
end
```

Package description: "Julia ecosystem for mechanistic niche modelling of plants, animals, and
microbes — the Julia successor to NicheMapR." The name preserves NicheMapR community
recognition at the most visible level.

It defines only semantic contracts — abstract types and accessor functions — never
implementations, physics, or data structures tied to any one domain. Each `*Mapper.jl`
package is a backend plugin.

**Internal conceptual layers (one package, two responsibilities — keep them separate):**

**Layer A — NicheCore** (forcing contracts; highly stable, changes rarely):
- `AbstractForcing` + semantic accessor functions
- `DEFAULT_DT` convention
- `AbstractEnvironmentSampler` — formalises the shade-interpolation pattern

**Layer B — NicheProtocol** (simulation contracts; may evolve with solver needs):
- `AbstractSimulationEngine` + `step!`, `state`, `result`
- `AbstractResourceField` — unifies food/litter/substrate across all three packages
- Minimal capability traits (what kind of dynamical system is this?)

Since MicroclimateMapper.jl is being co-designed, `MicroResult` implements `AbstractForcing`
natively. `MicroclimateMapper` is the **default closed-system implementation** of
`AbstractForcing` — not "the forcing system". Future `CoupledForcing <: AbstractForcing`
implementations (e.g. with canopy feedback or burrowing effects) extend this without
breaking the NicheMapper contract.

```julia
module NicheMapper

# ── Layer A: NicheCore (forcing contracts) ────────────────────────────────────

const DEFAULT_DT = 1u"hr"

abstract type AbstractForcing end
struct Air end; struct Soil end  # location dispatch tags

# Semantic accessors — MicroclimateMapper implements these for MicroResult
air_temperature(f::AbstractForcing, step, height_node)         # → u"°C"
soil_temperature(f::AbstractForcing, step, depth_node)         # → u"°C"
solar_radiation(f::AbstractForcing, step)                      # → u"W/m^2"
wind_speed(f::AbstractForcing, step, height_node)              # → u"m/s"
relative_humidity(f::AbstractForcing, step, height_node)       # → dimensionless 0–1
soil_water_potential(f::AbstractForcing, step, depth_node)     # → u"J/kg"
vapour_pressure_deficit(f::AbstractForcing, step, height_node) # → u"kPa"

# Environment sampler — formalises the AvailableEnvironments shade-interpolation pattern
# (currently in BiophysicalBehaviour.jl; this abstract type makes it explicit)
abstract type AbstractEnvironmentSampler end
sample(sampler::AbstractEnvironmentSampler, shade_fraction, step) → AbstractForcing

# ── Layer B: NicheProtocol (simulation contracts) ─────────────────────────────

abstract type AbstractOrganism end  # minimal capability marker — no biology

# Simulation engine — all simulate_* functions return a type implementing this
abstract type AbstractSimulationEngine end
step!(engine::AbstractSimulationEngine, step_index::Int, forcing::AbstractForcing, dt)
state(engine::AbstractSimulationEngine)
result(engine::AbstractSimulationEngine)  # → package-specific Result type

# Resource field — unifies food (animals), C/N/light (plants), substrate (microbes)
# as depletable/regenerating resource pools with optional spatial distribution
abstract type AbstractResourceField end
resource_availability(field::AbstractResourceField, step)   # → Quantity (units depend on domain)
deplete!(field::AbstractResourceField, consumed, step, dt)  # required — update field state

end
```

**What NicheMapper.jl does NOT contain:** biological models, DEB, photosynthesis, microbial
kinetics, lifecycle concepts, shared result structs, array-level MicroResult access patterns.

**Dependency graph:**
```
NicheMapper.jl                       (Layer A + B contracts only)
       ↑
MicroclimateMapper.jl                (MicroResult <: AbstractForcing — default implementation)
       ↑
AnimalMapper.jl   PlantMapper.jl   MicrobeMapper.jl
       ↑                ↑
     AnimalMapper ext/PlantMapperExt.jl
```

---

## Context

Three organism-level packages implementing mechanistic niche modelling for animals, plants,
and microbes. Each consumes `AbstractForcing` via semantic accessors and produces an
organism-specific result type.

**Scope boundary with HeatExchange.jl:**
HeatExchange.jl solves the instantaneous heat and water exchange balance — respiratory
heat/water loss, skin evaporative water loss, egg water exchange, and body temperature
solving. It accepts metabolic heat production as an INPUT (not origin).

DEB models (via DEBtool_J.jl, activated in `ext/DEBtoolExt.jl`) compute the metabolic
flux rates FROM the DEB state at each timestep:
- Heat production rate (dissipation + assimilation overhead + growth overhead)
- O2 consumption rate, CO2 production rate
- Metabolic water production rate (from substrate oxidation)
- Nitrogenous waste production rate (urea/uric acid → urinary water loss)
- Faecal waste production rate (→ faecal water loss)

These flux rates feed in two directions:
- Metabolic heat → HeatExchange.jl (as forcing term for body temperature solver)
- Metabolic water + waste fluxes → `DigestiveWaterFluxes` (complementing food-derived water)

**What these packages add:**
- The simulation PIPELINE conforming to `AbstractSimulationEngine` that drives
  HeatExchange.jl + BiophysicalBehaviour.jl over an `AbstractForcing` time series,
  spanning both single-season snapshots and full **lifecycle** simulations (egg/seed →
  senescent adult)
- **Scope for growth/reproduction** — net assimilation minus maintenance costs, the core
  output of static energy budget approaches. For ectotherms: thermoregulation-constrained
  activity time limits food acquisition; scope for growth is what remains after maintenance.
  For endotherms: the homeothermy cost is itself a maintenance cost subtracted before scope
  for growth is computed. For plants: carbon assimilation minus dark respiration and growth
  respiration; residual drives structural growth
- **Lifecycle state tracking** — abstract `life_stage()` and `advance_lifecycle!()` functions
  on all `AbstractEnergyBudgetModel` and `AbstractPlantGrowthModel` implementations; concrete
  stages (Egg/Seed → Juvenile → Adult → Senescent) defined per model; DEB maturity thresholds
  (E_H_b, E_H_j, E_H_p) implement these naturally; simpler models use mass or thermal-time thresholds
- Digestive and whole-organism MASS BALANCE (food → metabolic water, excretion) —
  distinct from the heat flux physics in HeatExchange.jl
- Abstract interfaces for energy/growth/metabolism models; DEB is the first full lifecycle
  implementation but all interfaces are designed to express lifecycle dynamics; extensibility
  is the primary design goal
- DEB coupling via Julia weakdep `ext/` (DEBtool_J.jl activates extensions automatically)

**Design conventions:**
- **Declarative parameter structs** with `@kwdef` and sensible defaults
- **Expressive field names** (e.g. `wilting_soil_water_potential` not `wilting_point`);
  typical symbols (ψ, Vcmax, μ_max) may appear in internal formulae and docstrings
- **Fractions, not percentages** — all composition/fraction fields are dimensionless 0–1
- **Unitful throughout** — all physical quantities carry SI units via Unitful.jl
- **Type parameters** on structs to allow Unitful and non-Unitful quantities (following
  the `{W, P, T, ...}` pattern in BiophysicalBehaviour.jl)
- **Function dispatch** on struct types rather than conditional branching
- **Naming conventions**: rates → `*_rate`, model constants → `*_parameter`,
  dimensionless ratios → `*_coefficient`
- **Explicit timestep**: `NicheMapper.DEFAULT_DT = 1u"hr"`; all `simulate_*` accept
  a `dt` keyword

**AbstractForcing pipeline (from BiophysicalGrids.jl ectotherm example, generalised):**
MicroclimateMapper produces two `MicroResult <: AbstractForcing` objects at min-shade and
max-shade fractions. `AvailableEnvironments` (BiophysicalBehaviour.jl) wraps them and
interpolates at each `thermoregulate()` call.

```julia
available_environments = AvailableEnvironments(
    micro_0, micro_90, minimum_shade_fraction, maximum_shade_fraction, depths, heights
)
engine = OrganismSimulationEngine(organism, available_environments, limits,
                                   environmental_parameters; energy_budget_model, ...)
previous_depth_node = limits.depth.reference
active_today        = false
for step_index in 1:total_steps
    (step_index - 1) % 24 == 0 && (active_today = false)
    step!(engine, step_index, micro_0, DEFAULT_DT)
    s = state(engine)
    active_today = active_today || s.activity_state isa Active || s.activity_state isa Basking
end
result(engine)   # → OrganismResult
```

**Unified DEB extension pattern (consistent across all packages):**
DEBtool_J.jl owns all DEB types and the ODE solver — `*Mapper` packages provide only
environment adapters. No package reimplements the DEB solver.

DEBtool_J.jl's key types used by extensions:
- `DEBAnimal{M,L,TR}` — model container (`mode`, `lifecycle`, `temperatureresponse`)
- `AbstractLifeStage` — lifecycle nodes: `Embryo`, `Juvenile`, `Adult`, `Instar`, `Pupa`, `Imago`, etc.
- `AbstractTransition` — lifecycle edges: `Birth`, `Puberty`, `Metamorphosis`, `Death`, etc.
- `LifeCycle{S}` — ordered (stage → transition) pairs; queried via `lifecycle(model)`
- `MetabolismBehaviorEnvironment{M,B,E,P}` — bundles model + behavior + environment + params
- `ConstantEnvironment` / `Environment` — holds forcing variables (temperature, food, etc.)
- `d_sim(state, transition, metabolism, mbe, t)` — universal ODE dispatcher, dispatches on lifecycle stage
- `simulate(simulator, mbe)` — drives the ODE via OrdinaryDiffEq; returns SciMLBase.ODESolution
- Temperature correction via `temperature_correction(m::AbstractArrheniusModel, T)` from
  ThermalPhysiology.jl — used by all organisms. DEBtool_J.jl currently has its own
  `tempcorr()` / `AbstractTemperatureResponse` hierarchy but will migrate to use
  ThermalPhysiology.jl; the `SharpSchoolDEBModel` in ThermalPhysiology.jl is the
  DEBtool-normalised Sharpe-Schoolfield equivalent

Each `ext/DEBtoolExt.jl` pattern:
1. Wraps `DEBAnimal` + `LifeCycle` in the package's abstract type (e.g. `DEBEnergyBudget`)
2. At each timestep, builds `ConstantEnvironment` from `AbstractForcing` accessors
3. Calls `simulate(simulator, mbe)` over `dt` horizon → new ODE state
4. Reads lifecycle stage (`lifecycle(model)` + current maturity level) → `life_stage()`
5. Extracts domain-specific quantities (structural mass, LAI, biomass) from ODE state
6. DEB state variables (E, V, E_H, E_R for animals; V_S, C_S, N_S, V_R, C_R, N_R for plants)
   extend each package's `Result` type via a `LifeCycleResult` wrapper

**Shared dependencies across all three packages:**
- `NicheMapper.jl` — `AbstractForcing`, `AbstractEnvironmentSampler`, `AbstractOrganism`,
  `AbstractSimulationEngine`, `AbstractResourceField`, semantic accessors, `DEFAULT_DT`
- `ThermalPhysiology.jl` — `temperature_correction()`, `thermal_performance()`, `q10()`
- `BiologicalScaling.jl` — `allometric()`, `basal_metabolic_rate()` for defaults/priors
- `Unitful.jl` — dimensional analysis throughout
- Weakdep: `DEBtool_J.jl`

---

## Package 1 — AnimalMapper.jl

**Scope:** Simulate animal niches by orchestrating BiophysicalBehaviour.jl thermoregulation
over an `AbstractForcing` time series, and tracking the whole-organism digestive MASS BALANCE
(food composition → metabolic water production, excretion, energy assimilation).
Covers ectotherms and endotherms.

### What AnimalMapper adds vs. existing packages

| Existing package | Handles |
|---|---|
| HeatExchange.jl | Instantaneous body temperature, metabolic heat, respiratory/skin fluxes |
| BiophysicalBehaviour.jl | Microhabitat selection, thermoregulation strategy per hourly step |
| NicheMapper.jl | AbstractForcing accessors, AbstractSimulationEngine contract |
| AnimalMapper.jl | Time-series pipeline; digestive water/energy mass balance; DEB coupling |

### Abstract interfaces

```julia
# Energy assimilation, maintenance, scope for growth, and lifecycle — NOT heat production
abstract type AbstractEnergyBudgetModel end
assimilation_rate(model, food_intake_rate, body_temperature)   → typeof(1.0u"J/s") # required
maintenance_rate(model, body_temperature)                      → typeof(1.0u"J/s") # required
scope_for_growth_rate(model, food_intake_rate, body_temperature) → typeof(1.0u"J/s")
    # = assimilation_rate - maintenance_rate; positive → growth/reproduction possible
    # required; default implementation = assimilation_rate - maintenance_rate
allocate!(model, scope_for_growth_rate, body_temperature, dt)  → EnergyState      # required
structural_mass(model)                                         → typeof(1.0u"kg")  # required
life_stage(model)                                              → AbstractLifeStage # required
advance_lifecycle!(model, scope_for_growth_rate, body_temperature, dt)             # required
    # updates internal state; triggers maturity transitions; no-op for static models

# AbstractLifeStage is DEBtool_J.AbstractLifeStage when DEBtool_J is loaded;
# for non-DEB models, AnimalMapper defines a lightweight fallback:
abstract type AbstractAnimalLifeStage end
struct EggStage <: AbstractAnimalLifeStage end
struct JuvenileStage <: AbstractAnimalLifeStage end
struct AdultStage <: AbstractAnimalLifeStage end
struct SenescentStage <: AbstractAnimalLifeStage end
# DEBtool_J stages (Embryo, Juvenile, Adult, Instar, Pupa, Imago...) are used directly
# by DEBEnergyBudget in ext/DEBtoolExt.jl — no wrapping needed

# Food source — animal-domain specialisation of NicheMapper.AbstractResourceField
# resource_availability() returns food mass rate (u"g/hr"); deplete!() inherited
abstract type AbstractFoodSource <: AbstractResourceField end
food_availability_rate(source, step)  → typeof(1.0u"g/hr")  # required (wraps resource_availability)
food_composition(source, step)        → FoodComposition      # required — macronutrient breakdown

# Digestive water budget — separate from evaporative/respiratory water in HeatExchange.jl
abstract type AbstractDigestiveWaterModel end
digestive_water_fluxes(model, food_intake_rate, composition, dt) → DigestiveWaterFluxes  # required
```

### Key parameter structs (declarative, `@kwdef`)

**`LifeHistoryParameters`** — lifecycle triggers and limits NOT covered by HeatExchange.jl or BiophysicalBehaviour.jl:
```julia
@kwdef struct LifeHistoryParameters{Td, Ta, Mh, Hr, Hd}
    # Photoperiod breeding triggers — co-designed with daylength output from SolarRadiation.jl
    # A general photoperiod_response() function in BiophysicalBehaviour.jl should be shared
    # between animals (breeding) and plants (flowering/germination/senescence)
    breeding_start_photoperiod::Symbol = :winter_solstice  # :none | :summer_solstice |
        # :autumnal_equinox | :winter_solstice | :vernal_equinox | :daylength_threshold
    breeding_end_photoperiod::Symbol   = :summer_solstice
    breeding_start_daylength::Td       = 12.5u"hr"  # used when :daylength_threshold
    breeding_end_daylength::Ta         = 13.0u"hr"
    daylength_increasing_at_start::Bool = true   # trigger on rising (true) or falling (false) daylength
    daylength_increasing_at_end::Bool   = false

    # Dormancy / torpor — metabolic depression during unfavourable periods
    can_be_dormant::Bool = false
    metabolic_depression_factor::Float64 = 1.0   # metabolic rate multiplier during dormancy (1.0 = no depression)
    dormancy_soil_depth_node::Int        = 7     # soil node to retreat to

    # Reproductive parameters
    # clutch size allometry (size = a*SVL + b) handled by BiologicalScaling.jl
    clutch_size::Int = 5
    minimum_clutch_size::Int = 0
    viviparous::Bool = false

    # Mortality — prefer AbstractMortalityModel (see below) over fixed rates;
    # thermal knockdown mortality links to ThermalPhysiology.jl TDT functions
    mortality_model::AbstractMortalityModel = ConstantMortalityModel()
    hatchling_first_year_survivorship::Mh = 0.5    # dimensionless 0–1

    # Hydration safety limits (fraction of wet body mass)
    minimum_hydration_fraction_for_activity::Hr = 0.15  # below this: no foraging
    lethal_dehydration_fraction::Hd             = 0.35  # above this: death
end
```

**`AbstractMortalityModel`** — mortality is a derived function, not a fixed rate:
```julia
abstract type AbstractMortalityModel end
mortality_rate(model, activity_state, body_temperature, dt) → Float64  # instantaneous hazard
# ConstantMortalityModel — fixed active/inactive rates (default, simplest)
# TDTMortalityModel — links to ThermalPhysiology.jl TDT functions: thermal knockdown
#   mortality computed from cumulative dose above critical temperature; accounts for
#   both acute heat death and sub-lethal accumulation during activity
```

**`AbstractFeedingAlgorithm`** — feeding is a behavioural algorithm coupled to `AbstractFoodSource`, not a fixed parameter set. Replaces the previous `StomachParameters`:
```julia
abstract type AbstractFeedingAlgorithm end
food_intake_rate(algorithm, food_source, activity_state, body_temperature, step) → typeof(1.0u"g/hr")
# HollingTypeTwoFeeding — functional response (half-saturation, satiation gut fill)
#   gut fill tracks stomach state; satiation suppresses foraging when gut fill > threshold
#   food_source provides resource_availability(source, step) to determine encounter rate
# (gut fill ODE will be added to DEBtool_J.jl in future — StomachParameters will migrate there)
```

**Starvation / reserve mobilisation** — belongs in DEBtool_J.jl, not AnimalMapper:
Reserve mobilisation mode (`:before_structure`, `:maximize_reserve_density`) and
reproduction buffer use are DEB-specific concepts. Handled in `ext/DEBtoolExt.jl` by
passing configuration to `DEBAnimal`; AnimalMapper does not need to own these parameters.

**`FoodComposition{P,L,C,Fi,W,D}`**
All fractions are dimensionless (0–1), not percentages:
```julia
@kwdef struct FoodComposition{P,L,C,Fi,W,D}
    protein_fraction::P              = 0.56    # fraction of dry mass that is protein
    lipid_fraction::L                = 0.218   # fraction of dry mass that is lipid
    carbohydrate_fraction::C         = 0.1246  # fraction of dry mass that is carbohydrate
    fibre_fraction::Fi               = 0.0828  # fraction of dry mass that is indigestible fibre
    moisture_fraction::W             = 0.82    # fraction of total (wet) mass that is water
    carbohydrate_digestibility::D    = 0.9     # fraction of carbohydrate that is digestible
end
```
Default: lizard prey composition (Andrews & Pough 1985).

**`MetabolicWaterYields`** — Hainsworth (1981) constants, carried as Unitful quantities:
```julia
const PROTEIN_METABOLIC_WATER_YIELD       = 0.40u"g/g"
const LIPID_METABOLIC_WATER_YIELD         = 1.07u"g/g"
const CARBOHYDRATE_METABOLIC_WATER_YIELD  = 0.56u"g/g"
const PROTEIN_ENERGY_DENSITY              = 17_985.0u"J/g"
const LIPID_ENERGY_DENSITY                = 39_339.0u"J/g"
const CARBOHYDRATE_ENERGY_DENSITY         = 17_577.0u"J/g"
const UREA_YIELD_PER_PROTEIN_MASS         = 0.343u"g/g"   # g urea per g protein
const URINE_DENSITY                       = 1.0474u"g/mL"
```

### Built-in simple implementations

**`ScopeForGrowthBudget <: AbstractEnergyBudgetModel`**
Static energy budget approach — the simplest mechanistically meaningful model:
- `assimilation_rate` = food intake rate × assimilation efficiency × energy density of food
- `maintenance_rate` = standard metabolic rate (from `BiologicalScaling.allometric(StandardMetabolicRate(), taxon, mass)`) × temperature correction
- `scope_for_growth_rate` = assimilation - maintenance; accumulated over the simulation to give total energy available for growth/reproduction
- For ectotherms: thermoregulation-constrained activity time (from `thermoregulate()`) already limits food intake; scope for growth reflects this activity limitation automatically
- For endotherms: add homeothermy cost (from HeatExchange.jl endotherm output) to maintenance before computing scope
- `life_stage` — fixed (does not evolve); body mass fixed
- `advance_lifecycle!` — no-op for this static model
- Contrast with DEB: ScopeForGrowthBudget has no reserve dynamics, no maturity transitions, no coupled growth state; it is a one-step budget, not a lifecycle model

**`FixedFoodAvailability <: AbstractFoodSource`**
Constant food availability rate with user-supplied `FoodComposition`.

**`SimpleDigestiveWater <: AbstractDigestiveWaterModel`**
Port of `water_metabolism.R` (Hainsworth 1981). Computes the digestive/excretory water
balance entirely separate from evaporative and respiratory water loss in HeatExchange.jl:
- Metabolic water from substrate oxidation using `PROTEIN/LIPID/CARBOHYDRATE_METABOLIC_WATER_YIELD`
- Free water absorbed from wet food
- Urinary water from urea excretion via `UREA_YIELD_PER_PROTEIN_MASS` and `URINE_DENSITY`
- Faecal water from indigestible fraction and faecal moisture fraction

Returns `DigestiveWaterFluxes`:
```julia
struct DigestiveWaterFluxes{M,F,U,Fa}
    metabolic_water_production_rate::M   # u"g/hr"
    food_free_water_intake_rate::F       # u"g/hr"
    urinary_water_loss_rate::U           # u"g/hr"
    faecal_water_loss_rate::Fa           # u"g/hr"
end
```

### Stage-specific parameter tables

Life-stage-dependent parameters (thermal tolerance, behaviour, water balance, nutrition) are
handled by indexing into per-stage parameter tables. The number and identity of stages is
model-specific (ectotherm lizard has different stages than amphibian with aquatic larva).
Stage tables are stored as `Vector` of named structs (one per lifecycle stage in order).
Field names must align with BiophysicalBehaviour.jl terminology (e.g. CT_min/CT_max,
T_F_min/T_F_max, T_B_min, T_pref — exact names to be confirmed during NicheMapper.jl
co-design with MicroclimateMapper):
```julia
# each stage has a subset of LifeHistoryParameters + BehaviouralLimits overrides
thermal_stages::Vector{ThermalLimitsPerStage}    # CT_min, CT_max, T_F_min, T_F_max, T_B_min, T_pref
behav_stages::Vector{BehaviourPerStage}          # diurnal, nocturnal, fossorial, aquabask, etc. (BiophysicalBehaviour.jl terms)
water_stages::Vector{WaterBalancePerStage}       # skin_resistance, F_O2 (respiratory fraction), gut fill fraction
nutri_stages::Vector{NutritionPerStage}          # food limited flag, assimilation efficiency
```
Stage transitions are triggered by lifecycle events from `life_stage(energy_budget_model)`;
for DEB models these map to `AbstractTransition` events (Birth, Metamorphosis, Puberty...).

### Behavioural decision architecture and future extensions

The current behavioural engine in BiophysicalBehaviour.jl implements thermoregulation as the
primary survival circuit. `AnimalMapper` adds hunger, hydration, and reproductive state as
physiological signals that modulate which microhabitat choice is optimal:
```julia
physiological_priorities(deb_state, life_history_parameters)
    → NamedTuple(hungry, thirsty, reproductive_ready, dormant)
```
These flags are passed to `thermoregulate()` to bias microhabitat selection (e.g. accept
suboptimal temperature when severely dehydrated to seek shade).

**Future extension (AHA model — Giske et al. 2025):**
The AHA (Adaptive Heuristics and Architecture) framework models vertebrate decision-making
as two-step survival-circuit competition: (1) competition between emotional states (hunger,
fear, reproduction, thirst) to determine the dominant global organismic state; (2) imagination-
based wellbeing maximisation using episodic-like memory. This is a candidate future extension
of **BiophysicalBehaviour.jl** (not AnimalMapper), since it replaces the behavioural
decision engine. AnimalMapper accommodates this via the hook:
```julia
abstract type AbstractBehavioralDecisionModel end
# Default: ThermoregulationFirst — current BiophysicalBehaviour.jl thermoregulate()
# Future: AHADecisionModel (in BiophysicalBehaviour.jl ext/) — survival circuit competition
```
The `simulate_organism()` keyword `behavioral_model = ThermoregulationFirst()` allows
swapping in AHA or other decision models without changing the AnimalMapper pipeline.

### Simulation pipeline

**`simulate_organism(micro_0, micro_90, organism, behavioural_limits, environmental_parameters; ...)`**

`micro_0` and `micro_90` are `AbstractForcing` (i.e. `MicroResult` from MicroclimateMapper).

**Note — spatially implicit vs. future agent-based extension:**
The current design is spatially implicit: the organism selects among microhabitats
(shade fractions, depths, heights) represented by interpolated `AbstractForcing` objects,
but has no explicit position in space. Future agent-based models will require explicit
spatial movement — organisms moving through a landscape of heterogeneous `AbstractForcing`
patches. This should be accommodated via an `AbstractSpatialModel` abstraction:
```julia
abstract type AbstractSpatialModel end
# Default: ImplicitSpatialModel — current shade-interpolation approach
# Future: LandscapeAgentModel — explicit grid/patch movement with AnimalMapper as the physiology engine
```
The `behavioral_model` keyword is the extension point; `ThermoregulationFirst()` operates
implicitly while future spatial models inherit from `AbstractSpatialModel`.

Keyword arguments:
- `minimum_shade_fraction = 0.0`, `maximum_shade_fraction = 0.9`
- `energy_budget_model = ScopeForGrowthBudget()`
- `digestive_water_model = SimpleDigestiveWater()`
- `food_source = FixedFoodAvailability()`
- `feeding_algorithm = HollingTypeTwoFeeding()`
- `life_history_parameters = LifeHistoryParameters()`
- `behavioral_model = ThermoregulationFirst()`
- `depths`, `heights` — vectors from MicroResult
- `dt = DEFAULT_DT`

Returns `OrganismResult` via `AbstractSimulationEngine` protocol. At each hourly step:
1. Calls `thermoregulate()` → body temperature, activity state, microhabitat
2. If `Active`: calls `food_availability_rate(food_source, step) × active_fraction` → food intake
3. Calls `digestive_water_fluxes(digestive_water_model, food_intake_rate, composition, dt)`
4. Calls `assimilation_rate(energy_budget_model, food_intake_rate, body_temperature)`
5. Calls `allocate!(energy_budget_model, assimilation_rate, body_temperature, dt)`
6. Accumulates into `OrganismResult`

**`OrganismResult`** — time series of:
`body_temperature`, `shade_fraction`, `soil_depth_node`, `height_above_ground`,
`activity_state` (Resting/Basking/Active), `active_today`, `food_intake_rate`,
`digestive_water_fluxes`, `energy_assimilation_rate`, `energy_state`,
`metabolic_heat_production_rate` (→ HeatExchange.jl input),
`oxygen_consumption_rate`, `co2_production_rate`,
`metabolic_water_production_rate`, `nitrogenous_waste_production_rate`
(last four from DEB model when `ext/DEBtoolExt.jl` is active; from empirical
scaling otherwise), plus the raw `thermoregulation_output` NamedTuple from each step.

### Module structure

```
src/
  AnimalMapper.jl
  EnergyBudget/
    abstract_energy_budget.jl       # AbstractEnergyBudgetModel + required interface
    simple_energy_budget.jl         # SimpleEnergyBudget
  WaterBudget/
    abstract_digestive_water.jl     # AbstractDigestiveWaterModel + required interface
    food_composition.jl             # FoodComposition struct + MetabolicWaterYields constants
    simple_digestive_water.jl       # SimpleDigestiveWater — port of water_metabolism.R
    digestive_water_fluxes.jl       # DigestiveWaterFluxes result struct
  Nutrition/
    abstract_food_source.jl         # AbstractFoodSource + required interface (nutritional geometry: iso221 DEB model)
    abstract_feeding_algorithm.jl   # AbstractFeedingAlgorithm + required interface
    fixed_food_availability.jl      # FixedFoodAvailability
    holling_type2_feeding.jl        # HollingTypeTwoFeeding (functional response + gut fill)
  Simulation/
    organism_result.jl              # OrganismResult, EnergyState
    simulate_organism.jl            # simulate_organism(micro_0, micro_90, organism, ...; dt)
                                    #   OrganismSimulationEngine <: AbstractSimulationEngine

ext/
  DEBtoolExt.jl
    deb_energy_budget.jl            # DEBEnergyBudget <: AbstractEnergyBudgetModel
                                    #   wraps DEBAnimal{M,L,TR} + LifeCycle from DEBtool_J
                                    #   at each step: build ConstantEnvironment from AbstractForcing
                                    #     (temperature via temperature_correction(), food via food_availability_rate)
                                    #   calls simulate(simulator, mbe) over dt → new ODE solution
                                    #   structural_mass(V) = L^3 * d_V → HeatExchange.jl geometry
                                    #   life_stage() reads current AbstractLifeStage from LifeCycle
    deb_food_source.jl              # DEBFoodSource — scaled assimilation flux as food availability
    coupled_organism.jl             # CoupledOrganism: HeatExchangeTraits + behavioural limits
                                    #   + DEBEnergyBudget; structural_mass(V) → geometry update;
                                    #   physiological_priorities(deb_state) → thirst/hunger flags
    coupled_simulation.jl           # simulate_lifecycle(coupled_organism, micro_0, micro_90; dt)
                                    #   hourly: current LifeStage → structural_mass → thermoregulate()
                                    #   → build ConstantEnvironment → simulate(simulator, mbe)
    lifecycle_result.jl             # LifeCycleResult: OrganismResult + DEB state (E, V, E_H, E_R)
                                    #   + current AbstractLifeStage at each timestep
  PlantMapperExt.jl
    vegetation_food_source.jl       # VegetationFoodSource <: AbstractFoodSource
                                    #   bridges PlantMapper.PlantResult → food_availability_rate/composition
                                    #   plant_water_fraction from PlantResult → moisture_fraction in FoodComposition
```

### Dependencies

`NicheMapper.jl`, `HeatExchange.jl`, `BiophysicalBehaviour.jl`, `BiologicalScaling.jl`,
`ThermalPhysiology.jl`, `Unitful.jl`
Weakdeps: `DEBtool_J.jl`, `PlantMapper.jl`

---

## Package 2 — PlantMapper.jl

**Scope:** Simulate plant niches — photosynthesis, stomatal conductance, root water
uptake, and growth — driven by an `AbstractForcing` time series. Leaf temperature solved by
HeatExchange.jl. PAR computed from SolarRadiation.jl spectral output or estimated from
global radiation. Includes simple soil-moisture-driven vegetation model (replacement for
NicheMapR `plantgro.R`) as a built-in `AbstractPlantGrowthModel`.

### What PlantMapper adds vs. existing packages

| Existing package | Handles |
|---|---|
| HeatExchange.jl | Leaf temperature solving, leaf evaporative flux |
| SolarRadiation.jl | Wavelength-resolved irradiance (PAR band 400–700 nm extractable) |
| MicroclimateMapper.jl | `AbstractPlantModel` interface (transpiration!, LAI, root density) |
| NicheMapper.jl | AbstractForcing accessors, AbstractSimulationEngine contract |
| PlantMapper.jl | Photosynthesis, stomata, root uptake, growth, Tleaf/gs coupling |

### PAR derivation

Two pathways — both exposed, user selects:
```julia
# Precise: integrate SolarRadiation.jl spectral output over PAR waveband (400–700 nm)
photosynthetically_active_radiation(solar_result) → typeof(1.0u"W/m^2")

# Approximate: fraction of global radiation (used when SolarRadiation.jl not loaded)
photosynthetically_active_radiation(forcing::AbstractForcing, step;
                                    par_fraction = 0.5) → typeof(1.0u"W/m^2")
    # uses solar_radiation(forcing, step) accessor from NicheMapper
```

### AbstractForcing fields accessed by PlantMapper (via NicheMapper accessors)

```julia
solar_radiation(forcing, step)                     # → global irradiance u"W/m^2"
air_temperature(forcing, step, height_node)        # → Tair at canopy height
wind_speed(forcing, step, height_node)             # → for leaf boundary layer
relative_humidity(forcing, step, height_node)      # → for VPD calculation
vapour_pressure_deficit(forcing, step, height_node)# → u"kPa"
soil_temperature(forcing, step, depth_node)        # → root zone temperature
soil_water_potential(forcing, step, depth_node)    # → soil ψ u"J/kg"
# diffuse_fraction and zenith_angle accessed via MicroclimateMapper-specific extension
# or as additional AbstractForcing accessors co-designed with MicroclimateMapper
```

**Note — spatial integration over canopy height and root depth:**
Canopy processes (photosynthesis, leaf temperature) require profiles integrated over height,
not just a single node value. Root water uptake requires integration over depth weighted by
root density. Accessor helpers to be added:
```julia
canopy_integrated_temperature(forcing, step, height_range)   # → canopy-weighted mean Tair
root_zone_integrated_water_potential(forcing, step, root_density_profile)  # → depth-weighted mean ψ
```
These may be implemented as utility functions in PlantMapper wrapping the NicheMapper
accessors, rather than new AbstractForcing methods — to be confirmed during co-design.

### Abstract interfaces

```julia
abstract type AbstractPhotosynthesisModel end
# net_assimilation_rate (not assimilation_rate) to be unambiguous vs. animal energy budget
net_assimilation_rate(model, par, leaf_temperature, ambient_co2, stomatal_conductance)
    → typeof(1.0u"μmol/m^2/s")   # required

abstract type AbstractStomatalModel end
stomatal_conductance(model, net_assimilation_rate, ambient_co2, vapour_pressure_deficit,
                     leaf_temperature) → typeof(1.0u"mol/m^2/s")   # required

abstract type AbstractRootWaterUptakeModel end
root_water_uptake_rate(model, root_density_profile, soil_water_potential, soil_temperature)
    → typeof(1.0u"kg/s")   # required — total uptake across all nodes

# Plant architecture — root density and canopy geometry mapped to microclimate node grid
# Lives in PlantMapper.jl (not BiophysicalGeometry.jl / BiologicalScaling.jl)
abstract type AbstractPlantArchitecture end
root_density_profile(arch::AbstractPlantArchitecture, depth_nodes) → Vector{Float64}
    # dimensionless weights summing to 1 — maps architecture to microclimate soil node grid
canopy_height(arch::AbstractPlantArchitecture) → typeof(1.0u"m")
leaf_area_index(arch::AbstractPlantArchitecture) → Float64

# SimplePlantArchitecture — exponential root density profile + fixed canopy height
# covers the WaterLimitedVegetation case; replaces bare shallow_root_node/deep_root_node
@kwdef struct SimplePlantArchitecture{H, R}
    canopy_height::H              = 0.5u"m"
    maximum_rooting_depth::R      = 1.0u"m"
    root_density_decay_coefficient::Float64 = 2.0  # exponential decay with depth
    maximum_leaf_area_index::Float64        = 3.0
end
# Future: MTGPlantArchitecture wrapping PlantSimEngine.jl MTG for full FSPM structure

# Refines AbstractPlantModel from MicroclimateMapper — adds growth state
abstract type AbstractPlantGrowthModel <: AbstractPlantModel end
advance_plant_state!(model, dt, net_assimilation_rate, soil_temperature, water_uptake_rate)
root_density_profile(model) → Vector{<:Quantity}   # required — one value per soil depth node
canopy_leaf_area_index(model) → Float64             # required (dimensionless)
# plant lifecycle stages for non-DEB models (lightweight fallback):
abstract type AbstractPlantLifeStage end
struct SeedStage <: AbstractPlantLifeStage end; struct SeedlingStage <: AbstractPlantLifeStage end
struct JuvenilePlantStage <: AbstractPlantLifeStage end; struct AdultPlantStage <: AbstractPlantLifeStage end
# DEBPlantModel (ext/DEBtoolExt.jl) uses DEBtool_J lifecycle directly:
#   Embryo(Seed) → Birth(Germination) → Juvenile(Seedling) → Puberty(Reproduction) → Adult → Ultimate
```

### VirtualPlantLab integration

Four packages are available at c:/git/ from the VirtualPlantLab ecosystem:

| Package | Relevant content | Integration strategy |
|---|---|---|
| **Ecophys.jl** | FvCB C3/C4 photosynthesis, Ball-Berry stomata, leaf energy balance, Unitful versions | **Primary leaf physiology dep** — bridge via `EcophysExt.jl` wrapping Ecophys models into `AbstractPhotosynthesisModel` / `AbstractStomatalModel` interfaces |
| **PlantSimEngine.jl** | Modular process framework, Multi-Scale Tree Graph (MTG) for plant architecture | Weakdep for future FSPM extensions; MTG can represent canopy layers and root distribution |
| **PlantGraphs.jl** | L-systems / graph rewriting for dynamic structural plant models | Weakdep for future full structural plant models (beyond current scope) |
| **SkyDomes.jl** | Sky dome discretization, clear/cloudy sky models, PAR/NIR waveband conversion | Weakdep alongside SolarRadiation.jl for 3D canopy radiation interception |

**Ecophys.jl note:** `C3()` / `C3Q()` implement the full Yin & Struik FvCB framework with
Arrhenius and peaked temperature responses. `solve_energy_balance()` couples photosynthesis
with leaf temperature — this partially overlaps with the FixedPointSolver plan. The
`EcophysExt.jl` bridge should wrap Ecophys models to implement PlantMapper's abstract
interfaces, so users who load Ecophys get the full FvCB model, and those who don't get
the simple built-ins below.

### Built-in implementations (used when Ecophys.jl not loaded)

**`FarquharBerryPhotosynthesis <: AbstractPhotosynthesisModel`**
Simplified FvCB for use without Ecophys.jl — Rubisco-limited (`A_c`) and
electron-transport-limited (`A_j`) rates; temperature correction via ThermalPhysiology.jl:

```julia
@kwdef struct FarquharBerryPhotosynthesis{Vc, Je, Rd, Γ, Km}
    maximum_carboxylation_rate_at_reference::Vc  = 80.0u"μmol/m^2/s"
    maximum_electron_transport_rate_at_reference::Je = 160.0u"μmol/m^2/s"
    dark_respiration_rate_at_reference::Rd       = 1.5u"μmol/m^2/s"
    co2_compensation_point::Γ                    = 42.0u"μmol/mol"
    michaelis_constant_co2::Km                   = 404.9u"μmol/mol"
    # oxygen_partial_pressure is specified within HeatExchange.jl atmosphere parameters
    vcmax_arrhenius_model::ArrheniusModel         = arrhenius(T_A=58_520.0u"J/mol")
    jmax_sharpe_schoolfield_model::SharpSchoolHighModel = sharpe_schoolfield(...)
end
```

**`RectangularHyperbolePhotosynthesis <: AbstractPhotosynthesisModel`**
`A_net = (A_max × PAR) / (half_saturation_par_parameter + PAR) - dark_respiration_rate`
Temperature correction via `ThermalPhysiology.q10(model, leaf_temperature)`.

**`BallBerryStomatalConductance <: AbstractStomatalModel`**
`g_s = minimum_conductance + slope_coefficient × (A_net × relative_humidity / ambient_co2)`
(Ecophys.jl provides the full parameterisation; this is the lightweight built-in version.)

**`MedlynStomatalConductance <: AbstractStomatalModel`**
`g_s = minimum_conductance + (1 + marginal_water_cost_coefficient / √vpd) × (A_net / ambient_co2)`
Optimal stomatal theory (Medlyn et al. 2011); `vpd` in `u"kPa"`. Not in Ecophys.jl — PlantMapper owns this.

**`ProportionalRootWaterUptake <: AbstractRootWaterUptakeModel`**
Uptake at each node ∝ `root_density_profile[node] × (soil_water_potential[node] - leaf_water_potential)`.
Soil ψ obtained via `soil_water_potential(forcing, step, node)` accessor.

**`LogisticVegetationGrowth <: AbstractPlantGrowthModel`**
Logistic LAI growth driven by net assimilation with temperature correction.
Fixed exponential root density profile; ThermalPhysiology correction on growth rate.

**`PlantLifeHistoryParameters`** — lifecycle triggers for plants, analogous to `LifeHistoryParameters` for animals:
```julia
@kwdef struct PlantLifeHistoryParameters{Td, Tf, Tv, Ts}
    # Germination triggers
    germination_start_photoperiod::Symbol = :none  # :none | :vernal_equinox | :daylength_threshold
    germination_daylength_threshold::Td   = 10.0u"hr"
    germination_soil_temperature_minimum::Tv = 5.0u"°C"
    germination_soil_water_potential_minimum::Ts = -500.0u"J/kg"

    # Flowering / reproduction triggers
    # Photoperiod responses (long-day, short-day, day-neutral) should use a shared
    # photoperiod_response() function from BiophysicalBehaviour.jl — used by animals
    # and plants alike (e.g. breeding season triggers for animals, flowering for plants)
    flowering_start_photoperiod::Symbol = :summer_solstice
    flowering_daylength_threshold::Tf   = 14.0u"hr"
    daylength_increasing_at_flowering::Bool = true  # long-day vs short-day plant

    # Senescence / dormancy triggers
    senescence_start_photoperiod::Symbol = :autumnal_equinox
    senescence_daylength_threshold::Td   = 10.0u"hr"

    # Seed dormancy / diapause — links to insect diapause and ThermalPhysiology.jl dosage
    # machinery (chill/heat accumulation to break dormancy, analogous to TDT for knockdown)
    seed_dormancy_period::typeof(1u"d") = 30u"d"   # minimum cold/dry period before germination
    # Future: DormancyDosageModel using ThermalPhysiology.jl thermal accumulation functions
end
```
Plant lifecycle: Seed (dormant) → Germination trigger → Seedling → Flowering trigger → Adult
→ Senescence trigger → Senescent. DEB plant model (`DEBPlantModel`) maps these to DEBtool_J
lifecycle events (Embryo→Birth→Juvenile→Puberty→Adult→Ultimate).

**`WaterLimitedVegetation <: AbstractPlantGrowthModel`**
Simple soil-moisture-driven vegetation model — replacement for NicheMapR `plantgro.R`,
improved in structure. Requires only soil fields from `AbstractForcing`; no photosynthesis.
Used as a food source for animals via AnimalMapper's `PlantMapperExt.jl`.

```julia
@kwdef struct WaterLimitedVegetation{Ww, Wp, Tg, R, F, Arch}
    wilting_soil_water_potential::Ww              = -200.0u"J/kg"
    permanent_wilting_soil_water_potential::Wp    = -1500.0u"J/kg"
    minimum_growth_temperature::Tg                = 15.0u"°C"
    recovery_delay_after_desiccation::R           = 1u"d"
    maximum_plant_water_fraction::F               = 0.82       # dimensionless, 0–1
    architecture::Arch                            = SimplePlantArchitecture()
    # Plant architecture (root density profile with depth, canopy geometry) is specified
    # via a plant architecture struct rather than bare node indices. This will be developed
    # in coordination with BiophysicalGeometry.jl and BiologicalScaling.jl.
    # MicroclimateMapper needs root density with depth — architecture struct provides this.
    # shallow_root_node / deep_root_node become architecture properties, not bare Int fields.
end
```

Key computed quantities (all Unitful where physical):
- `plant_present(vegetation, mean_soil_water_potential)` → `Bool`
  True when ψ_soil > `permanent_wilting_soil_water_potential` AND recovery delay elapsed.
- `plant_water_fraction(vegetation, mean_soil_water_potential)` → dimensionless
  Linear interpolation: `maximum_plant_water_fraction` above wilting point, 0 at/below
  permanent wilting point. Provides `moisture_fraction` to `FoodComposition` in AnimalMapper.
- `accumulated_thermal_time(vegetation, plant_temperature, mean_soil_water_potential)` → `u"K*d"`
  Growing degree-hours above `minimum_growth_temperature`, accumulated only while plant is
  present and ψ_soil > `wilting_soil_water_potential`. Proxy for relative plant biomass.
  Based on ThermalPhysiology.jl thermal accumulation functions (degree-day / thermal-time
  machinery); implementation should call into ThermalPhysiology.jl rather than reimplementing.
- `mean_root_zone_conditions(vegetation, forcing, step)` → (mean ψ, mean moisture)
  Averages `soil_water_potential(forcing, step, node)` over the root depth range defined
  by `vegetation.architecture`.

`WaterLimitedVegetation` implements `AbstractPlantGrowthModel`:
- `root_density_profile` — uniform over `shallow_root_node:deep_root_node`
- `canopy_leaf_area_index` — proportional to accumulated thermal time (saturates at max)
- `advance_plant_state!` — updates accumulated_thermal_time and presence flag
- `transpiration!` — simplified: proportional to LAI × VPD × plant_water_fraction

### Leaf temperature / stomatal conductance coupling

Tleaf and gs are mutually dependent — `stomatal_coupling.jl` iterates using a fixed-point
solver with shared convergence policy:
```julia
@kwdef struct FixedPointSolver
    convergence_tolerance::typeof(1.0u"K") = 0.01u"K"
    maximum_iterations::Int                = 50
    relaxation_coefficient::Float64        = 0.5   # damping to aid convergence
end

# Iteration:
# initialise: leaf_temperature = air_temperature(forcing, step, height_node)
# repeat until Δleaf_temperature < convergence_tolerance (or maximum_iterations):
#   g_s          = stomatal_conductance(stomatal_model, A_net, co2, vpd, leaf_temperature)
#   leaf_temperature = solve_temperature(leaf_organism, env_vars_with_gs, env_pars)  # HeatExchange.jl
#   A_net        = net_assimilation_rate(photo_model, par, leaf_temperature, co2, g_s)
#   leaf_temperature = (1 - relaxation_coefficient) × prev + relaxation_coefficient × new
```

### Simulation pipeline

**`simulate_plant(forcing, plant_growth_model; ...)`**

`forcing::AbstractForcing` (MicroResult from MicroclimateMapper).

Keyword arguments:
- `photosynthesis_model = FarquharBerryPhotosynthesis()`
- `stomatal_model = MedlynStomatalConductance()`
- `root_uptake_model = ProportionalRootWaterUptake()`
- `solver = FixedPointSolver()`
- `height_node = 2`, `par_source = :spectrum | :global`
- `dt = DEFAULT_DT`

Returns `PlantResult` via `AbstractSimulationEngine` protocol.

**`PlantResult`** — time series of:
`canopy_leaf_area_index`, `stomatal_conductance`, `leaf_temperature`, `net_assimilation_rate`,
`dark_respiration_rate`, `root_water_uptake_rate`, `transpiration_rate`,
`accumulated_thermal_time`, `plant_water_fraction`.

### Module structure

```
src/
  PlantMapper.jl
  AbstractTypes/
    abstract_plant_growth.jl         # AbstractPlantGrowthModel (refines AbstractPlantModel)
    abstract_photosynthesis.jl       # AbstractPhotosynthesisModel
    abstract_stomatal_conductance.jl # AbstractStomatalModel
    abstract_root_water_uptake.jl    # AbstractRootWaterUptakeModel
    abstract_plant_architecture.jl   # AbstractPlantArchitecture + required interface
                                     #   root_density_profile(arch, depth_nodes)
                                     #   canopy_height(arch), leaf_area_index(arch)
  Architecture/
    simple_plant_architecture.jl     # SimplePlantArchitecture — exponential root decay + fixed canopy
                                     #   maps to microclimate depth nodes; replaces bare node Int fields
                                     #   root_density_profile weights sum to 1 over depth_nodes vector
  Radiation/
    par_from_spectrum.jl             # photosynthetically_active_radiation(solar_result)
                                     # photosynthetically_active_radiation(forcing, step; par_fraction)
  Photosynthesis/
    farquhar_berry.jl                # FarquharBerryPhotosynthesis (built-in; Ecophys.jl preferred)
    rectangular_hyperbola.jl         # RectangularHyperbolePhotosynthesis
  Stomata/
    ball_berry.jl                    # BallBerryStomatalConductance (built-in; Ecophys.jl preferred)
    medlyn.jl                        # MedlynStomatalConductance (PlantMapper-owned; not in Ecophys.jl)
    fixed_point_solver.jl            # FixedPointSolver + stomatal coupling iteration
  Roots/
    proportional_uptake.jl           # ProportionalRootWaterUptake
  Growth/
    logistic_vegetation.jl           # LogisticVegetationGrowth
    water_limited_vegetation.jl      # WaterLimitedVegetation — replacement for plantgro.R
  Simulation/
    plant_result.jl                  # PlantResult
    simulate_plant.jl                # simulate_plant(forcing, plant_growth_model; dt, ...)
                                     # PlantSimulationEngine <: AbstractSimulationEngine
                                     # Implements AbstractPlantModel for MicroclimateMapper:
                                     #   transpiration!, canopy_albedo, canopy_leaf_area_index,
                                     #   root_density_profile(arch, depth_nodes)

ext/
  DEBtoolExt.jl
    deb_plant_model.jl               # DEBPlantModel <: AbstractPlantGrowthModel
                                     #   wraps DEBtool_J plant_model() — DEBAnimal{Plant,L,TR}
                                     #   6D state: (V_S, C_S, N_S, V_R, C_R, N_R)
                                     #     V_S/V_R = shoot/root volume; C/N = carbon/nitrogen reserves
                                     #   root_density_profile derived from V_R structural root volume
                                     #   canopy_leaf_area_index derived from V_S structural shoot volume
                                     #   lifecycle: Seed(Embryo) → Germination(Birth) →
                                     #     Seedling(Juvenile) → Reproduction(Puberty) → Adult → Ultimate
    deb_plant_result.jl              # Extends PlantResult with DEBState (V_S, C_S, N_S, V_R, C_R, N_R)
                                     #   + current lifecycle stage at each timestep
  EcophysExt.jl                      # activated when `using PlantMapper, Ecophys`
    ecophys_photosynthesis.jl        # EcophysC3Photosynthesis <: AbstractPhotosynthesisModel
                                     #   wraps Ecophys.jl C3Q() model (Unitful version)
                                     #   passes PAR, Tleaf, CO2 → returns A_net in u"μmol/m^2/s"
    ecophys_stomata.jl               # EcophysBallBerry <: AbstractStomatalModel
                                     #   wraps Ecophys.jl Ball-Berry stomata (embedded in C3Q)
    ecophys_energy_balance.jl        # Bridges Ecophys.jl solve_energy_balance() to FixedPointSolver
                                     #   (Ecophys couples Tleaf↔gs internally; bridge allows
                                     #   PlantMapper to use it while keeping the FixedPointSolver API)
  SolarRadiationExt.jl
    par_spectrum.jl                  # photosynthetically_active_radiation(solar_result)
                                     #   integrates SolarRadiation.jl spectrum over 400–700 nm
  SkyDomesExt.jl                     # activated when `using PlantMapper, SkyDomes`
    sky_dome_radiation.jl            # SkyDomePARInterception <: AbstractPhotosynthesisModel preamble
                                     #   uses SkyDomes.jl sky() for 3D canopy radiation interception
                                     #   (beyond current scope; hook for future ray-tracing integration)
  PlantSimEngineExt.jl               # activated when `using PlantMapper, PlantSimEngine`
    mtg_architecture.jl              # MTGPlantArchitecture <: AbstractPlantArchitecture
                                     #   wraps PlantSimEngine.jl MTG (Multi-Scale Tree Graph)
                                     #   for full FSPM structural plant representation
                                     #   root_density_profile ← MTG root node volumes per soil node
  PlantGraphsExt.jl                  # activated when `using PlantMapper, PlantGraphs`
    graph_plant_model.jl             # Future: graph-rewriting for dynamic structural development
  BiophysicalBehaviourExt.jl
    stomatal_optimisation.jl         # Optimal stomatal conductance as constrained carbon gain
                                     #   maximisation — analogous to ectotherm microhabitat selection
```

### Dependencies

`NicheMapper.jl`, `HeatExchange.jl`, `ThermalPhysiology.jl`, `BiologicalScaling.jl`
(leaf morphology), `FluidProperties.jl`, `Unitful.jl`
Interface: implements `AbstractPlantModel` from MicroclimateMapper; consumes `AbstractForcing`
Weakdeps: `DEBtool_J.jl`, `SolarRadiation.jl`, `BiophysicalBehaviour.jl`,
`Ecophys.jl` (FvCB + Ball-Berry + energy balance), `SkyDomes.jl` (sky dome radiation),
`PlantSimEngine.jl` (MTG plant architecture), `PlantGraphs.jl` (structural FSPM)

---

## Package 3 — MicrobeMapper.jl

**Scope:** Population-level simulation of soil microbes growing as a function of soil
temperature and water potential from `AbstractForcing`. No individual heat budget —
HeatExchange.jl is not needed. Substrate can come from constant input, plant litter
(PlantMapper extension), or animal excretion (AnimalMapper extension).

### AbstractForcing fields accessed by MicrobeMapper (via NicheMapper accessors)

```julia
soil_temperature(forcing, step, depth_node)      # → u"°C" per node for thermal performance
soil_water_potential(forcing, step, depth_node)  # → u"J/kg" per node for moisture modifier
```

### Abstract interfaces

```julia
abstract type AbstractMicrobialGrowthModel end
net_growth_rate(model, substrate_concentration, thermal_performance_factor,
                moisture_availability_factor) → typeof(1.0u"hr^-1")   # required
maintenance_rate(model, thermal_performance_factor) → typeof(1.0u"hr^-1")  # required
biomass_yield_coefficient(model) → Float64  # dimensionless: g biomass per g substrate

# Substrate model — microbe-domain specialisation of NicheMapper.AbstractResourceField
# resource_availability() returns concentration (u"g/m^3"); deplete!() inherited
abstract type AbstractSubstrateModel <: AbstractResourceField end
substrate_concentration(model, step) → typeof(1.0u"g/m^3")   # required (wraps resource_availability)

abstract type AbstractMoistureAvailabilityModel end
moisture_availability_factor(model, soil_water_potential) → Float64   # 0–1; required
```

### Key parameter structs (declarative, `@kwdef`)

**`MonodGrowthModel <: AbstractMicrobialGrowthModel`**
`μ_net = μ_max × S / (K_s + S) × f_T × f_ψ - m × f_T`

```julia
@kwdef struct MonodGrowthModel{R, H, B, M, T}
    maximum_specific_growth_rate::R  = 0.5u"hr^-1"
    half_saturation_substrate_parameter::H = 10.0u"g/m^3"
    biomass_yield_coefficient::B     = 0.5          # dimensionless
    maintenance_rate_coefficient::M  = 0.01u"hr^-1"
    thermal_performance_model::T     = utpc()        # ThermalPhysiology.jl UniversalTPCModel
end
```

**`LogisticMicrobialGrowth <: AbstractMicrobialGrowthModel`**
`dN/dt = r × N × (1 - N/K) × f_T × f_ψ`

```julia
@kwdef struct LogisticMicrobialGrowth{R, K, T}
    intrinsic_growth_rate::R         = 0.1u"hr^-1"
    carrying_capacity::K             = 1000.0u"g/m^3"
    thermal_performance_model::T     = utpc()
end
```

**`ConstantSubstrateSupply <: AbstractSubstrateModel`**
Fixed substrate concentration — for parameter fitting or simple scenarios.

**`LitterDecompositionSubstrate <: AbstractSubstrateModel`**
Substrate pool depleted by microbial consumption; recharged at constant litter input rate:
```julia
@kwdef struct LitterDecompositionSubstrate{C, I}
    initial_substrate_concentration::C = 500.0u"g/m^3"
    litter_input_rate::I               = 1.0u"g/m^3/d"
end
```

**`CampbellMoistureAvailability <: AbstractMoistureAvailabilityModel`**
`f_ψ = clamp((ψ - ψ_threshold) / (0 - ψ_threshold), 0, 1)`:
```julia
@kwdef struct CampbellMoistureAvailability{W}
    water_potential_threshold::W = -1500.0u"J/kg"
end
```

**`VanGenuchtenMoistureAvailability <: AbstractMoistureAvailabilityModel`**
`f_ψ = [1 + (α |ψ|)^n]^(-(1 - 1/n))` (van Genuchten 1980); `α` in `u"kg/J"`:
```julia
@kwdef struct VanGenuchtenMoistureAvailability{A, N}
    scaling_parameter::A   = 0.1u"kg/J"
    shape_parameter::N     = 1.5
end
```

### Simulation pipeline

**`simulate_microbial_population(forcing, growth_model; ...)`**

`forcing::AbstractForcing`.

Keyword arguments:
- `substrate_model = ConstantSubstrateSupply()`
- `moisture_model = CampbellMoistureAvailability()`
- `active_soil_nodes = 1:4`
- `dt = DEFAULT_DT`

Returns `MicrobeResult` via `AbstractSimulationEngine` protocol.

**`MicrobeResult`** — per-node time series of:
`microbial_biomass`, `substrate_concentration`, `co2_production_rate`,
`thermal_performance_factor`, `moisture_availability_factor`.

### Module structure

```
src/
  MicrobeMapper.jl
  AbstractTypes/
    abstract_microbial_growth.jl       # AbstractMicrobialGrowthModel + required interface
    abstract_substrate.jl              # AbstractSubstrateModel + required interface
    abstract_moisture_availability.jl  # AbstractMoistureAvailabilityModel + required interface
  GrowthModels/
    monod_growth.jl                    # MonodGrowthModel
    logistic_growth.jl                 # LogisticMicrobialGrowth
  SubstrateModels/
    constant_substrate.jl              # ConstantSubstrateSupply
    litter_decomposition.jl            # LitterDecompositionSubstrate
  MoistureAvailability/
    campbell_moisture.jl               # CampbellMoistureAvailability
    van_genuchten_moisture.jl          # VanGenuchtenMoistureAvailability
  Simulation/
    microbe_result.jl                  # MicrobeResult
    simulate_microbial_population.jl   # simulate_microbial_population(forcing, growth_model; dt, ...)
                                       # MicrobialSimulationEngine <: AbstractSimulationEngine

ext/
  DEBtoolExt.jl
    deb_microbe_model.jl               # DEBMicrobeModel <: AbstractMicrobialGrowthModel (future)
                                       #   port of DEBtool_M/microbe flux-balance functions to Julia
                                       #   state: (X=substrate, V=structure, E=reserve, P=product)
                                       #   growth rate r solved via flux-balance (not maturity threshold)
                                       #   cell division at M_Vd instead of puberty transition
                                       #   supports chemostat / batch / fed-batch reactor dynamics
                                       #   temperature via temperature_correction(model.temperatureresponse, T_soil)
  PlantMapperExt.jl
    plant_litter_substrate.jl          # PlantLitterSubstrate <: AbstractSubstrateModel
                                       #   litter_input_rate from PlantMapper.PlantResult
  AnimalMapperExt.jl
    animal_excretion_substrate.jl      # AnimalExcretionSubstrate <: AbstractSubstrateModel
                                       #   substrate from AnimalMapper.OrganismResult excretion
```

### Dependencies

`NicheMapper.jl`, `ThermalPhysiology.jl`, `Unitful.jl`
No HeatExchange.jl, no BiophysicalBehaviour.jl, no BiologicalScaling.jl —
population-level; thermal response solely from ThermalPhysiology.jl TPCs.
Weakdeps: `DEBtool_J.jl`, `PlantMapper.jl`, `AnimalMapper.jl`

---

## Shared patterns summary

### ThermalPhysiology.jl usage

| Package | Use case | Call |
|---|---|---|
| AnimalMapper | Q10 on assimilation rate | `temperature_correction(model, body_temperature)` |
| AnimalMapper | Activity knockdown risk | `survival_time(tdt_model, body_temperature)` |
| PlantMapper | Vcmax/Jmax temperature response | `temperature_correction(arrhenius_model, leaf_temperature)` |
| PlantMapper | Dark respiration rate | `temperature_correction(q10_model, leaf_temperature)` |
| MicrobeMapper | μ_max thermal modifier | `thermal_performance(utpc_model, soil_temperature)` |
| All | Fluctuating-T equivalent | `constant_temperature_equivalent(model, temperature_series)` |

### BiologicalScaling.jl usage

| Package | Use case | Call |
|---|---|---|
| AnimalMapper | Default assimilation priors by taxon | `allometric(StandardMetabolicRate(), taxon, mass)` |
| PlantMapper | Leaf area from dimensions | `allometric(LeafArea(), C3Plant(), (length, width))` |
| MicrobeMapper | Not used | — |

### DEBtool_J extension pattern (consistent across all packages)

Each package's `ext/DEBtoolExt.jl`:
1. Provides a `deb_inputs()` adapter converting package-specific state → `DEBInputs`
2. Calls `DEBStep!(deb_state::DEBState, inputs::DEBInputs, dt)` — owned by DEBtool_J.jl
3. Reads `DEBState` to update package-specific quantities (structural mass, priorities, etc.)
4. Extends the package's `Result` type with `DEBState` fields (E, V, E_H, E_R)
5. AnimalMapper only: `structural_mass(deb_state.structure)` → HeatExchange.jl geometry

The DEB solver is never reimplemented; packages are pure adapters.

---

## Immediate next step: NicheMapper.jl stub repo

Create `c:/git/NicheMapper.jl/` as the initial GitHub repo. No code required initially —
the repo is the architecture hub and coordination space for all collaborators.

**Files to create:**

```
NicheMapper.jl/
├── Project.toml                          # package name, UUID, julia compat, no deps yet
├── README.md                             # brief description + link to architecture doc
├── LICENSE                               # MIT
├── docs/
│   └── architecture/
│       └── mechanistic_niche_modelling_framework.md   # this plan document
├── src/
│   └── NicheMapper.jl                    # stub module with abstract interface stubs
└── .github/
    └── ISSUE_TEMPLATE/
        └── design_question.md            # template for architecture discussion issues
```

**`src/NicheMapper.jl` stub** (abstract interfaces only — no implementations):
```julia
module NicheMapper

using Unitful

export AbstractForcing, AbstractEnvironmentSampler, AbstractOrganism
export AbstractSimulationEngine, AbstractResourceField
export air_temperature, soil_temperature, solar_radiation, wind_speed
export relative_humidity, soil_water_potential, vapour_pressure_deficit
export step!, state, result, resource_availability, deplete!

const DEFAULT_DT = 1u"hr"

# ── Layer A: Forcing contracts ─────────────────────────────────────────────────
abstract type AbstractForcing end
struct Air end; struct Soil end

air_temperature(f::AbstractForcing, step, height_node)          = error("not implemented")
soil_temperature(f::AbstractForcing, step, depth_node)          = error("not implemented")
solar_radiation(f::AbstractForcing, step)                       = error("not implemented")
wind_speed(f::AbstractForcing, step, height_node)               = error("not implemented")
relative_humidity(f::AbstractForcing, step, height_node)        = error("not implemented")
soil_water_potential(f::AbstractForcing, step, depth_node)      = error("not implemented")
vapour_pressure_deficit(f::AbstractForcing, step, height_node)  = error("not implemented")

abstract type AbstractEnvironmentSampler end
sample(s::AbstractEnvironmentSampler, shade_fraction, step) = error("not implemented")

# ── Layer B: Simulation contracts ─────────────────────────────────────────────
abstract type AbstractOrganism end

abstract type AbstractSimulationEngine end
step!(e::AbstractSimulationEngine, step_index::Int, forcing::AbstractForcing, dt) = error("not implemented")
state(e::AbstractSimulationEngine)  = error("not implemented")
result(e::AbstractSimulationEngine) = error("not implemented")

abstract type AbstractResourceField end
resource_availability(f::AbstractResourceField, step)           = error("not implemented")
deplete!(f::AbstractResourceField, consumed, step, dt)          = error("not implemented")

end
```

**After creating the stub:** push to GitHub under `github.com/BiophysicalEcology/NicheMapper.jl`
so we can collaboratively comment, open Issues, and suggest edits via PRs.

---

## Build order

1. **NicheMapper.jl** — `AbstractForcing` + accessors + `AbstractSimulationEngine` contract;
   co-design accessor signatures with MicroclimateMapper.
2. **AnimalMapper.jl** — most direct port; `simulate_organism()` formalises the
   BiophysicalGrids ectotherm loop with digestive water budget added.
3. **PlantMapper.jl** — `WaterLimitedVegetation` first (validates plantgro.R port, no
   photosynthesis needed); then FarquharBerry + Medlyn + FixedPointSolver coupling.
4. **MicrobeMapper.jl** — fewest dependencies; Monod + CampbellMoistureAvailability first.
5. **AnimalMapper `PlantMapperExt.jl`** — `VegetationFoodSource` bridging WaterLimitedVegetation
   to AnimalMapper food source interface; validates plant-animal food chain.
6. **DEBtool_J extensions** — once DEBtool_J.jl stabilises beyond v0.1.0.
7. **Remaining cross-package extensions** — PlantLitterSubstrate, AnimalExcretionSubstrate.

---

## Verification

**NicheMapper.jl:**
1. MicroclimateMapper `MicroResult` implements all `AbstractForcing` accessors — spot-check
   `soil_water_potential(result, 1, 4)` returns correct units and value vs. direct field access
2. `OrganismSimulationEngine`, `PlantSimulationEngine`, `MicrobialSimulationEngine` all
   satisfy `AbstractSimulationEngine` — call `step!`, `state`, `result` on each

**AnimalMapper:**
1. `SimpleDigestiveWater` outputs match `water_metabolism.R` for identical inputs — verify
   `metabolic_water_production_rate`, `urinary_water_loss_rate`, `faecal_water_loss_rate` in `u"g/hr"`
2. `simulate_organism()` for a 20 g lizard with TerraClimate forcing at Madison WI matches
   NicheMapR `ectotherm()` body temperature and activity time series
3. `OrganismResult.activity_state` distribution (Resting/Basking/Active fractions) matches NicheMapR

**PlantMapper:**
1. `WaterLimitedVegetation` outputs match `plantgro.R` for identical soil ψ inputs:
   verify `plant_water_fraction`, `plant_present`, `accumulated_thermal_time`
2. `FarquharBerryPhotosynthesis` net_assimilation_rate vs. PAR at 25°C matches published FvCB benchmarks
3. `FixedPointSolver` converges within 10 iterations under typical summer conditions
4. `maximum_carboxylation_rate(model, leaf_temperature)` peaks at ~25°C for C3 species

**MicrobeMapper:**
1. `MonodGrowthModel` at constant temperature and substrate matches analytical Monod solution
2. `thermal_performance(utpc_model, T_soil)` peaks at T_opt, reaches 0 at CTmax
3. Seasonal biomass driven by soil temperature shows expected Q10 amplification
4. `CampbellMoistureAvailability` output matches tabulated values from Campbell (1974)

---

## TODOs in other packages (triggered by this design)

Items identified during this planning that belong in packages outside the *Mapper ecosystem:

**BiologicalScaling.jl:**
- Add clutch size allometry: `allometric(ClutchSize(), taxon, svl)` — removed from `LifeHistoryParameters` because clutch size scales with body size (SVL or mass); should live alongside other allometric relationships
- Confirm or add `allometric(LeafArea(), C3Plant(), (length, width))` — used by PlantMapper

**BiophysicalBehaviour.jl:**
- Add `photoperiod_response(daylength, trigger_type, threshold; increasing)` — shared between animals (breeding triggers) and plants (flowering/germination/senescence triggers); avoids duplicating daylength logic in each *Mapper package
- Add `AbstractBehavioralDecisionModel` + `ThermoregulationFirst()` hook (noted in AnimalMapper plan) — future AHA model extension point

**ThermalPhysiology.jl:**
- Confirm thermal-time / degree-day accumulation functions exist (used by `accumulated_thermal_time` in `WaterLimitedVegetation`)
- Confirm chill/heat dosage functions for dormancy breaking exist (seed dormancy / insect diapause link)
- Confirm `survival_time(tdt_model, body_temperature)` exists for `TDTMortalityModel` in AnimalMapper

**HeatExchange.jl:**
- Confirm `oxygen_partial_pressure` is accessible as part of the atmosphere parameters (removed from `FarquharBerryPhotosynthesis` on this basis)

**BiologicalScaling.jl:**
- Confirm or add leaf allometry: `allometric(LeafArea(), C3Plant(), (length, width))` — used by PlantMapper

**DEBtool_J.jl:**
- Starvation / reserve mobilisation parameters (`:before_structure`, `:maximize_reserve_density`) — removed from AnimalMapper, should be configurable on `DEBAnimal` directly
- Gut fill ODE (future) — `HollingTypeTwoFeeding` in AnimalMapper will eventually delegate stomach state to DEBtool_J stomach model when implemented
- Confirm `plant_model()` 6D state (V_S, C_S, N_S, V_R, C_R, N_R) is stable for PlantMapper DEBtoolExt

**Ecophys.jl (VirtualPlantLab — c:/git/Ecophys.jl):**
- Confirm `C3Q()` (Unitful version) interface signature — PlantMapper's `EcophysExt.jl` wraps it into `AbstractPhotosynthesisModel`; need to verify input/output units match PlantMapper conventions
- Confirm whether Ecophys.jl `solve_energy_balance()` can be bridged to PlantMapper's `FixedPointSolver` API or whether both run independently
- Note: Medlyn stomatal model is NOT in Ecophys.jl — PlantMapper owns `MedlynStomatalConductance`

**PlantSimEngine.jl / PlantGraphs.jl / SkyDomes.jl (VirtualPlantLab — c:/git/):**
- These are weakdeps for future extensions (FSPM structure, 3D radiation); no action needed for skeleton build

**MicroclimateMapper.jl:**
- Co-design `AbstractForcing` accessor signatures (NicheMapper.jl Layer A) — especially `soil_water_potential(forcing, step, depth_node)` return units and node indexing convention
- Implement `canopy_integrated_temperature()` and `root_zone_integrated_water_potential()` helpers, or confirm PlantMapper should wrap the node accessors directly
- Confirm `AbstractPlantModel` interface (transpiration!, canopy_albedo, canopy_lai, root_density_profile) stays in MicroclimateMapper
