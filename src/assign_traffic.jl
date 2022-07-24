struct AssignTraffic
    traffic::TrafficImpl
    flow::Vector{Float64}
    objective::Vector{Float64}
    calc_time::Vector{Float64}
end

function assign_traffic(
    traffic::Traffic;
    algorithm::Symbol=:truncated_quadratic,
    search_method::AbstractOptimizer=GoldenSection(),
    max_iter::Int=1000,
    tol::Float64=1e-3,
    trace::Bool=true
)
    assign_traffic(
        TrafficImpl(traffic),
        algorithm=algorithm,
        search_method=search_method,
        max_iter=max_iter,
        tol=tol,
        trace=trace
    )
end

function assign_traffic(
    traffic::TrafficImpl;
    algorithm::Symbol=:truncated_quadratic,
    search_method::AbstractOptimizer=GoldenSection(),
    max_iter::Int=1000,
    tol::Float64=1e-3,
    trace::Bool=true
)
    cost = traffic.link_performance()
    flow = all_or_nothing(
        traffic,
        cost=cost
    )

    iter = 0
    obj = Float64[]
    calc_time_start = time()
    calc_time = Float64[]

    @assert algorithm in [:frank_wolfe, :truncated_quadratic]
    while true
        iter += 1

        if algorithm == :frank_wolfe
            flow, obj_new = frank_wolfe(
                traffic,
                flow=flow,
                search_method=search_method
            )
        elseif algorithm == :truncated_quadratic
            flow, obj_new = truncated_quadratic(
                traffic,
                flow=flow,
                iter=iter,
                search_method=search_method
            )
        end

        if trace
            @printf "Iteration: %7d, Objective: %13f\n" iter obj_new
        end

        # TODO
        push!(obj, obj_new)
        push!(calc_time, time() - calc_time_start)

        if iter >= max_iter
            break
        end
    end

    return AssignTraffic(
        traffic,
        flow,
        obj,
        calc_time
    )
end



# One dimensional search
function one_dimensional_search(
    link_performance::AbstractLinkPerformance;
    flow_start::Vector{Float64},
    flow_end::Vector{Float64},
    search_method::AbstractOptimizer=GoldenSection()
)
    f(x) = objective(link_performance, @. flow_start + x * (flow_end - flow_start))

    one_dimensional_search(
        f,
        flow_start=flow_start,
        flow_end=flow_end,
        search_method=search_method
    )
end

function one_dimensional_search(
    f::Function;
    flow_start::Vector{Float64},
    flow_end::Vector{Float64},
    search_method::AbstractOptimizer=GoldenSection()
)
    opt = optimize(f, 0.0, 1.0, method=search_method)
    obj = opt.minimum

    flow = @. flow_start + opt.minimizer * (flow_end - flow_start)

    return flow, obj
end



# Frank-Wolfe algorithm
function frank_wolfe(
    traffic::TrafficImpl;
    flow::Vector{Float64},
    search_method::AbstractOptimizer=GoldenSection(),
)
    link_performance = traffic.link_performance

    cost = link_performance(flow)
    flow_end = all_or_nothing(
        traffic,
        cost=cost
    )

    one_dimensional_search(
        link_performance,
        flow_start=flow,
        flow_end=flow_end,
        search_method=search_method
    )
end



# TODO: Bug Fix?
# Truncated Quadratic Programming method
function truncated_quadratic(
    traffic::TrafficImpl;
    flow::Vector{Float64},
    iter::Int,
    search_method::AbstractOptimizer=GoldenSection()
)
    link_performance = traffic.link_performance

    cost = link_performance(flow)
    grad = gradient(link_performance, flow)

    max_iter = min(4, Int(round(iter / 3)))

    iter = 0
    flow_end = copy(flow)

    while iter <= max_iter
        iter += 1

        # Sub problem
        cost_sub = @. cost + grad * (flow_end - flow)

        flow_sub = all_or_nothing(
            traffic,
            cost=cost_sub
        )

        function f(x)
            diff_flow = flow_end + x * (flow_sub - flow_end) - flow

            sum(@. cost * diff_flow + grad * diff_flow^2.0 / 2.0)
        end

        flow_end, _ = one_dimensional_search(
            f,
            flow_start=flow_end,
            flow_end=flow_sub,
            search_method=search_method
        )
    end

    one_dimensional_search(
        link_performance,
        flow_start=flow,
        flow_end=flow_end,
        search_method=search_method
    )
end



# Simplicial Decomposiotion method
function simplicial_decomposiotion(
    traffic::TrafficImpl;
    flow::Vector{Float64},
    max_elems::Int=5
)
    link_performance = traffic.link_performance

    # E
    elems = Vector{Vector{Float64}}
    
    # F
    elem = flow

    cost = link_performance(flow)
    flow_end = all_or_nothing(
        traffic,
        cost=cost
    )

    if cost' * (flow_end - flow) >= 0.0
        obj = objective(link_performance, flow)

        return flow, obj
    end


end