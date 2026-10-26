# Extending the ecosystem with multiple dispatch

Alternative formulations of a process are types, and the function computing the process has a method for each.
Julia chooses the method from the types of all the arguments (multiple dispatch), so a formulation can be added
without changing the package that defines the function: define a subtype of the abstract type and a method for it.
The new formulation then works wherever the built-in ones do, including in every package downstream.

## Examples

::: tabs

== Vapour pressure

In FluidProperties.jl each saturation vapour pressure equation is a subtype of `VapourPressureEquation`, and
`vapour_pressure` has a method for each. The Magnus form fitted by Alduchov and Eskridge (1996), over liquid water,
can be added in a few lines:

```julia
using FluidProperties, Unitful

struct AlduchovEskridge <: VapourPressureEquation end

function FluidProperties.vapour_pressure(::AlduchovEskridge, T)
    Tc = ustrip(u"°C", T)
    return 6.1094 * exp(17.625 * Tc / (243.04 + Tc)) * 100u"Pa"
end

vapour_pressure(AlduchovEskridge(), 20.0u"°C")  # 2333 Pa
```

It now works wherever the other equations do, including in `wet_air_properties` and in the packages built on
FluidProperties.jl, such as Microclimate.jl:

```julia
wet_air_properties(20.0u"°C", 0.5, 101325.0u"Pa"; vapour_pressure_equation = AlduchovEskridge()).vapour_pressure
```

== Thermal response

In ThermalPhysiology.jl each thermal performance curve is a subtype of `AbstractTPCModel`, and
`thermal_performance` has a method for each. A development rate rising linearly above a threshold temperature, the
basis of degree-day models (Campbell et al. 1974), is:

```julia
using ThermalPhysiology, Unitful

struct LinearDevelopment{R,T} <: AbstractPhenomenologicalModel
    slope::R
    threshold::T
end

ThermalPhysiology.thermal_performance(m::LinearDevelopment, T) =
    max(zero(m.slope * 1u"K"), m.slope * (uconvert(u"K", T) - uconvert(u"K", m.threshold)))

development = LinearDevelopment(0.01u"1/d/K", 10.0u"°C")
thermal_performance(development, 25.0u"°C")  # 0.15 d⁻¹
```

The generic functions built on `thermal_performance` now accept it, such as the mean over a temperature series:

```julia
mean_thermal_performance(development, [5.0, 15.0, 25.0]u"°C")  # 0.067 d⁻¹
```

== Allometry

In BiologicalScaling.jl each quantity (e.g. `BasalMetabolicRate`) and each taxon (e.g. `EutherianMammal`) is a type,
and `allometric` has a method for each pair. `FieldMetabolicRate` has no allometry yet; that of Nagy et al. (1999)
for mammals is:

```julia
using BiologicalScaling, Unitful

const MAMMAL_FMR = PowerLaw(4.82, 0.734; input_unit = u"g", output_unit = u"kJ/d",
    reference = "Nagy, Girard & Brown 1999")

BiologicalScaling.allometric(::FieldMetabolicRate, ::AbstractMammal, mass) = MAMMAL_FMR(mass)
# temperature-independent, so it can also be called with one, as HeatExchange.jl does
BiologicalScaling.allometric(rate::FieldMetabolicRate, taxon::AbstractMammal, mass, temperature) =
    allometric(rate, taxon, mass)

uconvert(u"W", allometric(FieldMetabolicRate(), EutherianMammal(), 1.0u"kg"))  # 8.9 W
```

Every mammal taxon now has it, and HeatExchange.jl can use it for an organism's metabolic heat:

```julia
MetabolismParameters(; model = (FieldMetabolicRate(), EutherianMammal()))
```

:::

## References

Alduchov OA, Eskridge RE. 1996. Improved Magnus form approximation of saturation vapor pressure. Journal of Applied
Meteorology 35: 601-609.

Campbell A, Frazer BD, Gilbert N, Gutierrez AP, Mackauer M. 1974. Temperature requirements of some aphids and their
parasites. Journal of Applied Ecology 11: 431-438.

Nagy KA, Girard IA, Brown TK. 1999. Energetics of free-ranging mammals, reptiles, and birds. Annual Review of
Nutrition 19: 247-277.
