__precompile__()
module SpaCy

export load

using PyCall

const spacy = PyNULL()
const spacy_cli = PyNULL()

function __init__()
    copy!(spacy, pyimport_conda("spacy", "spacy"))
    copy!(spacy_cli, pyimport_conda("spacy.cli", "spacy"))
    PyCall.pytype_mapping(spacy["tokens"]["doc"]["Doc"], Doc)
    PyCall.pytype_mapping(spacy["tokens"]["token"]["Token"], Token)
    PyCall.pytype_mapping(spacy["tokens"]["span"]["Span"], Span)
    #PyCall.pytype_mapping(spacy.tokens[:lexeme][:Lexeme], Lexeme)
end

struct Language
    o::PyObject
end

struct Doc
    o::PyObject
end

struct Token
    o::PyObject
end

struct Span
    o::PyObject
end

struct Lexeme
    o::PyObject
end

for T in (Language, Doc, Token, Span, Lexeme)
    @eval begin
        PyCall.PyObject(f::$T) = f.o
        Base.convert(::Type{$T}, o::PyObject) = $T(o)
        Base.:(==)(f::$T, g::$T) = f.o == g.o
        Base.:(==)(f::$T, g::PyObject) = f.o == g
        Base.:(==)(f::PyObject, g::$T) = f == g.o
        Base.hash(f::$T) = hash(f.o)
        PyCall.pycall(f::$T, args...; kws...) = pycall(f.o, args...; kws...)
        (f::$T)(args...; kws...) = pycall(f.o, PyAny, args...; kws...)
        Base.Docs.doc(f::$T) = Base.Docs.doc(f.o)

        function Base.getproperty(f::$T, x::Symbol)
            x === :o ? getfield(f, :o) : getindex(f.o, x)
        end
        Base.getindex(f::$T, x) = get(f.o, x)
        #setindex!(f::$T, v, x) = setindex!(f.o, v, x)
        #haskey(f::$T, x) = haskey(f.o, x)
        #keys(f::$T) = keys(f.o)
    end
end

function load(s::AbstractString)
    try
        spacy["load"](s)
    catch
        spacy_cli["download"](s)
        spacy["load"](s)
    end |> Language
end

(lang::Language)(s) = Doc(lang.o(s))

end # module
