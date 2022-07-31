abstract type AbstractTrafficAssigAlgorithm end

@kwdef struct FrankWolfe <: AbstractTrafficAssigAlgorithm
    search_method::AbstractOptimizer = GoldenSection()
    tol::Float64 = 1e-4
    max_iter = 1000
    trace::Bool = true
end

@kwdef struct ConjugateFrankWolfe <: AbstractTrafficAssigAlgorithm
    search_method::AbstractOptimizer = GoldenSection()
    δ::Float64 = 1e-6
    tol::Float64 = 1e-4
    max_iter = 1000
    trace::Bool = true
end

@kwdef struct BiconjugateFrankWolfe <: AbstractTrafficAssigAlgorithm
    search_method::AbstractOptimizer = GoldenSection()
    δ::Float64 = 1e-6
    tol::Float64 = 1e-4
    max_iter = 1000
    trace::Bool = true
end

@kwdef mutable struct TrafficAssigLogs
    best_lower_bound::Float64 = -Inf64
    upper_bound::Float64 = 0.0
    objective::Vector{Float64} = Float64[]
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
    if algorithm.trace
        start_logs()
    end

    for iter in 1:algorithm.max_iter
        flow_FW, Δflow_FW = dir_FW(traffic, flow)
        update_best_lower_bound!(logs, traffic, flow, flow_FW)

        τ, logs.upper_bound = one_dimensional_search(
            link_performance, flow, Δflow_FW,
            search_method=algorithm.search_method
        )
        update_objective!(logs)
        update_relative_gap!(logs)

        flow = @. flow + τ * Δflow_FW
        update_exec_time!(logs)

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

    flow_FW = Vector{Float64}(undef, n_edges) # y_k^FW
    flow_CFW = Vector{Float64}(undef, n_edges) # s_k^CFW

    Δflow_FW = Vector{Float64}(undef, n_edges) # d_k^FW
    Δflow_CFW = Vector{Float64}(undef, n_edges) # d_k^CFW

    δ = algorithm.δ
    τ = 1.0

    step_FW = :FW

    logs = TrafficAssigLogs()
    if algorithm.trace
        start_logs()
    end

    for iter in 1:algorithm.max_iter
        flow_FW, Δflow_FW = dir_FW(traffic, flow)
        update_best_lower_bound!(logs, traffic, flow, flow_FW)

        if step_FW == :FW
            # Frank-Wolfe
            flow_CFW = flow_FW
            Δflow_CFW = flow_CFW - flow

            step_FW = :CFW
        else
            # Conjugate Frank-Wolfe
            flow_CFW, Δflow_CFW = dir_CFW(
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
        if τ > 1 - δ
            step_FW = :FW
        end
        update_objective!(logs)
        update_relative_gap!(logs)

        flow = @. flow + τ * Δflow_CFW
        update_exec_time!(logs)

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

    flow_FW = Vector{Float64}(undef, n_edges) # y_k^FW
    flow_BFW = Vector{Float64}(undef, n_edges) # s_k^BFW
    flow_BFW_pred = Vector{Float64}(undef, n_edges) # s_{k-1}^BFW

    Δflow_FW = Vector{Float64}(undef, n_edges) # d_k^FW
    Δflow_BFW = Vector{Float64}(undef, n_edges) # d_k^BFW
    Δflow_BFW_pred = Vector{Float64}(undef, n_edges) # d_{k-1}^BFW

    δ = algorithm.δ

    τ = 1.0
    τ_pred = 1.0

    step_FW = :FW

    logs = TrafficAssigLogs()
    if algorithm.trace
        start_logs()
    end

    for iter in 1:algorithm.max_iter
        flow_FW, Δflow_FW = dir_FW(traffic, flow)
        update_best_lower_bound!(logs, traffic, flow, flow_FW)

        if step_FW == :FW
            # Frank-Wolfe
            flow_BFW = flow_FW
            Δflow_BFW = flow_BFW - flow

            step_FW = :CFW
        elseif step_FW == :CFW
            # Conjugate Frank-Wolfe
            flow_BFW_pred = flow_BFW
            Δflow_BFW_pred = Δflow_BFW
            flow_BFW, Δflow_BFW = dir_CFW(
                traffic, flow,
                flow_FW=flow_FW,
                flow_CFW=flow_BFW,
                Δflow_FW=Δflow_FW,
                Δflow_CFW=Δflow_BFW,
                τ=τ,
                δ=δ
            )

            step_FW = :BFW
        else
            # Biconjugate Frank-Wolfe
            flow_BFW_new, Δflow_BFW_new = dir_BFW(
                traffic, flow,
                flow_FW=flow_FW,
                flow_BFW=flow_BFW,
                flow_BFW_pred=flow_BFW_pred,
                Δflow_FW=Δflow_FW,
                Δflow_BFW=Δflow_BFW,
                Δflow_BFW_pred=Δflow_BFW_pred,
                τ=τ,
                τ_pred=τ_pred
            )
            flow_BFW_pred = flow_BFW
            Δflow_BFW_pred = Δflow_BFW
            flow_BFW = flow_BFW_new
            Δflow_BFW = Δflow_BFW_new
        end

        τ_pred = τ
        τ, logs.upper_bound = one_dimensional_search(
            link_performance, flow, Δflow_BFW,
            search_method=algorithm.search_method
        )
        if τ > 1 - δ
            step_FW = :FW
        end
        update_objective!(logs)
        update_relative_gap!(logs)

        flow = @. flow + τ * Δflow_BFW
        update_exec_time!(logs)

        if algorithm.trace
            trace_logs(iter, logs)
        end

        if last(logs.relative_gap) < algorithm.tol
            break
        end
    end

    return flow, logs
end

function dir_FW(
    traffic::TrafficImpl,
    flow::Vector{Float64}
)
    cost = traffic.link_performance(flow)
    flow_FW = all_or_nothing(traffic, cost)
    Δflow_FW = flow_FW - flow

    return flow_FW, Δflow_FW
end

function dir_CFW(
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

    # a: alpha
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

function dir_BFW(
    traffic::TrafficImpl,
    flow::Vector{Float64};
    flow_FW::Vector{Float64},
    flow_BFW::Vector{Float64},
    flow_BFW_pred::Vector{Float64},
    Δflow_FW::Vector{Float64},
    Δflow_BFW::Vector{Float64},
    Δflow_BFW_pred::Vector{Float64},
    τ::Float64,
    τ_pred::Float64
)
    Δflow_bar = (1.0 - τ) * Δflow_BFW
    Δflow_bar_bar = (1.0 - τ) * (1 - τ_pred) * Δflow_BFW_pred # τ * flow_BFW - flow + (1 - τ) * flow_BFW_pred

    H = gradient(traffic.link_performance, flow)
    μ = -(Δflow_bar_bar' * (H .* Δflow_FW)) / (Δflow_bar_bar' * (H .* (flow_BFW_pred - flow_BFW)))
    v = -(Δflow_bar' * (H .* Δflow_FW)) / (Δflow_bar' * (H .* Δflow_bar)) + μ * τ / (1 - τ) # v: nu

    μ = max(0.0, μ)
    v = max(0.0, v)

    β_FW = 1.0 / (1.0 + μ + v)
    β_BFW = v * β_FW
    β_BFW_pred = μ * β_FW

    flow_BFW = β_FW * flow_FW + β_BFW * flow_BFW + β_BFW_pred * flow_BFW_pred
    Δflow_BFW = flow_BFW - flow

    return flow_BFW, Δflow_BFW
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



# Update and trace logs
function start_logs()
    @printf "Start Execution\n"
end

function update_best_lower_bound!(
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

function update_objective!(logs::TrafficAssigLogs)
    push!(logs.objective, logs.upper_bound)

    return logs
end

function update_relative_gap!(logs::TrafficAssigLogs)
    best_lower_bound = logs.best_lower_bound

    gap = logs.upper_bound - best_lower_bound

    relative_gap = gap / abs(best_lower_bound)

    push!(logs.relative_gap, relative_gap)

    return logs
end

function update_exec_time!(logs::TrafficAssigLogs)
    push!(logs.exec_time, time() - logs.exec_time_start)

    return logs
end

function trace_logs(
    iter::Int,
    logs::TrafficAssigLogs
)
    obj = last(logs.objective)
    relative_gap = last(logs.relative_gap)
    exec_time = last(logs.exec_time)
    @printf "Iteration: %7d, Objective: %13f, Relative-Gap: %13f, Execution-Time: %13f\n" iter obj relative_gap exec_time
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