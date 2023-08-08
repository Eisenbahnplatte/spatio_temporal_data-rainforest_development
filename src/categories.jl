module RainforestCategories


    include("utils.jl")
    using .Rainforestlib_utils

    struct Category
        name::String
        lccs_classes::Set{String}
        float::Float64
        lccs_flags::Array{UInt8}
        Category(n, lccs, val) = new(n, Set(lccs), val, Set(get_lccs_flag.(lccs_classes)))
    end

    categories_list=[
        Category(
            "rainforest",
            [
                "tree_broadleaved_evergreen_closed_to_open"
            ],
            0.0
        ),
        Category(
            "forest",
            [
                "tree_broadleaved_deciduous_closed_to_open",
                "tree_broadleaved_deciduous_closed",
                "tree_broadleaved_deciduous_open",
                "tree_needleleaved_evergreen_closed_to_open",
                "tree_needleleaved_evergreen_closed",
                "tree_needleleaved_evergreen_open",
                "tree_needleleaved_deciduous_closed_to_open",
                "tree_needleleaved_deciduous_closed",
                "tree_needleleaved_deciduous_open",
                "tree_mixed",
                "tree_cover_flooded_saline_water",
                "tree_cover_flooded_fresh_or_brakish_water",
            ],
            0.1
        ),
        Category(
            "shrubland",
            [
                "shrubland",
                "shrubland_evergreen",
                "shrubland_deciduous",
                "shrub_or_herbaceous_cover_flooded",
            ],
            0.2
        ),
        Category(
            "flat_vegetation",
            [
                "grassland",
                "lichens_and_mosses",
            ],
            0.3
        ),
        Category(
            "sparse_vegetation",
            [
                "mosaic_natural_vegetation",
                "mosaic_tree_and_shrub", 
                "mosaic_herbaceous", 
                "sparse_vegetation",
                "sparse_tree",
                "sparse_shrub",
                "sparse_herbaceous",
            ],
            0.4
        ),
        Category(
            "no_data",
            [
                "no_data"
            ],
            0.5
        ),
        Category(
            "water",
            [
                "water",
                "snow_and_ice"
            ],
            0.7
        ),
        Category(
            "bare_areas",
            [
                "bare_areas",
                "bare_areas_consolidated",
                "bare_areas_unconsolidated",
            ],
            0.8
        ),
        Category(
            "cropland",
            [
                "cropland_rainfed", 
                "cropland_rainfed_herbaceous_cover", 
                "cropland_rainfed_tree_or_shrub_cover",
                "cropland_irrigated",
                "mosaic_cropland"
            ],
            0.9
        ),
        Category(
            "urban",
            [
                "urban"
            ],
            1.0
        )
    ]

    categories = Dict(c.name => c for c in categories_list)

    function flag_to_category_val(flag::UInt8, categories::Set{Category})
        
        for category in categories
            if flag in category.lccs_flags
                return category.float
            end
        end
    end


end