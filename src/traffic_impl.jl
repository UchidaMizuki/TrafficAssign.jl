# Traffic implementation
struct TrafficImpl
    n_nodes::Int
    from::Vector{Int}
    to::Vector{Int}
    
    trips::SparseMatrixCSC{Float64,Int}
    graph::SimpleDiGraph{Int}
    link_performance::AbstractLinkPerformance
end

function TrafficImpl(traffic::Traffic)
    n_nodes = traffic.n_nodes
    network = traffic.network

    from = network.from
    to = network.to

    # trips
    trips = traffic.trips |>
        x -> filter([:orig, :dest] => (orig, dest) -> orig != dest, x)

    trips = sparse(trips.orig, trips.dest, trips.trips, n_nodes, n_nodes)
    dropzeros!(trips)

    # graph
    graph = DiGraph(n_nodes)

    for (from, to) in zip(from, to)
        add_edge!(graph, from, to)
    end

    # link_performance
    # TODO: Support for non BPR functions.
    link_performance = traffic.options.link_performance
    @assert link_performance in [:BPR]

    if link_performance == :BPR
        link_performance = BPR(traffic)
    end

    TrafficImpl(
        n_nodes,
        from,
        to,
        trips,
        graph,
        link_performance
    )
end