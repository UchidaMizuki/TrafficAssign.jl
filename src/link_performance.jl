# Link performance
abstract type AbstractLinkPerformance end

# Free flow link performance
function (link_performance::AbstractLinkPerformance)()
    n_nodes = link_performance.n_nodes
    flow = spzeros(n_nodes, n_nodes)
    link_performance(flow)
end



# BPR
struct BPR <: AbstractLinkPerformance
    n_nodes::Int
    from::Vector{Int}
    to::Vector{Int}

    free_flow_time::Vector{Float64}
    capacity::Vector{Float64}
    alpha::Vector{Float64}
    beta::Vector{Float64}

    toll_factor::Vector{Float64}
    toll::Vector{Float64}

    length_factor::Vector{Float64}
    length::Vector{Float64}

    function BPR(traffic::Traffic)
        n_nodes = traffic.n_nodes
        network = traffic.network
        options = traffic.options

        from = network.from
        to = network.to
        n = size(from, 1)

        free_flow_time = network.free_flow_time
        capacity = network.capacity
        alpha = network.alpha
        beta = network.beta

        toll_factor = fill(options.toll_factor, n)
        toll = network.toll

        length_factor = fill(options.length_factor, n)
        length = network.length

        first_thru_node = options.first_thru_node
        @. free_flow_time[to<first_thru_node] = Inf

        new(
            n_nodes,
            from,
            to, free_flow_time,
            capacity,
            alpha,
            beta, toll_factor,
            toll, length_factor,
            length
        )
    end
end

function (bpr::BPR)(flow::SparseMatrixCSC{Float64,Int64})
    from = bpr.from
    to = bpr.to
    flow = [flow[i] for i in zip(from, to)]

    out = @. bpr.free_flow_time * (1.0 + bpr.alpha * (flow / bpr.capacity)^bpr.beta)
    @. out += bpr.toll_factor * bpr.toll + bpr.length_factor * bpr.length

    n_nodes = bpr.n_nodes
    sparse(from, to, out, n_nodes, n_nodes)
end



# Objective function
function objective(
    bpr::BPR,
    flow::SparseMatrixCSC{Float64,Int64}
)
    from = bpr.from
    to = bpr.to
    flow = [flow[i] for i in zip(from, to)]

    out = @. bpr.free_flow_time * (flow + bpr.alpha * (flow^(bpr.beta + 1.0)) / (bpr.beta + 1.0) / bpr.capacity^bpr.beta)
    @. out += (bpr.toll_factor * bpr.toll + bpr.length_factor * bpr.length) * flow
    filter!(isfinite, out)

    sum(out)
end



# Gradient function
function gradient(
    bpr::BPR,
    flow::SparseMatrixCSC{Float64,Int64}
)
    from = bpr.from
    to = bpr.to
    flow = [flow[i] for i in zip(from, to)]

    out = @. bpr.free_flow_time * bpr.alpha * (1. / bpr.capacity)^bpr.beta

    n_nodes = bpr.n_nodes
    sparse(from, to, out, n_nodes, n_nodes)
end