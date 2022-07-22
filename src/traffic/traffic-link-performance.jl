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

function BPR(tntp::TNTP)
    n_nodes = tntp.n_nodes
    network = tntp.network
    options = tntp.options

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

function objective(bpr::BPR, flow::Matrix{Float64})

end