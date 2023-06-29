module RainforestLib

    using Zarr
    using YAXArrays
    using DotEnv


    sample_cube_dir = "./sample_cubes"

    CONFIG = DotEnv.config()

    
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
    
    function get_lcc_datacube()
        zarr = Zarr.zopen(CONFIG["ZARR_PATH"])
        lc_dataset = YAXArrays.open_dataset(zarr)
        return lc_dataset[:lccs_class]
    end


    function rough_spatial_filter(cube, lon_bounds = (-90,-30), lat_bounds = (-30, 15), time_bounds = (Date(2010), Date(2012)))

            return cube[lon = lon_bounds, lat = lat_bounds, time = time_bounds]
    end

    

    function save_samplecube(cube, name="testcube.zarr", override=false)
        
        pathname = string(sample_cube_dir, "/", name) 
        
        if !isfile(pathname)
            println("Saving the sample cube to disk...")
            
            YAXArrays.savecube(cube, pathname, driver=:zarr)
        elseif override
            println("Overriding existing sample cube....")
            YAXArrays.savecube(cube, pathname, driver=:zarr)
        end
    
    end
    
    function get_samplecube()
        
        if !isfile(testing_cube_path)
            
            println("Sample cube not available, building....")
            build_and_save_samplecube()
        end
        
        zarr = Zarr.zopen(testing_cube_path)
        return YAXArrays.Cube(YAXArrays.open_dataset(zarr))
    
    end

    function build_bitmask_by_lccs_class(datacube::YAXArrays.YAXArray, accepted_values::Set{string})

        result = mapslices(datacube)
        
    end

end