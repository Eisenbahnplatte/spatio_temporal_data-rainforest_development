module Rainforestlib
    # load necessary packages
    using Zarr
    using YAXArrays
    import DotEnv
    using GeoMakie
    using GLMakie
    using CairoMakie
    using Colors, ColorSchemes
    using Dates

    include("./utils.jl")
    using .Rainforestlib_utils
    # include the other module called LCCSClasses, where categories were defined
    include("LCCSClasses.jl")
    using .LCCSClasses
    # load metadata link
    CONFIG = DotEnv.config()

    function get_lcc_datacube()
        zarr = Zarr.zopen(CONFIG["ZARR_PATH"])
        lc_dataset = YAXArrays.open_dataset(zarr)
        return lc_dataset[:lccs_class]
    end

    # get a rough extent of South America to decrease the amount of data
    function rough_spatial_filter(cube; lon_bounds = (-90,-30), lat_bounds = (-30, 15), time_bounds = (Date(2010), Date(2021)))

            return cube[lon = lon_bounds, lat = lat_bounds, time = time_bounds]
    end

    
    # create cube for testing
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
    # create a bitmask with the defined categories
    function build_bitmask(local_matrix::Matrix{UInt8}, category::LCCSClasses.Category; set_nan::Bool = false)::Matrix{Float32}

        return build_bitmask(local_matrix, category.lccs_flags; set_nan = set_nan)
    end

    function build_bitmask(local_matrix::Matrix{UInt8}, lccs_classes::Set{String}; set_nan::Bool = false):: Matrix{Float32}

        # fetch the flag values for each string item
        flag_vals = Set(get_lccs_flag.(lccs_classes))

        return build_bitmask(local_matrix, flag_vals; set_nan = set_nan)
        
    end

    function build_bitmask(local_matrix::Matrix{UInt8}, flag_vals::Set{UInt8}; set_nan::Bool = false)::Matrix{Float32}
        # generate the bitmask by broadcasting the isin function
        bitmask = set_nan ? Rainforestlib_utils.replace_zero_with_nan.(Float32.(in.(local_matrix, Ref(flag_vals)))) : Float32.(in.(local_matrix, Ref(flag_vals)))

        # last step is for converting to NaN
        return bitmask
    end
    # filter bitmask by defined values
    function filter_bitmask(bitmask, accepted_values::Set{Float64})::Matrix{Float32}
        return Rainforestlib_utils.filter_matched_items.(bitmask, Ref(accepted_values))
    end    

    function build_category_mask(local_matrix::Matrix{UInt8})
        return LCCSClasses.flag_to_category_val.(local_matrix)
    end

    function build_selected_categorial_mask(local_matrix::Matrix{UInt8}, selected_categories::Set{LCCSClasses.Category})
    
        return LCCSClasses.get_category_val_for_selected_categories.(local_matrix, Ref(selected_categories))
    end

    # function categorize_bitmask(bitmask, categories::Dict)::Matrix{Float32}
    #     i = 0.0
    #     categorized_bitmask = Matrix{Float32}

    #     function replace_number_with_category_index(x::Real, i::Float64)

    #         return i
        
    #     end


    #     for (key, value) in categories

    #         flag_vals = Set(get_lccs_flag.(categories[key].lccs_classes))
    #         categorized_bitmask = replace_number_with_category_index.(Float32.(in.(bitmask, Ref(flag_vals))), i)
    #         i = i + 1.0
    #     end

    #     return categorized_bitmask
    # end

    # create figure that fits the projection type 
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

    # create a figure using the lcc classes
    function build_figure_by_lcc_classes(
        datacube, 
        accepted_values::Set{String};
        local_map::Bool = true,
        timestep::Int = 1,
        lonpadding::Float64 = 1.0, 
        latpadding::Float64 = 1.0,
        colormap = :viridis,
        colorrange::Tuple{<:Real, <:Real} = (0, 1), 
        shading::Bool = false,
        set_nan::Bool = false,
        resolution::Union{Nothing, Tuple{Int, Int}} = nothing)::Makie.Figure

        bitmask = build_bitmask(datacube[:, :, timestep], accepted_values; set_nan = set_nan)

        fig = isnothing(resolution) ?  Figure() : Figure(resolution = resolution)

        lon = YAXArrays.getAxis("lon", datacube).values |> extrema 
        lat = YAXArrays.getAxis("lat", datacube).values |> extrema
        lonrange = range(lon[1], lon[end], size(bitmask, 1))

        # we need to flip the latitude because of an error in the datacube!
        latrange = range(lat[1], lat[end], size(bitmask, 2))[end:-1:1]

        if local_map
            ga = local_geoaxis_creation!(fig, lon, lat, lonpadding, latpadding)
            surface!(ga, lonrange, latrange, bitmask; shading = shading, colormap = colormap, colorrange = colorrange)
        else
            projection = "+proj=lonlat"
            ga = GeoMakie.GeoAxis(
                fig[1, 1]; # any cell of the figure's layout
                dest = projection,
                source = projection,
                coastlines = true # plot coastlines from Natural Earth, as a reference.
            )

            surface!(ga, lonrange, latrange, bitmask; shading = shading, colormap = colormap, colorrange = colorrange)

        end

        return fig
    end

    # create a figure using the categories
    function build_figure_by_categories(
        datacube, 
        categories::Set{LCCSClasses.Category};
        local_map::Bool = true,
        timestep::Int = 1,
        lonpadding::Float64 = 1.0, 
        latpadding::Float64 = 1.0,
        colormap = :viridis,
        colorrange::Tuple{<:Real, <:Real} = (0, 1), 
        shading::Bool = false,
        resolution::Union{Nothing, Tuple{Int, Int}} = nothing)::Makie.Figure


        bitmask = build_selected_categorial_mask(datacube[:, :, timestep], categories)
        
        fig = isnothing(resolution) ?  Figure() : Figure(resolution = resolution)

        lon = YAXArrays.getAxis("lon", datacube).values |> extrema 
        lat = YAXArrays.getAxis("lat", datacube).values |> extrema
        lonrange = range(lon[1], lon[end], size(bitmask, 1))

        # we need to flip the latitude because of an error in the datacube!
        latrange = range(lat[1], lat[end], size(bitmask, 2))[end:-1:1]

        if local_map
            ga = local_geoaxis_creation!(fig, lon, lat, lonpadding, latpadding)
            surface!(ga, lonrange, latrange, bitmask; shading = shading, colormap = colormap, colorrange = colorrange)
        else
            projection = "+proj=lonlat"
            ga = GeoMakie.GeoAxis(
                fig[1, 1]; # any cell of the figure's layout
                dest = projection,
                source = projection,
                coastlines = true # plot coastlines from Natural Earth, as a reference.
            )

            surface!(ga, lonrange, latrange, bitmask; shading = shading, colormap = colormap, colorrange = colorrange)

        end

        return fig
    end
    # create geographical axes
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

    # bimask for all available classes
    function build_bitmask_all_classes(datacube; set_nan::Bool = false)::Matrix
    
        return set_nan ?  Rainforestlib_utils.replace_zero_with_nan.(LCCSClasses.flag_to_category_val.(datacube)) : LCCSClasses.flag_to_category_val.(datacube)
    end


    # figure for all classes
    function build_figure_all_classes(
        datacube; 
        local_map::Bool = true,
        timestep::Int = 1,
        lonpadding::Float64 = 1.0, 
        latpadding::Float64 = 1.0,
        colormap = :viridis, 
        colorrange::Tuple{<:Real, <:Real} = (0, 1),
        shading::Bool = false,
        resolution::Union{Nothing, Tuple{Int, Int}} = nothing,
        set_nan::Bool = false)::Makie.Figure

        bitmask = build_bitmask_all_classes(datacube[:, :, timestep], set_nan = set_nan)

        fig = isnothing(resolution) ?  Figure() : Figure(resolution = resolution)

        lon = YAXArrays.getAxis("lon", datacube).values |> extrema 
        lat = YAXArrays.getAxis("lat", datacube).values |> extrema
        lonrange = range(lon[1], lon[end], size(bitmask, 1))

        # we need to flip the latitude because of an error in the datacube!
        latrange = range(lat[1], lat[end], size(bitmask, 2))[end:-1:1]

        if local_map
            ga = local_geoaxis_creation!(fig, lon, lat, lonpadding, latpadding)
            surface!(ga, lonrange, latrange, bitmask; shading = shading, colormap = colormap, colorrange = colorrange)
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
    # get plots for each step/year
    function build_plots_over_time(
        datacube,
        accepted_values::Set{String}; 
        lonpadding::Float64 = 1.0, 
        latpadding::Float64 = 1.0,
        colormap = :viridis,
        colorrange::Tuple{<:Real, <:Real} = (0, 1),
        shading::Bool = false,
        resolution::Union{Nothing, Tuple{Int, Int}} = Nothing,
        set_nan::Bool = false)::Makie.Figure


        fig = isnothing(resolution) ?  Figure() : Figure(resolution = resolution)

        timesteps = YAXArrays.getAxis("time", datacube).values

        last = 0.0

        # 3 is the time dimension
        for t in range(1, length(timesteps))
            y_val = (t % 3) 
            x_val = t ÷ 3

            year = timesteps[t]

            bitmask = build_bitmask(datacube[:, :, t], accepted_values; set_nan = set_nan)

            number_of_rf_pixels = sum(filter(!isnan, bitmask))
            

            println("Number of rainforest pixels in $(year): $(number_of_rf_pixels)")
            println("Diff to last: $(number_of_rf_pixels - last)")

            last = number_of_rf_pixels

            lon = YAXArrays.getAxis("lon", datacube).values |> extrema 
            lat = YAXArrays.getAxis("lat", datacube).values |> extrema
            lonrange = range(lon[1], lon[end], size(bitmask, 1))

            # we need to flip the latitude because of an error in the datacube!
            latrange = range(lat[1], lat[end], size(bitmask, 2))[end:-1:1]

            ga = local_geoaxis_creation!(fig, lon, lat; lonpadding = lonpadding, latpadding = latpadding, figure_x = x_val, figure_y = y_val, title = "Plot $(year)")
            surface!(ga, lonrange, latrange, bitmask; shading = shading, colormap = colormap, colorrange = colorrange)
        
        end
        
        return fig
    end
    # create plots with pixel differences
    function build_diff_figure(
        datacube,
        timestep::Int,
        previous_mask::Union{Nothing, Matrix},
        tracked_category::LCCSClasses.Category;
        lonpadding::Float64 = 1.0, 
        latpadding::Float64 = 1.0,
        colormap = :viridis,
        colorrange::Tuple{<:Real, <:Real} = (0, 3), 
        shading::Bool = false,
        resolution::Union{Nothing, Tuple{Int, Int}} = nothing
        )::Tuple{Figure, Matrix}

        timesteps = YAXArrays.getAxis("time", datacube).values

        year = timesteps[timestep]

        # cant use set NaN here because NaN != NaN
        bitmask::Matrix = build_bitmask(datacube[:, :, timestep], tracked_category; set_nan = false)

        # if there is no previous mask use identity as diff
        if isnothing(previous_mask)
            previous_mask = bitmask
        end

        diff_bitmask = Rainforestlib_utils.diff_matrices(bitmask, previous_mask) do new, old
            if old == new
                return old
            else
                if new > old
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

        fig = isnothing(resolution) ?  Figure() : Figure(resolution = resolution)

        # we need to flip the latitude because of an error in the datacube!
        latrange = range(lat[1], lat[end], size(diff_bitmask, 2))[end:-1:1]

        ga = local_geoaxis_creation!(fig, lon, lat; lonpadding = lonpadding, latpadding = latpadding, title = "Plot $(year)")
        surface!(ga, lonrange, latrange, diff_bitmask; shading = shading, colormap = colormap, colorrange = colorrange)

        return fig, bitmask
    end


    # pixel differences over the years
    function build_diff_figures_over_time(
        datacube,
        tracked_category::LCCSClasses.Category,
        target_path::String;
        name_base::String = "figure", 
        lonpadding::Float64 = 1.0, 
        latpadding::Float64 = 1.0,
        colorrange::Tuple{<:Real, <:Real} = (0, 3), 
        shading::Bool = false,
        gradual_diff::Bool = false,
        resolution::Union{Nothing, Tuple{Int, Int}} = nothing
    )::Nothing
        # build one figure with diffs for each timestep
        timesteps = YAXArrays.getAxis("time", datacube).values

        if gradual_diff
            last_bitmask = nothing
        else
            # set it to the first bitmask and dont change it anymore
            last_bitmask = build_bitmask(datacube[:, :, 1], tracked_category; set_nan = false)
        end

        colormap = [
            RGB(1.0, 1.0, 1.0),  # White
            RGB(0.0, 1.0, 0.0),  # Green
            RGB(0.0, 0.0, 1.0),  # Blue
            RGB(1.0, 0.0, 0.0),  # Red
        ]
        
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
                resolution = resolution,
                colorrange = colorrange
            )

            if gradual_diff
                last_bitmask = new_bitmask
            end

            save(filename, figure)
        end
    end


    # how many pixels have been replaced
    function count_replacement(old_flag_matrix::Matrix{UInt8}, new_flag_matrix::Matrix{UInt8}, tracked_category::LCCSClasses.Category; reverse::Bool = false)::Dict{UInt8, Int64}
        # it is assumed that both have the same size
    
        result = Dict()

        function check_if_replacement(tracked_value::UInt8, other_value::UInt8, tracked_category::LCCSClasses.Category)
            # checks if the values are unequal, if the tracked values is in the tracked category and if the other value is not in the tracked category
            return tracked_value != other_value && tracked_value in tracked_category.lccs_flags && !(other_value in tracked_category.lccs_flags)
        end
    
        (rows, cols) = size(old_flag_matrix)
        for row in 1:rows
            for col in 1:cols
                if reverse
                    tracked_compared_value = new_flag_matrix[row, col]
                    other_value = old_flag_matrix[row, col]
                else
                    tracked_compared_value = old_flag_matrix[row, col]
                    other_value = new_flag_matrix[row, col]
                end
                
                
                if check_if_replacement(tracked_compared_value, other_value, tracked_category)
    
                    if other_value in keys(result)
                        result[other_value] += 1
                    else
                        result[other_value] = 1
                    end
                end
            end
        end
    
        return result
    
    end
    # get data of what was replaced
    function get_replacement_data(
        datacube,
        timestep::Int,
        tracked_category::LCCSClasses.Category;
        reverse::Bool = false
    )::Tuple{Vector{Int}, Vector{Int}, Vector{Int}, Vector{UInt8}}

        
        # step number is aways one smaller then the start
        step = timestep - 1
    
        results_dict = count_replacement(datacube[:, :, timestep-1], datacube[:, :, timestep], tracked_category; reverse = reverse)
    
        sorted_result_keys = sort!([k for k in keys(results_dict)])
    
    
        x_vals = fill(step, length(sorted_result_keys))
    
        y_vals = [results_dict[k] for k in sorted_result_keys]
    
        grp = 1:length(sorted_result_keys)
    
    
        return (x_vals, y_vals, grp, sorted_result_keys)
    
    end

    # create figures to show what was replaced
    function build_replacement_figure(
        datacube,
        tracked_category::LCCSClasses.Category;
        resolution::Union{Nothing, Tuple{Int, Int}} = nothing,
        reverse::Bool = false
    )::Makie.Figure
    
        timesteps = YAXArrays.getAxis("time", datacube).values
    
    
        fig = isnothing(resolution) ?  Figure() : Figure(resolution = resolution)
    
        x_vals = Vector{Int}()
        y_vals = Vector{Int}()
        gpr_vals = Vector{Int}()
        color_mapping_vals = Vector{Int}()
    
        xaxis_names = Vector{String}()

    
        for timestep in eachindex(timesteps)

            if timestep == 1
                # there is no diff for the first time step
                continue
            end
            
            old_year = timesteps[timestep-1]
            new_year = timesteps[timestep]

            push!(xaxis_names, string(year(old_year)) * " to " * string(year(new_year)))

            x, y, gpr, color_mappings = get_replacement_data(
                datacube,
                timestep,
                tracked_category;
                reverse = reverse
            )

            x_vals = [x_vals; x]
            y_vals = [y_vals; y]
            gpr_vals = [gpr_vals; gpr]
            color_mapping_vals = [color_mapping_vals; color_mappings]
            
        end   

        colors = ColorSchemes.tab20

        # colors = Makie.wong_colors()

        
        ax = Axis(
            fig[1,1], 
            xticks = (1:length(xaxis_names), xaxis_names),
            title = "Replacement of Rainforest pixels by year"
        )
    
        

        # Creating a legend

        sorted_possible_vals = sort([k for k in Set(color_mapping_vals)])

        color_index_mapping = Dict([v => i for (i, v) in enumerate([k for k in sorted_possible_vals])])

        labels = LCCSClasses.get_lccs_name.(UInt8.(sorted_possible_vals))

        elements = [PolyElement(polycolor = colors[i]) for (i, _) in enumerate(labels)]

        title = "LCCS Classes"


        # generate the barplot

        barplot!(
            ax,
            x_vals,
            y_vals,
            dodge = gpr_vals,
            color = colors[[color_index_mapping[v] for v in color_mapping_vals]],
        )

        Legend(fig[1,2], elements, labels, title)
    
        return fig
    end

    # create rainforest pixl differences for our period
    function rainforest_diff_over_time(
        datacube,
        tracked_category::LCCSClasses.Category; 
        resolution::Union{Nothing, Tuple{Int, Int}} = Nothing,
        gradual_diff::Bool = false,
        )::Makie.Figure


        fig = isnothing(resolution) ?  Figure() : Figure(resolution = resolution)

        timesteps = YAXArrays.getAxis("time", datacube).values

        

        colormap = [
            RGB(0.0, 1.0, 0.0),  # Green
            RGB(1.0, 0.0, 0.0),  # Red
        ]

        
        # set it to the first bitmask and dont change it anymore
        last_bitmask = build_bitmask(datacube[:, :, 1], tracked_category; set_nan = false)
        

        x_vals = Vector{Int}()
        y_vals = Vector{Int}()
        grp_vals = Vector{Int}()

        xaxis_names = Vector{String}()

        last_raw_count = 0.0

        # 3 is the time dimension
        for t in eachindex(timesteps)

            current_year = timesteps[t]

            push!(xaxis_names, string(year(current_year)))

            bitmask = build_bitmask(datacube[:, :, t], tracked_category; set_nan = false)

            diff_bitmask = Rainforestlib_utils.diff_matrices(bitmask, last_bitmask) do new, old
                if old == new
                    return old
                else
                    if new > old
                        # this means something got added
                        return Float32(2)
                    else
                        # this means something previously selected got unselected
                        return Float32(3)
                    end
                end
            end

            raw_tracked_number = sum(filter(!isnan, bitmask))
            
            added_vals = sum(map(diff_bitmask) do x
                if x == 2
                    return 1
                else
                    0
                end                
            end)

            removed_vals = sum(map(diff_bitmask) do x
                if x == 3
                    return 1
                else
                    0
                end                
            end)


            append!(x_vals, [t, t])
            append!(y_vals, [added_vals, removed_vals])
            append!(grp_vals, [1, 2])

            println("Number of rainforest pixels in $(year(current_year)): $(raw_tracked_number)")
            println("Diff to last: $(raw_tracked_number - last_raw_count)")

            last_raw_count = raw_tracked_number

            if gradual_diff
                last_bitmask = bitmask
            end
        
        end

        ax = Axis(
            fig[1,1], 
            xticks = (1:length(xaxis_names), xaxis_names),
            title = "Change of Rainforest pixels by year"
        )

        labels = ["added values", "removed values"]
        elements = [PolyElement(polycolor = color) for color in colormap]
        title = "Change Types"

        Legend(fig[1,2], elements, labels, title)

        barplot!(
            ax,
            x_vals,
            y_vals,
            dodge = grp_vals,
            color = grp_vals,
            colormap = colormap
        )
        
        return fig
    end
end