# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

PSRGraf.jl is a Julia library for manipulating PSR Graf time series files. It supports both binary (.bin/.hdr) and CSV (.csv) file formats for reading and writing time series data with stages, scenarios, blocks, and agents (named data series).

## Common Commands

### Running Tests

```bash
# Run all tests
julia --project=. -e 'using Pkg; Pkg.test()'

# Run all tests with detailed output
julia --project=. test/runtests.jl

# Run a specific test file
julia --project=. test/read_and_write_csv_monthly.jl
julia --project=. test/time_series_utils.jl
```

### Development Setup

```bash
# Activate the project environment
julia --project=.

# Install dependencies
julia --project=. -e 'using Pkg; Pkg.instantiate()'
```

## Architecture

### File Format Support

The library supports two file formats with parallel implementations:

1. **Binary format**: `.bin` (data) + `.hdr` (header) or `.dat` (single file)
2. **CSV format**: `.csv` (combined data and header)

Each format has corresponding Reader and Writer types:
- `BinaryReader` / `BinaryWriter` (in [src/binary/](src/binary/))
- `CSVReader` / `CSVWriter` (in [src/csv/](src/csv/))

### Data Model

Time series files are organized in a 4-dimensional structure:
- **Stages**: Time periods (months, weeks, days, hours, years, etc.)
- **Scenarios**: Alternative futures/realizations
- **Blocks**: Sub-period divisions (e.g., hourly blocks within a stage)
- **Agents**: Named data series (e.g., "Plant1", "Plant2")

### Stage Types

The `StageType` enum ([src/stage_type.jl](src/stage_type.jl)) defines temporal granularity:
- `STAGE_MONTH`, `STAGE_WEEK`, `STAGE_DAY`, `STAGE_HOUR`
- `STAGE_2MONTHS`, `STAGE_3MONTHS`, `STAGE_4MONTHS`, `STAGE_6MONTHS`, `STAGE_13MONTHS`
- `STAGE_YEAR`, `STAGE_DECADE`

### Hourly vs Block-based Data

Files can be either:
- **Hourly**: `is_hourly=true`, blocks are calculated based on `stage_type` and `hour_discretization` (1, 2, 3, 4, 6, or 12 sub-hour divisions)
- **Block-based**: Fixed number of blocks per stage

Monthly hourly files have variable blocks per stage (28-31 days × 24 hours). The `blocks_in_stage()` function handles this calculation.

### File I/O Pattern

All readers and writers follow a consistent interface defined in [src/stage_type.jl](src/stage_type.jl):

**Opening files:**
```julia
reader = open(BinaryReader, "path/to/file"; kwargs...)
writer = open(BinaryWriter, "path/to/file"; blocks=N, scenarios=M, stages=T, agents=["X","Y"], unit="MW", kwargs...)
```

**Reading data:**
```julia
goto(reader, stage, scenario, block)  # Navigate to specific position
next_registry(reader)                  # Advance to next registry
reader[agent_index]                    # Access data for agent
```

**Writing data:**
```julia
write_registry(writer, data_vector, stage, scenario, block)
```

**Metadata accessors:**
- `max_stages()`, `max_scenarios()`, `max_blocks()`, `max_agents()`
- `current_stage()`, `current_scenario()`, `current_block()`
- `agent_names()`, `data_unit()`, `stage_type()`, `is_hourly()`
- `initial_stage()`, `initial_year()`

### Conversion and Utilities

[src/convert.jl](src/convert.jl) provides `convert_file()` to convert between formats:
```julia
convert_file(CSVReader, BinaryWriter, "input_path"; path_to="output_path")
```

Helper functions `file_to_array()` and `array_to_file()` enable array-based I/O for simpler use cases.

### Binary File Structure

Binary files use a versioned header format (versions 1-9 supported):
- Header (.hdr): Metadata including dimensions, agent names, stage type, initial date
- Binary (.bin): Float32 data in (stage, scenario, block, agent) order
- Single binary (.dat): Combined header + data

Position calculation differs for hourly vs block-based files due to variable blocks per stage in hourly monthly files.

### CSV File Structure

CSV files combine header metadata (first 3 lines) with columnar data:
```
Varies per block?       ,<block_type>,Unit,<unit>,<stage_type>,<initial_stage>,<initial_year>
Varies per sequence?    ,<scenarios_type>
# of agents             ,<num_agents>
Stag,Seq.,Blck,<agent1>,<agent2>,...
1,1,1,<data>,...
...
```

### Date Handling

Functions like `_date_from_stage()`, `_stage_from_date()`, and `_year_stage()` convert between stage indices and calendar dates. Special handling for:
- Leap years: February 29 and December 31 are invalid for weekly/daily stages (365-day years)
- Weekly stages: 52 weeks per year (364 days)
- Monthly stages: Standard calendar months

### Test Organization

Tests are organized by format and feature:
- Binary format: [test/read_and_write_blocks.jl](test/read_and_write_blocks.jl), [test/read_and_write_binary_hourly.jl](test/read_and_write_binary_hourly.jl)
- CSV format: [test/read_and_write_csv_monthly.jl](test/read_and_write_csv_monthly.jl), [test/read_and_write_csv_hourly.jl](test/read_and_write_csv_hourly.jl)
- Utilities: [test/time_series_utils.jl](test/time_series_utils.jl)
- Edge cases: [test/nonpositive_indices.jl](test/nonpositive_indices.jl), [test/incomplete_file.jl](test/incomplete_file.jl), [test/use_header.jl](test/use_header.jl)

The [test/utils.jl](test/utils.jl) file contains helper functions like `safe_remove()` for cleanup.

## Key Constraints

- Agent names must be unique and fit within `name_length` (12 or 24 characters, configurable with `allow_unsafe_name_length=true`)
- File paths must be provided without extensions (automatically appended)
- `block_type=0` requires `blocks=1`; `scenarios_type=0` requires `scenarios=1`
- `hour_discretization` must be in {1, 2, 3, 4, 6, 12}
- Readers/writers must be explicitly closed with `close()`
