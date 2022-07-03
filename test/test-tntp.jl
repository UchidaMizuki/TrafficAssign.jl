using TrafficAssign
using Test

@testset "tntp" begin
    tntp = load_tntp("SiouxFalls", toll_factor=1, length_factor=1)
end
