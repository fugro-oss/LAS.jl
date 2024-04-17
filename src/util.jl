"""
    $(TYPEDSIGNATURES)

Read a string from `nb` bytes from an IO channel `io`
"""
function readstring(io, nb::Integer)
    bytes = read(io, nb)
    # strip possible null bytes
    lastchar = findlast(bytes .!= 0)
    if isnothing(lastchar)
        return ""
    else
        return String(bytes[1:lastchar])
    end
end

"""
    $(TYPEDSIGNATURES)

Write a string `str` to an IO channel `io`, writing exactly `nb` bytes (padding if `str` is too short)
"""
function writestring(io, str::AbstractString, nb::Integer)
    n = length(str)
    npad = nb - n
    @assert npad ≥ 0 "String length $(n) exceeds number of bytes $(nb)"
    if npad == 0
        write(io, str)
    else
        writestr = string(str * "\0" ^ npad)
        write(io, writestr)
    end
end

upcast_to_8_byte(x::TData) where {TData <: Unsigned} = UInt64(x)
upcast_to_8_byte(x::TData) where {TData <: Signed} = Int64(x)
upcast_to_8_byte(x::TData) where {TData <: AbstractFloat} = Float64(x)

# skip the LAS file's magic four bytes, "LASF"
skiplasf(s::Union{Stream{format"LAS"}, Stream{format"LAZ"}, IO}) = readstring(s, 4)

function get_laszip_executable_path()
    if Sys.iswindows()
        return joinpath(dirname(@__DIR__), "resources", "laszip.exe")
    elseif Sys.islinux()
        return joinpath(dirname(@__DIR__), "resources", "laszip")
    else
        error("Windows and linux only!")
    end
end

chmod(get_laszip_executable_path(), 0o777)

function open_las(func::Function, file::String, rw::String = "r")
    @assert rw == "r" || rw == "w" "IO flags must be read (r) or write (w)"
    wrapper = rw == "r" ? BufferedInputStream : BufferedOutputStream
    io = wrapper(open(file, rw))
    try
        return func(io)
    finally
        close(io)
    end
end

function open_laz(func, file::String, rw::String="r")

    las_file = tempname() * ".las"
    mkpath(dirname(las_file))

    if (rw=="r")

        # we'll unzip so the user can read as LAS:
        run(`$(get_laszip_executable_path()) -i $(file) -o $(las_file)`)
        io = BufferedInputStream(open(las_file, rw))

        try
            return func(io)
        finally        
            close(io)
            rm(las_file, force=true)
        end

    elseif (rw=="w")

        # user can write LAS, we'll zip it when done:
        io = BufferedOutputStream(open(las_file, rw))
        success = false

        try
            result = func(io)
            success = true
            return result
        finally        
            close(io)
            
            if (success)
                mkpath(dirname(file))
                run(`$(get_laszip_executable_path()) -i $(las_file) -o $(file)`)
            end

            rm(las_file, force=true)
        end
        
    else
        error("Read \"r\" OR write \"w\".")
    end
end

is_laz(file_name::AbstractString) = endswith(file_name, ".laz")

function get_open_func(file_name::String)
    ext = String(split(file_name, ".", keepempty = false)[end])
    @assert (ext == "las") || (ext == "laz") "Invalid file extension! Require .las or .laz files"
    open_func = (ext == "las") ? open_las : open_laz
    return open_func
end

function denormalize(::Type{T}, value::Real) where {T <: Integer}
    return floor(T, typemax(T) * clamp(value, 0.0, 1.0))
end

function denormalize(::Type{T}, value::Normed{T,N}) where {T <: Integer, N}
    return value.i
end

macro check(obj, ex)
    return :($(esc(ex)) == 0 ? nothing : laszip_error($(esc(obj))))
end

function laszip_error(laszip_obj::Ptr{Cvoid})
    errstr = Ref(Cstring(C_NULL))
    laszip_get_error(laszip_obj, errstr)
    if errstr[] != C_NULL
        error(unsafe_string(errstr[]))
    end
    nothing
end

function software_version()
    laspoints_version = read_project(joinpath( dirname(@__FILE__()), "..", "Project.toml")).version
    return "LAS.jl v$(laspoints_version)"
end