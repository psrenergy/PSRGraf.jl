function test_read_and_write_monthly()
    path = joinpath(".", "data", "monthly")

    stages = 12
    blocks = 3
    scenarios = 4
    agents = ["X", "Y", "Z"]
    stage_type = PSRGraf.STAGE_MONTH
    initial_stage = 1
    initial_year = 2006
    unit = "MW"

    iow = PSRGraf.open(
        PSRGraf.CSVWriter,
        path,
        blocks = blocks,
        scenarios = scenarios,
        stages = stages,
        agents = agents,
        unit = unit,
        # optional:
        stage_type = stage_type,
        initial_stage = initial_stage,
        initial_year = initial_year,
    )

    for stage in 1:stages, scenario in 1:scenarios, block in 1:blocks
        X = stage + scenario + 0.0
        Y = scenario - stage + 0.0
        Z = stage + scenario + block * 100.0
        PSRGraf.write_registry(
            iow,
            [X, Y, Z],
            stage,
            scenario,
            block,
        )
    end

    PSRGraf.close(iow)

    ior = PSRGraf.open(
        PSRGraf.CSVReader,
        path,
    )

    @test PSRGraf.max_stages(ior) == stages
    @test PSRGraf.max_scenarios(ior) == scenarios
    @test PSRGraf.max_blocks(ior) == blocks
    @test PSRGraf.stage_type(ior) == stage_type
    @test PSRGraf.initial_stage(ior) == initial_stage
    @test PSRGraf.initial_year(ior) == initial_year
    @test PSRGraf.data_unit(ior) == unit
    @test PSRGraf.agent_names(ior) == agents

    for stage in 1:stages
        for scenario in 1:scenarios
            for block in 1:blocks
                @test PSRGraf.current_stage(ior) == stage
                @test PSRGraf.current_scenario(ior) == scenario
                @test PSRGraf.current_block(ior) == block

                X = stage + scenario
                Y = scenario - stage
                Z = stage + scenario + block * 100
                ref = [X, Y, Z]

                for agent in 1:3
                    @test ior[agent] == ref[agent]
                end
                PSRGraf.next_registry(ior)
            end
        end
    end

    PSRGraf.close(ior)

    @test_throws ErrorException PSRGraf.convert_file(
        PSRGraf.CSVReader,
        PSRGraf.CSVWriter,
        path,
    )

    ior = nothing

    safe_remove(path * ".csv")

    return nothing
end

test_read_and_write_monthly()