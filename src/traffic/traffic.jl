struct Traffic
    trips::SparseMatrixCSC{Float64, Int}
    graph::SimpleDiGraph{Int}
    link_performance::AbstractLinkPerformance
end

function Traffic(tntp::TNTP)
    n_nodes = tntp.n_nodes

    # trips
    trips = tntp.trips
    orig = trips.orig
    dest = trips.dest

    @assert !any(orig .== dest)
    
    trips = sparse(orig, dest, trips.trips, n_nodes, n_nodes)
    dropzeros!(trips)

    # graph
    network = tntp.network
    graph = DiGraph(n_nodes)

    for (from, to) in zip(network.from, network.to)
        add_edge!(graph, from, to)
    end

    # link_performance
    link_performance = BPR(tntp)

    Traffic(trips, graph, link_performance)
end