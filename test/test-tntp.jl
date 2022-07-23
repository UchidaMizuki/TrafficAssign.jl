using UserEqm
using Test

# using SparseArrays

# import Graphs

@testset "tntp" begin
    tntp = load_tntp("SiouxFalls", toll_factor=1, length_factor=1)
end

tntp = load_tntp("SiouxFalls")
res = assign_traffic(tntp, trace=false, max_iter=1000)

# using Plots

# plot(log.(res.calc_time), log.(res.objective))

# res.objective

# using TrafficAssignment

# ta_data = load_ta_network("SiouxFalls")

# link_flow, link_travel_time, objective = ta_frank_wolfe(ta_data, tol=1e-6)
# objective