# Run with: julia scripts/ecosystem_graph.jl
# Fetches Project.toml from each ecosystem GitHub repo and writes a Mermaid
# dependency diagram into docs/src/architecture/mechanistic_niche_modelling_framework.md.

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
    "MicroclimateMapper.jl",
    "HeatExchange.jl",
    "BiophysicalBehaviour.jl",
    "DEBtool_J.jl",
    "NicheMapper.jl",
)

# Packages not yet on GitHub — deps defined here until their repos exist.
# Keys are Symbol(packagename) without the .jl suffix.
const PLANNED = (
    AnimalMapper      = ["MicroclimateMapper.jl", "HeatExchange.jl",
                          "BiophysicalBehaviour.jl", "ThermalPhysiology.jl",
                          "BiologicalScaling.jl", "DEBtool_J.jl"],
    PlantMapper        = ["MicroclimateMapper.jl", "HeatExchange.jl",
                          "ThermalPhysiology.jl", "BiologicalScaling.jl",
                          "DEBtool_J.jl"],
    MicrobeMapper      = ["MicroclimateMapper.jl", "ThermalPhysiology.jl",
                          "BiologicalScaling.jl", "DEBtool_J.jl"],
)

# Planned future deps for existing packages not yet reflected in their Project.toml.
# Packages outside the ecosystem, drawn only in subsets that list them.
const EXTERNAL = ("Rasters.jl", "RasterDataSources.jl", "Geomorphometry.jl")

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
    ecosystem = Set(EXISTING) ∪ Set(sym_to_pkg.(propertynames(PLANNED))) ∪ Set(EXTERNAL)
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

# Edge colour by the package depended on; others are grey.
const EDGE_COLOURS = Dict(
    "HeatExchange.jl"         => "#e0553f",
    "Microclimate.jl"         => "#2f7fe0",
    "BiophysicalBehaviour.jl" => "#2f7fe0",
    "AnimalMapper.jl"         => "#2f7fe0",
    "PlantMapper.jl"          => "#2f7fe0",
    "MicrobeMapper.jl"        => "#2f7fe0",
    "BiologicalScaling.jl"    => "#3a9a6a",
    "DEBtool_J.jl"            => "#e0b020",
    "ThermalPhysiology.jl"    => "#b060c0",
    "MicroclimateMapper.jl"   => "#1aa0d0",
)
const DEFAULT_EDGE_COLOUR = "#d0d0d0"

is_mapper(pkg) = endswith(strip_jl(pkg), "Mapper") && pkg != "NicheMapper.jl"

# One graph per subset, showing the dependencies among its packages; `nothing` is all packages.
const SUBSETS = (
    (title = "Microclimate",
     packages = ["FluidProperties.jl", "SolarRadiation.jl", "BiophysicalGeometry.jl",
                 "HeatExchange.jl", "Microclimate.jl", "MicroclimateMapper.jl",
                 "Rasters.jl", "RasterDataSources.jl", "Geomorphometry.jl"]),
    (title = "Heat exchange",
     packages = ["FluidProperties.jl", "BiophysicalGeometry.jl", "HeatExchange.jl",
                 "BiophysicalBehaviour.jl", "Microclimate.jl", "AnimalMapper.jl", "PlantMapper.jl"]),
    (title = "Organism mappers",
     packages = ["MicroclimateMapper.jl", "HeatExchange.jl", "BiophysicalBehaviour.jl",
                 "ThermalPhysiology.jl", "BiologicalScaling.jl", "DEBtool_J.jl",
                 "AnimalMapper.jl", "PlantMapper.jl", "MicrobeMapper.jl", "NicheMapper.jl"]),
    (title = "All packages", packages = nothing),
)

graph_blocks(graph) = join(map(SUBSETS) do s
    "### $(s.title)\n\n" * mermaid_block(graph, s.packages)
end, "\n\n")

function mermaid_block(graph, packages = nothing)
    all_nodes = Set(EXISTING) ∪ Set(sym_to_pkg.(propertynames(PLANNED)))
    nodes = isnothing(packages) ? all_nodes : Set(packages) ∩ (all_nodes ∪ Set(EXTERNAL))

    io = IOBuffer()
    println(io, "```mermaid")
    println(io, "%%{init: {\"theme\": \"dark\"}}%%")
    println(io, "graph TD")
    println(io)
    for pkg in sort(collect(nodes))
        class = pkg ∈ EXTERNAL ? ":::external" : is_mapper(pkg) ? ":::mapper" : ":::pkg"
        println(io, "  $(node_id(pkg))[\"$(strip_jl(pkg))\"]", class)
    end
    println(io)
    colours = String[]
    for (pkg, deps) in sort(collect(graph))
        pkg ∈ nodes || continue
        for dep in sort(deps)
            dep ∈ nodes || continue
            println(io, "  $(node_id(dep)) --> $(node_id(pkg))")
            push!(colours, get(EDGE_COLOURS, dep, DEFAULT_EDGE_COLOUR))
        end
    end
    println(io)
    println(io, "  classDef pkg fill:#22223a,stroke:#9a9aaa,stroke-width:2px,color:#fff")
    println(io, "  classDef mapper fill:#2f6fd6,stroke:#8fbfff,stroke-width:3px,stroke-dasharray:6 4,color:#fff")
    println(io, "  classDef external fill:#1c2a24,stroke:#6a9a80,stroke-width:2px,color:#cfe")
    for colour in unique(colours)
        links = join(findall(==(colour), colours) .- 1, ",")
        println(io, "  linkStyle $links stroke:$colour,stroke-width:2px")
    end
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

docpath = joinpath(@__DIR__, "..", "docs", "src", "architecture", "mechanistic_niche_modelling_framework.md")
inject_into_doc(graph_blocks(build_graph()), docpath)
println("Updated $docpath")
