# History

**Beginnings.** Biophysical modelling applies the physics of heat, mass and momentum transfer to
organisms ([Porter & Gates 1969](https://doi.org/10.2307/1948545); Gates 1980). Warren Porter
took it up to answer a question about the [desert iguana](https://en.wikipedia.org/wiki/Desert_iguana):
what is the thermal advantage of changing colour from dark to light? With mechanical engineers
he built a heat budget for the lizard ([Porter et al. 1973](https://doi.org/10.1007/BF00379617)),
a microclimate model of the desert to drive it (Mitchell et al. 1975), and a clear-sky solar
radiation model ([McCullough & Porter 1971](https://doi.org/10.2307/1933806)). The same models
gave water loss, energy requirements and predator-prey constraints
([Porter & James 1979](https://doi.org/10.2307/1443867)), and Tracy
([1976](https://doi.org/10.2307/1942256)) extended them to wet-skinned ectotherms such as frogs.

**Endotherms.** For birds and mammals the heat budget is solved for the metabolic or water loss
rate that balances it, rather than for body temperature
([Porter et al. 1994](https://doi.org/10.1071/ZO9940125);
[2000](https://doi.org/10.1093/icb/40.4.597)).

**Landscapes.** From 1998 the calculations were applied across landscapes
([Porter et al. 2002](https://doi.org/10.1093/icb/42.3.431)) and developed into mechanistic
species distribution models that map the fundamental niche to space
([Kearney & Porter 2004](https://doi.org/10.1890/03-0820);
[2009](https://doi.org/10.1111/j.1461-0248.2008.01277.x)). The suite of microclimate,
ectotherm and endotherm models became known as Niche Mapper.

**Dynamic Energy Budgets.** Metabolic, digestive, growth and reproduction rates were at first
allometric functions of mass and temperature. Dynamic Energy Budget theory replaced these with
an integrated, thermodynamically grounded account of the whole life cycle
([Kearney et al. 2010](https://doi.org/10.1098/rstb.2010.0034);
[Kearney 2012](https://doi.org/10.1111/j.1365-2435.2011.01917.x);
[Kearney et al. 2013](https://doi.org/10.1111/1365-2435.12020)).

**NicheMapR.** The Fortran models were given an R interface as
[NicheMapR](https://github.com/mrke/NicheMapR): the microclimate model
([Kearney & Porter 2017](https://doi.org/10.1111/ecog.02360)) with soil moisture
([Kearney & Maino 2018](https://doi.org/10.1016/j.jhydrol.2018.04.040)) and snow
([Kearney 2020](https://doi.org/10.1111/geb.13100)), the ectotherm and DEB models
([Kearney & Porter 2019](https://doi.org/10.1111/ecog.04680)), the endotherm model
([Kearney et al. 2021](https://doi.org/10.1111/ecog.05550)) and egg and wet-skin water uptake
([Kearney & Enriquez-Urzelai 2022](https://doi.org/10.1111/2041-210X.14018)).

**NicheMapper.jl.** The Julia ecosystem separates these models into packages with clear
interfaces, so each part can be tested, swapped and differentiated on its own; see the
[Architecture overview](architecture/mechanistic_niche_modelling_framework.md).

Tests and applications of the NicheMapR models are listed on the
[NicheMapR website](https://mrke.github.io/): [tests](https://mrke.github.io/tests/) and
[applications](https://mrke.github.io/examples/).

## References

- Gates, D. M. (1980). *Biophysical Ecology*. Springer.
- Mitchell, J. W., Beckman, W. A., Bailey, R. T., & Porter, W. P. (1975). Microclimatic modeling of the desert. In *Heat and Mass Transfer in the Biosphere* (pp. 275–286). Scripta.
