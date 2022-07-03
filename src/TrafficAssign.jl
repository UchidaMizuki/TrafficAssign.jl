module TrafficAssign

import DataFrames
import ZipFile

# traffic
include("traffic/traffic.jl")

# tntp
include("tntp/tntp-download.jl")
include("tntp/tntp-global.jl")
include("tntp/tntp-load.jl")

export TrafficOptions, Traffic
export load_tntp

end
