struct AssignTraffic
    traffic::TrafficImpl
    flow::Vector{Float64}
    objective::Vector{Float64}
    calc_time::Vector{Float64}
end

Base.@kwdef mutable struct AssignTrafficAttrs
    search_method::AbstractOptimizer
    max_iter::Int
    tol::Float64
    trace::Bool

    iter::Int = 0

    best_lower_bound::Float64 = -Inf64
    upper_bound::Float64 = 0.0

    calc_time_start::Float64 = time()
    calc_time::Vector{Float64} = Float64[]
end

function assign_traffic(
    traffic::Traffic;
    algorithm::Symbol=:FW,
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
    flow::Vector{Float64}=[0.0],
    algorithm::Symbol=:FW,
    search_method::AbstractOptimizer=GoldenSection(),
    max_iter::Int=1000,
    tol::Float64=1e-3,
    trace::Bool=true
)
    cost = traffic.link_performance(flow)
    flow = all_or_nothing(
        traffic,
        cost=cost
    )

    @assert algorithm in [:FW, :CFW, :BFW]
    if algorithm == :FW
        algorithm = frank_wolfe
    elseif algorithm == :CFW
        algorithm = conjugate_frank_wolfe
    elseif algorithm == :BFW
        algorithm = biconjugate_frank_wolfe
    end

    attrs = AssignTrafficAttrs(
        search_method=search_method,
        max_iter=max_iter,
        tol=tol,
        trace=trace
    )

    while attrs.iter <= max_iter
        flow, attrs = algorithm(
            traffic,
            flow=flow,
            attrs=attrs
        )

        # if trace
        #     @printf "Iteration: %7d, Objective: %13f\n" iter obj_new
        # end

        # TODO
        # push!(obj, obj_new)
        # push!(calc_time, time() - calc_time_start)

        attrs.iter += 1
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
    flow::Vector{Float64},
    Δflow::Vector{Float64},
    search_method::AbstractOptimizer=GoldenSection()
)
    f(x) = objective(link_performance, @. flow + x * Δflow)

    one_dimensional_search(
        f,
        flow=flow,
        Δflow=Δflow,
        search_method=search_method
    )
end

function one_dimensional_search(
    f::Function;
    flow::Vector{Float64},
    Δflow::Vector{Float64},
    search_method::AbstractOptimizer=GoldenSection()
)
    opt = optimize(f, 0.0, 1.0, method=search_method)
    obj = opt.minimum

    flow = @. flow + opt.minimizer * Δflow

    return flow, obj
end



# Frank-Wolfe algorithm
# function frank_wolfe(
#     traffic::TrafficImpl;
#     flow::Vector{Float64},
#     attrs::AssignTrafficAttrs
# )
#     link_performance = traffic.link_performance

#     cost = link_performance(flow)
#     flow_end = all_or_nothing(
#         traffic,
#         cost=cost
#     )
#     Δflow = flow_end - flow
#     lower_bound = objective(link_performance, flow) + cost' * Δflow
#     attrs.best_lower_bound = max(attrs.best_lower_bound, lower_bound)

#     flow, attrs.upper_bound = one_dimensional_search(
#         link_performance,
#         flow=flow,
#         Δflow=Δflow,
#         search_method=attrs.search_method
#     )

#     # TODO


    
# end



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