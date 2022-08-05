abstract type AbstractLinkPerformance end

@kwdef struct BPR <: AbstractLinkPerformance
    first_thru_node::Int = 1

    alpha::Float64 = 0.15
    beta::Float64 = 4.0

    toll::Float64 = 0.0
    toll_factor::Float64 = 0.0

    length::Float64 = 0.0
    length_factor::Float64 = 0.0
end

function (bpr::BPR)(network::DataFrame)
    n = size(network, 1)
    names_network = propertynames(network)

    free_flow_time = network.free_flow_time

    free_flow_time_no_thru = copy(free_flow_time)
    no_thru_node = @. network.to < bpr.first_thru_node
    free_flow_time_no_thru[no_thru_node] .= Inf

    capacity = network.capacity
    alpha = :alpha ∈ names_network ? network.alpha : fill(bpr.alpha, n)
    beta = :beta ∈ names_network ? network.beta : fill(bpr.beta, n)

    toll_factor = fill(bpr.toll_factor, n)
    toll = :tol ∈ names_network ? network.toll : fill(bpr.toll, n)

    length_factor = fill(bpr.length_factor, n)
    length = :length ∈ names_network ? network.length : fill(bpr.length, n)

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
