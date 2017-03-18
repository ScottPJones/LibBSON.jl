



# immutable bson_t_padding
#   padding_1::Cushort
#   padding_2::Cushort
#   padding_3::Cushort
#   padding_4::Cushort
#   padding_5::Cushort
#   padding_6::Cushort
#   padding_7::Cushort
#   padding_8::Cushort
#   padding_9::Cushort
#   padding_10::Cushort
#   padding_11::Cushort
#   padding_12::Cushort
#   padding_13::Cushort
#   padding_14::Cushort
#   padding_15::Cushort
#   padding_16::Cushort
#   padding_17::Cushort
#   padding_18::Cushort
#   padding_19::Cushort
#   padding_20::Cushort
#   padding_21::Cushort
#   padding_22::Cushort
#   padding_23::Cushort
#   padding_24::Cushort
#   padding_25::Cushort
#   padding_26::Cushort
#   padding_27::Cushort
#   padding_28::Cushort
#   padding_29::Cushort
#   padding_30::Cushort
#   padding_31::Cushort
#   padding_32::Cushort
#   padding_33::Cushort
#   padding_34::Cushort
#   padding_35::Cushort
#   padding_36::Cushort
#   padding_37::Cushort
#   padding_38::Cushort
#   padding_39::Cushort
#   padding_40::Cushort
#   padding_41::Cushort
#   padding_42::Cushort
#   padding_43::Cushort
#   padding_44::Cushort
#   padding_45::Cushort
#   padding_46::Cushort
#   padding_47::Cushort
#   padding_48::Cushort
#   padding_49::Cushort
#   padding_50::Cushort
#   padding_51::Cushort
#   padding_52::Cushort
#   padding_53::Cushort
#   padding_54::Cushort
#   padding_55::Cushort
#   padding_56::Cushort
#   padding_57::Cushort
#   padding_58::Cushort
#   padding_59::Cushort
#   padding_60::Cushort
#   padding_61::Cushort
#   padding_62::Cushort
#   padding_63::Cushort
#   padding_64::Cushort
#   padding_65::Cushort
#   padding_66::Cushort
#   padding_67::Cushort
#   padding_68::Cushort
#   padding_69::Cushort
#   padding_70::Cushort
#   padding_71::Cushort
#   padding_72::Cushort
#   padding_73::Cushort
#   padding_74::Cushort
#   padding_75::Cushort
#   padding_76::Cushort
#   padding_77::Cushort
#   padding_78::Cushort
#   padding_79::Cushort
#   padding_80::Cushort
#   padding_81::Cushort
#   padding_82::Cushort
#   padding_83::Cushort
#   padding_84::Cushort
#   padding_85::Cushort
#   padding_86::Cushort
#   padding_87::Cushort
#   padding_88::Cushort
#   padding_89::Cushort
#   padding_90::Cushort
#   padding_91::Cushort
#   padding_92::Cushort
#   padding_93::Cushort
#   padding_94::Cushort
#   padding_95::Cushort
#   padding_96::Cushort
#   padding_97::Cushort
#   padding_98::Cushort
#   padding_99::Cushort
#   padding_100::Cushort
#   padding_101::Cushort
#   padding_102::Cushort
#   padding_103::Cushort
#   padding_104::Cushort
#   padding_105::Cushort
#   padding_106::Cushort
#   padding_107::Cushort
#   padding_108::Cushort
#   padding_109::Cushort
#   padding_110::Cushort
#   padding_111::Cushort
#   padding_112::Cushort
#   padding_113::Cushort
#   padding_114::Cushort
#   padding_115::Cushort
#   padding_116::Cushort
#   padding_117::Cushort
#   padding_118::Cushort
#   padding_119::Cushort
#   padding_120::Cushort
# end
# type bson_t
#     flags::Cuint
#     len::Cuint
#     padding::bson_t_padding
# end
# export bson_t

type BSONBinary
    _wrap_::Ptr{Void}
    _ref_::Any

    BSONBinary() = begin
        _wrap_ = ccall(
            (:bson_new, libbson),
            Ptr{Void}, ()
            )
        BSONBinary = new(_wrap_, Union{})
        finalizer(BSONBinary, destroy)
        return BSONBinary
    end

    BSONBinary(vec::Vector) = begin
        BSONBinary = BSONBinary()
        for ele in vec
            append(BSONBinary, ele)
        end
        return BSONBinary
    end

    BSONBinary(data::Ptr{UInt8}, length::Integer, _ref_::Any) = begin
        # buffer = Array(UInt8, 128)
        @show length
        bt = ccall(
            # TODO rather use bson_append_binary?
            (:bson_new_from_data, libbson),
            Ptr{bson_t}, (Ptr{UInt8}, UInt32),
            data, length
            )
        return bt
    end

    BSONBinary(_wrap_::Ptr{Void}, _ref_::Any) = new(_wrap_, _ref_)
end
export BSONBinary
