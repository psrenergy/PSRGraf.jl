function issue13()
    path = joinpath(".", "data", "businj")

    reader = PSRGraf.open(
        PSRGraf.CSVReader,
        path,
    )

    @test PSRGraf.data_unit(reader) == "MW"
    @test PSRGraf.stage_type(reader) == PSRGraf.STAGE_MONTH
    @test PSRGraf.initial_stage(reader) == 1
    @test PSRGraf.initial_year(reader) == 2003

    @test PSRGraf.max_agents(reader) == 3
    @test PSRGraf.agent_names(reader)[1] == "Barra 1"
    @test PSRGraf.agent_names(reader)[2] == "Barra 2"
    @test PSRGraf.agent_names(reader)[3] == "Barra 3"
end

function test_issues()
    @testset "Issue 13" begin issue13() end
end

test_issues()