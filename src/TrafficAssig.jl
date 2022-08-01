module TrafficAssig

import Base: @kwdef

import DataFrames: DataFrame
import DataFrames: select

import Distributed: @distributed

import Graphs: AbstractGraph, DiGraph, SimpleGraphs.SimpleDiGraph
import Graphs: add_edge!, dijkstra_shortest_paths

# import Memoize: @memoize

import Optim: AbstractOptimizer, GoldenSection
import Optim: optimize

import Printf: @printf

import SparseArrays: SparseMatrixCSC
import SparseArrays: dropzeros!, findnz, nnz, sparse, spzeros

import ZipFile: Reader

include("tntp.jl")
include("traffic.jl")
include("link_performance.jl")
include("traffic_impl.jl")
include("all_or_nothing.jl")
include("algorithm.jl")
include("assign_traffic.jl")

export download_tntp, load_tntp
export TrafficOptions, Traffic
export BPR
export TrafficImpl
export all_or_nothing, ShortestPaths
export AbstractTrafficAssigAlgorithm, FrankWolfe, ConjugateFrankWolfe, BiconjugateFrankWolfe, AbstractTrafficAssigLogs, TrafficAssigLogs
export assign_traffic

end
