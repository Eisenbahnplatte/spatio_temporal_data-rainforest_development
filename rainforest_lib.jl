module RainforestLib

    using Zarr
    using YAXArrays
    using DotEnv

    DotEnv.config()

    sample_cube_dir = "./sample_cubes"

    
    
    function get_lcc_datacube()
        zarr = Zarr.zopen(ENV["ZARR_PATH"])
        lc_dataset = YAXArrays.open_dataset(zarr)
        return lc_dataset[:lccs_class]
    end


    function rough_spatial_filter(cube, lon_bounds = (30,90), lat_bounds = (-30, 15), time_bounds = (Date(2010), Date(2012)))

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

end