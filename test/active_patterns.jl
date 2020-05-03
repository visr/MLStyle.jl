@testcase "active pattern" begin
    @testset "regular case" begin
        @lift @active LessThan0(x) begin
            if x > 0
                nothing
            else
                Some(x)
            end
        end

        b = (@match 15 begin
            LessThan0(_) => :a
            _ => :b
        end)
        
        
        @test b === :b

        @test (@match -15 begin
            LessThan0(a) => a
            _ => 0
        end) == -15
    end

    @testset "parametric case" begin

        @lift @active Re{r :: Regex}(x) begin
            ret = match(r, x)
            ret === nothing || return Some(ret)
        end

        @test (@match "123" begin
            Re{r"\d+"}(x) => x.match
            _ => @error ""
        end) == "123"

        @test_skip @match "abc" begin
            Re{r"\d+"}(x) => x
            _ => @error ""
        end
    end

    @testset "custom pattern for given structs" begin
        @eval struct Interval end

        @lift @active internal Interval{a, b}(arg) begin
            a <= arg <= b
        end

        @use Enum

        @lift @active visible in (@__MODULE__) IsEven(a) begin
            a % 2 === 0
        end

        @lift MLStyle.is_enum(::Type{IsEven}) = true
        function parity(x)
            @match x begin
                IsEven => :even
                _ => :odd
            end
        end
        @test :even === parity(4)
        @test :odd === parity(3)

        @test 2 == @match 3 begin
            Interval{1, 2} => 1
            Interval{3, 4} => 2
            Interval{5, 6} => 3
            Interval{7, 8} => 4
        end

    end
end