module Rainforestlib_utils

    function diff_matrices(difffun::Function, matrix1::Matrix, matrix2::Matrix)::Matrix 
        
        rows, cols = size(matrix1)

        result = zeros(rows, cols)

        for r in range(1, rows)
            for c in range(1, cols)

                result[r, c] = difffun(matrix1[r, c], matrix2[r, c])
            end
        end

        return result
    end


    function replace_zero_with_nan(x::Real)

        return x != 0 || isnan(x) ? x : NaN32
    
    end

    
end