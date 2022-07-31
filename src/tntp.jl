# Global variables
const SHA_TNTP = "ac96f2975ec13b8803e18275e7bd92c6d7bbcde5"
const DIR_NAME_TNTP = "TransportationNetworks-$(SHA_TNTP)"
const PATH_TNTP = dirname(@__DIR__)



# Download TNTP
function download_tntp(
    path=PATH_TNTP; 
    overwrite=false
)
    dir_tntp = joinpath(path, DIR_NAME_TNTP)

    if !isdir(dir_tntp) || overwrite
        file = tempname()
        download("https://github.com/bstabler/TransportationNetworks/archive/$(SHA_TNTP).zip", file)

        reader = Reader(file)

        for file in reader.files
            file_name = joinpath(path, file.name)

            if endswith(file_name, "/")
                if !isdir(file_name)
                    mkdir(file_name)
                end
            else
                write(file_name, read(file))
            end
        end

        close(reader)
        rm(file)
    end

    return dir_tntp
end



# Load TNTP
function load_tntp(
    network_name::String;
    path=PATH_TNTP,
    kwargs...
)
    file_trips, file_network = file_tntp(network_name, path=path)

    load_tntp(file_trips, file_network; kwargs...)
end

function load_tntp(
    file_trips::String, 
    file_network::String; 
    kwargs...
)
    @assert ispath(file_trips)
    @assert ispath(file_network)

    # trips
    trips, n_zones_trips = load_tntp_trips(file_trips)

    # network
    first_thru_node, network, n_zones_network = load_tntp_network(file_network)

    @assert n_zones_trips == n_zones_network

    options = TrafficOptions(
        first_thru_node=first_thru_node;
        kwargs...
    )

    return Traffic(trips, network, options=options)
end

function file_tntp(
    network_name; 
    path=PATH_TNTP
)
    dir_tntp = joinpath(download_tntp(path), network_name)

    files = readdir(dir_tntp)
    file_name_trips = files[contains.(files, "_trips")][1]
    file_name_network = files[contains.(files, "_net")][1]

    file_trips = joinpath(dir_tntp, file_name_trips)
    file_network = joinpath(dir_tntp, file_name_network)

    return file_trips, file_network
end

function load_tntp_trips(file_trips)
    open(file_trips, "r") do file
        tag_n_zones = "<NUMBER OF ZONES>"
        tag_total_od_flow = "<TOTAL OD FLOW>"
        tag_end = "<END OF METADATA>"

        n_zones = 0
        total_od_flow = 0

        while true
            line = readline(file)

            if startswith(line, tag_n_zones)
                n_zones = read_tntp_tag(line, tag_n_zones)
            elseif startswith(line, tag_total_od_flow)
                total_od_flow = read_tntp_tag(line, tag_total_od_flow)
            elseif startswith(line, tag_end)
                break
            end
        end

        @assert n_zones > 0
        @assert total_od_flow > 0

        orig = Vector{Int}(undef, n_zones^2)
        dest = Vector{Int}(undef, n_zones^2)
        trips = zeros(n_zones^2)

        idx = 0
        orig_new = 0

        while !eof(file)
            line = readline(file)

            if line == ""
                continue
            else
                if startswith(line, "Origin")
                    orig_new = read_tntp_tag(line, "Origin")
                else
                    line = split(line, r";\s*", keepempty=false)

                    for dest_trips in line
                        dest_trips = split(dest_trips, ":")

                        idx += 1
                        orig[idx] = orig_new
                        dest[idx] = parse(Int, dest_trips[1])
                        trips[idx] = parse(Float64, dest_trips[2])
                    end
                end
            end
        end

        @assert idx > 0
        @assert orig_new > 0

        orig = orig[1:idx]
        dest = dest[1:idx]
        trips = trips[1:idx]

        if size(unique([orig; dest]), 1) != n_zones
            @warn "Number of unique origins and destinations does not match the number of zones"
        end

        if !isapprox(sum(trips), total_od_flow, atol=1.0)
            @warn "`total_od_flow` does not match total number of trips"
        end

        trips = DataFrame(
            orig=orig,
            dest=dest,
            trips=trips
        )

        return trips, n_zones
    end
end

function load_tntp_network(file_network)
    open(file_network, "r") do file
        tag_n_zones = "<NUMBER OF ZONES>"
        tag_n_nodes = "<NUMBER OF NODES>"
        tag_first_thru_node = "<FIRST THRU NODE>"
        tag_n_edges = "<NUMBER OF LINKS>"
        tag_end = "<END OF METADATA>"

        n_zones = 0
        n_nodes = 0
        first_thru_node = 0
        n_edges = 0

        while true
            line = readline(file)

            if startswith(line, tag_n_zones)
                n_zones = read_tntp_tag(line, tag_n_zones)
            elseif startswith(line, tag_n_nodes)
                n_nodes = read_tntp_tag(line, tag_n_nodes)
            elseif startswith(line, tag_first_thru_node)
                first_thru_node = read_tntp_tag(line, tag_first_thru_node)
            elseif startswith(line, tag_n_edges)
                n_edges = read_tntp_tag(line, tag_n_edges)
            elseif startswith(line, tag_end)
                break
            end
        end

        @assert n_zones > 0
        @assert n_nodes > 0
        @assert first_thru_node > 0
        @assert n_edges > 0

        from = Vector{Int}(undef, n_edges)
        to = Vector{Int}(undef, n_edges)
        free_flow_time = zeros(n_edges)
        capacity = zeros(n_edges)
        alpha = zeros(n_edges)
        beta = zeros(n_edges)
        toll = zeros(n_edges)
        length = zeros(n_edges)
        # speed_limit = zeros(n_edges)
        # link_type = Vector{Int}(undef, n_edges)

        idx = 0
        while !eof(file)
            line = readline(file)

            if contains(line, r"^\s*$") || startswith(line, "~")
                continue
            else
                line = split(line, r"\s+")

                idx += 1
                from[idx] = parse(Int, line[2])
                to[idx] = parse(Int, line[3])
                capacity[idx] = parse(Float64, line[4])
                length[idx] = parse(Float64, line[5])
                free_flow_time[idx] = parse(Float64, line[6])
                alpha[idx] = parse(Float64, line[7])
                beta[idx] = parse(Float64, line[8])
                # speed_limit[idx] = parse(Float64, line[9])
                toll[idx] = parse(Float64, line[10])
                # link_type[idx] = parse(Int, line[11])
            end
        end

        if !issetequal([from; to], 1:n_nodes)
            @warn "The number of nodes in the graph does not match the total number of nodes"
        end

        if idx != n_edges
            @warn "The number of edges in the graph does not match the total number of edges"
        end

        network = DataFrame(
            from=from,
            to=to,
            free_flow_time=free_flow_time,
            capacity=capacity,
            alpha=alpha,
            beta=beta,
            # speed_limit=speed_limit,
            toll=toll,
            length=length
            # link_type=link_type
        )

        return first_thru_node, network, n_zones
    end
end

function read_tntp_tag(line, tag)
    int = match(Regex("(?<=^$(tag))[\\d\\s]+"), line).match

    return parse(Int, int)
end
