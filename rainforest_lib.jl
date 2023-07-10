module RainforestLib

    using Zarr
    using YAXArrays
    using DotEnv
    using GeoMakie
    using GLMakie


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

    function build_bitmask_by_lccs_class(local_matrix::Matrix, accepted_values::Set{String}):: Matrix{Float32}

        # fetch the flag values for each string item
        flag_vals = get_lccs_flag.(accepted_values)

        # generate the bitmask by broadcasting the isin function
        bitmask = in.(local_matrix, flag_vals)

        # last step is for converting to NaN and 
        return map(bitmask) do x
            if x == 0
                NaN32
            else
                Float32(1)
            end
        end
        
    end

    function local_geoaxis_creation!(
        figure::Makie.Figure, 
        lonlims::Tuple{Float64, Float64}, 
        latlims::Tuple{Float64, Float64}, 
        lonpadding::Float64 = 1.0, 
        latpadding::Float64 = 1.0,
        figure_x::Int = 1,
        figure_y::Int = 1,
        coastlines::Bool = true
        )::Makie.Axis
        
        paddingfun = (x, y) -> x < 0 ? x-y : x + y

        lon_padded = paddingfun.(lonlims, lonpadding)
        lon_center = lon_padded[1] + ((lon_padded[2] - lon_padded[1]) / 2)



        lat_padded = paddingfun.(latlims, latpadding)
        lat_center = lat_padded[1] + ((lat_padded[2] - lat_padded[1]) / 2)
        
        geoaxis = GeoMakie.GeoAxis(
            figure[figure_x, figure_y]; 
            dest = "+proj=ortho +lon_0=$(lon_center) +lat_0=$(lat_center)",
            # source = dest,
            lonlims = lonlims,
            latlims = latlims,
            coastlines = coastlines
        )

        return geoaxis
    end


    function build_figure_by_lcc_classes(
        datacube, 
        accepted_values::Set{String}, 
        local_map::Bool = true,
        timestep::Int = 1,
        lonpadding::Float64 = 1.0, 
        latpadding::Float64 = 1.0,
        colormap::Union{Symbol, Vector{<:Colorant}} = :viridis, 
        shading::Bool = false)::Makie.Figure

        bitmask = build_bitmask_by_lccs_class(datacube[:, :, timestep], accepted_values)

        fig = Figure()

        lon = YAXArrays.getAxis("lon", datacube).values |> extrema 
        lat = YAXArrays.getAxis("lat", datacube).values |> extrema
        lonrange = range(lon[1], lon[end], size(bitmask, 1))

        # we need to flip the latitude because of an error in the datacube!!!!!
        latrange = range(lat[1], lat[end], size(bitmask, 2))[end:-1:1]

        if local_map
            ga = local_geoaxis_creation!(fig, lon, lat, lonpadding, latpadding)
            surface!(ga, lonrange, latrange, bitmask; shading = shading, colormap = colormap)
        else
            projection = "+proj=lonlat"
            ga = GeoMakie.GeoAxis(
                fig[1, 1]; # any cell of the figure's layout
                dest = projection,
                source = projection,
                coastlines = true # plot coastlines from Natural Earth, as a reference.
            )

            surface!(ga, lonrange, latrange, bitmask; shading = shading, colormap = colormap)

        end

        return fig
    end

end