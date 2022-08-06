function (algorithm::FrankWolfe)(
    traffic::TrafficImpl,
    flow::Vector{Float64}
)
    logs = TrafficAssignLogs()
    if algorithm.trace
        start_logs()
    end

    for iter ∈ 1:algorithm.max_iter
        flow_FW, Δflow_FW = dir_FW(
            traffic, flow,
            assign_method=algorithm.assign_method
        )
        update_best_lower_bound!(logs, traffic, flow, flow_FW)

        τ, logs.upper_bound = one_dimensional_search(
            traffic.link_performance, flow, Δflow_FW,
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
    n_edges = size(flow, 1)

    flow_FW = Vector{Float64}(undef, n_edges) # y_k^FW
    flow_CFW = Vector{Float64}(undef, n_edges) # s_k^CFW

    Δflow_FW = Vector{Float64}(undef, n_edges) # d_k^FW
    Δflow_CFW = Vector{Float64}(undef, n_edges) # d_k^CFW

    tol = algorithm.tol
    δ = algorithm.delta
    τ = 1.0

    step_FW = :FW

    logs = TrafficAssignLogs()
    if algorithm.trace
        start_logs()
    end

    for iter ∈ 1:algorithm.max_iter
        flow_FW, Δflow_FW = dir_FW(
            traffic, flow,
            assign_method=algorithm.assign_method
        )
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
        if τ > 1 - tol
            step_FW = :FW
        end
        update_objective!(logs)
        update_relative_gap!(logs)

        flow = @. flow + τ * Δflow_CFW
        update_exec_time!(logs)

        if algorithm.trace
            trace_logs(iter, logs)
        end

        if last(logs.relative_gap) < tol
            break
        end
    end

    return flow, logs
end

function (algorithm::BiconjugateFrankWolfe)(
    traffic::TrafficImpl,
    flow::Vector{Float64}
)
    n_edges = size(flow, 1)

    flow_FW = Vector{Float64}(undef, n_edges) # y_k^FW
    flow_BFW = Vector{Float64}(undef, n_edges) # s_k^BFW
    flow_BFW_pred = Vector{Float64}(undef, n_edges) # s_{k-1}^BFW

    Δflow_FW = Vector{Float64}(undef, n_edges) # d_k^FW
    Δflow_BFW = Vector{Float64}(undef, n_edges) # d_k^BFW
    Δflow_BFW_pred = Vector{Float64}(undef, n_edges) # d_{k-1}^BFW

    tol = algorithm.tol
    δ = algorithm.delta

    τ = 1.0
    τ_pred = 1.0

    step_FW = :FW

    logs = TrafficAssignLogs()
    if algorithm.trace
        start_logs()
    end

    for iter ∈ 1:algorithm.max_iter
        flow_FW, Δflow_FW = dir_FW(
            traffic, flow,
            assign_method=algorithm.assign_method
        )
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
        if τ > 1 - tol
            step_FW = :FW
        end
        update_objective!(logs)
        update_relative_gap!(logs)

        flow = @. flow + τ * Δflow_BFW
        update_exec_time!(logs)

        if algorithm.trace
            trace_logs(iter, logs)
        end

        if last(logs.relative_gap) < tol
            break
        end
    end

    return flow, logs
end

function dir_FW(
    traffic::TrafficImpl,
    flow::Vector{Float64};
    assign_method::AbstractTrafficAssignMethod
)
    cost = traffic.link_performance(flow)
    flow_FW = assign_method(traffic, cost)
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

    H = link_performance_gradient(traffic.link_performance, flow)
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

    H = link_performance_gradient(traffic.link_performance, flow)
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
