module LCCSClasses

    export get_lccs_flag, get_lccs_name

    vals = [
        "no_data",
        "cropland_rainfed",
        "cropland_rainfed_herbaceous_cover",
        "cropland_rainfed_tree_or_shrub_cover",
        "cropland_irrigated",
        "mosaic_cropland",
        "mosaic_natural_vegetation",
        "tree_broadleaved_evergreen_closed_to_open",
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
        "mosaic_tree_and_shrub",
        "mosaic_herbaceous",
        "shrubland",
        "shrubland_evergreen",
        "shrubland_deciduous",
        "grassland",
        "lichens_and_mosses",
        "sparse_vegetation",
        "sparse_tree",
        "sparse_shrub",
        "sparse_herbaceous",
        "tree_cover_flooded_fresh_or_brakish_water",
        "tree_cover_flooded_saline_water",
        "shrub_or_herbaceous_cover_flooded",
        "urban",
        "bare_areas",
        "bare_areas_consolidated",
        "bare_areas_unconsolidated",
        "water",
        "snow_and_ice"
    ]

    

    keys = UInt8.([0, 10, 11, 12, 20, 30, 40, 50, 60, 61, 62, 70, 71, 72, 80, 81,
    82, 90, 100, 110, 120, 121, 122, 130, 140, 150, 151, 152, 153, 160, 170, 180,
    190, 200, 201, 202, 210, 220])


    LCC_DICT = Dict{UInt8, String}()
    LCC_DICT_INVERSE = Dict{String, UInt8}()

    for (k, v) in zip(keys, vals)
        LCC_DICT[k] = v
        LCC_DICT_INVERSE[v] = k
    end

    function get_lccs_flag(name::String)
        return LCC_DICT_INVERSE[name]
    end

    function get_lccs_name(flag::UInt8)
        return LCC_DICT[flag]
    end

    function get_float_repr(name::String)::Float64
        class_number = length(vals)

        index = findfirst(item -> item == name, vals)

        return (1/class_number) * index
    end    

    function get_float_repr(flag::UInt8)::Float64
        class_number = length(keys)

        index = findfirst(item -> item == flag, keys)

        return (1/class_number) * index
    end 



    ############# Categorizing 

    struct Category
        name::String
        lccs_classes::Set{String}
        float::Float64
        lccs_flags::Set{UInt8}
        Category(n, lccs, val) = new(n, Set(lccs), val, Set(get_lccs_flag.(lccs)))
    end

    categories_list=[
        Category(
            "rainforest",
            [
                "tree_broadleaved_evergreen_closed_to_open"
            ],
            0.1
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
            0.2
        ),
        Category(
            "shrubland",
            [
                "shrubland",
                "shrubland_evergreen",
                "shrubland_deciduous",
                "shrub_or_herbaceous_cover_flooded",
            ],
            0.3
        ),
        Category(
            "flat_vegetation",
            [
                "grassland",
                "lichens_and_mosses",
            ],
            0.4
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
            0.5
        ),
        Category(
            "no_data",
            [
                "no_data"
            ],
            0.6
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

    function flag_to_category_val(flag::UInt8)::Float32
        
        for (_, category) in categories
            if flag in category.lccs_flags
                return Float32(category.float)
            end
        end

        return Float32(NaN)
    end


end