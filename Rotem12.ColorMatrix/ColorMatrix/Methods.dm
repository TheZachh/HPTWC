/**
 * matrix related methods
 */


proc
	/**
	 * Multiply two color matrices, they have to be same size.
	 *
	 * @param mat1   first list or color matrix to multiply
	 * @param mat2   second list or color matrix to multiply
     * @return resultMatrix new color matrix list multiplication result
	 */
	matrixMultiply(list/mat1, list/mat2)

		if(istype(mat1, /ColorMatrix))
			mat1 = mat1:matrix

		if(istype(mat2, /ColorMatrix))
			mat2 = mat2:matrix

		if(mat1.len != mat2.len || mat1.len < 9) return

		var/rowSize = mat1.len % 3 == 0 ? 3 : 4
		var/colSize = mat1.len / rowSize

		var/resultMatrix[mat1.len]

		var/i1
		var/i2
		for(var/i = 1 to colSize)
			i1 = (i - 1) * rowSize + 1

			for(var/j = 1 to rowSize)
				i2 = j

				var/result = 0

				for(var/k = 1 to rowSize)

					result += mat1[i1 + (k - 1)] * mat2[i2]
					i2     += rowSize

				resultMatrix[(i - 1) * rowSize + j] = result

		return resultMatrix