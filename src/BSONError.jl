type BSONError
    _wrap_::Vector{Uint8}

    function BSONError()
        return new(Array(Uint8, 512))
    end
end
export BSONError
