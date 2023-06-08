using Zarr
using YAXArrays
using DotEnv

DotEnv.config()

# testing environment

println(ENV["ZARR_PATH"])
