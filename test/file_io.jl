@testset "Basic I/O Tests" begin
    file_name = joinpath(@__DIR__, "test_files/example.las")

    las = load_las(file_name)
    
    mktempdir() do tmp
        out_file = joinpath(tmp, "pc.las")
        save_las(out_file, las)
        new_las = load_las(out_file)
        @test new_las == las
    end
end

function check_las_file(file_name::String, desired_version::VersionNumber, ::Type{TPoint},
                            output_columns::Vector{Symbol},
                            desired_classifications::Vector{Int},
                            desired_return_numbers::Union{Vector{Int}, Missing} = missing,
                            desired_number_of_returns::Union{Int, Missing} = missing) where {TPoint <: LasPoint}
    las = load_las(file_name, output_columns)
    
    pc = get_pointcloud(las)
    @test length(pc) == 225
    @test all(output_columns .∈ Ref(columnnames(pc)))
    @test all(pc.classification .∈ Ref(desired_classifications))
    
    header = get_header(las)
    @test las_version(header) == desired_version
    @test record_format(header) == LAS.PointRecord{TPoint}
    @test system_id(header) == "OTHER"

    @test length(pc) == number_of_points(header)

    if !ismissing(desired_return_numbers) && !ismissing(desired_number_of_returns) && all([:returnnumber, :numberofreturns] .∈ Ref(columnnames(pc)))
        @test all(pc.returnnumber .∈ Ref(desired_return_numbers))
        @test all(pc.returnnumber .≤ pc.numberofreturns)
        @test all(pc.numberofreturns .≤ desired_number_of_returns)
    end
    
    xyz = spatial_info(header)
    @test all(map(p -> p.x ∈ xyz.range.x, pc.position))
    @test all(map(p -> p.y ∈ xyz.range.y, pc.position))
    @test all(map(p -> p.z ∈ xyz.range.z, pc.position))

    # no VLRs/EVLRs here
    @test isempty(get_vlrs(las))
    @test isempty(get_evlrs(las))
    # and no user defined bytes
    @test isempty(get_user_defined_bytes(las))
end

@testset "Reading LAS Files" begin
    @testset "Legacy Specs" begin
        check_las_file(joinpath(@__DIR__, "test_files/example_1_1.las"), v"1.1", LasPoint0, [:position, :classification, :returnnumber, :numberofreturns], collect(0:3), [1, 2], 2)
        check_las_file(joinpath(@__DIR__, "test_files/example_1_2.las"), v"1.2", LasPoint2, [:position, :classification, :returnnumber, :numberofreturns], collect(0:3), [1, 2], 2)
        check_las_file(joinpath(@__DIR__, "test_files/example_1_3.las"), v"1.3", LasPoint2, [:position, :classification, :returnnumber, :numberofreturns], collect(0:3), [1, 2], 2)
    end

    @testset "LAS v1.4" begin
        check_las_file(joinpath(@__DIR__, "test_files/example_1_4_p0.las"), v"1.4", LasPoint0, [:position, :classification, :returnnumber, :numberofreturns], collect(0:3), [1, 2], 2)
        check_las_file(joinpath(@__DIR__, "test_files/example_1_4_p2.las"), v"1.4", LasPoint2, [:position, :classification, :returnnumber, :numberofreturns], collect(0:3), [1, 2], 2)
        check_las_file(joinpath(@__DIR__, "test_files/example_1_4_p6.las"), v"1.4", LasPoint6, [:position, :classification, :returnnumber, :numberofreturns], collect(0:3), [1, 2], 2)
    end
end

# don't feel like importing the whole LinearAlgebra package for this one:
norm(x) = sqrt(sum(x.^2))

@testset "Freak data" begin
    
    ps = rand(SVector{3,Float64}, 100) .* 1000

    amount_over_max = 230.13
    amount_under_min = 41003.8

    overflow_point = typemax(Int32) * LAS.POINT_SCALE + amount_over_max
    underflow_point = typemin(Int32) * LAS.POINT_SCALE - amount_under_min

    extreme_point_A = SVector{3}(overflow_point, 20.0, 42.0)
    extreme_point_B = SVector{3}(20.0, 42.0, underflow_point)
    
    ps[1] = extreme_point_A
    ps[end] = extreme_point_B

    simple_pointcloud_table = Table(position = ps, classification = rand(1:5, length(ps)))

    pc = mktemp() do file,io
        close(io)
        save_las("$(file).las", simple_pointcloud_table)
        load_pointcloud("$(file).las")
    end

    # test the non-freak points:
    normal_point_differences = norm.(ps[2:end-1] .- pc.position[2:end-1])
    @test maximum(normal_point_differences) ≈ 0.0 atol=LAS.POINT_SCALE
    
    # test the non-freak components of the extreme points:
    @test pc.position[1][2] ≈ 20.0 atol=LAS.POINT_SCALE
    @test pc.position[1][3] ≈ 42.0 atol=LAS.POINT_SCALE
    
    @test pc.position[end][1] ≈ 20.0 atol=LAS.POINT_SCALE
    @test pc.position[end][2] ≈ 42.0 atol=LAS.POINT_SCALE
    
    # the amount over/under max/min affects the clamped values, as the LAS bounding box is affected as well:
    @test pc.position[1][1] ≈ (typemax(Int32) * LAS.POINT_SCALE + amount_over_max) atol=LAS.POINT_SCALE
    @test pc.position[end][3] ≈ (typemin(Int32) * LAS.POINT_SCALE - amount_under_min) atol=LAS.POINT_SCALE
    
end

@testset "Test Extract PointCloud" begin

    # try to read all fields
    pc = load_pointcloud(joinpath(@__DIR__, "test_files/test_io.las"))
    @test length(columnnames(pc)) !== 0
    
    expected_columns = [
        :id,
        :intensity,
        :classification,      
        :point_source_id,
        :position,
        :gps_time,
        :returnnumber,
        :numberofreturns,
    ]

    @test all([c in columnnames(pc) for c in expected_columns])
    @test length(pc) == 19
    @test all(pc.id .== 1:19)

    # try to read only certain fields
    desired_attributes = Vector{Symbol}([:position, :intensity])
    pc = load_pointcloud(joinpath(@__DIR__, "test_files/test_io.las"), desired_attributes)

    @test length(columnnames(pc)) == length(desired_attributes) + 1 # for :id
    @test all([c in columnnames(pc) for c in desired_attributes])

    # test with a 3D bounding box
    # bb = FugroGeometry.BoundingBox(387676.885, 7826736.304,-131.82,387677.014,7826736.380,-131.81)

    # pc = load_las(
    #     joinpath(@__DIR__, "test_files/test_io.las"),
    #     desired_attributes,
    #     bb,
    # )

    # @test length(columnnames(pc)) == length(desired_attributes) + 1 # for :id
    # @test all([c in columnnames(pc) for c in desired_attributes])
    # @test length(pc) == 11
    # @test all(length.(collect(columns(pc))) .== 11)
    # @test pc.id == [7, 8, 10, 11, 12, 13, 14, 15, 16, 17, 18]

    # # test with a 2D bounding box
    # bb = bounding_ranges(
    #     SVector{2,Float64}(387676.885, 387677.014),
    #     SVector{2,Float64}(7826736.304, 7826736.380),
    # )
    # pc = load_las(
    #     joinpath(@__DIR__, "test_files/test_io.las"),
    #     desired_attributes,
    #     bb,
    # )

    # @test length(columnnames(pc)) == length(desired_attributes) + 1 # for :id
    # @test all([c in columnnames(pc) for c in desired_attributes])
    # @test length(pc) == 16
    # @test all(length.(collect(columns(pc))) .== 16)
    # @test pc.id == [1, 2, 4, 5, 6, 7, 8, 10, 11, 12, 13, 14, 15, 16, 17, 18]

end

@testset "Test Save PointCloud As LAS" begin
    number_of_points = 100
    position = [SVector{3,Float64}(rand(3)) for i = 1:number_of_points]
    data = Table(
        position = position,
        intensity = rand(Float64, number_of_points),
        gps_time = rand(number_of_points),
        classification = convert(Vector{UInt8}, rand(1:255, number_of_points)),
        returnnumber = convert(Vector{UInt8}, rand(1:30, number_of_points)),
        numberofreturns = convert(Vector{UInt8}, rand(1:10, number_of_points)),
        withheld = rand(Bool, number_of_points),
        synthetic = rand(Bool, number_of_points),
        key_point = rand(Bool, number_of_points),
        color = rand(RGB, number_of_points),
        terrainHeight = rand(Float64, number_of_points), # this is not a valid LAS field
    )

    tmpdir = mktempdir()
    output_file_path = joinpath(tmpdir, "test_las_write.las")

    # TODO - this needs to point the PointCloudData interface once that is implemented
    @test save_las(output_file_path, data) == nothing

    pc = load_pointcloud(output_file_path, SVector{0,Symbol}())

    expected_columns = [ # since we use gps time and no color, we write data as LasPoint3
        :id,
        :position,
        :intensity,
        :returnnumber,
        :numberofreturns,
        :scan_direction,
        :edge_of_flight_line,
        :classification,
        :synthetic,
        :key_point,
        :withheld,
        :scan_angle,
        :user_data,
        :point_source_id,
        :gps_time,
        :color,
    ]

    @test length(expected_columns) == length(columnnames(pc))
    @test all([c in columnnames(pc) for c in expected_columns])
    @test length(pc) == number_of_points
    @test maximum(abs.(pc.intensity .- data.intensity)) < 0.001
    # TODO: add another test, where load, then save, see that intensity did not lose a bit (should be the case we transform to-and-from Normed{UInt16})

    @test maximum(map(p -> p.color.r, pc) .- map(p -> p.color.r, data)) < 0.001
    @test maximum(map(p -> p.color.g, pc) .- map(p -> p.color.g, data)) < 0.001
    @test maximum(map(p -> p.color.b, pc) .- map(p -> p.color.b, data)) < 0.001

    @test all(pc.gps_time .== data.gps_time)
    @test all([
        isapprox(pc[i].position[1], pc[i].position[1], atol = 0.001) &&
        isapprox(pc[i].position[2], pc[i].position[2], atol = 0.001) &&
        isapprox(pc[i].position[3], pc[i].position[3], atol = 0.001)
        for i = 1:number_of_points
    ])

    return_ok = data.returnnumber .<= 5

    @test all(pc.returnnumber[return_ok] .== data.returnnumber[return_ok])
    @test all(pc.returnnumber[.!return_ok] .== 5)

    num_returns_ok = data.numberofreturns .<= 5

    @test all(pc.numberofreturns[num_returns_ok] .== data.numberofreturns[num_returns_ok])
    @test all(pc.numberofreturns[.!num_returns_ok] .== 5)

    class_ok = data.classification .<= 31
    @test all(pc.classification[class_ok] .== data.classification[class_ok])
    @test all(pc.classification[.!class_ok] .== 0)

    @test all(pc.synthetic .== data.synthetic)
    @test all(pc.key_point .== data.key_point)
    @test all(pc.withheld .== data.withheld)

    rm(tmpdir, recursive = true)

    number_of_points = 100
    position = [SVector{3,Float64}(rand(3)) for i = 1:number_of_points]
    data = Table(
        position = position,
        intensity = rand(Float64, number_of_points),
        classification = convert(Vector{UInt8}, rand(1:255, number_of_points)),
        returnnumber = convert(Vector{UInt8}, rand(1:30, number_of_points)),
        numberofreturns = convert(Vector{UInt8}, rand(1:10, number_of_points)),
    )

    tmpdir = mktempdir()
    output_file_path = joinpath(tmpdir, "test_las_write.las")

    # TODO - this needs to point the PointCloudData interface once that is implemented
    @test save_las(output_file_path, data) == nothing

    pc = load_pointcloud(output_file_path, [:position, :intensity, :classification, :withheld])

    expected_columns = [ # since we use gps time and no color, we write data as LasPoint3
        :id,
        :position,
        :intensity,
        :classification,
        :withheld
    ]

    @test length(expected_columns) == length(columnnames(pc))
    @test all([c in columnnames(pc) for c in expected_columns])
    @test length(pc) == number_of_points
    @test eltype(pc.withheld) == Bool

    rm(tmpdir, recursive = true)
end

@testset "Test Save PointCloud As LAZ" begin
    number_of_points = 100
    position = [SVector{3,Float64}(rand(3)) for i = 1:number_of_points]
    data = Table(
        position = position,
        intensity = rand(Float64, number_of_points),
        gps_time = rand(number_of_points),
        classification = convert(Vector{UInt8}, rand(1:255, number_of_points)),
        returnnumber = convert(Vector{UInt8}, rand(1:30, number_of_points)),
        numberofreturns = convert(Vector{UInt8}, rand(1:10, number_of_points)),
        withheld = rand(Bool, number_of_points),
        synthetic = rand(Bool, number_of_points),
        key_point = rand(Bool, number_of_points),
        color = rand(RGB, number_of_points),
        terrainHeight = rand(Float64, number_of_points), # this is not a valid LAS field
    )

    tmpdir = mktempdir()
    # tmpdir = "/home/msb/git/FugroLAS.jl/test_folder"
    output_file_path = joinpath(tmpdir, "test_las_write.laz")

    @test save_las(output_file_path, data) == nothing

    # try to read all fields
    pc = load_pointcloud(output_file_path, ALL_LAS_COLUMNS)

    @test length(columnnames(pc)) !== 0

    expected_columns = [ # since we use gps time and no color, we write data as LasPoint3
        :id,
        :position,
        :intensity,
        :returnnumber,
        :numberofreturns,
        :scan_direction,
        :edge_of_flight_line,
        :classification,
        :synthetic,
        :key_point,
        :withheld,
        :scan_angle,
        :user_data,
        :point_source_id,
        :gps_time,
        :color,
    ]

    @test length(expected_columns) == length(columnnames(pc))
    @test all([c in columnnames(pc) for c in expected_columns])
    @test length(pc) == number_of_points
    @test maximum(abs.(pc.intensity .- data.intensity)) < 0.001
    # TODO: add another test, where load, then save, see that intensity did not lose a bit (should be the case we transform to-and-from Normed{UInt16})

    @test maximum(map(p -> p.color.r, pc) .- map(p -> p.color.r, data)) < 0.001
    @test maximum(map(p -> p.color.g, pc) .- map(p -> p.color.g, data)) < 0.001
    @test maximum(map(p -> p.color.b, pc) .- map(p -> p.color.b, data)) < 0.001

    @test all(pc.gps_time .== data.gps_time)
    @test all([
        isapprox(pc[i].position[1], pc[i].position[1], atol = 0.001) &&
        isapprox(pc[i].position[2], pc[i].position[2], atol = 0.001) &&
        isapprox(pc[i].position[3], pc[i].position[3], atol = 0.001)
        for i = 1:number_of_points
    ])

    return_ok = data.returnnumber .<= 5

    @test all(pc.returnnumber[return_ok] .== data.returnnumber[return_ok])
    @test all(pc.returnnumber[.!return_ok] .== 5)

    num_returns_ok = data.numberofreturns .<= 5

    @test all(pc.numberofreturns[num_returns_ok] .== data.numberofreturns[num_returns_ok])
    @test all(pc.numberofreturns[.!num_returns_ok] .== 5)

    class_ok = data.classification .<= 31
    @test all(pc.classification[class_ok] .== data.classification[class_ok])
    @test all(pc.classification[.!class_ok] .== 0)

    @test all(pc.synthetic .== data.synthetic)
    @test all(pc.key_point .== data.key_point)
    @test all(pc.withheld .== data.withheld)

    rm(tmpdir, recursive = true)
end

@testset "Test PointFormat7 with LAS1.4" begin
    number_of_points = 100
    maximum_returns = UInt8(15)
    maximum_classification = UInt8(255)
    maximum_scanner_channel = UInt8(3)
    position = [SVector{3,Float64}(rand(3)) for i = 1:number_of_points]
    data = Table(
        position = position,
        intensity = rand(Float64, number_of_points),
        gps_time = rand(number_of_points),
        classification = convert(Vector{UInt8}, rand(1:255, number_of_points)),
        returnnumber = convert(Vector{UInt8}, rand(1:maximum_returns, number_of_points)),
        numberofreturns = convert(Vector{UInt8}, fill(maximum_returns, number_of_points)),
        scanner_channel = convert(Vector{UInt8}, rand(1:10, number_of_points)),
        point_source_id = convert(Vector{UInt16}, rand(1:10, number_of_points)),
        withheld = rand(Bool, number_of_points),
        synthetic = rand(Bool, number_of_points),
        key_point = rand(Bool, number_of_points),
        overlap = rand(Bool, number_of_points),
        color = rand(RGB, number_of_points),
        terrainHeight = rand(Float64, number_of_points), # this is not a valid LAS field
    )

    tmpdir = mktempdir()
    # tmpdir = "/home/msb/git/FugroLAS.jl/test_folder"
    output_file_path = joinpath(tmpdir, "test_las_write_laspoint6.las")

    wkt_str = """GEOGCS["GCS_WGS_1984",DATUM["D_WGS_1984",SPHEROID["WGS_1984",6378137,298.257223563]],PRIMEM["Greenwich",0],UNIT["Degree",0.017453292519943295]]"""
    crs_vlr = LasVariableLengthRecord("LASF_Projection", 2112, "Description - wkt info", map(s -> UInt8(s), collect(wkt_str)))

    @test save_las(output_file_path, data, vlrs = LasVariableLengthRecord[crs_vlr]) == nothing

    # try to read all fields
    pc = load_pointcloud(output_file_path, SVector{0, Symbol}())
    @test length(columnnames(pc)) !== 0

    expected_columns = [ # since we use gps time and no color, we write data as LasPoint3
        :id,
        :position,
        :intensity,
        :returnnumber,
        :numberofreturns,
        :scan_direction,
        :scanner_channel,
        :edge_of_flight_line,
        :classification,
        :synthetic,
        :key_point,
        :withheld,
        :overlap,
        :scan_angle,
        :user_data,
        :point_source_id,
        :gps_time,
        :color,
    ]

    @test length(expected_columns) == length(columnnames(pc))
    @test all([c in columnnames(pc) for c in expected_columns])
    @test length(pc) == number_of_points
    @test maximum(abs.(pc.intensity .- data.intensity)) < 0.001
    # TODO: add another test, where load, then save, see that intensity did not lose a bit (should be the case we transform to-and-from Normed{UInt16})

    @test maximum(map(p -> p.color.r, pc) .- map(p -> p.color.r, data)) < 0.001
    @test maximum(map(p -> p.color.g, pc) .- map(p -> p.color.g, data)) < 0.001
    @test maximum(map(p -> p.color.b, pc) .- map(p -> p.color.b, data)) < 0.001

    @test all(pc.gps_time .== data.gps_time)
    @test all([
        isapprox(pc[i].position[1], pc[i].position[1], atol = 0.001) &&
        isapprox(pc[i].position[2], pc[i].position[2], atol = 0.001) &&
        isapprox(pc[i].position[3], pc[i].position[3], atol = 0.001)
        for i = 1:number_of_points
    ])

    return_ok = data.returnnumber .<= maximum_returns
    @test all(pc.returnnumber[return_ok] .== data.returnnumber[return_ok])
    @test all(pc.returnnumber[.!return_ok] .== maximum_returns)

    num_returns_ok = data.numberofreturns .<= maximum_returns
    @test all(pc.numberofreturns[num_returns_ok] .== data.numberofreturns[num_returns_ok])
    @test all(pc.numberofreturns[.!num_returns_ok] .== maximum_returns)

    class_ok = data.classification .<= maximum_classification
    @test all(pc.classification[class_ok] .== data.classification[class_ok])
    @test all(pc.classification[.!class_ok] .== 0)

    scanner_channel_ok = data.scanner_channel .<= maximum_scanner_channel
    @test all(
        pc.scanner_channel[scanner_channel_ok] .== data.scanner_channel[scanner_channel_ok],
    )
    @test all(pc.scanner_channel[.!scanner_channel_ok] .== maximum_scanner_channel)

    @test all(pc.synthetic .== data.synthetic)
    @test all(pc.key_point .== data.key_point)
    @test all(pc.withheld .== data.withheld)
    @test all(pc.overlap .== data.overlap)

    rm(tmpdir, recursive = true)
end