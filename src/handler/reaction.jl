# Reactors
#
# On every MessageCreate event, we can apply a reaction to the message.
# The code below can be easily extends by defining a subtype of
# `AbstractReactor` and implement the respective interface methods.

# ----------------------------------------------------------------------
# Interface
# ----------------------------------------------------------------------

abstract type AbstractReactor end

function reactions(r::AbstractReactor, m::Message)::Vector{Char}
end

const NO_REACTION = Char[]

# ----------------------------------------------------------------------
# Reactors
# ----------------------------------------------------------------------

function contains_any(s::AbstractString, words::AbstractVector{String})
    return any(occursin.(lowercase.(words), s))
end

struct HappyReactor <: AbstractReactor end

function reactions(::HappyReactor, m::Message)
    words = ["happy", "nice", "great", "awesome", "cheers", "yay", "congrat",
        "it helped", "appreciate", "noice", "thank"]
    except = ["unhappy"]
    if contains_any(m.content, words) && !contains_any(m.content, except)
        return ['😄']
    end
    return NO_REACTION
end

struct DisappointedReactor <: AbstractReactor end

function reactions(::DisappointedReactor, m::Message)
    words = ["disappointed", "unhappy", "sad", "aw shucks", "yeow"]
    if contains_any(m.content, words)
        return ['😞']
    end
    return NO_REACTION
end

struct ExcitedReactor <: AbstractReactor end

function reactions(::ExcitedReactor, m::Message)
    words = ["excited", "fantastic", "fabulous", "wonderful", "looking forward to",
        "love", "learned", "saved me", "beautiful"]
    if contains_any(m.content, words)
        return ['🤩']
    end
    return NO_REACTION
end

struct GoodbyeReactor <: AbstractReactor end

function reactions(::GoodbyeReactor, m::Message)
    words = ["cya", "bye", "goodbye", "ciao", "adios", "brb"]
    if contains_any(m.content, words)
        return ['👋']
    end
    return NO_REACTION
end

struct AnimalReactor <: AbstractReactor end

function reactions(::AnimalReactor, m::Message)
    if contains_any(m.content, ["shiba", "corgi", "chihuahua", "retriever"])
        return ["🐕"]
    elseif contains_any(m.content, ["kitten"])
        return ["🐈"]
    elseif contains_any(m.content, ["snake"])
        return ["🐍"]
    end
    return NO_REACTION
end

# ----------------------------------------------------------------------
# Main logic
# ----------------------------------------------------------------------

const REACTORS = AbstractReactor[
    HappyReactor(),
    DisappointedReactor(),
    ExcitedReactor(),
    GoodbyeReactor(),
    AnimalReactor(),
]

function handler(c::Client, e::MessageCreate, ::Val{:reaction})
    # @info "react_handler called"
    # @info "Received message" e.message.channel_id e.message.id e.message.content
    username = e.message.author.username
    discriminator = e.message.author.discriminator
    !get_opt!(username, discriminator, :reaction) && return nothing
    for reactor in REACTORS
        rs = reactions(reactor, e.message)
        foreach(rs) do emoji
            create(c, Reaction, e.message, emoji)
        end
    end
    return nothing
end
