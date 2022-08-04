struct Traffic
    n_nodes::Int
    trips::DataFrame
    network::DataFrame
    link_performance::AbstractLinkPerformance
end

function Traffic(
    trips::DataFrame,
    network::DataFrame;
    link_performance::AbstractLinkPerformance=BPR()
)
    # TODO: Support for non BPR functions.
    if typeof(link_performance) == BPR
        select!(trips, :orig, :dest, :trips)
        select!(network, :from, :to, :free_flow_time, :capacity, :alpha, :beta, :toll, :length)
    end

    n_nodes = max([network.from; network.to]...)

    Traffic(
        n_nodes,
        trips,
        network,
        link_performance
    )
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
