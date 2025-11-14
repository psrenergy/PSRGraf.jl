function test_read_and_write_hourly()
    path = joinpath(".", "data", "hourly")

    stages = 3
    scenarios = 2
    agents = ["X", "Y", "Z"]
    unit = "MW"
    stage_type = PSRGraf.STAGE_MONTH
    initial_stage = 2
    initial_year = 2006

    gerter = PSRGraf.open(
        PSRGraf.CSVWriter,
        path,
        is_hourly = true,
        scenarios = scenarios,
        stages = stages,
        agents = agents,
        unit = unit,
        # optional:
        stage_type = stage_type,
        initial_stage = initial_stage,
        initial_year = initial_year,
    )

    for stage in 1:stages
        for scenario in 1:scenarios
            for block in 1:PSRGraf.blocks_in_stage(gerter, stage)
                X = 10_000.0 * stage + 1000.0 * scenario + block
                Y = block + 0.0
                Z = 10.0 * stage + scenario
                PSRGraf.write_registry(
                    gerter,
                    [X, Y, Z],
                    stage,
                    scenario,
                    block,
                )
            end
        end
    end

    PSRGraf.close(gerter)

    ior = PSRGraf.open(
        PSRGraf.CSVReader,
        path,
        is_hourly = true,
    )

    @test PSRGraf.max_stages(ior) == stages
    @test PSRGraf.max_scenarios(ior) == scenarios
    @test PSRGraf.max_blocks(ior) == 744
    @test PSRGraf.stage_type(ior) == stage_type
    @test PSRGraf.initial_stage(ior) == initial_stage
    @test PSRGraf.initial_year(ior) == initial_year
    @test PSRGraf.data_unit(ior) == unit
    @test PSRGraf.agent_names(ior) == agents

    for stage in 1:stages
        for scenario in 1:scenarios
            for block in 1:PSRGraf.blocks_in_stage(ior, stage)
                @test PSRGraf.current_stage(ior) == stage
                @test PSRGraf.current_scenario(ior) == scenario
                @test PSRGraf.current_block(ior) == block

                X = 10_000.0 * stage + 1000.0 * scenario + block
                Y = block + 0.0
                Z = 10.0 * stage + scenario
                ref = [X, Y, Z]

                for agent in 1:3
                    @test ior[agent] == ref[agent]
                end

                PSRGraf.next_registry(ior)
            end
        end
    end

    PSRGraf.close(ior)
    ior = nothing
    GC.gc()
    GC.gc()

    safe_remove(path * ".csv")

    return nothing
end

test_read_and_write_hourly()
