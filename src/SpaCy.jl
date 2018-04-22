__precompile__()
module SpaCy

export load

using PyCall
using PyCall: PyObject_struct

const spacy = PyNULL()
const spacy_cli = PyNULL()

function __init__()
    copy!(spacy, pyimport_conda("spacy", "spacy"))
    copy!(spacy_cli, pyimport_conda("spacy.cli", "spacy"))
    PyCall.pytype_mapping(spacy["tokens"]["Doc"], Doc)
    PyCall.pytype_mapping(spacy["tokens"]["Token"], Token)
    PyCall.pytype_mapping(spacy["tokens"]["Span"], Span)
    PyCall.pytype_mapping(spacy["lexeme"]["Lexeme"], Lexeme)
end

struct PyLanguage
    o::PyObject
end

struct PyDoc
    o::PyObject
end

struct PyToken
    o::PyObject
end

struct PySpan
    o::PyObject
end

struct PyLexeme
    o::PyObject
end

for T in (PyLanguage, PyDoc, PyToken, PySpan, PyLexeme)
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
    end |> PyLanguage
end

(lang::PyLanguage)(s) = unsafe_load(convert(Ptr{Doc}, lang.o(s).o))

const flags_t = UInt64
const attr_t = UInt64
const hash_t = UInt64
const POS_enum = Int32 # ?
const Cbool = Int32

abstract type CythonStruct end
abstract type CythonObject <: CythonStruct end
const PythonObject = Union{CythonObject, PyObject_struct}
const PythonStruct = Union{CythonStruct, PyObject_struct}

struct LexemeC <: CythonStruct # doc.c:1811 __pyx_t_5spacy_7structs_LexemeC
    flags::flags_t
    lang::attr_t
    id::attr_t
    length::attr_t
    orth::attr_t
    lower::attr_t
    norm::attr_t
    shape::attr_t
    prefix::attr_t
    suffix::attr_t
    cluster::attr_t
    prob::Float32
    sentiment::Float32
end

struct TokenC <: CythonStruct # doc.c:1859 __pyx_t_5spacy_7structs_TokenC
    lex::Ptr{LexemeC} # struct __pyx_t_5spacy_7structs_LexemeC const *lex;
    morph::UInt64 # uint64_t morph;
    pos::POS_enum # enum __pyx_t_5spacy_15parts_of_speech_univ_pos_t pos;
    spacy::Cbool # int spacy;
    tag::attr_t # __pyx_t_5spacy_8typedefs_attr_t tag;
    idx::Int32 # int idx;
    lemma::attr_t # __pyx_t_5spacy_8typedefs_attr_t lemma;
    sense::attr_t # __pyx_t_5spacy_8typedefs_attr_t sense;
    head::Int32 # int head;
    dep::attr_t # __pyx_t_5spacy_8typedefs_attr_t dep;
    l_kids::UInt32 # uint32_t l_kids;
    r_kids::UInt32 # uint32_t r_kids;
    l_edge::UInt32 # uint32_t l_edge;
    r_edge::UInt32 # uint32_t r_edge;
    sent_start::Int32 # int sent_start;
    ent_iob::Int32 # int ent_iob;
    ent_type::attr_t # __pyx_t_5spacy_8typedefs_attr_t ent_type;
    ent_id::hash_t # __pyx_t_5spacy_8typedefs_hash_t ent_id;
end

struct Vocab <: CythonObject
    ob_base::PyObject_struct # PyObject_HEAD
    vtable::Ptr{Cvoid}
    mem::Ptr{Cvoid} # cymem.cymem.Pool
    strings::Ptr{Cvoid} # spacy.strings.StringStore
    morphology::Ptr{Cvoid} # spacy.morphology.Morphology
    vectors::PyPtr # array?
    length::Int32
    data_dir::PyPtr
    lex_attr_getters::PyPtr
    cfg::PyPtr
    _by_hash::Ptr{Cvoid} # preshed.maps.PreshMap
    _by_orth::Ptr{Cvoid} # preshed.maps.PreshMap
end

struct Doc <: CythonObject # doc.c:2526
    ob_base::PyObject_struct # PyObject_struct_HEAD
    vtable::Ptr{Cvoid} # struct __pyx_vtabstruct_5spacy_6tokens_3doc_Doc *__pyx_vtab;
    mem::Ptr{Cvoid} # struct __pyx_obj_5cymem_5cymem_Pool *mem;
    vocab::Ptr{Vocab} # struct __pyx_obj_5spacy_5vocab_Vocab *vocab;
    _vector::PyPtr # PyObject_struct *_vector;
    _vector_norm::PyPtr # PyObject_struct *_vector_norm;
    tensor::PyPtr # PyObject_struct *tensor;
    cats::PyPtr # PyObject_struct *cats;
    user_data::PyPtr # PyObject_struct *user_data;
    c::Ptr{TokenC} # struct __pyx_t_5spacy_7structs_TokenC *c;
    is_tagged::Cbool # int is_tagged;
    is_parsed::Cbool # int is_parsed;
    sentiment::Float32 # float sentiment;
    user_hooks::PyPtr # PyObject_struct *user_hooks;
    user_token_hooks::PyPtr # PyObject_struct *user_token_hooks;
    user_span_hooks::PyPtr # PyObject_struct *user_span_hooks;
    _py_tokens::PyPtr # PyObject_struct *_py_tokens;
    length::Int32 # int length;
    max_length::Int32 # int max_length;
    noun_chunks_iterator::PyPtr # PyObject_struct *noun_chunks_iterator;
    __weakref__::PyPtr # PyObject_struct *__weakref__;
end

struct Span <: CythonObject
    ob_base::PyObject_struct # PyObject_struct_HEAD
    vtable::Ptr{Cvoid}
    doc::Ptr{Doc}
    start::Int32
    end_::Int32
    start_char::Int32
    end_char::Int32
    label::attr_t
    _vector::PyPtr
    _vector_norm::PyPtr
end

struct Token <: CythonObject
    ob_base::PyObject_struct # PyObject_struct_HEAD
    vtable::Ptr{Cvoid}
    vocab::Ptr{Vocab} # cdef readonly Vocab vocab
    c::Ptr{TokenC} # cdef TokenC* c
    i::Int32 # cdef readonly int i
    doc::Ptr{Doc} # cdef readonly Doc doc
end

struct Lexeme <: CythonObject
    ob_base::PyObject_struct # PyObject_struct_HEAD
    vtable::Ptr{Cvoid}
    c::Ptr{LexemeC} # cdef LexemeC* c
    vocab::Ptr{Vocab} # cdef readonly Vocab vocab
    orth::attr_t # cdef readonly attr_t orth
end

function Base.getproperty(x::T, s::Symbol) where {T<:CythonStruct}
    F = fieldtype(T, s)
    val = getfield(x, s)
    if F == PyPtr
        return PyObject(val)
    end
    return (F <: Ptr && s != :__weakref__) ? unsafe_load(val) : val
end

Base.show(io::IO, x::CythonStruct) = dump(io, x)

function Base.dump(io::IO, x::Ptr{T}, n::Int, indent) where {T<:CythonStruct}
    print(io, Ptr{T})
    x = unsafe_load(x)
    if n > 0
        for field in fieldnames(T)
            println(io)
            print(io, indent, "  ", field, ": ")
            dump(io, getfield(x, field), n - 1, string(indent, "  "))
        end
    end
end

Base.dump(io::IO, x::Ptr, n::Int, indent) = print(io, x)
function Base.show(io::IO, x::PyPtr)
    if x == PyCall.PyPtr_NULL
        print(io, "Ptr{PyObject} NULL")
    else
        print(io, "Ptr{PyObject} ", py"object.__repr__($(PyObject(x)))")
    end
end

end # module
