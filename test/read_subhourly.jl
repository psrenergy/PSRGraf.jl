function read_binary_subhourly()
    STAGES = 2
    SCENARIOS = 2
    AGENTS = ["X", "Y", "Z"]
    UNIT = "MW"

    for stage_type in [PSRGrafBinary.STAGE_MONTH, PSRGrafBinary.STAGE_WEEK, PSRGrafBinary.STAGE_DAY]
        for hour_discretization in [2, 4, 6]
            path = joinpath(
                @__DIR__,
                "data",
                "case4",
                "subhourly_$(stage_type)_$(hour_discretization)",
            )

            io = PSRGrafBinary.open(PSRGrafBinary.Reader, path; use_header = false)

            @test PSRGrafBinary.max_stages(io) == STAGES
            @test PSRGrafBinary.max_scenarios(io) == SCENARIOS
            @test PSRGrafBinary.max_blocks(io) ==
                  hour_discretization *
                  (stage_type == PSRGrafBinary.STAGE_MONTH ? 744 : PSRGrafBinary.HOURS_IN_STAGE[stage_type])
            @test PSRGrafBinary.stage_type(io) == stage_type
            @test PSRGrafBinary.initial_stage(io) == 2
            @test PSRGrafBinary.initial_year(io) == 2006
            @test PSRGrafBinary.data_unit(io) == UNIT
            @test PSRGrafBinary.agent_names(io) == AGENTS
            @test PSRGrafBinary.is_hourly(io) == true
            @test PSRGrafBinary.hour_discretization(io) == hour_discretization

            for t in 1:STAGES
                for s in 1:SCENARIOS
                    @test PSRGrafBinary.blocks_in_stage(io, t) <= PSRGrafBinary.max_blocks(io)
                    for b in 1:PSRGrafBinary.blocks_in_stage(io, t)
                        @test PSRGrafBinary.current_stage(io) == t
                        @test PSRGrafBinary.current_scenario(io) == s
                        @test PSRGrafBinary.current_block(io) == b
                        X = 10_000.0 * t + 1000.0 * s + b
                        Y = b + 0.0
                        Z = 10.0 * t + s
                        ref = [X, Y, Z]
                        for agent in 1:3
                            @test io[agent] == ref[agent]
                        end
                        PSRGrafBinary.next_registry(io)
                    end
                end
            end

            PSRGrafBinary.close(io)
        end
    end
    return
end

read_binary_subhourly()
