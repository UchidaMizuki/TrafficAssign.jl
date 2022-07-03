Base.@kwdef struct TrafficOptions
  first_thru_node::Int = 1
  toll_factor::Float64 = 0
  length_factor::Float64 = 0
end

struct Traffic
  trips::DataFrames.DataFrame
  network::DataFrames.DataFrame
  options::TrafficOptions
  function Traffic(trips::DataFrames.DataFrame, network::DataFrames.DataFrame; options::TrafficOptions=TrafficOptions())
    trips = trips[:, [:orig, :dest, :trips]]
    network = network[:, [:from, :to, :capacity, :length, :free_flow_time, :alpha, :beta, :speed_limit, :toll]]

    return new(trips, network, options)
  end
end

function Base.show(io::IO, mime::MIME"text/plain", traffic::Traffic)
  print(io, "# Trips:\n")
  show(io, mime, traffic.trips)
  print(io, "\n\n")
  print(io, "# Network:\n")
  show(io, mime, traffic.network)

  return nothing
end