using TrafficAssig
using Test

@testset "tntp" begin
    tntp = load_tntp("SiouxFalls")
end

tntp = load_tntp("Anaheim")

@time res = assign_traffic(
    tntp,
    algorithm=FrankWolfe()
)
# @time res = assign_traffic(
#     tntp,
#     algorithm=ConjugateFrankWolfe()
# )
# @time res = assign_traffic(
#     tntp,
#     algorithm=BiconjugateFrankWolfe()
# )

# using TrafficAssignment
# ta_data = load_ta_network("GoldCoast")
# @time link_flow, link_travel_time, objective = ta_frank_wolfe(ta_data, tol=1e-6, log=:on)
