struct ShortestPaths{T<:Integer}
    parents::Vector{T}
    function ShortestPaths(graph::Graphs.AbstractGraph, orig::T) where T<:Integer
        shortest_paths = Graphs.dijkstra_shortest_paths(graph, orig)
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

    if isempty(from)
        return zeros(n_nodes, n_nodes)
    else
        to = [from[2:end]; dest]
        Matrix(SparseArrays.sparse(from, to, 1.0, n_nodes, n_nodes))
    end
end
