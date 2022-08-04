# All or nothing assignment
function all_or_nothing(
    traffic::TrafficImpl,
    cost::Vector{Float64}
)
    n_nodes = traffic.n_nodes
    from = traffic.from
    to = traffic.to

    trips = traffic.trips
    graph = traffic.graph

    cost = sparse(from, to, cost, n_nodes, n_nodes)
    
    out = @distributed (+) for orig in collect(axes(trips, 1))
        trips_orig = trips[orig, :]

        if nnz(trips_orig) > 0
            shortest_paths = DijkstraShortestPaths(
                graph,
                cost=cost,
                orig=orig
            )

            @distributed (+) for (dest, trip) in collect(zip(findnz(trips_orig)...))
                trip * shortest_paths(dest)
            end
        else
            spzeros(n_nodes, n_nodes)
        end
    end

    return [out[i] for i in zip(from, to)]
end



# Shortest paths
struct DijkstraShortestPaths
    parents::Vector{Int}
    function DijkstraShortestPaths(
        graph::AbstractGraph;
        cost::AbstractMatrix{Float64},
        orig::Integer
    )
        shortest_paths = dijkstra_shortest_paths(graph, orig, cost)
        new(shortest_paths.parents)
    end
end

# struct DijkstraShortestPaths{T<:Integer}
#     parents::Vector{T}
#     function DijkstraShortestPaths(
#         graph::AbstractGraph;
#         cost::AbstractMatrix{U},
#         orig::T
#     ) where {T<:Integer,U<:Real}
#         shortest_paths = dijkstra_shortest_paths(graph, orig, cost)
#         new{T}(shortest_paths.parents::Vector{T})
#     end
# end

function (shortest_paths::DijkstraShortestPaths)(dest::Int)
    parents = shortest_paths.parents
    n_nodes = size(parents, 1)

    function shortest_path_nodes(dest::Int)
        parent = parents[dest]

        if parent == 0
            return Int[]
        else
            return [shortest_path_nodes(parent); parent]
        end
    end

    from = shortest_path_nodes(dest)

    @assert !isempty(from)

    to = [from[2:end]; dest]
    sparse(from, to, 1.0, n_nodes, n_nodes)
end

# function (shortest_paths::DijkstraShortestPaths)(dest::T) where {T<:Integer}
#     parents = shortest_paths.parents
#     n_nodes = size(parents, 1)

#     function shortest_path_nodes(dest::T) where {T<:Integer}
#         parent = parents[dest]

#         if parent == 0
#             return Vector{T}()
#         else
#             return [shortest_path_nodes(parent); parent]
#         end
#     end

#     from = shortest_path_nodes(dest)

#     @assert !isempty(from)

#     to = [from[2:end]; dest]
#     sparse(from, to, 1.0, n_nodes, n_nodes)
# end
