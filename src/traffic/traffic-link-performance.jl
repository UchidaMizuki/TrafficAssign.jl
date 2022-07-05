abstract type AbstractLinkPerformance end

# BPR
struct BPR <: AbstractLinkPerformance
    free_flow_time::Matrix{Float64}
    capacity::Matrix{Float64}
    alpha::Matrix{Float64}
    beta::Matrix{Float64}

    toll_factor::Float64
    toll::Matrix{Float64}
    
    length_factor::Float64
    length::Matrix{Float64}

    function BPR(traffic::Traffic)
        n_nodes = traffic.n_nodes
        network = traffic.network
        options = traffic.options

        from = network.from
        to = network.to
    
        matrix_network = x -> Matrix(SparseArrays.sparse(from, to, x, n_nodes, n_nodes))

        free_flow_time = matrix_network(network.free_flow_time)
        capacity = matrix_network(network.capacity)
        alpha = matrix_network(network.alpha)
        beta = matrix_network(network.beta)
        
        toll_factor = options.toll_factor
        toll = matrix_network(network.toll)
        
        length_factor = options.length_factor
        length = matrix_network(network.length)

        new(free_flow_time, capacity, alpha, beta, toll_factor, toll, length_factor, length)
    end
end

function (bpr::BPR)(flow::Matrix{Float64})
    out = @. bpr.free_flow_time * (1.0 + bpr.alpha * (flow / bpr.capacity)^bpr.beta)
    @. out + bpr.toll_factor * bpr.toll + bpr.length_factor * bpr.length
end
