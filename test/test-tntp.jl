using UserEqm
using Test

using SparseArrays

import Graphs

@testset "tntp" begin
    tntp = load_tntp("SiouxFalls", toll_factor=1, length_factor=1)
end

tntp = load_tntp("Anaheim", toll_factor=1, length_factor=1)
tntp = TrafficImpl(tntp)

# tntp.link_performance
tntp.link_performance(0.)
objective(tntp.link_performance, 0.)

# traffic = Traffic(tntp)

# flow = all_or_nothing(traffic, 0.0)
# flow_new = all_or_nothing(traffic, flow)

# flow_new - flow

# a = sparse(1:3, 1:3, 1:3)
# b = sparse(1:3, [1, 2, 2], 1:3, 3, 3)
