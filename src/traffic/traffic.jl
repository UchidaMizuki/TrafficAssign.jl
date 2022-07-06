struct Traffic
    trips::SparseMatrixCSC{Float64, Int}
    graph::SimpleDiGraph{Int}
    link_performance::AbstractLinkPerformance

    function Traffic(tntp::TNTP)
        n_nodes = tntp.n_nodes

        # trips
        trips = tntp.trips
        trips = sparse(trips.orig, trips.dest, trips.trips, n_nodes, n_nodes)

        # graph
        network = tntp.network
        graph = DiGraph(n_nodes)

        for (from, to) in zip(network.from, network.to)
            add_edge!(graph, from, to)
        end

        # link_performance
        link_performance = BPR(tntp)

        new(trips, graph, link_performance)
    end
end
