module Rainforestlib

    using Zarr
    using YAXArrays
    using DotEnv
    using GeoMakie
    using GLMakie

    include("./utils.jl")
    using .Rainforestlib_utils

    include("LCCSClasses.jl")
    using .LCCSClasses

    CONFIG = DotEnv.config()

    function get_lcc_datacube()
        zarr = Zarr.zopen(CONFIG["ZARR_PATH"])
        lc_dataset = YAXArrays.open_dataset(zarr)
        return lc_dataset[:lccs_class]
    end


    function rough_spatial_filter(cube; lon_bounds = (-90,-30), lat_bounds = (-30, 15), time_bounds = (Date(2010), Date(2012)))

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

    function build_bitmask(local_matrix::Matrix, category::LCCSClasses.Category)

        return build_bitmask(local_matrix, category.lccs_flags)
    end

    function build_bitmask(local_matrix::Matrix, lccs_classes::Set{String}):: Matrix{Float32}

        # fetch the flag values for each string item
        flag_vals = get_lccs_flag.(lccs_classes)

        return build_bitmask(local_matrix, flag_vals)
        
    end

    function build_bitmask(local_matrix::Matrix, flag_vals::Set{UInt8})
        # generate the bitmask by broadcasting the isin function
        bitmask = in.(local_matrix, Ref(flag_vals))

        # last step is for converting to NaN and 
        return bitmask
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
        accepted_values::Set{String};
        local_map::Bool = true,
        timestep::Int = 1,
        lonpadding::Float64 = 1.0, 
        latpadding::Float64 = 1.0,
        colormap = :viridis,
        colorrange::Tuple{<:Real, <:Real}, 
        shading::Bool = false)::Makie.Figure

        bitmask = build_bitmask(datacube[:, :, timestep], accepted_values)

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

            # transforms zeros to Nans
            nan_bitmask = map(bitmask) do x
                if x == 0.0
                    return Float32(NaN)
                else
                    return x
                end
            end

            surface!(ga, lonrange, latrange, nan_bitmask; shading = shading, colormap = colormap, colorrange = colorrange)

        end

        return fig
    end

    function local_geoaxis_creation!(
        figure::Makie.Figure,
        lonlims::Tuple{Float64, Float64}, 
        latlims::Tuple{Float64, Float64}; 
        lonpadding::Float64 = 1.0, 
        latpadding::Float64 = 1.0,
        figure_x::Int = 1,
        figure_y::Int = 1,
        coastlines::Bool = true,
        title::String = ""
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
            coastlines = coastlines,
            title = title
        )

        return geoaxis
    end


    function build_bitmask_all_classes(datacube)::Matrix
    
        return Rainforestlib_utils.get_float_repr.(datacube)
    end

    function build_figure_all_classes(
        datacube; 
        local_map::Bool = true,
        timestep::Int = 1,
        lonpadding::Float64 = 1.0, 
        latpadding::Float64 = 1.0,
        colormap = :viridis, 
        shading::Bool = false)::Makie.Figure

        bitmask = build_bitmask_all_classes(datacube[:, :, timestep])

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

    function build_plots_over_time(
        datacube,
        accepted_values::Set{String}; 
        lonpadding::Float64 = 1.0, 
        latpadding::Float64 = 1.0,
        colormap = :viridis, 
        shading::Bool = false,
        resolution::Union{Nothing, Tuple{Int, Int}} = Nothing
    )::Makie.Figure


        fig = isnothing(resolution) ?  Figure(resolution = resolution) : Figure()

        timesteps = YAXArrays.getAxis("time", datacube).values

        last = 0.0

        # 3 is the time dimension
        for t in range(1, length(timesteps))
            y_val = (t % 3) + 1 
            x_val = t ÷ 3

            year = timesteps[t]

            bitmask = build_bitmask(datacube[:, :, t], accepted_values)

            number_of_rf_pixels = sum(filter(!isnan, bitmask))
            

            println("Number of rainforest pixels in $(year): $(number_of_rf_pixels)")
            println("Diff to last: $(number_of_rf_pixels - last)")

            last = number_of_rf_pixels

            lon = YAXArrays.getAxis("lon", datacube).values |> extrema 
            lat = YAXArrays.getAxis("lat", datacube).values |> extrema
            lonrange = range(lon[1], lon[end], size(bitmask, 1))

            # we need to flip the latitude because of an error in the datacube!!!!!
            latrange = range(lat[1], lat[end], size(bitmask, 2))[end:-1:1]

            ga = local_geoaxis_creation!(fig, lon, lat; lonpadding = lonpadding, latpadding = latpadding, figure_x = x_val, figure_y = y_val, title = "Plot $(year)")
            surface!(ga, lonrange, latrange, bitmask; shading = shading, colormap = colormap)
        
        end
        
        return fig
    end

    function build_diff_figure(
        datacube,
        timestep::Int,
        previous_mask::Matrix,
        tracked_category::LCCSClasses.Category;
        lonpadding::Float64 = 1.0, 
        latpadding::Float64 = 1.0,
        colormap = :viridis, 
        shading::Bool = false,
        resolution::Union{Nothing, Tuple{Int, Int}} = Nothing
    )::Tuple{Figure, Matrix}

        timesteps = YAXArrays.getAxis("time", datacube).values

        year = timesteps[timestep]

        bitmask::Matrix = build_bitmask(datacube[:, :, timestep], tracked_category)


        diff_bitmask = Rainforestlib_utils.diff_matrices(bitmask, previous_mask) do new, old
            if old == new
                return old
            else
                if old < new
                    # this means something got added
                    return Float32(2)
                else
                    # this means something previously selected got unselected
                    return Float32(3)
                end
            end
        end

        number_of_rf_pixels = sum(filter(!isnan, bitmask))
        

        println("Number of rainforest pixels in $(year): $(number_of_rf_pixels)")

        lon = YAXArrays.getAxis("lon", datacube).values |> extrema 
        lat = YAXArrays.getAxis("lat", datacube).values |> extrema
        lonrange = range(lon[1], lon[end], size(diff_bitmask, 1))

        fig = fig = isnothing(resolution) ?  Figure() : Figure(resolution = resolution)

        # we need to flip the latitude because of an error in the datacube!!!!!
        latrange = range(lat[1], lat[end], size(diff_bitmask, 2))[end:-1:1]

        ga = local_geoaxis_creation!(fig, lon, lat; lonpadding = lonpadding, latpadding = latpadding, title = "Plot $(year)")
        surface!(ga, lonrange, latrange, diff_bitmask; shading = shading, colormap = colormap)

        return fig, bitmask
    end



    function build_diff_figures_over_time(
        datacube,
        tracked_category::LCCSClasses.Category,
        target_path::String;
        name_base::String = "figure", 
        lonpadding::Float64 = 1.0, 
        latpadding::Float64 = 1.0,
        colormap = :viridis, 
        shading::Bool = false,
        resolution::Union{Nothing, Tuple{Int, Int}} = nothing
    )::Nothing
        # build one figure with diffs for each timestep
        mapCube
        timesteps = YAXArrays.getAxis("time", datacube).values

        lonsize = length(YAXArrays.getAxis("lon", datacube).values)
        latsize = length(YAXArrays.getAxis("lat", datacube).values)

        last_bitmask = zeros(lonsize, latsize)

        # 3 is the time dimension
        for t in range(1, length(timesteps))

            filename = "$(target_path)/$(name_base)_$(t).png"

            figure, new_bitmask = build_diff_figure(
                datacube, 
                t, 
                last_bitmask, 
                tracked_category; 
                lonpadding = lonpadding,
                latpadding = latpadding,
                colormap = colormap,
                shading = shading,
                resolution = resolution 
            )

            last_bitmask = new_bitmask

            save(filename, figure)
        end
    end

end