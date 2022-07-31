struct TrafficAssigResults
    traffic::TrafficImpl
    flow::Vector{Float64}
    logs::TrafficAssigLogs
end

function assign_traffic(
    traffic::Traffic;
    flow_init::Vector{Float64}=[0.0],
    algorithm::AbstractTrafficAssigAlgorithm=BiconjugateFrankWolfe()
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
    algorithm::AbstractTrafficAssigAlgorithm=BiconjugateFrankWolfe()
)
    cost = traffic.link_performance(flow_init)
    flow = all_or_nothing(traffic, cost)

    flow, logs = algorithm(traffic, flow)

    return TrafficAssigResults(traffic, flow, logs)
end
