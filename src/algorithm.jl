abstract type AbstractTrafficAssigAlgorithm end

@kwdef struct FrankWolfe <: AbstractTrafficAssigAlgorithm
    search_method::AbstractOptimizer = GoldenSection()
    tol::Float64 = 1e-4
    max_iter = 1000
    trace::Bool = false
end

@kwdef struct ConjugateFrankWolfe <: AbstractTrafficAssigAlgorithm
    search_method::AbstractOptimizer = GoldenSection()
    δ::Float64 = 1e-6
    tol::Float64 = 1e-4
    max_iter = 1000
    trace::Bool = false
end

@kwdef struct BiconjugateFrankWolfe <: AbstractTrafficAssigAlgorithm
    search_method::AbstractOptimizer = GoldenSection()
    δ::Float64 = 1e-6
    tol::Float64 = 1e-4
    max_iter = 1000
    trace::Bool = false
end

@kwdef mutable struct TrafficAssigLogs
    best_lower_bound::Float64 = -Inf64
    upper_bound::Float64 = 0.0
    relative_gap::Vector{Float64} = Float64[]

    exec_time_start::Float64 = time()
    exec_time::Vector{Float64} = Float64[]
end

function (algorithm::FrankWolfe)(
    traffic::TrafficImpl,
    flow::Vector{Float64}
)
    link_performance = traffic.link_performance

    logs = TrafficAssigLogs()

    for iter in 1:algorithm.max_iter
        flow_FW, Δflow_FW = direction_frank_wolfe(traffic, flow)
        best_lower_bound!(logs, traffic, flow, flow_FW)

        τ, logs.upper_bound = one_dimensional_search(
            link_performance, flow, Δflow_FW,
            search_method=algorithm.search_method
        )
        relative_gap!(logs)

        flow = @. flow + τ * Δflow_FW
        exec_time!(logs)

        if algorithm.trace
            trace_logs(iter, logs)
        end

        if last(logs.relative_gap) < algorithm.tol
            break
        end
    end

    return flow, logs
end

function (algorithm::ConjugateFrankWolfe)(
    traffic::TrafficImpl,
    flow::Vector{Float64}
)
    link_performance = traffic.link_performance

    n_edges = size(flow, 1)

    flow_FW = flow # y_k^FW
    flow_CFW = flow # s_k^CFW

    Δflow_FW = Vector{Float64}(undef, n_edges) # d_k^FW
    Δflow_CFW = Vector{Float64}(undef, n_edges) # d_k^CFW

    δ = algorithm.δ

    τ = 1.0

    logs = TrafficAssigLogs()

    for iter in 1:algorithm.max_iter
        flow_FW, Δflow_FW = direction_frank_wolfe(traffic, flow)
        best_lower_bound!(logs, traffic, flow, flow_FW)

        if τ > 1 - δ
            # Frank-Wolfe
            flow_CFW = flow_FW
            Δflow_CFW = flow_CFW - flow
        else
            # Conjugate Frank-Wolfe
            flow_CFW, Δflow_CFW = direction_conjugate_frank_wolfe(
                traffic, flow,
                flow_FW=flow_FW,
                flow_CFW=flow_CFW,
                Δflow_FW=Δflow_FW,
                Δflow_CFW=Δflow_CFW,
                τ=τ,
                δ=δ
            )
        end

        τ, logs.upper_bound = one_dimensional_search(
            link_performance, flow, Δflow_CFW,
            search_method=algorithm.search_method
        )
        relative_gap!(logs)

        flow = @. flow + τ * Δflow_CFW
        exec_time!(logs)

        if algorithm.trace
            trace_logs(iter, logs)
        end

        if last(logs.relative_gap) < algorithm.tol
            break
        end
    end

    return flow, logs
end

function (algorithm::BiconjugateFrankWolfe)(
    traffic::TrafficImpl,
    flow::Vector{Float64}
)
    link_performance = traffic.link_performance

    n_edges = size(flow, 1)

    flow_FW = flow # y_k^FW
    flow_BFW = flow # s_k^BFW
    flow_BFW_pred = flow # s_{k-1}^BFW

    Δflow_FW = Vector{Float64}(undef, n_edges) # d_k^FW
    Δflow_BFW = Vector{Float64}(undef, n_edges) # d_k^BFW
    Δflow_BFW_pred = Vector{Float64}(undef, n_edges) # d_{k-1}^BFW

    δ = algorithm.δ

    τ_pred = 1.0
    τ = 1.0

    logs = TrafficAssigLogs()

    for iter in 1:algorithm.max_iter
        flow_FW, Δflow_FW = direction_frank_wolfe(traffic, flow)
        best_lower_bound!(logs, traffic, flow, flow_FW)

        # if τ > 1 - δ
        #     # Frank-Wolfe
        #     flow_BFW_pred = flow_FW
        #     Δflow_BFW = flow_BFW - flow
        #     # TODO

        # elseif τ_pred > 1 - δ
        #     # Conjugate Frank-Wolfe
        #     # TODO

        # else
            
    end

        # if τ > 1 - δ
        #     flow_CFW = flow_FW
        #     Δflow_CFW = flow_CFW - flow
        # else
        #     flow_CFW, Δflow_CFW = direction_conjugate_frank_wolfe(
        #         traffic, flow,
        #         flow_FW=flow_FW,
        #         flow_CFW=flow_CFW,
        #         Δflow_FW=Δflow_FW,
        #         Δflow_CFW=Δflow_CFW,
        #         τ=τ,
        #         δ=δ
        #     )
        # end

        # τ, logs.upper_bound = one_dimensional_search(
        #     link_performance, flow, Δflow_CFW,
        #     search_method=algorithm.search_method
        # )
        # relative_gap!(logs)

        # flow = @. flow + τ * Δflow_CFW
        # exec_time!(logs)

        if algorithm.trace
            trace_logs(iter, logs)
        end

        if last(logs.relative_gap) < algorithm.tol
            break
        end
    end

    return flow, logs
end

function direction_frank_wolfe(
    traffic::TrafficImpl,
    flow::Vector{Float64}
)
    cost = traffic.link_performance(flow)
    flow_FW = all_or_nothing(traffic, cost)
    Δflow_FW = flow_FW - flow

    return flow_FW, Δflow_FW
end

function direction_conjugate_frank_wolfe(
    traffic::TrafficImpl,
    flow::Vector{Float64};
    flow_FW::Vector{Float64},
    flow_CFW::Vector{Float64},
    Δflow_FW::Vector{Float64},
    Δflow_CFW::Vector{Float64},
    τ::Float64,
    δ::Float64
)
    Δflow_bar = (1.0 - τ) * Δflow_CFW
    H = gradient(traffic.link_performance, flow)
    N = Δflow_bar' * (H .* Δflow_FW)
    D = Δflow_bar' * (H .* (Δflow_FW - Δflow_bar))

    N_D = N / D
    if D != 0.0 && 0.0 <= N_D <= 1.0 - δ
        a = N_D
    elseif D != 0.0 && 1.0 - δ < N_D
        a = 1.0 - δ
    else
        a = 0.0
    end

    flow_CFW = @. a * flow_CFW + (1.0 - a) * flow_FW
    Δflow_CFW = flow_CFW - flow

    return flow_CFW, Δflow_CFW
end

function best_lower_bound!(
    logs::TrafficAssigLogs,
    traffic::TrafficImpl,
    flow::Vector{Float64},
    flow_end::Vector{Float64}
)
    link_performance = traffic.link_performance

    cost = link_performance(
        flow,
        no_thru=false
    )

    lower_bound = objective(link_performance, flow) + cost' * (flow_end - flow)
    logs.best_lower_bound = max(logs.best_lower_bound, lower_bound)

    return logs
end

function relative_gap!(logs::TrafficAssigLogs)
    best_lower_bound = logs.best_lower_bound

    gap = logs.upper_bound - best_lower_bound

    relative_gap = gap / abs(best_lower_bound)

    push!(logs.relative_gap, relative_gap)

    return logs
end

function exec_time!(logs::TrafficAssigLogs)
    push!(logs.exec_time, time() - logs.exec_time_start)

    return logs
end

function trace_logs(
    iter::Int,
    logs::TrafficAssigLogs
)
    @printf "Iteration: %7d, Objective: %13f, Execution-Time: %13f\n" iter last(logs.relative_gap) last(logs.exec_time)
end

# Truncated Quadratic Programming method
# function truncated_quadratic(
#     traffic::TrafficImpl;
#     flow::Vector{Float64},
#     iter::Int,
#     search_method::AbstractOptimizer=GoldenSection()
# )
#     link_performance = traffic.link_performance

#     cost = link_performance(flow)
#     grad = gradient(link_performance, flow)

#     max_iter = min(4, Int(round(iter / 3)))

#     iter = 0
#     flow_end = copy(flow)

#     while true
#         # Sub problem
#         cost_sub = @. cost + grad * (flow_end - flow)

#         flow_sub = all_or_nothing(
#             traffic,
#             cost=cost_sub
#         )

#         function f(x)
#             diff_flow = flow_end + x * (flow_sub - flow_end) - flow

#             return sum(@. cost * diff_flow + grad * diff_flow^2.0 / 2.0)
#         end

#         flow_end, _ = one_dimensional_search(
#             f,
#             flow_start=flow_end,
#             flow_end=flow_sub,
#             search_method=search_method
#         )

#         if iter >= max_iter
#             break
#         else
#             iter += 1
#         end
#     end

#     one_dimensional_search(
#         link_performance,
#         flow_start=flow,
#         flow_end=flow_end,
#         search_method=search_method
#     )
# end

# Simplicial Decomposition method
# function simplicial_decomposition(
#     traffic::TrafficImpl;
#     flow::Vector{Float64},
#     max_elems::Int=5
# )
#     link_performance = traffic.link_performance

#     cost = link_performance(flow)
#     flow_end = all_or_nothing(
#         traffic,
#         cost=cost
#     )

#     # TODO
#     if cost' * (flow_end - flow) >= 0.0
#         obj = objective(link_performance, flow)

#         return flow, obj
#     end

#     if size(elems, 1) < max_elems
#         push!(elems, flow_end)
#     else
#         deleteat!(elems, argmin(weights))
#         push!(elems, flow_end)
#         elem = flow
#     end


# end