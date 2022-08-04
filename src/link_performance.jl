abstract type AbstractLinkPerformance end

@kwdef struct BPR <: AbstractLinkPerformance
    first_thru_node::Int = 1
    toll_factor::Float64 = 0.0
    length_factor::Float64 = 0.0
end

function (bpr::BPR)(network::DataFrame)
    n = size(network, 1)

    free_flow_time = network.free_flow_time

    free_flow_time_no_thru = copy(free_flow_time)
    no_thru_node = @. network.to < bpr.first_thru_node
    free_flow_time_no_thru[no_thru_node] .= Inf

    capacity = network.capacity
    alpha = network.alpha
    beta = network.beta

    toll_factor = fill(bpr.toll_factor, n)
    toll = network.toll

    length_factor = fill(bpr.length_factor, n)
    length = network.length

    BPRImpl(
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
