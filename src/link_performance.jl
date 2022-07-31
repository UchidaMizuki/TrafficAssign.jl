# Link performance
abstract type AbstractLinkPerformance end



# BPR
struct BPR <: AbstractLinkPerformance
    free_flow_time::Vector{Float64}
    free_flow_time_no_thru::Vector{Float64}

    capacity::Vector{Float64}
    alpha::Vector{Float64}
    beta::Vector{Float64}

    toll_factor::Vector{Float64}
    toll::Vector{Float64}

    length_factor::Vector{Float64}
    length::Vector{Float64}

    function BPR(traffic::Traffic)
        network = traffic.network
        options = traffic.options
    
        n = size(network, 1)
    
        free_flow_time = network.free_flow_time
    
        free_flow_time_no_thru = copy(free_flow_time)
        no_thru_node = @. network.to < options.first_thru_node
        free_flow_time_no_thru[no_thru_node] .= Inf
    
        capacity = network.capacity
        alpha = network.alpha
        beta = network.beta
    
        toll_factor = fill(options.toll_factor, n)
        toll = network.toll
    
        length_factor = fill(options.length_factor, n)
        length = network.length
    
        new(
            free_flow_time,
            free_flow_time_no_thru,
            capacity,
            alpha,
            beta,
            toll_factor,
            toll,
            length_factor,
            length
        )
    end
end

function (bpr::BPR)(
    flow::Vector{Float64};
    no_thru::Bool=true
)
    if no_thru
        free_flow_time = bpr.free_flow_time_no_thru
    else
        free_flow_time = bpr.free_flow_time
    end

    out = @. free_flow_time * (1.0 + bpr.alpha * (flow / bpr.capacity)^bpr.beta)
    @. out += bpr.toll_factor * bpr.toll + bpr.length_factor * bpr.length

    return out
end



# Objective function
function objective(
    bpr::BPR,
    flow::Vector{Float64}
)
    out = @. bpr.free_flow_time * flow * (1.0 + bpr.alpha / (bpr.beta + 1.0) * (flow / bpr.capacity)^bpr.beta)
    @. out += (bpr.toll_factor * bpr.toll + bpr.length_factor * bpr.length) * flow

    return sum(out)
end



# Gradient function
function gradient(
    bpr::BPR,
    flow::Vector{Float64}
)
    out = @. bpr.free_flow_time * bpr.alpha * bpr.beta * flow^(bpr.beta - 1.0) / bpr.capacity^bpr.beta
    @. out[!isfinite(out)] = 0

    return out
end
