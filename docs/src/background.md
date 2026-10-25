# History

**Beginnings.** Biophysical modelling applies the physics of heat, mass and momentum transfer to
organisms ([Porter & Gates 1969](https://doi.org/10.2307/1948545); Gates 1980). Warren Porter
took it up to answer a question about the [desert iguana](https://en.wikipedia.org/wiki/Desert_iguana):
what is the thermal advantage of changing colour from dark to light? With mechanical engineers
he built a heat budget for the lizard ([Porter et al. 1973](https://doi.org/10.1007/BF00379617)),
a microclimate model of the desert to drive it (Mitchell et al. 1975), and a clear-sky solar
radiation model ([McCullough & Porter 1971](https://doi.org/10.2307/1933806)). The same models
gave water loss, energy requirements and predator-prey constraints
(Porter et al. 1975; [Porter & James 1979](https://doi.org/10.2307/1443867)), and Tracy
([1976](https://doi.org/10.2307/1942256)) extended them to wet-skinned ectotherms such as frogs.

**Endotherms.** For birds and mammals the heat budget is solved for the metabolic or water loss
rate that balances it, rather than for body temperature
([Porter et al. 1994](https://doi.org/10.1071/ZO9940125);
[2000](https://doi.org/10.1093/icb/40.4.597)).

**Landscapes.** From 1998 the calculations were applied across landscapes
([Porter et al. 2002](https://doi.org/10.1093/icb/42.3.431)) and developed into mechanistic
species distribution models that map the fundamental niche to space
([Kearney & Porter 2004](https://doi.org/10.1890/03-0820);
[2009](https://doi.org/10.1111/j.1461-0248.2008.01277.x)), and compared with correlative
approaches ([Kearney et al. 2008](https://doi.org/10.1111/j.0906-7590.2008.05457.x);
[Kearney et al. 2010](https://doi.org/10.1111/j.1755-263X.2010.00097.x)). The suite of
microclimate, ectotherm and endotherm models became known as Niche Mapper.

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
- Kearney, M. (2012). Metabolic theory, life history and the distribution of a terrestrial ectotherm. *Functional Ecology*, 26, 167–179. [doi:10.1111/j.1365-2435.2011.01917.x](https://doi.org/10.1111/j.1365-2435.2011.01917.x)
- Kearney, M. R. (2020). How will snow alter exposure of organisms to cold stress under climate warming? *Global Ecology and Biogeography*. [doi:10.1111/geb.13100](https://doi.org/10.1111/geb.13100)
- Kearney, M. R., Briscoe, N. J., Mathewson, P. D., & Porter, W. P. (2021). NicheMapR – an R package for biophysical modelling: the endotherm model. *Ecography*, 44, 1595–1605. [doi:10.1111/ecog.05550](https://doi.org/10.1111/ecog.05550)
- Kearney, M. R., & Enriquez-Urzelai, U. (2022). A general framework for jointly modelling thermal and hydric constraints on developing eggs. *Methods in Ecology and Evolution*. [doi:10.1111/2041-210X.14018](https://doi.org/10.1111/2041-210X.14018)
- Kearney, M. R., & Maino, J. L. (2018). Can next-generation soil data products improve soil moisture modelling at the continental scale? *Journal of Hydrology*, 561, 662–673. [doi:10.1016/j.jhydrol.2018.04.040](https://doi.org/10.1016/j.jhydrol.2018.04.040)
- Kearney, M., Phillips, B. L., Tracy, C. R., Christian, K., Betts, G., & Porter, W. P. (2008). Modelling species distributions without using species distributions: the cane toad in Australia under current and future climates. *Ecography*, 31, 423–434. [doi:10.1111/j.0906-7590.2008.05457.x](https://doi.org/10.1111/j.0906-7590.2008.05457.x)
- Kearney, M., & Porter, W. P. (2004). Mapping the fundamental niche: physiology, climate, and the distribution of a nocturnal lizard. *Ecology*, 85, 3119–3131. [doi:10.1890/03-0820](https://doi.org/10.1890/03-0820)
- Kearney, M., & Porter, W. P. (2009). Mechanistic niche modelling: combining physiological and spatial data to predict species' ranges. *Ecology Letters*, 12, 334–350. [doi:10.1111/j.1461-0248.2008.01277.x](https://doi.org/10.1111/j.1461-0248.2008.01277.x)
- Kearney, M. R., & Porter, W. P. (2017). NicheMapR – an R package for biophysical modelling: the microclimate model. *Ecography*, 40, 664–674. [doi:10.1111/ecog.02360](https://doi.org/10.1111/ecog.02360)
- Kearney, M. R., & Porter, W. P. (2019). NicheMapR – an R package for biophysical modelling: the ectotherm and Dynamic Energy Budget models. *Ecography*. [doi:10.1111/ecog.04680](https://doi.org/10.1111/ecog.04680)
- Kearney, M., Simpson, S. J., Raubenheimer, D., & Helmuth, B. (2010). Modelling the ecological niche from functional traits. *Philosophical Transactions of the Royal Society B*, 365, 3469–3483. [doi:10.1098/rstb.2010.0034](https://doi.org/10.1098/rstb.2010.0034)
- Kearney, M. R., Simpson, S. J., Raubenheimer, D., & Kooijman, S. A. L. M. (2013). Balancing heat, water and nutrients under environmental change: a thermodynamic niche framework. *Functional Ecology*, 27, 950–966. [doi:10.1111/1365-2435.12020](https://doi.org/10.1111/1365-2435.12020)
- Kearney, M. R., Wintle, B. A., & Porter, W. P. (2010). Correlative and mechanistic models of species distribution provide congruent forecasts under climate change. *Conservation Letters*, 3, 203–213. [doi:10.1111/j.1755-263X.2010.00097.x](https://doi.org/10.1111/j.1755-263X.2010.00097.x)
- McCullough, E. C., & Porter, W. P. (1971). Computing clear day solar radiation spectra for the terrestrial ecological environment. *Ecology*, 52, 1008–1015. [doi:10.2307/1933806](https://doi.org/10.2307/1933806)
- Mitchell, J. W., Beckman, W. A., Bailey, R. T., & Porter, W. P. (1975). Microclimatic modeling of the desert. In D. A. De Vries & N. H. Afgan (Eds.), *Heat and Mass Transfer in the Biosphere, Part 1* (pp. 275–286). Scripta.
- Porter, W. P., Budaraju, S., Stewart, W. E., & Ramankutty, N. (2000). Calculating climate effects on birds and mammals: impacts on biodiversity, conservation, population parameters, and global community structure. *American Zoologist*, 40, 597–630. [doi:10.1093/icb/40.4.597](https://doi.org/10.1093/icb/40.4.597)
- Porter, W. P., & Gates, D. M. (1969). Thermodynamic equilibria of animals with environment. *Ecological Monographs*, 39, 227–244. [doi:10.2307/1948545](https://doi.org/10.2307/1948545)
- Porter, W. P., & James, F. C. (1979). Behavioral implications of mechanistic ecology II: the African rainbow lizard, *Agama agama*. *Copeia*, 1979, 594–619. [doi:10.2307/1443867](https://doi.org/10.2307/1443867)
- Porter, W. P., Mitchell, J. W., Beckman, W. A., & DeWitt, C. B. (1973). Behavioral implications of mechanistic ecology: thermal and behavioral modeling of desert ectotherms and their microenvironment. *Oecologia*, 13, 1–54. [doi:10.1007/BF00379617](https://doi.org/10.1007/BF00379617)
- Porter, W. P., Mitchell, J. W., Beckman, W. A., & Tracy, C. R. (1975). Environmental constraints on some predator-prey interactions. In D. M. Gates & R. B. Schmerl (Eds.), *Perspectives in Biophysical Ecology* (pp. 347–364). Springer.
- Porter, W. P., Munger, J. C., Stewart, W. E., Budaraju, S., & Jaeger, J. (1994). Endotherm energetics: from a scalable individual-based model to ecological applications. *Australian Journal of Zoology*, 42, 125–162. [doi:10.1071/ZO9940125](https://doi.org/10.1071/ZO9940125)
- Porter, W. P., Sabo, J. L., Tracy, C. R., Reichman, O. J., & Ramankutty, N. (2002). Physiology on a landscape scale: plant-animal interactions. *Integrative and Comparative Biology*, 42, 431–453. [doi:10.1093/icb/42.3.431](https://doi.org/10.1093/icb/42.3.431)
- Tracy, C. R. (1976). A model of the dynamic exchanges of water and energy between a terrestrial amphibian and its environment. *Ecological Monographs*, 46, 293–326. [doi:10.2307/1942256](https://doi.org/10.2307/1942256)
