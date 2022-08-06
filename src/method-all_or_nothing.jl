# All or nothing assignment
function (::AllOrNothing)(
    traffic::TrafficImpl,
    cost::Vector{Float64}
)
    n_nodes = traffic.n_nodes
    from = traffic.from
    to = traffic.to

    trips = traffic.trips
    graph = traffic.graph

    cost = sparse(from, to, cost, n_nodes, n_nodes)
    
    out = @distributed (+) for orig ∈ collect(axes(trips, 1))
        trips_orig = trips[orig, :]

        if nnz(trips_orig) > 0
            shortest_paths = DijkstraShortestPaths(
                graph,
                cost=cost,
                orig=orig
            )

            @distributed (+) for (dest, trip) ∈ collect(zip(findnz(trips_orig)...))
                trip * shortest_paths(dest)
            end
        else
            spzeros(n_nodes, n_nodes)
        end
    end

    return [out[i] for i ∈ zip(from, to)]
end
