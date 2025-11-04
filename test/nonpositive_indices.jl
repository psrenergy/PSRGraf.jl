function test_nonpositive_indices()
    path = joinpath(@__DIR__, "data", "case5", "inflow")

    io_r = PSRGrafBinary.open(PSRGrafBinary.Reader, path; use_header = false)

    @test io_r isa PSRGrafBinary.Reader
    @test io_r.initial_stage == 5
    @test io_r.first_stage == -2
    @test io_r.relative_stage_skip == 0
    @test PSRGrafBinary._get_position(
        io_r,
        io_r.first_stage,
        1,
        1,
    ) == 0

    src_table = CSV.read(
        "$path.csv", DataFrames.DataFrame;
        header = 4,
        skipto = 5,
    )

    @testset "Read" begin
        @test PSRGrafBinary.goto(io_r, -2, 1, 1) === nothing

        @test_throws AssertionError PSRGrafBinary.goto(io_r, -3, 1, 1)

        # TODO Test read
    end

    temp_path = tempname()

    io_w = PSRGrafBinary.open(
        PSRGrafBinary.Writer,
        temp_path;
        first_stage = -2,
        unit = io_r.unit,
        stages = io_r.stage_total,
        blocks = io_r.block_total,
        scenarios = io_r.scenario_total,
        agents = io_r.agent_names,
    )

    @testset "Write" begin
        @test io_w.first_stage == -2

        for row in eachrow(src_table)
            t, s, b, data... = row

            cache = collect(Float64, data)

            PSRGrafBinary.write_registry(io_w, cache, t, s, b)
        end
    end

    PSRGrafBinary.close(io_w)
    PSRGrafBinary.close(io_r)

    return nothing
end

test_nonpositive_indices()
