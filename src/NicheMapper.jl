module NicheMapper

using Unitful

export AbstractForcing, AbstractEnvironmentSampler, AbstractOrganism
export AbstractSimulationEngine, AbstractResourceField
export air_temperature, soil_temperature, solar_radiation, wind_speed
export relative_humidity, soil_water_potential, vapour_pressure_deficit
export step!, state, result, resource_availability, deplete!

const DEFAULT_DT = 1u"hr"

# ── Layer A: Forcing contracts ────────────────────────────────────────────────
# Highly stable — changes rarely. MicroclimateMapper implements these for MicroResult.

abstract type AbstractForcing end
struct Air end
struct Soil end

air_temperature(f::AbstractForcing, step, height_node)         = error("not implemented for $(typeof(f))")
soil_temperature(f::AbstractForcing, step, depth_node)         = error("not implemented for $(typeof(f))")
solar_radiation(f::AbstractForcing, step)                      = error("not implemented for $(typeof(f))")
wind_speed(f::AbstractForcing, step, height_node)              = error("not implemented for $(typeof(f))")
relative_humidity(f::AbstractForcing, step, height_node)       = error("not implemented for $(typeof(f))")
soil_water_potential(f::AbstractForcing, step, depth_node)     = error("not implemented for $(typeof(f))")
vapour_pressure_deficit(f::AbstractForcing, step, height_node) = error("not implemented for $(typeof(f))")

# Formalises the AvailableEnvironments shade-interpolation pattern from BiophysicalBehaviour.jl
abstract type AbstractEnvironmentSampler end
sample(s::AbstractEnvironmentSampler, shade_fraction, step) = error("not implemented for $(typeof(s))")

# ── Layer B: Simulation contracts ─────────────────────────────────────────────
# May evolve with solver needs.

abstract type AbstractOrganism end  # minimal capability marker — no biology

# All simulate_* functions return a type implementing AbstractSimulationEngine
abstract type AbstractSimulationEngine end
step!(e::AbstractSimulationEngine, step_index::Int, forcing::AbstractForcing, dt) = error("not implemented for $(typeof(e))")
state(e::AbstractSimulationEngine)                                                = error("not implemented for $(typeof(e))")
result(e::AbstractSimulationEngine)                                               = error("not implemented for $(typeof(e))")

# Unifies food (animals), C/N/light (plants), substrate (microbes) as depletable resource pools
abstract type AbstractResourceField end
resource_availability(f::AbstractResourceField, step)         = error("not implemented for $(typeof(f))")
deplete!(f::AbstractResourceField, consumed, step, dt)        = error("not implemented for $(typeof(f))")

end
