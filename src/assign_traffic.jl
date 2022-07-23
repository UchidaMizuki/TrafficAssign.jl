struct AssignTraffic
    traffic::TrafficImpl
    flow::SparseMatrixCSC{Float64,Int}
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
    trips = traffic.trips
    graph = traffic.graph
    link_performance = traffic.link_performance

    cost = link_performance()
    flow = all_or_nothing(
        trips,
        graph,
        cost=cost
    )

    @assert algorithm in [:frank_wolfe, :truncated_quadratic]
    if algorithm == :frank_wolfe
        algorithm = frank_wolfe
    elseif algorithm == :truncated_quadratic
        algorithm = truncated_quadratic
    end

    iter = 0
    obj = Float64[]
    calc_time_start = time()
    calc_time = Float64[]

    while true
        iter += 1

        flow, obj_new = algorithm(
            trips,
            graph,
            link_performance,
            flow=flow,
            iter=iter,
            search_method=search_method,
            trace=trace
        )

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
    flow_start::SparseMatrixCSC{Float64,Int},
    flow_end::SparseMatrixCSC{Float64,Int},
    search_method::AbstractOptimizer=GoldenSection(),
    trace::Bool=true
)
    f(x) = objective(link_performance, @. flow_start + x * (flow_end - flow_start))

    one_dimensional_search(
        f,
        link_performance,
        flow_start=flow_start,
        flow_end=flow_end,
        search_method=search_method,
        trace=trace
    )
end

function one_dimensional_search(
    f::Function,
    link_performance::AbstractLinkPerformance;
    flow_start::SparseMatrixCSC{Float64,Int},
    flow_end::SparseMatrixCSC{Float64,Int},
    search_method::AbstractOptimizer=GoldenSection(),
    trace::Bool=true
)
    opt = optimize(f, 0.0, 1.0, method=search_method)
    obj = opt.minimum

    if trace
        @printf "Objective: %15f\n" obj
    end

    flow = @. flow_start + opt.minimizer * (flow_end - flow_start)

    return flow, obj
end



# Frank-Wolfe algorithm
function frank_wolfe(
    trips::SparseMatrixCSC{Float64,Int},
    graph::SimpleDiGraph{Int},
    link_performance::AbstractLinkPerformance;
    flow::SparseMatrixCSC{Float64,Int},
    iter::Int,
    search_method::AbstractOptimizer=GoldenSection(),
    trace::Bool=true
)
    cost = link_performance(flow)
    flow_end = all_or_nothing(
        trips,
        graph,
        cost=cost
    )

    one_dimensional_search(
        link_performance,
        flow_start=flow,
        flow_end=flow_end,
        search_method=search_method,
        trace=trace
    )
end



# Truncated Quadratic Programming method
function truncated_quadratic(
    trips::SparseMatrixCSC{Float64,Int},
    graph::SimpleDiGraph{Int},
    link_performance::AbstractLinkPerformance;
    flow::SparseMatrixCSC{Float64,Int},
    iter::Int,
    search_method::AbstractOptimizer=GoldenSection(),
    trace::Bool=true
)
    cost = link_performance(flow)
    grad = gradient(link_performance, flow)

    max_iter = min(4, Int(round(iter / 3)))
    iter = 0
    flow_start = flow

    while iter < max_iter
        iter += 1

        cost_end = @. cost + grad * (flow_start - flow)
        flow_end = all_or_nothing(
            trips,
            graph,
            cost=cost_end
        )

        function f(x)
            diff_flow = flow_start + x * (flow_end - flow_start) - flow

            sum(@. cost * diff_flow + 1.0 / 2.0 * grad * diff_flow^2.0)
        end

        flow_start, _ = one_dimensional_search(
            f,
            link_performance,
            flow_start=flow_start,
            flow_end=flow_end,
            search_method=search_method,
            trace=false
        )
    end

    one_dimensional_search(
        link_performance,
        flow_start=flow,
        flow_end=flow_start,
        search_method=search_method,
        trace=trace
    )
end
