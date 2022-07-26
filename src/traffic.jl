# Traffic
Base.@kwdef struct TrafficOptions
    link_performance::Symbol=:BPR
    first_thru_node::Int = 1
    toll_factor::Float64 = 0.0
    length_factor::Float64 = 0.0
end

struct Traffic
    n_nodes::Int
    trips::DataFrame
    network::DataFrame
    options::TrafficOptions

    function Traffic(
        trips::DataFrame,
        network::DataFrame;
        options::TrafficOptions=TrafficOptions()
    )
        # TODO: Support for non BPR functions.
        link_performance = options.link_performance
        @assert link_performance in [:BPR]
    
        if link_performance == :BPR
            trips = trips |>
                x -> select(x, :orig, :dest, :trips)
            network = network |>
                x -> select(x, :from, :to, :free_flow_time, :capacity, :alpha, :beta, :toll, :length)
        end
    
        n_nodes = max([network.from; network.to]...)
    
        return new(
            n_nodes,
            trips,
            network,
            options
        )
    end
end

function Base.show(
    io::IO, 
    mime::MIME"text/plain", 
    traffic::Traffic
)
    print(io, "Number of nodes: $(traffic.n_nodes)\n")
    print(io, "Trips:\n")
    show(io, mime, traffic.trips)
    print(io, "\n\n")
    print(io, "Network:\n")
    show(io, mime, traffic.network)

    return nothing
end
