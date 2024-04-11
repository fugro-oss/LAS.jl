abstract type LasPoint{Format} end

"ASPRS LAS point data record format 0"
mutable struct LasPoint0 <: LasPoint{0}
    x::Int32
    y::Int32
    z::Int32
    intensity::UInt16
    flag_byte::UInt8
    raw_classification::UInt8
    scan_angle::Int8
    user_data::UInt8
    pt_src_id::UInt16
end

"ASPRS LAS point data record format 1"
mutable struct LasPoint1 <: LasPoint{1}
    x::Int32
    y::Int32
    z::Int32
    intensity::UInt16
    flag_byte::UInt8
    raw_classification::UInt8
    scan_angle::Int8
    user_data::UInt8
    pt_src_id::UInt16
    gps_time::Float64
end

"ASPRS LAS point data record format 2"
mutable struct LasPoint2 <: LasPoint{2}
    x::Int32
    y::Int32
    z::Int32
    intensity::UInt16
    flag_byte::UInt8
    raw_classification::UInt8
    scan_angle::Int8
    user_data::UInt8
    pt_src_id::UInt16
    red::UInt16
    green::UInt16
    blue::UInt16
end

"ASPRS LAS point data record format 3"
mutable struct LasPoint3 <: LasPoint{3}
    x::Int32
    y::Int32
    z::Int32
    intensity::UInt16
    flag_byte::UInt8
    raw_classification::UInt8
    scan_angle::Int8
    user_data::UInt8
    pt_src_id::UInt16
    gps_time::Float64
    red::UInt16
    green::UInt16
    blue::UInt16
end

"ASPRS LAS point data record format 4"
mutable struct LasPoint4 <: LasPoint{4}
    x::Int32
    y::Int32
    z::Int32
    intensity::UInt16
    flag_byte::UInt8
    raw_classification::UInt8
    scan_angle::Int8
    user_data::UInt8
    pt_src_id::UInt16
    gps_time::Float64
    wave_packet_descriptor_index::UInt8
    wave_packet_byte_offset::UInt64
    wave_packet_size_in_bytes::UInt32
    wave_return_location::Float32
    wave_x_t::Float32
    wave_y_t::Float32
    wave_z_t::Float32
end

"ASPRS LAS point data record format 5"
mutable struct LasPoint5 <: LasPoint{5}
    x::Int32
    y::Int32
    z::Int32
    intensity::UInt16
    flag_byte::UInt8
    raw_classification::UInt8
    scan_angle::Int8
    user_data::UInt8
    pt_src_id::UInt16
    gps_time::Float64
    red::UInt16
    green::UInt16
    blue::UInt16
    wave_packet_descriptor_index::UInt8
    wave_packet_byte_offset::UInt64
    wave_packet_size_in_bytes::UInt32
    wave_return_location::Float32
    wave_x_t::Float32
    wave_y_t::Float32
    wave_z_t::Float32
end

"ASPRS LAS point data record format 6"
mutable struct LasPoint6 <: LasPoint{6}
    x::Int32
    y::Int32
    z::Int32
    intensity::UInt16
    flag_byte_1::UInt8  # return number (4 bits) & number of returns (4 bits)
    flag_byte_2::UInt8 # classification flags, scanner channel, scan direction flag, edge of flight line
    classification::UInt8
    user_data::UInt8
    scan_angle::Int16
    pt_src_id::UInt16
    gps_time::Float64
end

"ASPRS LAS point data record format 7"
mutable struct LasPoint7 <: LasPoint{7}
    x::Int32
    y::Int32
    z::Int32
    intensity::UInt16
    flag_byte_1::UInt8  # return number (4 bits) & number of returns (4 bits)
    flag_byte_2::UInt8 # classification flags, scanner channel, scan direction flag, edge of flight line
    classification::UInt8
    user_data::UInt8
    scan_angle::Int16
    pt_src_id::UInt16
    gps_time::Float64
    red::UInt16
    green::UInt16
    blue::UInt16
end

"ASPRS LAS point data record format 8"
mutable struct LasPoint8 <: LasPoint{8}
    x::Int32
    y::Int32
    z::Int32
    intensity::UInt16
    flag_byte_1::UInt8  # return number (4 bits) & number of returns (4 bits)
    flag_byte_2::UInt8 # classification flags, scanner channel, scan direction flag, edge of flight line
    classification::UInt8
    user_data::UInt8
    scan_angle::Int16
    pt_src_id::UInt16
    gps_time::Float64
    red::UInt16
    green::UInt16
    blue::UInt16
    nir::UInt16
end

"ASPRS LAS point data record format 9"
mutable struct LasPoint9 <: LasPoint{9}
    x::Int32
    y::Int32
    z::Int32
    intensity::UInt16
    flag_byte_1::UInt8  # return number (4 bits) & number of returns (4 bits)
    flag_byte_2::UInt8 # classification flags, scanner channel, scan direction flag, edge of flight line
    classification::UInt8
    user_data::UInt8
    scan_angle::Int16
    pt_src_id::UInt16
    gps_time::Float64
    wave_packet_descriptor_index::UInt8
    wave_packet_byte_offset::UInt64
    wave_packet_size_in_bytes::UInt32
    wave_return_location::Float32
    wave_x_t::Float32
    wave_y_t::Float32
    wave_z_t::Float32
end

"ASPRS LAS point data record format 10"
mutable struct LasPoint10 <: LasPoint{10}
    x::Int32
    y::Int32
    z::Int32
    intensity::UInt16
    flag_byte_1::UInt8  # return number (4 bits) & number of returns (4 bits)
    flag_byte_2::UInt8 # classification flags, scanner channel, scan direction flag, edge of flight line
    classification::UInt8
    user_data::UInt8
    scan_angle::Int16
    pt_src_id::UInt16
    gps_time::Float64
    red::UInt16
    green::UInt16
    blue::UInt16
    nir::UInt16
    wave_packet_descriptor_index::UInt8
    wave_packet_byte_offset::UInt64
    wave_packet_size_in_bytes::UInt32
    wave_return_location::Float32
    wave_x_t::Float32
    wave_y_t::Float32
    wave_z_t::Float32
end

# make points equal if all their property values are equal
for N ∈ 0:10
    eval(:(Base.:(==)(p1::TPoint, p2::TPoint) where {TPoint <: LasPoint{$(N)}} = all(map(f -> getproperty(p1, f) == getproperty(p2, f), fieldnames(TPoint)))))
end

# for convenience in function signatures
const LasPointColor = Union{LasPoint2, LasPoint3, LasPoint5, LasPoint7, LasPoint8, LasPoint10}
const LasPointTime = Union{LasPoint1, LasPoint3, LasPoint4, LasPoint5, LasPoint6, LasPoint7, LasPoint8, LasPoint9, LasPoint10}
const LasPoint_0_5 = Union{LasPoint0, LasPoint1, LasPoint2, LasPoint3, LasPoint4, LasPoint5}
const LasPoint_6_10 = Union{LasPoint6, LasPoint7, LasPoint8, LasPoint9, LasPoint10}

get_point_format(::Type{LasPoint{0}}) = LasPoint0
get_point_format(::Type{LasPoint{1}}) = LasPoint1
get_point_format(::Type{LasPoint{2}}) = LasPoint2
get_point_format(::Type{LasPoint{3}}) = LasPoint3
get_point_format(::Type{LasPoint{4}}) = LasPoint4
get_point_format(::Type{LasPoint{5}}) = LasPoint5
get_point_format(::Type{LasPoint{6}}) = LasPoint6
get_point_format(::Type{LasPoint{7}}) = LasPoint7
get_point_format(::Type{LasPoint{8}}) = LasPoint8
get_point_format(::Type{LasPoint{9}}) = LasPoint9
get_point_format(::Type{LasPoint{10}}) = LasPoint10

get_point_format_id(::Type{T}) where {N, T <: LasPoint{N}} = N
get_point_format_id(point_format::T) where {N, T <: LasPoint{N}} = N

function get_point_format(::Type{LasPoint{T}}) where T
    # LAZ point formats, are offset by 128
    if T >= 128
        get_point_format(LasPoint{T-128})
    end
end

function lasversion_for_point end

lasversion_for_point(::Type{T}) where T <: LasPoint{0} = v"1.1"
lasversion_for_point(::Type{T}) where T <: LasPoint{1}  = v"1.1"
lasversion_for_point(::Type{T}) where T <: LasPoint{2}  = v"1.2"
lasversion_for_point(::Type{T}) where T <: LasPoint{3}  = v"1.2"
lasversion_for_point(::Type{T}) where T <: LasPoint{4}  = v"1.3"
lasversion_for_point(::Type{T}) where T <: LasPoint{5}  = v"1.3"
lasversion_for_point(::Type{T}) where T <: LasPoint{6}  = v"1.4"
lasversion_for_point(::Type{T}) where T <: LasPoint{7}  = v"1.4"
lasversion_for_point(::Type{T}) where T <: LasPoint{8}  = v"1.4"
lasversion_for_point(::Type{T}) where T <: LasPoint{9}  = v"1.4"
lasversion_for_point(::Type{T}) where T <: LasPoint{10}  = v"1.4"

function point_format(type::Type{TPoints}) where TPoints <: LasPoint{N} where N
    return N
end

# speeding up reading:
@reflect LasPoint0
@reflect LasPoint1
@reflect LasPoint2
@reflect LasPoint3
@reflect LasPoint4
@reflect LasPoint5
@reflect LasPoint6
@reflect LasPoint7
@reflect LasPoint8
@reflect LasPoint9
@reflect LasPoint10

concrete_type(::Type{LasPoint{0}}) = LasPoint0
concrete_type(::Type{LasPoint{1}}) = LasPoint1
concrete_type(::Type{LasPoint{2}}) = LasPoint2
concrete_type(::Type{LasPoint{3}}) = LasPoint3
concrete_type(::Type{LasPoint{4}}) = LasPoint4
concrete_type(::Type{LasPoint{5}}) = LasPoint5
concrete_type(::Type{LasPoint{6}}) = LasPoint6
concrete_type(::Type{LasPoint{7}}) = LasPoint7
concrete_type(::Type{LasPoint{8}}) = LasPoint8
concrete_type(::Type{LasPoint{9}}) = LasPoint9
concrete_type(::Type{LasPoint{10}}) = LasPoint10

Base.read(io::IO, ::Type{TPoint}) where {TPoint <: LasPoint} = read_struct(io, TPoint)
Base.write(io::IO, p::TPoint) where {TPoint <: LasPoint} = write_struct(io, p)

point(::Type{TPoint}) where {N, TPoint <: LasPoint{N}} = TPoint