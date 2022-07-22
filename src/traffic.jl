# Traffic
Base.@kwdef struct TrafficOptions
    first_thru_node::Int = 1
    toll_factor::Float64 = 0.0
    length_factor::Float64 = 0.0
end

struct Traffic
    n_nodes::Int
    trips::DataFrame
    network::DataFrame
    options::TrafficOptions
    function Traffic(trips::DataFrame, network::DataFrame; options::TrafficOptions=TrafficOptions())
        trips = select(trips, :orig, :dest, :trips)
        network = select(network, :from, :to, :free_flow_time, :capacity, :alpha, :beta, :toll, :length)
        n_nodes = max([network.from; network.to]...)

        return new(n_nodes, trips, network, options)
    end
end

function Base.show(io::IO, mime::MIME"text/plain", traffic::Traffic)
    print(io, "Number of nodes: $(traffic.n_nodes)\n")
    print(io, "Trips:\n")
    show(io, mime, traffic.trips)
    print(io, "\n\n")
    print(io, "Network:\n")
    show(io, mime, traffic.network)

    return nothing
end



# link_performance
abstract type AbstractLinkPerformance end

# BPR
struct BPR <: AbstractLinkPerformance
    free_flow_time::SparseMatrixCSC{Float64,Int}
    capacity::SparseMatrixCSC{Float64,Int}
    alpha::SparseMatrixCSC{Float64,Int}
    beta::SparseMatrixCSC{Float64,Int}

    toll_factor::SparseMatrixCSC{Float64,Int}
    toll::SparseMatrixCSC{Float64,Int}

    length_factor::SparseMatrixCSC{Float64,Int}
    length::SparseMatrixCSC{Float64,Int}

    function BPR(
        n_nodes::Int,
        from::Vector{Int},
        to::Vector{Int}; free_flow_time::Vector{Float64},
        capacity::Vector{Float64},
        alpha::Vector{Float64},
        beta::Vector{Float64}, toll_factor::Union{Float64,Vector{Float64}},
        toll::Vector{Float64}, length_factor::Union{Float64,Vector{Float64}},
        length::Vector{Float64}
    )

        matrix_network = x -> sparse(from, to, x, n_nodes, n_nodes)

        free_flow_time = matrix_network(free_flow_time)
        capacity = matrix_network(capacity)
        alpha = matrix_network(alpha)
        beta = matrix_network(beta)

        toll_factor = matrix_network(toll_factor)
        toll = matrix_network(toll)

        length_factor = matrix_network(length_factor)
        length = matrix_network(length)

        new(
            free_flow_time,
            capacity,
            alpha,
            beta, toll_factor,
            toll, length_factor,
            length
        )
    end
end

function BPR(traffic::Traffic)
    n_nodes = traffic.n_nodes
    network = traffic.network
    options = traffic.options

    from = network.from
    to = network.to

    free_flow_time = network.free_flow_time
    capacity = network.capacity
    alpha = network.alpha
    beta = network.beta

    toll_factor = options.toll_factor
    toll = network.toll

    length_factor = options.length_factor
    length = network.length

    first_thru_node = options.first_thru_node
    @. free_flow_time[to<first_thru_node] = Inf

    BPR(
        n_nodes,
        from,
        to, free_flow_time=free_flow_time,
        capacity=capacity,
        alpha=alpha,
        beta=beta, toll_factor=toll_factor,
        toll=toll, length_factor=length_factor,
        length=length
    )
end

function (bpr::BPR)(flow::Union{Float64,SparseMatrixCSC{Float64,Int64}})
    out = @. bpr.free_flow_time * (1.0 + bpr.alpha * (flow / bpr.capacity)^bpr.beta)
    @. out + bpr.toll_factor * bpr.toll + bpr.length_factor * bpr.length
end

function objective(bpr::BPR, flow::Union{Float64,SparseMatrixCSC{Float64,Int64}})
    out = @. bpr.free_flow_time * (flow + bpr.alpha * (flow^(bpr.beta + 1.0)) / (bpr.beta + 1.0) / bpr.capacity^bpr.beta)
    @. out + (bpr.toll_factor * bpr.toll + bpr.length_factor * bpr.length) * flow

    sum(out)
end



# TrafficImpl
struct TrafficImpl
    trips::SparseMatrixCSC{Float64,Int}
    graph::SimpleDiGraph{Int}
    link_performance::AbstractLinkPerformance
end

function TrafficImpl(traffic::Traffic)
    n_nodes = traffic.n_nodes

    # trips
    trips = traffic.trips
    orig = trips.orig
    dest = trips.dest

    @assert !any(orig .== dest)

    trips = sparse(orig, dest, trips.trips, n_nodes, n_nodes)
    dropzeros!(trips)

    # graph
    network = traffic.network
    graph = DiGraph(n_nodes)

    for (from, to) in zip(network.from, network.to)
        add_edge!(graph, from, to)
    end

    # link_performance
    link_performance = BPR(traffic)

    TrafficImpl(trips, graph, link_performance)
end
