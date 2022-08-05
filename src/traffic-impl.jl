# Traffic implementation
struct TrafficImpl
    n_nodes::Int
    from::Vector{Int}
    to::Vector{Int}
    
    trips::SparseMatrixCSC{Float64,Int}
    graph::SimpleDiGraph{Int}
    link_performance::AbstractLinkPerformanceImpl
end

function TrafficImpl(traffic::Traffic)
    n_nodes = traffic.n_nodes
    trips = traffic.trips
    network = traffic.network

    from = network.from
    to = network.to

    # trips
    subset!(trips, [:orig, :dest] => (orig, dest) -> orig .!= dest)

    trips = sparse(trips.orig, trips.dest, trips.trips, n_nodes, n_nodes)
    dropzeros!(trips)

    # graph
    graph = DiGraph(n_nodes)

    for (from, to) ∈ zip(from, to)
        add_edge!(graph, from, to)
    end

    # link_performance
    link_performance = traffic.link_performance(network)

    TrafficImpl(
        n_nodes,
        from,
        to,
        trips,
        graph,
        link_performance
    )
end