abstract type AbstractLinkPerformanceImpl end

# BPR
struct BPRImpl <: AbstractLinkPerformanceImpl
    free_flow_time::Vector{Float64}
    free_flow_time_no_thru::Vector{Float64}

    capacity::Vector{Float64}
    alpha::Vector{Float64}
    beta::Vector{Float64}

    toll_factor::Vector{Float64}
    toll::Vector{Float64}

    length_factor::Vector{Float64}
    length::Vector{Float64}
end

function (bpr::BPRImpl)(
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

function link_performance_objective(
    bpr::BPRImpl,
    flow::Vector{Float64}
)
    out = @. bpr.free_flow_time * flow * (1.0 + bpr.alpha / (bpr.beta + 1.0) * (flow / bpr.capacity)^bpr.beta)
    @. out += (bpr.toll_factor * bpr.toll + bpr.length_factor * bpr.length) * flow

    return sum(out)
end

function link_performance_gradient(
    bpr::BPRImpl,
    flow::Vector{Float64}
)
    out = @. bpr.free_flow_time * bpr.alpha * bpr.beta * flow^(bpr.beta - 1.0) / bpr.capacity^bpr.beta
    @. out[!isfinite(out)] = 0

    return out
end
