type BSONIter
    _wrap_::Vector{Uint8}
    done::Bool

    function BSONIter(bson::BSON)
        bsonIter = new(Array(Uint8, 128), false)
        ccall(
            (:bson_iter_init, BSON_LIB),
            Bool, (Ptr{Uint8}, Ptr{Uint8}),
            bsonIter._wrap_,
            bson._wrap_
            ) || error("BSONIter(): failure")
        return bsonIter
    end
end
export BSONIter

function key(bsonIter::BSONIter)
    bsonIter.done && error("alredy done iteration")
    cstr = ccall(
        (:bson_iter_key, BSON_LIB),
        Ptr{Uint8}, (Ptr{Uint8}, ),
        bsonIter._wrap_
        )
    cstr == C_NULL && error("bson_iter_key: failure")
    bytestring(cstr)
end
export key

# function value(bsonIter::BSONIter)
#     BSONValue(
#         ccall(
#             (:bson_iter_value, BSON_LIB),
#             Void, (Ptr{Uint8},),
#             bsonIter._wrap_
#             )
#         )
# end
# export value

function next!(bsonIter::BSONIter)
    bsonIter.done = !ccall(
        (:bson_iter_next, BSON_LIB),
        Bool, (Ptr{Uint8}, ),
        bsonIter._wrap_
        )
    !bsonIter.done
end
export next!

done(bsonIter::BSONIter) = bsonIter.done
export done
