function all_or_nothing(traffic::Traffic, flow::Union{Float64,SparseMatrixCSC{Float64,Int64}})
    trips = traffic.trips
    graph = traffic.graph
    cost = traffic.link_performance(flow)

    flow = spzeros(size(cost))

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
