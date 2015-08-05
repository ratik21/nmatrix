# = NMatrix
#
# A linear algebra library for scientific computation in Ruby.
# NMatrix is part of SciRuby.
#
# NMatrix was originally inspired by and derived from NArray, by
# Masahiro Tanaka: http://narray.rubyforge.org
#
# == Copyright Information
#
# SciRuby is Copyright (c) 2010 - 2014, Ruby Science Foundation
# NMatrix is Copyright (c) 2012 - 2014, John Woods and the Ruby Science Foundation
#
# Please see LICENSE.txt for additional copyright notices.
#
# == Contributing
#
# By contributing source code to SciRuby, you agree to be bound by
# our Contributor Agreement:
#
# * https://github.com/SciRuby/sciruby/wiki/Contributor-Agreement
#
# == lapack_spec.rb
#
# Tests for LAPACK functions that have internal implementations (i.e. they
# don't rely on external libraries). These tests will also be run for the
# plugins that do use external libraries, since they will override the
# internal implmentations.
#

require 'spec_helper'

describe "NMatrix::LAPACK functions with internal implementations" do
  # where integer math is allowed
  [:byte, :int8, :int16, :int32, :int64, :float32, :float64, :complex64, :complex128].each do |dtype|
    context dtype do
      # This spec seems a little weird. It looks like laswp ignores the last
      # element of piv, though maybe I misunderstand smth. It would make
      # more sense if piv were [2,1,3,3]
      it "exposes clapack laswp" do
        a = NMatrix.new(:dense, [3,4], [1,2,3,4,5,6,7,8,9,10,11,12], dtype)
        NMatrix::LAPACK::clapack_laswp(3, a, 4, 0, 3, [2,1,3,0], 1)
        b = NMatrix.new(:dense, [3,4], [3,2,4,1,7,6,8,5,11,10,12,9], dtype)
        expect(a).to eq(b)
      end

      # This spec is OK, because the default behavior for permute_columns
      # is :intuitive, which is different from :lapack (default laswp behavior)
      it "exposes NMatrix#permute_columns and #permute_columns! (user-friendly laswp)" do
        a = NMatrix.new(:dense, [3,4], [1,2,3,4,5,6,7,8,9,10,11,12], dtype)
        b = NMatrix.new(:dense, [3,4], [3,2,4,1,7,6,8,5,11,10,12,9], dtype)
        piv = [2,1,3,0]
        r = a.permute_columns(piv)
        expect(r).not_to eq(a)
        expect(r).to eq(b)
        a.permute_columns!(piv)
        expect(a).to eq(b)
      end
    end
  end

  # where integer math is not allowed
  [:float32, :float64, :complex64, :complex128].each do |dtype|
    context dtype do

      # clapack_getrf performs a LU decomposition, but unlike the
      # standard LAPACK getrf, it's the upper matrix that has unit diagonals
      # and the permutation is done in columns not rows. See the code for
      # details.
      # Also the rows in the pivot vector are indexed starting from 0,
      # rather than 1 as in LAPACK
      it "calculates LU decomposition using clapack_getrf (row-major, square)" do
        a = NMatrix.new(3, [4,9,2,3,5,7,8,1,6], dtype: dtype)
        ipiv = NMatrix::LAPACK::clapack_getrf(:row, a.shape[0], a.shape[1], a, a.shape[1])
        b = NMatrix.new(3,[9, 2.0/9, 4.0/9,
                           5, 53.0/9, 7.0/53,
                           1, 52.0/9, 360.0/53], dtype: dtype)
        ipiv_true = [1,2,2]

        # delta varies for different dtypes
        err = case dtype
                when :float32, :complex64
                  1e-6
                when :float64, :complex128
                  1e-15
              end

        expect(a).to be_within(err).of(b)
        expect(ipiv).to eq(ipiv_true)
      end

      it "calculates LU decomposition using clapack_getrf (row-major, rectangular)" do
        a = NMatrix.new([3,4], GETRF_EXAMPLE_ARRAY, dtype: dtype)
        ipiv = NMatrix::LAPACK::clapack_getrf(:row, a.shape[0], a.shape[1], a, a.shape[1])
        #we can't use GETRF_SOLUTION_ARRAY here, because of the different
        #conventions of clapack_getrf
        b = NMatrix.new([3,4],[10.0, -0.1,      0.0,       0.4,
                               3.0,   9.3,  20.0/93,   38.0/93,
                               1.0,   7.1, 602.0/93, 251.0/602], dtype: dtype)
        ipiv_true = [2,2,2]

        # delta varies for different dtypes
        err = case dtype
                when :float32, :complex64
                  1e-6
                when :float64, :complex128
                  1e-15
              end

        expect(a).to be_within(err).of(b)
        expect(ipiv).to eq(ipiv_true)
      end

      #Normally we wouldn't check column-major routines, since all our matrices
      #are row-major, but we use the column-major version in #getrf!, so we
      #want to test it here.
      it "calculates LU decomposition using clapack_getrf (col-major, rectangular)" do
        #this is supposed to represent the 3x2 matrix
        # -1  2
        #  0  3
        #  1 -2
        a = NMatrix.new([1,6], [-1,0,1,2,3,-2], dtype: dtype)
        ipiv = NMatrix::LAPACK::clapack_getrf(:col, 3, 2, a, 3)
        b = NMatrix.new([1,6], [-1,0,-1,2,3,0], dtype: dtype)
        ipiv_true = [0,1]

        # delta varies for different dtypes
        err = case dtype
                when :float32, :complex64
                  1e-6
                when :float64, :complex128
                  1e-15
              end

        expect(a).to be_within(err).of(b)
        expect(ipiv).to eq(ipiv_true)
      end

      it "calculates LU decomposition using #getrf! (rectangular)" do
        a = NMatrix.new([3,4], GETRF_EXAMPLE_ARRAY, dtype: dtype)
        ipiv = a.getrf!
        b = NMatrix.new([3,4], GETRF_SOLUTION_ARRAY, dtype: dtype)
        ipiv_true = [2,3,3]

        # delta varies for different dtypes
        err = case dtype
                when :float32, :complex64
                  1e-6
                when :float64, :complex128
                  1e-14
              end

        expect(a).to be_within(err).of(b)
        expect(ipiv).to eq(ipiv_true)
      end

      it "calculates LU decomposition using #getrf! (square)" do
        a = NMatrix.new([4,4], [0,1,2,3, 1,1,1,1, 0,-1,-2,0, 0,2,0,2], dtype: dtype)
        ipiv = a.getrf!

        b = NMatrix.new([4,4], [1,1,1,1, 0,2,0,2, 0,-0.5,-2,1, 0,0.5,-1,3], dtype: dtype)
        ipiv_true = [2,4,3,4]

        expect(a).to eq(b)
        expect(ipiv).to eq(ipiv_true)
      end

      # Together, these calls are basically xGESV from LAPACK: http://www.netlib.org/lapack/double/dgesv.f
      # Spec OK
      it "exposes clapack_getrs" do
        a     = NMatrix.new(3, [-2,4,-3, 3,-2,1, 0,-4,3], dtype: dtype)
        ipiv  = NMatrix::LAPACK::clapack_getrf(:row, 3, 3, a, 3)
        b     = NMatrix.new([3,1], [-1, 17, -9], dtype: dtype)

        NMatrix::LAPACK::clapack_getrs(:row, false, 3, 1, a, 3, ipiv, b, 3)

        expect(b[0]).to eq(5)
        expect(b[1]).to eq(-15.0/2)
        expect(b[2]).to eq(-13)
      end

      it "solves matrix equation (non-vector rhs) using clapack_getrs" do
        a     = NMatrix.new(3, [-2,4,-3, 3,-2,1, 0,-4,3], dtype: dtype)
        b     = NMatrix.new([3,2], [-1,2, 17,1, -9,-4], dtype: dtype)

        n = a.shape[0]
        nrhs = b.shape[1]

        ipiv  = NMatrix::LAPACK::clapack_getrf(:row, n, n, a, n)
        # Even though we pass :row to clapack_getrs, it still interprets b as
        # column-major, so need to transpose b before and after:
        b = b.transpose
        NMatrix::LAPACK::clapack_getrs(:row, false, n, nrhs, a, n, ipiv, b, n)
        b = b.transpose

        b_true = NMatrix.new([3,2], [5,1, -7.5,1, -13,0], dtype: dtype)
        expect(b).to eq(b_true)
      end

      #spec OK, but getri is only implemented by the atlas plugin, so maybe this one doesn't have to be shared
      it "exposes clapack_getri" do
        a = NMatrix.new(:dense, 3, [1,0,4,1,1,6,-3,0,-10], dtype)
        ipiv = NMatrix::LAPACK::clapack_getrf(:row, 3, 3, a, 3) # get pivot from getrf, use for getri

        begin
          NMatrix::LAPACK::clapack_getri(:row, 3, a, 3, ipiv)

          b = NMatrix.new(:dense, 3, [-5,0,-2,-4,1,-1,1.5,0,0.5], dtype)
          expect(a).to eq(b)
        rescue NotImplementedError => e
          pending e.to_s
        end
      end
    end
  end
end
