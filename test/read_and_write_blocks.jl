function read_write_binary_block()
    BLOCKS = 3
    SCENARIOS = 5
    STAGES = 12
    INITIAL_STAGE = 4

    FILE_PATH = joinpath(".", "example_21")

    for stage_type in [PSRGraf.STAGE_MONTH, PSRGraf.STAGE_WEEK, PSRGraf.STAGE_DAY]
        iow = PSRGraf.open(
            PSRGraf.BinaryWriter,
            FILE_PATH;
            blocks = BLOCKS,
            scenarios = SCENARIOS,
            stages = STAGES,
            agents = ["X", "Y", "Z"],
            unit = "MW",
            # optional:
            initial_stage = INITIAL_STAGE,
            initial_year = 2006,
            stage_type = stage_type,
        )

        for t in 1:STAGES, s in 1:SCENARIOS, b in 1:BLOCKS
            X = t + s + 0.0
            Y = s - t + 0.0
            Z = t + s + b * 100.0
            PSRGraf.write_registry(iow, [X, Y, Z], t, s, b)
        end

        # Finaliza gravacao
        PSRGraf.close(iow)

        ior = PSRGraf.open(
            PSRGraf.BinaryReader,
            FILE_PATH;
            use_header = false,
        )

        @test PSRGraf.max_stages(ior) == STAGES
        @test PSRGraf.max_scenarios(ior) == SCENARIOS
        @test PSRGraf.max_blocks(ior) == BLOCKS
        @test PSRGraf.stage_type(ior) == stage_type
        @test PSRGraf.initial_stage(ior) == INITIAL_STAGE
        @test PSRGraf.initial_year(ior) == 2006
        @test PSRGraf.data_unit(ior) == "MW"
        @test PSRGraf.is_hourly(ior) == false

        # obtem número de colunas
        @test PSRGraf.agent_names(ior) == ["X", "Y", "Z"]

        for t in 1:STAGES, s in 1:SCENARIOS, b in 1:BLOCKS
            @test PSRGraf.current_stage(ior) == t
            @test PSRGraf.current_scenario(ior) == s
            @test PSRGraf.current_block(ior) == b
            X = t + s
            Y = s - t
            Z = t + s + b * 100
            ref = [X, Y, Z]
            for agent in 1:3
                @test ior[agent] == ref[agent]
            end
            PSRGraf.next_registry(ior)
        end

        PSRGraf.close(ior)
        ior = nothing

    end

    rm(FILE_PATH * ".bin")
    rm(FILE_PATH * ".hdr")

    return
end

function read_write_binary_block_single_binary()
    BLOCKS = 3
    SCENARIOS = 5
    STAGES = 12
    INITIAL_STAGE = 4

    FILE_PATH = joinpath(".", "example_2")

    for stage_type in [PSRGraf.STAGE_MONTH, PSRGraf.STAGE_WEEK, PSRGraf.STAGE_DAY]
        iow = PSRGraf.open(
            PSRGraf.BinaryWriter,
            FILE_PATH;
            blocks = BLOCKS,
            scenarios = SCENARIOS,
            stages = STAGES,
            agents = ["X", "Y", "Z"],
            unit = "MW",
            # optional:
            initial_stage = INITIAL_STAGE,
            initial_year = 2006,
            stage_type = stage_type,
            single_binary = true,
        )
        @test first(splitext(PSRGraf.file_path(iow))) == FILE_PATH

        for t in 1:STAGES, s in 1:SCENARIOS, b in 1:BLOCKS
            X = t + s + 0.0
            Y = s - t + 0.0
            Z = t + s + b * 100.0
            PSRGraf.write_registry(iow, [X, Y, Z], t, s, b)
        end

        # Finaliza gravacao
        PSRGraf.close(iow)

        ior = PSRGraf.open(
            PSRGraf.BinaryReader,
            FILE_PATH;
            use_header = false,
            single_binary = true,
        )
        @test first(splitext(PSRGraf.file_path(ior))) == FILE_PATH

        @test PSRGraf.max_stages(ior) == STAGES
        @test PSRGraf.max_scenarios(ior) == SCENARIOS
        @test PSRGraf.max_blocks(ior) == BLOCKS
        @test PSRGraf.stage_type(ior) == stage_type
        @test PSRGraf.initial_stage(ior) == INITIAL_STAGE
        @test PSRGraf.initial_year(ior) == 2006
        @test PSRGraf.data_unit(ior) == "MW"
        @test PSRGraf.is_hourly(ior) == false

        # obtem número de colunas
        @test PSRGraf.agent_names(ior) == ["X", "Y", "Z"]

        for t in 1:STAGES, s in 1:SCENARIOS, b in 1:BLOCKS
            @test PSRGraf.current_stage(ior) == t
            @test PSRGraf.current_scenario(ior) == s
            @test PSRGraf.current_block(ior) == b
            X = t + s
            Y = s - t
            Z = t + s + b * 100
            ref = [X, Y, Z]
            for agent in 1:3
                @test ior[agent] == ref[agent]
            end
            PSRGraf.next_registry(ior)
        end

        PSRGraf.close(ior)
        ior = nothing
    end

    rm(FILE_PATH * ".dat")

    return
end

read_write_binary_block()
read_write_binary_block_single_binary()
