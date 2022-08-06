struct TrafficAssignResults
    traffic::TrafficImpl
    flow::Vector{Float64}
    logs::AbstractTrafficAssignLogs
end

function assign_traffic(
    traffic::Traffic;
    flow_init::Vector{Float64}=[0.0],
    algorithm::AbstractTrafficAssignAlgorithm=BiconjugateFrankWolfe()
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
    algorithm::AbstractTrafficAssignAlgorithm=BiconjugateFrankWolfe()
)
    cost = traffic.link_performance(flow_init)
    flow = algorithm.assign_method(traffic, cost)

    flow, logs = algorithm(traffic, flow)

    return TrafficAssignResults(traffic, flow, logs)
end
