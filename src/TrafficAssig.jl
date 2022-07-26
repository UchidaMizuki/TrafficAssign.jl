module TrafficAssig

import DataFrames: DataFrame
import DataFrames: select

import Graphs: AbstractGraph, DiGraph, SimpleGraphs.SimpleDiGraph
import Graphs: add_edge!, dijkstra_shortest_paths

import Optim: AbstractOptimizer, GoldenSection
import Optim: optimize

import Printf: @printf

import SparseArrays: SparseMatrixCSC
import SparseArrays: dropzeros!, nnz, sparse, spzeros

import ZipFile: Reader

include("tntp.jl")

include("traffic.jl")
include("link_performance.jl")
include("traffic_impl.jl")
include("all_or_nothing.jl")
include("assign_traffic.jl")

export download_tntp, load_tntp
export TrafficOptions, Traffic

# FIXME
export TrafficImpl
export all_or_nothing, objective
export assign_traffic

end
