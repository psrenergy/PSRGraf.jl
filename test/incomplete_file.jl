function incomplete_file()
    temp_path = joinpath(tempdir(), "openbin")
    bin_path = joinpath(temp_path, "binfile")

    mkpath(temp_path)

    n_stages = 4
    n_scenarios = 3
    n_blocks = 2

    agents = ["X", "Y", "Z"]

    unit = ""

    iow = PSRGrafBinary.open(
        PSRGrafBinary.Writer,
        bin_path;
        is_hourly = false,
        scenarios = n_scenarios,
        stages = n_stages,
        blocks = n_blocks,
        agents = agents,
        unit = unit,
        initial_stage = 1,
        initial_year = 2000,
        stage_type = PSRGrafBinary.STAGE_MONTH,
        single_binary = false,
    )

    PSRGrafBinary.write_registry(
        iow,
        [1.0, 2.0, 3.0],
        1,
        1,
        1,
    )

    PSRGrafBinary.write_registry(
        iow,
        [3.0, 2.0, 1.0],
        1,
        1,
        2,
    )

    PSRGrafBinary.close(iow)

    ior = PSRGrafBinary.open(
        PSRGrafBinary.Reader,
        bin_path;
        header = agents,
    )

    @test ior.data == [1.0, 2.0, 3.0]

    PSRGrafBinary.next_registry(ior)

    @test ior.data == [3.0, 2.0, 1.0]

    PSRGrafBinary.next_registry(ior)

    @test ior.data == [0.0, 0.0, 0.0]

    return PSRGrafBinary.close(ior)
end

incomplete_file()
