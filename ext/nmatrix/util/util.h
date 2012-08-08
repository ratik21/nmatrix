/////////////////////////////////////////////////////////////////////
// = NMatrix
//
// A linear algebra library for scientific computation in Ruby.
// NMatrix is part of SciRuby.
//
// NMatrix was originally inspired by and derived from NArray, by
// Masahiro Tanaka: http://narray.rubyforge.org
//
// == Copyright Information
//
// SciRuby is Copyright (c) 2010 - 2012, Ruby Science Foundation
// NMatrix is Copyright (c) 2012, Ruby Science Foundation
//
// Please see LICENSE.txt for additional copyright notices.
//
// == Contributing
//
// By contributing source code to SciRuby, you agree to be bound by
// our Contributor Agreement:
//
// * https://github.com/SciRuby/sciruby/wiki/Contributor-Agreement
//
// == util.h
//
// Header file for utility functions and data.

#ifndef UTIL_H
#define UTIL_H

/*
 * Standard Includes
 */

/*
 * Project Includes
 */

#include "types.h"

/*
 * Macros
 */

/*
 * Types
 */

/*
 * Data
 */

/*
 * Functions
 */

template <typename Type>
Type gcf(Type x, Type y);

/*extern template <>
int16_t gcf<int16_t>(int16_t, int16_t);
extern template <>
int32_t gcf<int32_t>(int32_t, int32_t);
extern template <>
int64_t gcf<int64_t>(int64_t, int64_t); */

#endif // UTIL_H
