function assign_traffic(
    traffic::Traffic;
    flow_init::Vector{Float64}=[0.0],
    algorithm::AbstractTrafficAssigAlgorithm=FrankWolfe()
)
    assign_traffic(
        TrafficImpl(traffic),
        flow_init=flow_init,
        algorithm=algorithm
    )
end

function assign_traffic(
    traffic::TrafficImpl;
    flow_init::Vector{Float64}=[0.0],
    algorithm::AbstractTrafficAssigAlgorithm=FrankWolfe()
)
    cost = traffic.link_performance(flow_init)
    flow = all_or_nothing(traffic, cost)

    flow, logs = algorithm(traffic, flow)

    return flow, logs
end



# One dimensional search
function one_dimensional_search(
    link_performance::AbstractLinkPerformance,
    flow::Vector{Float64},
    Δflow::Vector{Float64};
    search_method::AbstractOptimizer=GoldenSection()
)
    f(τ) = objective(link_performance, @. flow + τ * Δflow)

    one_dimensional_search(
        f, 
        search_method=search_method
    )
end

function one_dimensional_search(
    f::Function;
    search_method::AbstractOptimizer=GoldenSection()
)
    opt = optimize(
        f, 0.0, 1.0,
        method=search_method
    )

    τ = opt.minimizer
    obj = opt.minimum

    return τ, obj
end
