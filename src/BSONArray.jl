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
        new(b, (_ref_, b))
    end

    BSONArray(_wrap_::Ptr{Void}, _ref_::Any) = new(_wrap_, _ref_)
end
export BSONArray

function convert(::Type{AbstractString}, bsonArray::BSONArray)
    cstr = ccall(
        (:bson_array_as_json, libbson),
        Ptr{UInt8}, (Ptr{Void}, Ptr{UInt8}),
        bsonArray._wrap_,
        C_NULL
        )
    cstr == C_NULL && return ""
    result = bytestring(cstr)
    ccall(
        (:bson_free, libbson),
        Void, (Ptr{Void},),
        cstr
        )
    return result
end
export convert

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
    keyCStr = bytestring(string(length(bsonArray)))
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
    keyCStr = bytestring(string(length(bsonArray)))
    ccall(
        (:bson_append_double, libbson),
        Bool, (Ptr{Void}, Ptr{UInt8}, Cint, Cdouble),
        bsonArray._wrap_,
        keyCStr,
        length(keyCStr),
        val
        ) || error("libBSON: overflow")
end
function append(bsonArray::BSONArray, val::BSONArray)
    keyCStr = bytestring(string(length(bsonArray)))
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
    keyCStr = bytestring(string(length(bsonArray)))
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
    keyCStr = bytestring(string(length(bsonArray)))
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
    keyCStr = bytestring(string(length(bsonArray)))
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
    keyCStr = bytestring(string(length(bsonArray)))
    valUTF8 = utf8(val)
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
function append(bsonArray::BSONArray, val::Dict)
    keyCStr = bytestring(string(length(bsonArray)))
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
    keyCStr = bytestring(string(length(bsonArray)))
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
    keyCStr = bytestring(string(length(bsonArray)))
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
    keyCStr = bytestring(string(length(bsonArray)))
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
    keyCStr = bytestring(string(length(bsonArray)))
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
