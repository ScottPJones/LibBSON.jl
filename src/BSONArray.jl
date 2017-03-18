type BSONArray
    _wrap_::Ptr{Void}
    _ref_::Any

    BSONArray() = begin
        _wrap_ = ccall(
            (:bson_new, libbson),
            Ptr{Void}, ()
            )
        bsonArray = new(_wrap_, Union{})
        finalizer(bsonArray, destroy)
        return bsonArray
    end

    BSONArray(vec::Vector) = begin
        bsonArray = BSONArray()
        for ele in vec
            append(bsonArray, ele)
        end
        return bsonArray
    end

    BSONArray(data::Ptr{UInt8}, length::Integer, _ref_::Any) = begin
        buffer = Array(UInt8, 128)
        ccall(
            (:bson_init_static, libbson),
            Bool, (Ptr{Void}, Ptr{UInt8}, UInt32),
            buffer, data, length
            ) || error("bson_init_static: failure")
        b = Compat.unsafe_convert(Ptr{Void}, buffer)
        new(b, (_ref_, buffer))
    end

    BSONArray(_wrap_::Ptr{Void}, _ref_::Any) = new(_wrap_, _ref_)
end
export BSONArray

# this is a hack and should be removed
immutable bson_t_padding
  padding_1::Cushort
  padding_2::Cushort
  padding_3::Cushort
  padding_4::Cushort
  padding_5::Cushort
  padding_6::Cushort
  padding_7::Cushort
  padding_8::Cushort
  padding_9::Cushort
  padding_10::Cushort
  padding_11::Cushort
  padding_12::Cushort
  padding_13::Cushort
  padding_14::Cushort
  padding_15::Cushort
  padding_16::Cushort
  padding_17::Cushort
  padding_18::Cushort
  padding_19::Cushort
  padding_20::Cushort
  padding_21::Cushort
  padding_22::Cushort
  padding_23::Cushort
  padding_24::Cushort
  padding_25::Cushort
  padding_26::Cushort
  padding_27::Cushort
  padding_28::Cushort
  padding_29::Cushort
  padding_30::Cushort
  padding_31::Cushort
  padding_32::Cushort
  padding_33::Cushort
  padding_34::Cushort
  padding_35::Cushort
  padding_36::Cushort
  padding_37::Cushort
  padding_38::Cushort
  padding_39::Cushort
  padding_40::Cushort
  padding_41::Cushort
  padding_42::Cushort
  padding_43::Cushort
  padding_44::Cushort
  padding_45::Cushort
  padding_46::Cushort
  padding_47::Cushort
  padding_48::Cushort
  padding_49::Cushort
  padding_50::Cushort
  padding_51::Cushort
  padding_52::Cushort
  padding_53::Cushort
  padding_54::Cushort
  padding_55::Cushort
  padding_56::Cushort
  padding_57::Cushort
  padding_58::Cushort
  padding_59::Cushort
  padding_60::Cushort
  padding_61::Cushort
  padding_62::Cushort
  padding_63::Cushort
  padding_64::Cushort
  padding_65::Cushort
  padding_66::Cushort
  padding_67::Cushort
  padding_68::Cushort
  padding_69::Cushort
  padding_70::Cushort
  padding_71::Cushort
  padding_72::Cushort
  padding_73::Cushort
  padding_74::Cushort
  padding_75::Cushort
  padding_76::Cushort
  padding_77::Cushort
  padding_78::Cushort
  padding_79::Cushort
  padding_80::Cushort
  padding_81::Cushort
  padding_82::Cushort
  padding_83::Cushort
  padding_84::Cushort
  padding_85::Cushort
  padding_86::Cushort
  padding_87::Cushort
  padding_88::Cushort
  padding_89::Cushort
  padding_90::Cushort
  padding_91::Cushort
  padding_92::Cushort
  padding_93::Cushort
  padding_94::Cushort
  padding_95::Cushort
  padding_96::Cushort
  padding_97::Cushort
  padding_98::Cushort
  padding_99::Cushort
  padding_100::Cushort
  padding_101::Cushort
  padding_102::Cushort
  padding_103::Cushort
  padding_104::Cushort
  padding_105::Cushort
  padding_106::Cushort
  padding_107::Cushort
  padding_108::Cushort
  padding_109::Cushort
  padding_110::Cushort
  padding_111::Cushort
  padding_112::Cushort
  padding_113::Cushort
  padding_114::Cushort
  padding_115::Cushort
  padding_116::Cushort
  padding_117::Cushort
  padding_118::Cushort
  padding_119::Cushort
  padding_120::Cushort
end
type bson_t
    flags::Cuint
    len::Cuint
    padding::bson_t_padding
end
export bson_t

type BSONData
    _wrap_::Ptr{Void}
    _ref_::Any

    BSONData() = begin
        _wrap_ = ccall(
            (:bson_new, libbson),
            Ptr{Void}, ()
            )
        bsonData = new(_wrap_, Union{})
        finalizer(bsonData, destroy)
        return bsonData
    end

    BSONData(vec::Vector) = begin
        bsonData = BSONData()
        for ele in vec
            append(bsonData, ele)
        end
        return bsonData
    end

    BSONData(data::Ptr{UInt8}, length::Integer, _ref_::Any) = begin
        # buffer = Array(UInt8, 128)
        @show length
        bt = ccall(
            (:bson_new_from_data, libbson),
            Ptr{bson_t}, (Ptr{UInt8}, UInt32),
            data, length
            )
        return bt
    end

    BSONData(_wrap_::Ptr{Void}, _ref_::Any) = new(_wrap_, _ref_)
end
export BSONData


if Base.VERSION > v"0.5.0-"
Base.iteratoreltype(::Type{BSONArray}) = Base.EltypeUnknown()
end

function convert(::Type{AbstractString}, bsonArray::BSONArray)
    cstr = ccall(
        (:bson_array_as_json, libbson),
        Ptr{UInt8}, (Ptr{Void}, Ptr{UInt8}),
        bsonArray._wrap_,
        C_NULL
        )
    cstr == C_NULL && return ""
    result = unsafe_string(cstr)
    ccall(
        (:bson_free, libbson),
        Void, (Ptr{Void},),
        cstr
        )
    return result
end
export convert

convert(::Type{Array}, b::BSONArray) = collect(b)
convert{T}(::Type{Array{T}}, b::BSONArray) = collect(T, b)
convert{T}(::Type{Array{T,1}}, b::BSONArray) = collect(T, b)

string(bsonArray::BSONArray) = convert(AbstractString, bsonArray)

show(io::IO, bsonArray::BSONArray) = print(io, "BSONArray($(convert(AbstractString, bsonArray)))")
export show

length(bsonArray::BSONArray) =
    ccall(
        (:bson_count_keys, libbson),
        UInt32, (Ptr{Void},),
        bsonArray._wrap_
        )

function append(bsonArray::BSONArray, val::Bool)
    keyCStr = string(length(bsonArray))
    ccall(
        (:bson_append_bool, libbson),
        Bool, (Ptr{Void}, Ptr{UInt8}, Cint, Bool),
        bsonArray._wrap_,
        keyCStr,
        length(keyCStr),
        val
        ) || error("libBSON: overflow")
end
function append(bsonArray::BSONArray, val::Real)
    keyCStr = string(length(bsonArray))
    ccall(
        (:bson_append_double, libbson),
        Bool, (Ptr{Void}, Ptr{UInt8}, Cint, Cdouble),
        bsonArray._wrap_,
        keyCStr,
        length(keyCStr),
        val
        ) || error("libBSON: overflow")
end
using Base.Dates: datetime2unix
function append(bsonArray::BSONArray, val::DateTime)
    keyCStr = string(length(bsonArray))
    ts = round(Int64, datetime2unix(val)*1000)
    ccall(
        (:bson_append_date_time, libbson),
        Bool, (Ptr{Void}, Ptr{UInt8}, Cint, Clonglong),
        bsonArray._wrap_,
        keyCStr,
        length(keyCStr),
        ts
        ) || error("libBSON: overflow")
end
function append(bsonArray::BSONArray, val::Date)
    append(bsonArray, DateTime(val))
end
function append(bsonArray::BSONArray, val::BSONArray)
    keyCStr = string(length(bsonArray))
    childBuffer = Array(UInt8, 128)
    ccall(
        (:bson_append_array_begin, libbson),
        Bool, (Ptr{Void}, Ptr{UInt8}, Cint, Ptr{Void}),
        bsonArray._wrap_,
        keyCStr,
        length(keyCStr),
        childBuffer
        ) || error("bson_append_array_begin: failure")
    childBSONArray = BSONArray(Compat.unsafe_convert(Ptr{Void}, childBuffer), childBuffer)
    for element in val
        append(childBSONArray, element)
    end
    ccall(
        (:bson_append_array_end, libbson),
        Bool, (Ptr{Void}, Ptr{Void}),
        bsonArray._wrap_,
        childBuffer
        ) || error("bson_append_array_end: failure")
end
function append(bsonArray::BSONArray, val::Union{Int8, UInt8, Int16, UInt16, Int32, UInt32})
    keyCStr = string(length(bsonArray))
    ccall(
        (:bson_append_int32, libbson),
        Bool, (Ptr{Void}, Ptr{UInt8}, Cint, Int32),
        bsonArray._wrap_,
        keyCStr,
        length(keyCStr),
        val
        ) || error("libBSON: overflow")
end
function append(bsonArray::BSONArray, val::Union{Int64, UInt64})
    keyCStr = string(length(bsonArray))
    ccall(
        (:bson_append_int64, libbson),
        Bool, (Ptr{Void}, Ptr{UInt8}, Cint, Int64),
        bsonArray._wrap_,
        keyCStr,
        length(keyCStr),
        val
        ) || error("libBSON: overflow")
end
function append(bsonArray::BSONArray, val::BSONOID)
    keyCStr = string(length(bsonArray))
    ccall(
        (:bson_append_oid, libbson),
        Bool, (Ptr{Void}, Ptr{UInt8}, Cint, Ptr{UInt8}),
        bsonArray._wrap_,
        keyCStr,
        length(keyCStr),
        val._wrap_
        ) || error("libBSON: overflow")
end
function append(bsonArray::BSONArray, val::AbstractString)
    keyCStr = string(length(bsonArray))
    valUTF8 = String(val)
    ccall(
        (:bson_append_utf8, libbson),
        Bool, (Ptr{Void}, Ptr{UInt8}, Cint, Ptr{UInt8}, Cint),
        bsonArray._wrap_,
        keyCStr,
        length(keyCStr),
        valUTF8,
        sizeof(valUTF8)
        ) || error("libBSON: overflow")
end
function append(bsonArray::BSONArray, val::Void)
    append_null(bsonArray)
end
function append(bsonArray::BSONArray, val::Symbol)
    if val == :null
        append_null(bsonArray)
    elseif val == :minkey
        append_minkey(bsonArray)
    elseif val == :maxkey
        append_maxkey(bsonArray)
    else
        append(bsonArray, string(val))
    end
end
function append(bsonArray::BSONArray, val::Associative)
    keyCStr = string(length(bsonArray))
    childBuffer = Array(UInt8, 128)
    ccall(
        (:bson_append_document_begin, libbson),
        Bool, (Ptr{Void}, Ptr{UInt8}, Cint, Ptr{Void}),
        bsonArray._wrap_,
        keyCStr,
        length(keyCStr),
        childBuffer
        ) || error("bson_append_document_begin: failure")
    childBSONObject = BSONObject(Compat.unsafe_convert(Ptr{Void}, childBuffer), childBuffer)
    for (k, v) in val
        append(childBSONObject, k, v)
    end
    ccall(
        (:bson_append_document_end, libbson),
        Bool, (Ptr{Void}, Ptr{Void}),
        bsonArray._wrap_,
        childBuffer
        ) || error("bson_append_document_end: failure")
end
function append(bsonArray::BSONArray, val::Vector)
    keyCStr = string(length(bsonArray))
    childBuffer = Array(UInt8, 128)
    ccall(
        (:bson_append_array_begin, libbson),
        Bool, (Ptr{Void}, Ptr{UInt8}, Cint, Ptr{Void}),
        bsonArray._wrap_,
        keyCStr,
        length(keyCStr),
        childBuffer
        ) || error("bson_append_array_begin: failure")
    childBSONArray = BSONArray(Compat.unsafe_convert(Ptr{Void}, childBuffer), childBuffer)
    for element in val
        append(childBSONArray, element)
    end
    ccall(
        (:bson_append_array_end, libbson),
        Bool, (Ptr{Void}, Ptr{Void}),
        bsonArray._wrap_,
        childBuffer
        ) || error("bson_append_array_end: failure")
end
export append

function append_null(bsonArray::BSONArray)
    keyCStr = string(length(bsonArray))
    ccall(
        (:bson_append_null, libbson),
        Bool, (Ptr{Void}, Ptr{UInt8}, Cint),
        bsonArray._wrap_,
        keyCStr,
        length(keyCStr)
        ) || error("libBSON: overflow")
end
export append_null

function append_minkey(bsonArray::BSONArray)
    keyCStr = string(length(bsonArray))
    ccall(
        (:bson_append_minkey, libbson),
        Bool, (Ptr{Void}, Ptr{UInt8}, Cint),
        bsonArray._wrap_,
        keyCStr,
        length(keyCStr)
        ) || error("libBSON: overflow")
end
export append_minkey

function append_maxkey(bsonArray::BSONArray)
    keyCStr = string(length(bsonArray))
    ccall(
        (:bson_append_maxkey, libbson),
        Bool, (Ptr{Void}, Ptr{UInt8}, Cint),
        bsonArray._wrap_,
        keyCStr,
        length(keyCStr)
        ) || error("libBSON: overflow")
end
export append_maxkey

vector(bsonArray::BSONArray) = begin
    a = Any[]
    for v in bsonArray
        if isa(v, BSONObject)
            push!(a, dict(v))
        elseif isa(v, BSONArray)
            push!(a, vector(v))
        else
            push!(a, v)
        end
    end
    return a
end
export vector

# Private

function destroy(bsonArray::BSONArray)
    ccall(
        (:bson_destroy, libbson),
        Void, (Ptr{Void},),
        bsonArray._wrap_
        )
end
