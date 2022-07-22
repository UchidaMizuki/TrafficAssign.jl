Base.@kwdef struct TNTPOptions
    first_thru_node::Int = 1
    toll_factor::Float64 = 0.0
    length_factor::Float64 = 0.0
end

struct TNTP
    n_nodes::Int
    trips::DataFrame
    network::DataFrame
    options::TNTPOptions
    function TNTP(trips::DataFrame, network::DataFrame; options::TNTPOptions=TNTPOptions())
        trips = select(trips, :orig, :dest, :trips)
        network = select(network, :from, :to, :free_flow_time, :capacity, :alpha, :beta, :toll, :length)
        n_nodes = max([network.from; network.to]...)

        return new(n_nodes, trips, network, options)
    end
end

function Base.show(io::IO, mime::MIME"text/plain", tntp::TNTP)
    print(io, "# Number of nodes: $(tntp.n_nodes)\n")
    print(io, "# Trips:\n")
    show(io, mime, tntp.trips)
    print(io, "\n\n")
    print(io, "# Network:\n")
    show(io, mime, tntp.network)

    return nothing
end
