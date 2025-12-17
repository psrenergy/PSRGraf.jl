function read_binary_subhourly()
    STAGES = 2
    SCENARIOS = 2
    AGENTS = ["X", "Y", "Z"]
    UNIT = "MW"

    for stage_type in [PSRGraf.STAGE_MONTH, PSRGraf.STAGE_WEEK, PSRGraf.STAGE_DAY]
        for hour_discretization in [2, 4, 6]
            path = joinpath(
                @__DIR__,
                "data",
                "case4",
                "subhourly_$(stage_type)_$(hour_discretization)",
            )

            io = PSRGraf.open(PSRGraf.BinaryReader, path; use_header = false)

            @test PSRGraf.max_stages(io) == STAGES
            @test PSRGraf.max_scenarios(io) == SCENARIOS
            @test PSRGraf.max_blocks(io) ==
                  hour_discretization *
                  (stage_type == PSRGraf.STAGE_MONTH ? 744 : PSRGraf.HOURS_IN_STAGE[stage_type])
            @test PSRGraf.stage_type(io) == stage_type
            @test PSRGraf.initial_stage(io) == 2
            @test PSRGraf.initial_year(io) == 2006
            @test PSRGraf.data_unit(io) == UNIT
            @test PSRGraf.agent_names(io) == AGENTS
            @test PSRGraf.is_hourly(io) == true
            @test PSRGraf.hour_discretization(io) == hour_discretization

            for t in 1:STAGES
                for s in 1:SCENARIOS
                    @test PSRGraf.blocks_in_stage(io, t) <= PSRGraf.max_blocks(io)
                    for b in 1:PSRGraf.blocks_in_stage(io, t)
                        @test PSRGraf.current_stage(io) == t
                        @test PSRGraf.current_scenario(io) == s
                        @test PSRGraf.current_block(io) == b
                        X = 10_000.0 * t + 1000.0 * s + b
                        Y = b + 0.0
                        Z = 10.0 * t + s
                        ref = [X, Y, Z]
                        for agent in 1:3
                            @test io[agent] == ref[agent]
                        end
                        PSRGraf.next_registry(io)
                    end
                end
            end

            PSRGraf.close(io)
        end
    end
    return
end

read_binary_subhourly()
