"""
    StageType

Possible stage types used in for reading and writing time series files.

The current possible stage types are:

```julia
STAGE_UNKNOWN
STAGE_WEEK
STAGE_MONTH
STAGE_3MONTHS
STAGE_HOUR
STAGE_DAY
STAGE_13MONTHS
STAGE_2MONTHS
STAGE_4MONTHS
STAGE_6MONTHS
STAGE_YEAR
STAGE_DECADE
```
"""
@enum StageType begin
    STAGE_UNKNOWN = 0
    STAGE_WEEK = 1
    STAGE_MONTH = 2
    STAGE_3MONTHS = 3
    STAGE_HOUR = 4
    STAGE_DAY = 5
    STAGE_13MONTHS = 6
    STAGE_2MONTHS = 7
    STAGE_4MONTHS = 8
    STAGE_6MONTHS = 9
    STAGE_YEAR = 10
    STAGE_DECADE = 11
end

const DAYS_IN_MONTH = Int[
    31, # jan
    28, # feb - always 28
    31, # mar
    30, # apr
    31, # may
    30, # jun
    31, # jul
    31, # ago
    30, # sep
    31, # out
    30, # nov
    31, # dez
]

const STAGES_IN_YEAR = Dict{StageType, Int}(
    STAGE_HOUR => 8760,
    STAGE_DAY => 365,
    STAGE_WEEK => 52,
    STAGE_MONTH => 12,
    STAGE_YEAR => 1,
)

const HOURS_IN_STAGE = Dict{StageType, Int}(
    STAGE_HOUR => 1,
    STAGE_DAY => 24,
    STAGE_WEEK => 168,
    # STAGE_MONTH => 744,
    STAGE_YEAR => 8760,
)

function _delete_or_error(path::AbstractString)
    if isfile(path)
        # Try multiple times with garbage collection in case file handles are still open
        for attempt in 1:5
            try
                rm(path)
                return
            catch
                if attempt < 5
                    GC.gc()
                    sleep(0.05)
                else
                    error("Could not delete file $path: it might be open in other process")
                end
            end
        end
    end
    return
end

function blocks_in_stage(is_hourly, hour_discretization, stage_type, initial_stage, t)::Int
    if is_hourly
        if stage_type == STAGE_MONTH
            return hour_discretization * DAYS_IN_MONTH[mod1(t - 1 + initial_stage, 12)] * 24
        else
            return hour_discretization * HOURS_IN_STAGE[stage_type]
        end
    end
    return io.blocks
end

function blocks_in_stage(io, t)::Int
    if is_hourly(io)
        if stage_type(io) == STAGE_MONTH
            return hour_discretization(io) *
                   DAYS_IN_MONTH[mod1(t - 1 + initial_stage(io), 12)] * 24
        else
            return hour_discretization(io) * HOURS_IN_STAGE[stage_type(io)]
        end
    end
    return max_blocks(io)
end

function _date_from_stage(t::Int, stage_type::StageType, first_date::Dates.Date)
    date = if stage_type == STAGE_MONTH
        first_date + Dates.Month(t - 1)
    elseif stage_type == STAGE_WEEK
        y = 0
        if t >= 52
            y, t = divrem(t, 52)
            t += 1
        end
        first_date + Dates.Week(t - 1) + Dates.Year(y)
    elseif stage_type == STAGE_DAY
        y = 0
        if t >= 365
            y, t = divrem(t, 365)
            t += 1
        end
        current_date = first_date + Dates.Day(t - 1) + Dates.Year(y)
        if (
            Dates.isleapyear(first_date) &&
            first_date <= Dates.Date(Dates.year(first_date), 2, 28) &&
            current_date >= Dates.Date(Dates.year(first_date), 2, 29)
        )
            current_date += Dates.Day(1)
        elseif (
            Dates.isleapyear(current_date) &&
            first_date <= Dates.Date(Dates.year(current_date), 2, 28) &&
            current_date >= Dates.Date(Dates.year(current_date), 2, 29)
        )
            current_date += Dates.Day(1)
        end
        return current_date
    else
        error("Stage type $stage_type not currently supported")
    end
    return date
end

function _year_week(date::Dates.Date, go_back_if_needed = false)
    y, m, d = Dates.yearmonthday(date)
    # invalid dates for weekly model
    if m == 2 && d >= 29
        if go_back_if_needed
            d = 28
        else
            error("29th of February is not valid for weekly stages")
        end
    elseif m == 12 && d == 31
        if go_back_if_needed
            d = 30
        else
            error("31st of December is not valid for weekly stages")
        end
    end
    # use a non-leap year as ref
    w = div(Dates.dayofyear(Dates.Date(2002, m, d)) - 1, 7) + 1
    @assert 1 <= w <= 52
    return y, w
end

function _year_day(date::Dates.Date, go_back_if_needed = false)
    y, m, d = Dates.yearmonthday(date)
    # invalid dates for weekly model
    dd = Dates.dayofyear(date)
    if Dates.isleapyear(date)
        if m >= 3
            dd -= 1
        elseif m == 2 && d == 29
            if go_back_if_needed
                dd -= 1
            else
                error("29th of February is not valid for daily stages")
            end
        end
    end
    @assert 1 <= dd <= 365
    return y, dd
end

function _year_month(date::Dates.Date)
    return Dates.yearmonth(date)
end

function _stage_distance(year1, stage1, year2, stage2, cycle)
    # current(1) = reference(2)
    abs_stage1 = (year1 - 1) * cycle + stage1
    abs_stage2 = (year2 - 1) * cycle + stage2
    return abs_stage1 - abs_stage2
end

function _stage_from_date(
    date::Dates.Date,
    stage_type::StageType,
    first_date::Dates.Date,
)
    fy, fm = _year_stage(first_date, stage_type)
    y, m = _year_stage(date, stage_type)
    return _stage_distance(y, m, fy, fm, STAGES_IN_YEAR[stage_type]) + 1
end

function _year_stage(
    date::Dates.Date,
    stage_type::StageType,
)
    if stage_type == STAGE_MONTH
        return _year_month(date)
    elseif stage_type == STAGE_WEEK
        return _year_week(date)
    elseif stage_type == STAGE_DAY
        return _year_day(date)
    else
        error("Stage type $stage_type not currently supported")
    end
end

"""
    open(::Type{BinaryWriter}, path::String; kwargs...)

Method for opening file and registering time series data.
If specified file doesn't exist, the method will create it, otherwise, the previous one will be overwritten.
Returns updated `BinaryWriter` instance.

### Arguments:

  - `writer`: `BinaryWriter` instance to be used for opening file.

  - `path`: path to file.

### Keyword arguments:

  - `blocks`: case's number of blocks.

  - `scenarios`: case's number of scenarios.
  - `stages`: case's number of stages.
  - `agents`: list of element names.
  - `unit`: dimension of the elements' data.
  - `is_hourly`: if data is hourly. If yes, block dimension will be ignored.
  - `hour_discretization`: sub-hour parameter to discretize an hour into minutes.
  - `name_length`: length of element names.
  - `block_type`: case's type of block.
  - `scenarios_type`: case's type of scenario.
  - `stage_type`: case's type of stage.
  - `initial_stage`: stage at which to start registry.
  - `initial_year`: year at which to start registry.
  - `allow_unsafe_name_length`: allow element names outside safety bounds.

Examples:

  - [Writing and reading a time series into a file](@ref)

* * *

    open(reader::Type{Reader}, path::String; kwargs...)

Method for opening file and reading time series data.
Returns updated `Reader` instance.

### Arguments:

  - `reader::Type{Reader}`: `Reader` instance to be used for opening file.

  - `path::String`: path to file.

### Keyword arguments:

  - `is_hourly::Bool`: if data to be read is hourly, other than blockly.

  - `stage_type::StageType`: the [`StageType`](@ref) of the data, defaults to `STAGE_MONTH`.
  - `header::Vector{String}`: if file has a header with metadata.
  - `use_header::Bool`: if data from header should be retrieved.
  - `first_stage::Dates.Date`: stage at which start reading.
  - `verbose_header::Bool`: if data from header should be displayed during execution.

Examples:

  - [Writing and reading a time series into a file](@ref)
"""
function open end

"""
    close(ior::Reader)

Closes the [`Reader`](@ref) instance.

* * *

    close(iow::BinaryWriter)

Closes the [`BinaryWriter`](@ref) instance.
"""
function close end

"""
    is_hourly(ior::Reader)

Returns a `Bool` indicating whether the data in the file read by [`Reader`](@ref) is hourly.
"""
function is_hourly end

"""
    hour_discretization(ior::Reader)

Returns an `Int` indicating the hour discretization.
"""
function hour_discretization end

"""
    max_stages(ior::Reader)

Returns an `Int` indicating maximum number of stages in the file read by [`Reader`](@ref).
"""
function max_stages end

"""
    max_scenarios(ior::Reader)

Returns an `Int` indicating maximum number of scenarios in the file read by [`Reader`](@ref).
"""
function max_scenarios end

"""
    max_blocks(ior::Reader)

Returns an `Int` indicating maximum number of blocks in the file read by [`Reader`](@ref).
"""
function max_blocks end

"""
    max_blocks_current(ior::Reader)

Returns an `Int` indicating maximum number of blocks in the cuurent stage in the file read by [`Reader`](@ref).
"""
function max_blocks_current end

"""
    max_blocks_stage(ior::Reader, t::Integer)

Returns an `Int` indicating maximum number of blocks in the stage `t` in the file read by [`Reader`](@ref).
"""
function max_blocks_stage end

"""
    max_agents(ior::Reader)

Returns an `Int` indicating maximum number of agents in the file read by [`Reader`](@ref).
"""
function max_agents end

"""
    stage_type
"""
function stage_type end

"""
    initial_stage(ior::Reader)

Returns an `Int` indicating the initial stage in the file read by [`Reader`](@ref).
"""
function initial_stage end

"""
    initial_year(ior::Reader)

Returns an `Int` indicating the initial year in the file read by [`Reader`](@ref).
"""
function initial_year end

"""
    data_unit(ior::Reader)

Returns a `String` indicating the unit of the data in the file read by [`Reader`](@ref).
"""
function data_unit end

"""
    current_stage(ior::Reader)

Returns an `Int` indicating the current stage in the stream of the [`Reader`](@ref).
"""
function current_stage end

"""
    current_scenario(ior::Reader)

Returns an `Int` indicating the current scenarios in the stream of the [`Reader`](@ref).
"""
function current_scenario end

"""
    current_block(ior::Reader)

Returns an `Int` indicating the current block in the stream of the [`Reader`](@ref).
"""
function current_block end

"""
    agent_names(ior::Reader)

Returns a `Vector{String}` with the agent names in the file read by [`Reader`](@ref).
"""
function agent_names end

"""
    goto(
        ior::Reader, 
        t::Integer, 
        s::Integer = 1, 
        b::Integer = 1
    )

Goes to the registry of the stage `t`, scenario `s` and block `b`.
"""
function goto end

"""
    next_registry(ior::Reader)

Goes to the next registry on the [`Reader`](@ref).
"""
function next_registry end

"""
    add_reader!
"""
function add_reader! end

# Write methods

"""
    write_registry(
        iow::BinaryWriter,
        data::Vector{T},
        stage::Integer,
        scenario::Integer = 1,
        block::Integer = 1,
    ) where T <: Real

Writes a data row into opened file through [`BinaryWriter`](@ref) instance.

### Arguments:

  - `iow`: `BinaryWriter` instance to be used for accessing file.

  - `data`: elements data to be written.
  - `stage`: stage of the data to be written.
  - `scenario`: scenarios of the data to be written.
  - `block`: block of the data to be written.
"""
function write_registry end

"""
    array_to_file
"""
function array_to_file end

"""
    file_path(ior::Reader)
    file_path(iow::BinaryWriter)

Returns the path of the file associated with the [`Reader`](@ref) or [`BinaryWriter`](@ref) instance.
"""
function file_path end

# Abstract types
abstract type AbstractReader end
abstract type AbstractWriter end

# Reader utility functions

"""
    file_to_array(::Type{T}, path::String; use_header::Bool = true, header::Vector{String} = String[]) where T <: AbstractReader

Write a file to an array
"""
function file_to_array(
    ::Type{T},
    path::String;
    use_header::Bool = true,
    header::Vector{String} = String[],
) where {T <: AbstractReader}
    return file_to_array_and_header(T, path; use_header = use_header, header = header)[1]
end

"""
    file_to_array_and_header(::Type{T}, path::String; use_header::Bool = true, header::Vector{String} = String[]) where T <: AbstractReader

Write a file to an array and header
"""
function file_to_array_and_header(
    ::Type{T},
    path::String;
    use_header::Bool = true,
    header::Vector{String} = String[],
) where {T <: AbstractReader}
    io = open(
        T,
        path;
        use_header = use_header,
        header = header,
    )
    stages = max_stages(io)
    scenarios = max_scenarios(io)
    blocks = max_blocks(io)
    agents = max_agents(io)
    out = zeros(agents, blocks, scenarios, stages)
    for t in 1:stages, s in 1:scenarios, b in 1:blocks
        if b > blocks_in_stage(io, t)
            # leave a zero for ignored hours
            continue
        end
        for a in 1:agents
            out[a, b, s, t] = io[a]
        end
        next_registry(io)
    end
    names = copy(agent_names(io)) # hold data after close
    close(io)
    GC.gc() # Force garbage collection to release file handles on Windows
    sleep(0.1) # Give time for file handles to be released
    return out, names
end

"""
    array_to_file(::Type{T}, path::String, data::Array{Float64, 4}; kwargs...) where T <: AbstractWriter

Write an array to a file
"""
function array_to_file(
    ::Type{T},
    path::String,
    data::Array{Float64, 4}; #[a,b,s,t]
    # mandatory
    agents::Vector{String} = String[],
    unit::Union{Nothing, String} = nothing,
    # optional
    is_hourly::Bool = false,
    name_length::Integer = 24,
    block_type::Integer = 1,
    scenarios_type::Integer = 1,
    stage_type::StageType = STAGE_MONTH, # important for header
    initial_stage::Integer = 1, #month or week
    initial_year::Integer = 1900,
    # additional
    allow_unsafe_name_length::Bool = false,
    kwargs...,
) where {T <: AbstractWriter}
    (nagents, blocks, scenarios, stages) = size(data)
    if isempty(agents)
        agents = String["$i" for i in 1:nagents]
    end
    if length(agents) != nagents
        error(
            "agents names for header do not match with the first dimension of data vector",
        )
    end
    writer = open(
        T,
        path;
        # mandatory
        blocks = blocks,
        scenarios = scenarios,
        stages = stages,
        agents = agents,
        unit = unit,
        # optional
        is_hourly = is_hourly,
        name_length = name_length,
        block_type = block_type,
        scenarios_type = scenarios_type,
        stage_type = stage_type,
        initial_stage = initial_stage, #month or week
        initial_year = initial_year,
        # additional
        allow_unsafe_name_length = allow_unsafe_name_length,
        kwargs...,
    )

    cache = zeros(Float64, nagents)
    for t in 1:stages, s in 1:scenarios, b in 1:blocks
        for i in 1:nagents
            cache[i] = data[i, b, s, t]
        end
        write_registry(
            writer,
            cache,
            t,
            s,
            b,
        )
    end

    close(writer)

    return nothing
end
