function (algorithm::RestrictedSimplicialDecomposition)(
    traffic::TrafficImpl,
    flow::Vector{Float64}
)
    n = size(flow, 1)

    points = Array{Float64}(undef, n, 0) # W_s
    point = flow # W_x
    weights = Vector{Float64}(undef, n) # β

    logs = TrafficAssignLogs()
    if algorithm.trace
        start_logs()
    end

    for iter ∈ 1:algorithm.max_iter
        cost = traffic.link_performance(flow)
        flow_end = algorithm.assign_method(traffic, cost)
        update_best_lower_bound!(logs, traffic, flow, flow_end)
    
        if size(points, 2) < algorithm.max_points
            points = [points flow_end]
        else
            points[:, argmin(weights)] = flow_end
            point = flow
        end
    
        W = isnothing(point) ? points : [points point]
        r = size(W, 2)
    
        opt_model = Model()
        set_optimizer(opt_model, algorithm.optimizer)
    
        @variable(opt_model, β[1:r] .>= 0.0)
        @constraint(opt_model, sum(β) == 1.0)
    
        δf = traffic.link_performance(
            flow,
            no_thru=false
        )
        M = link_performance_gradient(
            traffic.link_performance, flow
        )
        @objective(
            opt_model, Min,
            δf' * (W * β - flow) + 1.0 / 2.0 * (W * β - flow)' * (M .* (W * β - flow))
        )
    
        optimize!(opt_model)
        weights = value.(β)
    
        weights_points = isnothing(point) ? weights : weights[1:end-1]
        points = points[:, weights_points.>algorithm.tol]
    
        if !isnothing(point) && last(weights) < algorithm.tol
            point = nothing
        end
    
        flow = W * weights
        logs.upper_bound = link_performance_objective(traffic.link_performance, flow)
        update_objective!(logs)
        update_relative_gap!(logs)
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
