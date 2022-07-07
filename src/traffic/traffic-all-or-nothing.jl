function flow_init(traffic::Traffic)
    zeros(size(traffic.trips))
end

function all_or_nothing(traffic::Traffic, flow::Matrix{Float64})
    trips = traffic.trips
    graph = traffic.graph
    cost = traffic.link_performance(flow)

    fill!(flow, 0.0)

    for orig in 1:size(trips, 1)
        trips_orig = trips[orig, :]

        if nnz(trips_orig) > 0
            shortest_paths = ShortestPaths(graph, cost, orig)

            for (dest, trip) in zip(trips_orig.nzind, trips_orig.nzval)
                flow += trip * shortest_paths(dest)
            end
        end
    end

    return flow
end