function read_write_binary_hourly()
    FILE_GERTER = joinpath(".", "gerter")

    STAGES = 2
    SCENARIOS = 2
    AGENTS = ["X", "Y", "Z"]
    UNIT = "MW"

    for stage_type in [PSRGrafBinary.STAGE_MONTH, PSRGrafBinary.STAGE_WEEK, PSRGrafBinary.STAGE_DAY]
        gerter = PSRGrafBinary.open(
            PSRGrafBinary.Writer,
            FILE_GERTER;
            is_hourly = true,
            scenarios = SCENARIOS,
            stages = STAGES,
            agents = AGENTS,
            unit = UNIT,
            # optional:
            initial_stage = 2,
            initial_year = 2006,
            stage_type = stage_type,
        )

        for t in 1:STAGES, s in 1:SCENARIOS
            for b in 1:PSRGrafBinary.blocks_in_stage(gerter, t)
                X = 10_000.0 * t + 1000.0 * s + b
                Y = b + 0.0
                Z = 10.0 * t + s
                PSRGrafBinary.write_registry(
                    gerter,
                    [X, Y, Z],
                    t,
                    s,
                    b,
                )
            end
        end

        PSRGrafBinary.close(gerter)

        ior = PSRGrafBinary.open(
            PSRGrafBinary.Reader,
            FILE_GERTER;
            use_header = false,
        )

        @test PSRGrafBinary.max_stages(ior) == STAGES
        @test PSRGrafBinary.max_scenarios(ior) == SCENARIOS
        @test PSRGrafBinary.max_blocks(ior) ==
              (stage_type == PSRGrafBinary.STAGE_MONTH ? 744 : PSRGrafBinary.HOURS_IN_STAGE[stage_type])
        @test PSRGrafBinary.stage_type(ior) == stage_type
        @test PSRGrafBinary.initial_stage(ior) == 2
        @test PSRGrafBinary.initial_year(ior) == 2006
        @test PSRGrafBinary.data_unit(ior) == "MW"
        @test PSRGrafBinary.agent_names(ior) == ["X", "Y", "Z"]
        @test PSRGrafBinary.is_hourly(ior) == true
        @test PSRGrafBinary.hour_discretization(ior) == 1

        for t in 1:1, s in 1:1
            @test PSRGrafBinary.blocks_in_stage(ior, t) <= PSRGrafBinary.max_blocks(ior)
            for b in 1:PSRGrafBinary.blocks_in_stage(ior, t)
                @test PSRGrafBinary.current_stage(ior) == t
                @test PSRGrafBinary.current_scenario(ior) == s
                @test PSRGrafBinary.current_block(ior) == b
                X = 10_000.0 * t + 1000.0 * s + b
                Y = b + 0.0
                Z = 10.0 * t + s
                ref = [X, Y, Z]
                for agent in 1:3
                    @test ior[agent] == ref[agent]
                end
                PSRGrafBinary.next_registry(ior)
            end
        end

        PSRGrafBinary.close(ior)
        ior = nothing
    end

    rm(FILE_GERTER * ".bin")
    rm(FILE_GERTER * ".hdr")
    return
end

function read_write_binary_subhourly()
    FILE_GERTER = joinpath(".", "gerter")

    STAGES = 2
    SCENARIOS = 2
    AGENTS = ["X", "Y", "Z"]
    UNIT = "MW"

    for stage_type in [PSRGrafBinary.STAGE_MONTH, PSRGrafBinary.STAGE_WEEK, PSRGrafBinary.STAGE_DAY]
        for hour_discretization in [2, 3, 4, 6, 12]
            gerter = PSRGrafBinary.open(
                PSRGrafBinary.Writer,
                FILE_GERTER;
                is_hourly = true,
                hour_discretization = hour_discretization,
                scenarios = SCENARIOS,
                stages = STAGES,
                agents = AGENTS,
                unit = UNIT,
                # optional:
                initial_stage = 2,
                initial_year = 2006,
                stage_type = stage_type,
            )

            for t in 1:STAGES, s in 1:SCENARIOS
                for b in 1:PSRGrafBinary.blocks_in_stage(gerter, t)
                    X = 10_000.0 * t + 1000.0 * s + b
                    Y = b + 0.0
                    Z = 10.0 * t + s
                    PSRGrafBinary.write_registry(gerter, [X, Y, Z], t, s, b)
                end
            end

            PSRGrafBinary.close(gerter)

            ior = PSRGrafBinary.open(PSRGrafBinary.Reader, FILE_GERTER; use_header = false)

            @test PSRGrafBinary.max_stages(ior) == STAGES
            @test PSRGrafBinary.max_scenarios(ior) == SCENARIOS
            @test PSRGrafBinary.max_blocks(ior) ==
                  hour_discretization *
                  (stage_type == PSRGrafBinary.STAGE_MONTH ? 744 : PSRGrafBinary.HOURS_IN_STAGE[stage_type])
            @test PSRGrafBinary.stage_type(ior) == stage_type
            @test PSRGrafBinary.initial_stage(ior) == 2
            @test PSRGrafBinary.initial_year(ior) == 2006
            @test PSRGrafBinary.data_unit(ior) == "MW"
            @test PSRGrafBinary.agent_names(ior) == ["X", "Y", "Z"]
            @test PSRGrafBinary.is_hourly(ior) == true
            @test PSRGrafBinary.hour_discretization(ior) == hour_discretization

            for t in 1:1, s in 1:1
                @test PSRGrafBinary.blocks_in_stage(ior, t) <= PSRGrafBinary.max_blocks(ior)
                for b in 1:PSRGrafBinary.blocks_in_stage(ior, t)
                    @test PSRGrafBinary.current_stage(ior) == t
                    @test PSRGrafBinary.current_scenario(ior) == s
                    @test PSRGrafBinary.current_block(ior) == b
                    X = 10_000.0 * t + 1000.0 * s + b
                    Y = b + 0.0
                    Z = 10.0 * t + s
                    ref = [X, Y, Z]
                    for agent in 1:3
                        @test ior[agent] == ref[agent]
                    end
                    PSRGrafBinary.next_registry(ior)
                end
            end

            PSRGrafBinary.close(ior)
            ior = nothing
        end
    end

    rm(FILE_GERTER * ".bin")
    rm(FILE_GERTER * ".hdr")
    return
end

function read_write_binary_hourly_single_binary()
    FILE_GERTER = joinpath(".", "gerter")

    STAGES = 2
    SCENARIOS = 2
    AGENTS = ["X", "Y", "Z"]
    UNIT = "MW"

    for stage_type in [PSRGrafBinary.STAGE_MONTH, PSRGrafBinary.STAGE_WEEK, PSRGrafBinary.STAGE_DAY]
        gerter = PSRGrafBinary.open(
            PSRGrafBinary.Writer,
            FILE_GERTER;
            is_hourly = true,
            scenarios = SCENARIOS,
            stages = STAGES,
            agents = AGENTS,
            unit = UNIT,
            # optional:
            initial_stage = 2,
            initial_year = 2006,
            stage_type = stage_type,
            single_binary = true,
        )

        for t in 1:STAGES, s in 1:SCENARIOS
            for b in 1:PSRGrafBinary.blocks_in_stage(gerter, t)
                X = 10_000.0 * t + 1000.0 * s + b
                Y = b + 0.0
                Z = 10.0 * t + s
                PSRGrafBinary.write_registry(
                    gerter,
                    [X, Y, Z],
                    t,
                    s,
                    b,
                )
            end
        end

        PSRGrafBinary.close(gerter)

        ior = PSRGrafBinary.open(
            PSRGrafBinary.Reader,
            FILE_GERTER;
            use_header = false,
            single_binary = true,
        )

        @test PSRGrafBinary.max_stages(ior) == STAGES
        @test PSRGrafBinary.max_scenarios(ior) == SCENARIOS
        @test PSRGrafBinary.max_blocks(ior) ==
              (stage_type == PSRGrafBinary.STAGE_MONTH ? 744 : PSRGrafBinary.HOURS_IN_STAGE[stage_type])
        @test PSRGrafBinary.stage_type(ior) == stage_type
        @test PSRGrafBinary.initial_stage(ior) == 2
        @test PSRGrafBinary.initial_year(ior) == 2006
        @test PSRGrafBinary.data_unit(ior) == "MW"
        @test PSRGrafBinary.agent_names(ior) == ["X", "Y", "Z"]
        @test PSRGrafBinary.is_hourly(ior) == true
        @test PSRGrafBinary.hour_discretization(ior) == 1

        for t in 1:1, s in 1:1
            @test PSRGrafBinary.blocks_in_stage(ior, t) <= PSRGrafBinary.max_blocks(ior)
            for b in 1:PSRGrafBinary.blocks_in_stage(ior, t)
                @test PSRGrafBinary.current_stage(ior) == t
                @test PSRGrafBinary.current_scenario(ior) == s
                @test PSRGrafBinary.current_block(ior) == b
                X = 10_000.0 * t + 1000.0 * s + b
                Y = b + 0.0
                Z = 10.0 * t + s
                ref = [X, Y, Z]
                for agent in 1:3
                    @test ior[agent] == ref[agent]
                end
                PSRGrafBinary.next_registry(ior)
            end
        end

        PSRGrafBinary.close(ior)
        ior = nothing
    end

    rm(FILE_GERTER * ".dat")
    return
end

read_write_binary_hourly()
read_write_binary_subhourly()
read_write_binary_hourly_single_binary()
