abstract type AbstractTrafficAssigMethod end

struct AllOrNothing <: AbstractTrafficAssigMethod end



# Shortest paths
struct DijkstraShortestPaths{T<:Integer}
    parents::Vector{T}
    function DijkstraShortestPaths(
        graph::AbstractGraph;
        cost::AbstractMatrix{U},
        orig::T
    ) where {T<:Integer,U<:Real}
        shortest_paths = dijkstra_shortest_paths(graph, orig, cost)
        new{T}(shortest_paths.parents::Vector{T})
    end
end

function (shortest_paths::DijkstraShortestPaths)(dest::T) where {T<:Integer}
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
