module RainforestLib

    using Zarr
    using YAXArrays
    using DotEnv

    DotEnv.config()


    function load_full_datacube()
        c1_zarr = Zarr.zopen(ENV["ZARR_PATH"])
        c1_dataset = YAXArrays.open_dataset(c1_zarr)
        return YAXArrays.Cube(c1_dataset)
    end

end