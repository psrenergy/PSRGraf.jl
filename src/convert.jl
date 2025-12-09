function convert_file(
    ::Type{R},
    ::Type{W},
    path_from::String;
    path_to::String = "",
) where {
    R <: AbstractReader,
    W <: AbstractWriter,
}
    if isempty(path_to)
        path_to = path_from
    end
    
    # Check if converting CSV to CSV or Binary to Binary - these are no-ops
    if (R == CSVReader && W == CSVWriter) || (R == BinaryReader && W == BinaryWriter)
        error("Conversion from $(R) to $(W) is a no-op. Use different formats (Binary ↔ CSV).")
    end

    reader = open(
        R,
        path_from;
        use_header = false,
    )

    # currently ignores block and scenarios type
    stages = max_stages(reader)
    scenarios = max_scenarios(reader)
    blocks = max_blocks(reader)
    agents = agent_names(reader)
    name_length = maximum(length.(agents))
    if name_length <= 12
        name_length = 12
    elseif name_length <= 24
        name_length = 24
    end
    n_agents = length(agents)

    writer = open(
        W,
        path_to;
        blocks = blocks,
        scenarios = scenarios,
        stages = stages,
        agents = agents,
        unit = data_unit(reader),
        is_hourly = is_hourly(reader),
        name_length = name_length,
        stage_type = stage_type(reader),
        initial_stage = initial_stage(reader),
        initial_year = initial_year(reader),
    )

    cache = zeros(Float64, n_agents)
    for t in 1:stages, s in 1:scenarios, b in 1:blocks_in_stage(reader, t)
        for agent in 1:n_agents
            cache[agent] = reader[agent]
        end
        write_registry(
            writer,
            cache,
            t,
            s,
            b,
        )
        next_registry(reader)
    end
    close(reader)
    close(writer)

    return nothing
end