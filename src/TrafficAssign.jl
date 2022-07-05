module TrafficAssign

import DataFrames
import Graphs
import SparseArrays
import ZipFile

# traffic
include("traffic/traffic.jl")
include("traffic/traffic-graph.jl")

# tntp
include("tntp/tntp-download.jl")
include("tntp/tntp-global.jl")
include("tntp/tntp-load.jl")

export TrafficOptions, Traffic
export TrafficGraph
export load_tntp

end
