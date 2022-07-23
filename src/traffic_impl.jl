# Traffic implementation
struct TrafficImpl
    trips::SparseMatrixCSC{Float64,Int}
    graph::SimpleDiGraph{Int}
    link_performance::AbstractLinkPerformance
end

function TrafficImpl(traffic::Traffic)
    n_nodes = traffic.n_nodes

    # trips
    trips = traffic.trips |>
        x -> filter([:orig, :dest] => (orig, dest) -> orig != dest, x)
    orig = trips.orig
    dest = trips.dest

    trips = sparse(orig, dest, trips.trips, n_nodes, n_nodes)
    dropzeros!(trips)

    # graph
    network = traffic.network
    graph = DiGraph(n_nodes)

    for (from, to) in zip(network.from, network.to)
        add_edge!(graph, from, to)
    end

    # link_performance
    # TODO: Support for non BPR functions.
    link_performance = traffic.options.link_performance
    @assert link_performance in [:BPR]

    if link_performance == :BPR
        link_performance = BPR(traffic)
    end

    TrafficImpl(trips, graph, link_performance)
end
