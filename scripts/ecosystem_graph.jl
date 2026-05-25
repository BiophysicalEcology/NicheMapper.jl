# Run with: julia scripts/ecosystem_graph.jl
# Fetches Project.toml from each ecosystem GitHub repo and writes a Mermaid
# dependency diagram into docs/architecture/mechanistic_niche_modelling_framework.md.

using Downloads, TOML

const ORG = "BiophysicalEcology"

# Override the default $ORG/$pkg/main URL for packages in other orgs or on other branches.
const CUSTOM_URLS = (
    DEBtool_J   = "https://raw.githubusercontent.com/add-my-pet/DEBtool_J.jl/main/Project.toml",
    NicheMapper = "https://raw.githubusercontent.com/BiophysicalEcology/NicheMapper.jl/master/Project.toml",
)

const EXISTING = (
    "BiophysicalEcologyBase.jl",
    "FluidProperties.jl",
    "BiophysicalGeometry.jl",
    "SolarRadiation.jl",
    "ThermalPhysiology.jl",
    "BiologicalScaling.jl",
    "Microclimate.jl",
    "HeatExchange.jl",
    "BiophysicalBehaviour.jl",
    "DEBtool_J.jl",
    "NicheMapper.jl",
)

# Packages not yet on GitHub — deps defined here until their repos exist.
# Keys are Symbol(packagename) without the .jl suffix.
const PLANNED = (
    MicroclimateMapper = ["Microclimate.jl", "SolarRadiation.jl"],
    AnimalMapper       = ["MicroclimateMapper.jl", "HeatExchange.jl",
                          "BiophysicalBehaviour.jl", "ThermalPhysiology.jl",
                          "BiologicalScaling.jl", "DEBtool_J.jl"],
    PlantMapper        = ["MicroclimateMapper.jl", "HeatExchange.jl",
                          "ThermalPhysiology.jl", "BiologicalScaling.jl",
                          "DEBtool_J.jl"],
    MicrobeMapper      = ["MicroclimateMapper.jl", "ThermalPhysiology.jl",
                          "BiologicalScaling.jl", "DEBtool_J.jl"],
)

# Planned future deps for existing packages not yet reflected in their Project.toml.
const FUTURE_DEPS = (
    NicheMapper = ["MicroclimateMapper.jl", "AnimalMapper.jl",
                   "PlantMapper.jl", "MicrobeMapper.jl"],
)

pkg_to_sym(pkg) = Symbol(replace(pkg, ".jl" => ""))
sym_to_pkg(sym) = string(sym) * ".jl"

function project_url(pkg)
    key = pkg_to_sym(pkg)
    hasproperty(CUSTOM_URLS, key) ? getfield(CUSTOM_URLS, key) :
        "https://raw.githubusercontent.com/$ORG/$pkg/main/Project.toml"
end

function fetch_deps(pkg, ecosystem)
    buf = IOBuffer()
    try
        Downloads.download(project_url(pkg), buf)
        toml = TOML.parse(String(take!(buf)))
        raw  = keys(merge(get(toml, "deps",     Dict{String,Any}()),
                          get(toml, "weakdeps",  Dict{String,Any}()),
                          get(toml, "extras",    Dict{String,Any}())))
        return [d * ".jl" for d in raw if d * ".jl" ∈ ecosystem]
    catch
        @warn "Could not fetch $pkg"
        return String[]
    end
end

function build_graph()
    ecosystem = Set(EXISTING) ∪ Set(sym_to_pkg.(propertynames(PLANNED)))
    graph = Dict(pkg => fetch_deps(pkg, ecosystem) for pkg in EXISTING)
    for k in propertynames(PLANNED)
        graph[sym_to_pkg(k)] = getfield(PLANNED, k)
    end
    for k in propertynames(FUTURE_DEPS)
        append!(graph[sym_to_pkg(k)], getfield(FUTURE_DEPS, k))
    end
    return graph
end

node_id(pkg) = replace(pkg, ".jl" => "", "-" => "_")
strip_jl(pkg) = replace(pkg, ".jl" => "")

const MARKER_START = "<!-- ecosystem-graph-start -->"
const MARKER_END   = "<!-- ecosystem-graph-end -->"

function mermaid_block(graph)
    existing = Set(EXISTING)
    planned  = Set(sym_to_pkg.(propertynames(PLANNED)))
    is_planned(pkg) = pkg ∈ planned

    io = IOBuffer()
    println(io, "```mermaid")
    println(io, "graph TD")
    println(io)
    println(io, "  %% Existing packages")
    for pkg in sort(collect(existing))
        println(io, "  $(node_id(pkg))([\"$(strip_jl(pkg))\"])")
    end
    println(io)
    println(io, "  %% Planned packages")
    for pkg in sort(collect(planned))
        println(io, "  $(node_id(pkg))([\"$(strip_jl(pkg)) ⬡\"]):::planned")
    end
    println(io)
    println(io, "  %% Dependencies")
    for (pkg, deps) in sort(collect(graph))
        for dep in deps
            (dep ∈ existing || dep ∈ planned) || continue
            arrow = (is_planned(pkg) || is_planned(dep)) ? "-.->" : "-->"
            println(io, "  $(node_id(dep)) $arrow $(node_id(pkg))")
        end
    end
    println(io)
    println(io, "  classDef planned stroke-dasharray:5 5,fill:#3b82f6")
    print(io, "```")
    return String(take!(io))
end

function inject_into_doc(block, path)
    content = read(path, String)
    i = findfirst(MARKER_START, content)
    j = findfirst(MARKER_END, content)
    (isnothing(i) || isnothing(j)) && error("Graph markers not found in $path")
    write(path, content[1:first(i)-1] * MARKER_START * "\n" * block * "\n" * MARKER_END * content[last(j)+1:end])
end

docpath = joinpath(@__DIR__, "..", "docs", "architecture", "mechanistic_niche_modelling_framework.md")
inject_into_doc(mermaid_block(build_graph()), docpath)
println("Updated $docpath")
