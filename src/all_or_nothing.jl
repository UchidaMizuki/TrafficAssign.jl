# All or nothing assignment
function all_or_nothing(
    traffic::TrafficImpl;
    cost::Vector{Float64}
)
    n_nodes = traffic.n_nodes
    from = traffic.from
    to = traffic.to

    trips = traffic.trips
    graph = traffic.graph

    cost = sparse(from, to, cost, n_nodes, n_nodes)
    out = spzeros(n_nodes, n_nodes)

    for orig in 1:size(trips, 1)
        trips_orig = trips[orig, :]

        if nnz(trips_orig) > 0
            shortest_paths = ShortestPaths(
                graph,
                cost=cost,
                orig=orig
            )

            for (dest, trip) in zip(trips_orig.nzind, trips_orig.nzval)
                out += trip * shortest_paths(dest)
            end
        end
    end

    return [out[i] for i in zip(from, to)]
end



# Shortest paths
struct ShortestPaths{T<:Integer}
    parents::Vector{T}
    function ShortestPaths(
        graph::AbstractGraph;
        cost::AbstractMatrix{U},
        orig::T
    ) where {T<:Integer,U<:Real}
        shortest_paths = dijkstra_shortest_paths(graph, orig, cost)
        new{T}(shortest_paths.parents::Vector{T})
    end
end

function (shortest_paths::ShortestPaths)(dest::T) where {T<:Integer}
    parents = shortest_paths.parents
    n_nodes = size(parents, 1)

    function shortest_path_nodes(dest::T) where {T<:Integer}
        parent = parents[dest]

        if parent == 0
            return Vector{T}()
        else
            return [shortest_path_nodes(parent); parent]
        end
    end

    from = shortest_path_nodes(dest)

    @assert !isempty(from)

    to = [from[2:end]; dest]
    sparse(from, to, 1.0, n_nodes, n_nodes)
end
