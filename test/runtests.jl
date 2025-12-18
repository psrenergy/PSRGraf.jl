using PSRGraf
using CSV
using DataFrames
using Test

include("utils.jl")

@testset begin 
    @testset "OpenBinary file format" begin
        @testset "Read and write with monthly data" begin
            @time include("read_and_write_blocks.jl")
        end
        @testset "Read and write with hourly data" begin
            @time include("read_and_write_binary_hourly.jl")
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
    @testset "OpenCSV file format" begin
        @testset "Read and write with monthly data" begin 
            @time include("read_and_write_csv_monthly.jl")
        end
        @testset "Read and write with hourly data" begin 
            @time include("read_and_write_csv_hourly.jl")
        end
        @testset "Utils" begin 
            @time include("time_series_utils.jl")
        end
        @testset "Issues" begin 
            @time include("issues.jl")
        end
    end
end
