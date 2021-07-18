# Package initiation hook
function __init__()
    # Unfortunately, the default GR backend does not work well with
    # offline plotting (see this issue https://github.com/JuliaPlots/Plots.jl/issues/2127).
    # So, we will use PyPlot backend instead.
    start_bot()
end

function start_bot(;
    run_duration = Minute(365 * 24 * 60),  # run for a very long time by default
)
    @info "Starting bot... command prefix = $COMMAND_PREFIX"
    global client = Client(
        ENV["HOJBOT_DISCORD_TOKEN"];
        presence=(game=(name="HoJ", type=AT_GAME),),
        prefix=COMMAND_PREFIX,
    )
    PluginBase.initialize!(client)
    # add_help!(client; help = help_message())
    open(client)
    auto_shutdown(client, run_duration, "SHUTDOWN")
    wait(client)
    PluginBase.shutdown!() || @warn "shutting down didn't work properly"
end

"""
    auto_shutdown(run_duration::TimePeriod)

Run a background process to track the program's run time and exit
the program when it has exceeded the specified `run_duration` or
when a file exists at `trigger_path`.
"""
function auto_shutdown(c::Client, run_duration::TimePeriod, trigger_path::AbstractString="")
    start_time = now()
    @async while true
        if now() > start_time + run_duration
            @info "Times up! The bot is shutting down automatically."
            shutdown_gracefully(c)
            break
        end
        if length(trigger_path) > 0 && isfile(trigger_path)
            @info "The bot is shutting down via trigger path `$trigger_path`."
            rm(trigger_path)
            shutdown_gracefully(c)
            break
        end
        sleep(5)
    end
end

function shutdown_gracefully(c::Client)
    try
        close(c)
    catch ex
        @warn "Unable to close client connection" ex
    end
end

function commander(c::Client, m::Message, service::Symbol)
    @info "commander requested" c m service
    commander(c, m, Val(service))
end
help_commander(c::Client, m::Message, service::Symbol) = help_commander(c, m, Val(service))
