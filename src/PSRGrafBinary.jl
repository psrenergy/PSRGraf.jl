module PSRGrafBinary

using Dates
using Encodings

import Base.open
import Base.close

include("stage_type.jl")
include("reader.jl")
include("writer.jl")

end
