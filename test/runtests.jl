using PSRGraf
using CSV
using DataFrames
using Test

@testset "OpenBinary file format" begin
    @testset "Read and write with monthly data" begin
        @time include("read_and_write_blocks.jl")
    end
    @testset "Read and write with hourly data" begin
        @time include("read_and_write_hourly.jl")
    end
    @testset "Read subhourly data" begin
        @time include("read_subhourly.jl")
    end
    @testset "Read data with Nonpositive Indices" begin
        @time include("nonpositive_indices.jl")
    end
    @testset "Write file partially" begin
        @time include("incomplete_file.jl")
    end
    @testset "Use header" begin
        @time include("use_header.jl")
    end
end