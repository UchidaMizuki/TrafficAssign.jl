include("traffic-link-performance.jl")

struct TrafficGraph
    trips::SparseArrays.SparseMatrixCSC{Float64,Int}
    graph::Graphs.SimpleGraphs.SimpleDiGraph{Int}
    link_performance::AbstractLinkPerformance # FIXME
    function TrafficGraph(traffic::Traffic)
        n_nodes = traffic.n_nodes

        # trips
        trips = traffic.trips
        trips = SparseArrays.sparse(trips.orig, trips.dest, trips.trips, n_nodes, n_nodes)

        # graph
        network = traffic.network
        graph = Graphs.DiGraph(n_nodes)

        for (from, to) in zip(network.from, network.to)
            Graphs.add_edge!(graph, from, to)
        end

        # link_performance
        options = traffic.options
        link_performance = options.link_performance

        if link_performance == :BPR
            link_performance = BPR(traffic)
        else
            error()
        end

        new(trips, graph, link_performance)
    end
end

function traffic_graph(traffic::Traffic)
    network = traffic.network
    n_nodes = max([network.from; network.to]...)

    graph = Graphs.DiGraph(n_nodes)

    for (from, to) in zip(network.from, network.to)
        Graphs.add_edge!(graph, from, to)
    end

    graph
end
