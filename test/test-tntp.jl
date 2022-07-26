using TrafficAssig
using Test

@testset "tntp" begin
    tntp = load_tntp("SiouxFalls")
end

# tntp = load_tntp("Anaheim")
# # @time res = assign_traffic(tntp, max_iter=100, trace=true); nothing
# @time res2 = assign_traffic(tntp, max_iter=100, algorithm=:frank_wolfe, trace=true); nothing

# res.flow
# res2.flow
# res.objective < res2.objective

# using TrafficAssignment
# ta_data = load_ta_network("Anaheim")
# @time link_flow, link_travel_time, objective = ta_frank_wolfe(ta_data, tol=1e-6, method=:fw, log=:on, max_iter_no=100); nothing
# objective
