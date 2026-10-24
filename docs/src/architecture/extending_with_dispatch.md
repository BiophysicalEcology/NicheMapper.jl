# Extending the ecosystem with multiple dispatch

*Note for the ecosystem docs, to be moved into them once they are built.*

Alternative formulations of a process are types, and the function computing the process has a method for each.
Julia chooses the method from the types of all the arguments (multiple dispatch), so a formulation can be added
without changing the package that defines the function: define a subtype of the abstract type and a method for it.
The new formulation then works wherever the built-in ones do, including in every package downstream.

## Example: a vapour pressure equation

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

vapour_pressure(AlduchovEskridge(), 20.0u"°C")
```

It now works wherever the other equations do, including in `wet_air_properties` and in the packages built on
FluidProperties.jl, such as Microclimate.jl:

```julia
wet_air_properties(20.0u"°C", 0.5, 101325.0u"Pa"; vapour_pressure_equation = AlduchovEskridge()).vapour_pressure
```

## References

Alduchov OA, Eskridge RE. 1996. Improved Magnus form approximation of saturation vapor pressure. Journal of Applied
Meteorology 35: 601-609.
