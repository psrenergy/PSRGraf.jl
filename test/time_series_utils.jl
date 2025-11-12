function test_non_unique_agents()
    path = joinpath(".", "data", "example_non_unique_agents")
    @test_throws ErrorException iow = PSRGraf.open(
        PSRGraf.CSVWriter,
        path,
        blocks = 3,
        scenarios = 4,
        stages = 5,
        agents = ["X", "Y", "X"],
        unit = "MW",
        # optional:
        initial_stage = 1,
        initial_year = 2006,
    )
end

function test_convert_twice()
    path1 = joinpath(".", "data", "convert_1")
    path2 = joinpath(".", "data", "convert_2")

    blocks = 3
    scenarios = 10
    stages = 12

    iow = PSRGraf.open(
        PSRGraf.BinaryWriter,
        path1,
        blocks = blocks,
        scenarios = scenarios,
        stages = stages,
        agents = ["X", "Y", "Z"],
        unit = "MW",
        # optional:
        initial_stage = 1,
        initial_year = 2006,
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

    PSRGraf.convert_file(
        PSRGraf.BinaryReader,
        PSRGraf.CSVWriter,
        path1,
    )

    ior = PSRGraf.open(
        PSRGraf.CSVReader,
        path1,
        use_header = false,
    )

    @test PSRGraf.max_stages(ior) == stages
    @test PSRGraf.max_scenarios(ior) == scenarios
    @test PSRGraf.max_blocks(ior) == blocks
    @test PSRGraf.stage_type(ior) == PSRGraf.STAGE_MONTH
    @test PSRGraf.initial_stage(ior) == 1
    @test PSRGraf.initial_year(ior) == 2006
    @test PSRGraf.data_unit(ior) == "MW"

    @test PSRGraf.agent_names(ior) == ["X", "Y", "Z"]

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
    ior = nothing

    PSRGraf.convert_file(
        PSRGraf.CSVReader,
        PSRGraf.BinaryWriter,
        path1,
        path_to = path2,
    )

    ior = PSRGraf.open(
        PSRGraf.BinaryReader,
        path2,
        use_header = false,
    )

    @test PSRGraf.max_stages(ior) == stages
    @test PSRGraf.max_scenarios(ior) == scenarios
    @test PSRGraf.max_blocks(ior) == blocks
    @test PSRGraf.stage_type(ior) == PSRGraf.STAGE_MONTH
    @test PSRGraf.initial_stage(ior) == 1
    @test PSRGraf.initial_year(ior) == 2006
    @test PSRGraf.data_unit(ior) == "MW"

    @test PSRGraf.agent_names(ior) == ["X", "Y", "Z"]

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

    safe_remove("$path1.bin")
    safe_remove("$path1.hdr")

    safe_remove("$path2.bin")
    safe_remove("$path2.hdr")
    
    safe_remove("$path1.csv")

    return nothing
end

function test_file_to_array()
    blocks = 3
    scenarios = 10
    stages = 12

    path = joinpath(".", "data", "example_array_1")
    iow = PSRGraf.open(
        PSRGraf.BinaryWriter,
        path,
        blocks = blocks,
        scenarios = scenarios,
        stages = stages,
        agents = ["X", "Y", "Z"],
        unit = "MW",
        # optional:
        initial_stage = 1,
        initial_year = 2006,
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

    data, header = PSRGraf.file_to_array_and_header(
        PSRGraf.BinaryReader,
        path;
        use_header = false,
    )

    data_order, header_order = PSRGraf.file_to_array_and_header(
        PSRGraf.BinaryReader,
        path;
        use_header = true,
        header = ["Y", "Z", "X"],
    )

    @test data == PSRGraf.file_to_array(
        PSRGraf.BinaryReader,
        path;
        use_header = false,
    )

    @test data_order == PSRGraf.file_to_array(
        PSRGraf.BinaryReader,
        path;
        use_header = true,
        header = ["Y", "Z", "X"],
    )

    @test data_order[1] == data[2] # "Y"
    @test data_order[2] == data[3] # "Z"
    @test data_order[3] == data[1] # "X"

    PSRGraf.array_to_file(
        PSRGraf.CSVWriter,
        path,
        data,
        agents = header,
        unit = "MW",
        initial_year = 2006,
    )

    ior = PSRGraf.open(
        PSRGraf.CSVReader,
        path,
        use_header = false,
    )

    @test PSRGraf.max_stages(ior) == stages
    @test PSRGraf.max_scenarios(ior) == scenarios
    @test PSRGraf.max_blocks(ior) == blocks
    @test PSRGraf.stage_type(ior) == PSRGraf.STAGE_MONTH
    @test PSRGraf.initial_stage(ior) == 1
    @test PSRGraf.initial_year(ior) == 2006
    @test PSRGraf.data_unit(ior) == "MW"

    @test PSRGraf.agent_names(ior) == ["X", "Y", "Z"]

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
    ior = nothing

    safe_remove("$path.bin")
    safe_remove("$path.hdr")
    safe_remove("$path.csv")

    return nothing
end

function test_time_series_utils()
    test_non_unique_agents()
    # test_convert_twice()
    test_file_to_array()
    return nothing
end

test_time_series_utils()