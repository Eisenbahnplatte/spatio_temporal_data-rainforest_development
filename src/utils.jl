module Rainforestlib_utils

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

    function diff_matrices(difffun::Function, matrix1::Matrix, matrix2::Matrix)::Matrix 
        
        rows, cols = size(matrix1)

        result = zeros(rows, cols)

        for r in range(1, rows)
            for c in range(1, cols)

                result[r, c] = difffun(matrix1[r, c], matrix2[r, c])
            end
        end

        return result
    end
end