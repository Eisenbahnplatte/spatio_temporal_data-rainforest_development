#!/bin/sh

julia -e 'using Pkg; Pkg.activate("."); Pkg.add(PackageSpec(name = "JLLWrappers", version = "1.5.0")); Pkg.add(PackageSpec(name = "Parsers", version = "2.7.2"));'