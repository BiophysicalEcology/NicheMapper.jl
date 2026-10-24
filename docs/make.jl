using Documenter
using DocumenterVitepress
using NicheMapper

makedocs(
    modules = [NicheMapper],
    sitename = "NicheMapper.jl",
    authors = "Michael Kearney, Rafael Schouten et al.",
    clean = true,
    doctest = false,
    checkdocs = :none,
    format = DocumenterVitepress.MarkdownVitepress(
        repo = "github.com/BiophysicalEcology/NicheMapper.jl",
        devbranch = "master",
        devurl = "dev";
    ),
    source = "src",
    build = "build",
    warnonly = true,
)

DocumenterVitepress.deploydocs(;
    repo = "github.com/BiophysicalEcology/NicheMapper.jl",
    branch = "gh-pages",
    devbranch = "master",
    push_preview = true,
)
