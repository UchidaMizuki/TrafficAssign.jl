module UserEqm

import DataFrames: DataFrame, select
import Graphs: SimpleGraphs.SimpleDiGraph, DiGraph, add_edge!
import Graphs: AbstractGraph, dijkstra_shortest_paths
import SparseArrays: SparseMatrixCSC, sparse, nnz, dropzeros!, spzeros
import ZipFile

include("tntp.jl")
include("traffic.jl")

export download_tntp, load_tntp

export TrafficImpl, objective

# export Traffic
# export AbstractLinkPerformance, BPR
# export ShortestPaths
# export all_or_nothing

end
