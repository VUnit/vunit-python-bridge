/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/.
 *
 * Copyright (c) 2014-2026, Lars Asplund lars.anders.asplund@gmail.com
 *
 * VHPI front end of the bridge, compiled into the library only for
 * Riviera-PRO/Active-HDL, which have no direct binding (VHPIDIRECT). Every
 * entry point of bridge.h is registered as a foreign subprogram of the same
 * name, bound by the "VHPI <library> <entry point>" attributes of the
 * generated python_bridge_pkg.vhd. The callbacks read the parameters with
 * vhpi_get_value, delegate, and write the out parameters and the return value
 * with vhpi_put_value, so that the bridge itself, the generated VHDL and
 * python_ffi_pkg_bridge.vhd are the same for all simulators.
 *
 * Strings are transferred as vectors of character positions: Riviera-PRO ends
 * a vhpiStrVal at a line feed.
 */

#include "bridge.h"

#include <vhpi_user.h>

/* The base name of the library file, which the attributes name the library by */
#define LIBRARY_NAME "libvunit_python_bridge_vhpi"

/* Length of the chunk subtypes of python_bridge_pkg */
#define CHUNK_LENGTH 1024

/* ------------------------------------------------------------------------ */
/* Parameters and results                                                    */
/* ------------------------------------------------------------------------ */

static vhpiHandleT parameter(const vhpiCbDataT *cb_data, int32_t index) {
  return vhpi_handle_by_index(vhpiParamDecls, cb_data->obj, index);
}

static int32_t get_integer(const vhpiCbDataT *cb_data, int32_t index) {
  vhpiValueT value = {0};
  vhpiHandleT handle = parameter(cb_data, index);

  value.format = vhpiIntVal;
  vhpi_get_value(handle, &value);
  vhpi_release_handle(handle);
  return (int32_t)value.value.intg;
}

static void get_vector(const vhpiCbDataT *cb_data, int32_t index, vhpiFormatT format, void *buffer, size_t size) {
  vhpiValueT value = {0};
  vhpiHandleT handle = parameter(cb_data, index);

  value.format = format;
  value.bufSize = size;
  value.value.ptr = buffer;
  vhpi_get_value(handle, &value);
  vhpi_release_handle(handle);
}

static void put_vector(const vhpiCbDataT *cb_data, int32_t index, vhpiFormatT format, void *buffer, size_t size) {
  vhpiValueT value = {0};
  vhpiHandleT handle = parameter(cb_data, index);

  value.format = format;
  value.bufSize = size;
  value.numElems = CHUNK_LENGTH;
  value.value.ptr = buffer;
  vhpi_put_value(handle, &value, vhpiDeposit);
  vhpi_release_handle(handle);
}

static void return_integer(const vhpiCbDataT *cb_data, int32_t result) {
  vhpiValueT value = {0};

  value.format = vhpiIntVal;
  value.value.intg = (vhpiIntT)result;
  vhpi_put_value(cb_data->obj, &value, vhpiDeposit);
}

static void return_real(const vhpiCbDataT *cb_data, double result) {
  vhpiValueT value = {0};

  value.format = vhpiRealVal;
  value.value.real = result;
  vhpi_put_value(cb_data->obj, &value, vhpiDeposit);
}

static void get_string_chunk(const vhpiCbDataT *cb_data, int32_t index, char *chunk) {
  vhpiEnumT positions[CHUNK_LENGTH];

  get_vector(cb_data, index, vhpiEnumVecVal, positions, sizeof(positions));
  for (int32_t idx = 0; idx < CHUNK_LENGTH; idx++) {
    chunk[idx] = (char)positions[idx];
  }
}

static void put_string_chunk(const vhpiCbDataT *cb_data, int32_t index, const char *chunk) {
  vhpiEnumT positions[CHUNK_LENGTH];

  for (int32_t idx = 0; idx < CHUNK_LENGTH; idx++) {
    positions[idx] = (unsigned char)chunk[idx];
  }
  put_vector(cb_data, index, vhpiEnumVecVal, positions, sizeof(positions));
}

/* ------------------------------------------------------------------------ */
/* Entry points                                                              */
/* ------------------------------------------------------------------------ */

static void vhpi_vpy_setup(const vhpiCbDataT *cb_data) { return_integer(cb_data, vpy_setup()); }

static void vhpi_vpy_cleanup(const vhpiCbDataT *cb_data) { return_integer(cb_data, vpy_cleanup()); }

static void vhpi_vpy_buffer_clear(const vhpiCbDataT *cb_data) { return_integer(cb_data, vpy_buffer_clear()); }

static void vhpi_vpy_buffer_append(const vhpiCbDataT *cb_data) {
  char chunk[CHUNK_LENGTH];

  get_string_chunk(cb_data, 0, chunk);
  return_integer(cb_data, vpy_buffer_append(chunk, get_integer(cb_data, 1)));
}

static void vhpi_vpy_begin(const vhpiCbDataT *cb_data) { return_integer(cb_data, vpy_begin()); }

static void vhpi_vpy_execute(const vhpiCbDataT *cb_data) {
  return_integer(cb_data, vpy_execute(get_integer(cb_data, 0)));
}

static void vhpi_vpy_eval(const vhpiCbDataT *cb_data) {
  return_integer(cb_data, vpy_eval(get_integer(cb_data, 0), get_integer(cb_data, 1)));
}

static void vhpi_vpy_push_array(const vhpiCbDataT *cb_data) {
  return_integer(cb_data, vpy_push_array(get_integer(cb_data, 0), get_integer(cb_data, 1), get_integer(cb_data, 2),
                                         get_integer(cb_data, 3), get_integer(cb_data, 4), get_integer(cb_data, 5)));
}

static void vhpi_vpy_array_write(const vhpiCbDataT *cb_data) {
  int32_t chunk[CHUNK_LENGTH];

  get_vector(cb_data, 0, vhpiIntVecVal, chunk, sizeof(chunk));
  return_integer(cb_data, vpy_array_write(chunk, get_integer(cb_data, 1)));
}

static void vhpi_vpy_stage(const vhpiCbDataT *cb_data) { return_integer(cb_data, vpy_stage()); }

static void vhpi_vpy_result_integer(const vhpiCbDataT *cb_data) { return_integer(cb_data, vpy_result_integer()); }

static void vhpi_vpy_result_real(const vhpiCbDataT *cb_data) { return_real(cb_data, vpy_result_real()); }

static void vhpi_vpy_result_meta(const vhpiCbDataT *cb_data) {
  return_integer(cb_data, vpy_result_meta(get_integer(cb_data, 0)));
}

static void vhpi_vpy_error_length(const vhpiCbDataT *cb_data) { return_integer(cb_data, vpy_error_length()); }

/* The read procedures fill a whole chunk, the part beyond length is left as it was */
static void vhpi_vpy_result_read_string(const vhpiCbDataT *cb_data) {
  char chunk[CHUNK_LENGTH];

  get_string_chunk(cb_data, 0, chunk);
  vpy_result_read_string(chunk, get_integer(cb_data, 1), get_integer(cb_data, 2));
  put_string_chunk(cb_data, 0, chunk);
}

static void vhpi_vpy_result_read_integers(const vhpiCbDataT *cb_data) {
  int32_t chunk[CHUNK_LENGTH];

  get_vector(cb_data, 0, vhpiIntVecVal, chunk, sizeof(chunk));
  vpy_result_read_integers(chunk, get_integer(cb_data, 1), get_integer(cb_data, 2));
  put_vector(cb_data, 0, vhpiIntVecVal, chunk, sizeof(chunk));
}

static void vhpi_vpy_result_read_reals(const vhpiCbDataT *cb_data) {
  double chunk[CHUNK_LENGTH];

  get_vector(cb_data, 0, vhpiRealVecVal, chunk, sizeof(chunk));
  vpy_result_read_reals(chunk, get_integer(cb_data, 1), get_integer(cb_data, 2));
  put_vector(cb_data, 0, vhpiRealVecVal, chunk, sizeof(chunk));
}

static void vhpi_vpy_error_read(const vhpiCbDataT *cb_data) {
  char chunk[CHUNK_LENGTH];

  get_string_chunk(cb_data, 0, chunk);
  vpy_error_read(chunk, get_integer(cb_data, 1), get_integer(cb_data, 2));
  put_string_chunk(cb_data, 0, chunk);
}

/* ------------------------------------------------------------------------ */
/* Registration                                                              */
/* ------------------------------------------------------------------------ */

static void register_entry_point(vhpiForeignT kind, const char *name, void (*execf)(const vhpiCbDataT *)) {
  vhpiForeignDataT data = {kind, (char *)LIBRARY_NAME, (char *)name, NULL, execf};

  if (vhpi_register_foreignf(&data) == NULL) {
    vhpi_assert(vhpiError, "VUnit Python bridge: failed to register the foreign subprogram %s", name);
  }
}

static void register_entry_points(void) {
  register_entry_point(vhpiFuncF, "vpy_setup", vhpi_vpy_setup);
  register_entry_point(vhpiFuncF, "vpy_cleanup", vhpi_vpy_cleanup);
  register_entry_point(vhpiFuncF, "vpy_buffer_clear", vhpi_vpy_buffer_clear);
  register_entry_point(vhpiFuncF, "vpy_buffer_append", vhpi_vpy_buffer_append);
  register_entry_point(vhpiFuncF, "vpy_begin", vhpi_vpy_begin);
  register_entry_point(vhpiFuncF, "vpy_execute", vhpi_vpy_execute);
  register_entry_point(vhpiFuncF, "vpy_eval", vhpi_vpy_eval);
  register_entry_point(vhpiFuncF, "vpy_push_array", vhpi_vpy_push_array);
  register_entry_point(vhpiFuncF, "vpy_array_write", vhpi_vpy_array_write);
  register_entry_point(vhpiFuncF, "vpy_stage", vhpi_vpy_stage);
  register_entry_point(vhpiFuncF, "vpy_result_integer", vhpi_vpy_result_integer);
  register_entry_point(vhpiFuncF, "vpy_result_real", vhpi_vpy_result_real);
  register_entry_point(vhpiFuncF, "vpy_result_meta", vhpi_vpy_result_meta);
  register_entry_point(vhpiFuncF, "vpy_error_length", vhpi_vpy_error_length);
  register_entry_point(vhpiProcF, "vpy_result_read_string", vhpi_vpy_result_read_string);
  register_entry_point(vhpiProcF, "vpy_result_read_integers", vhpi_vpy_result_read_integers);
  register_entry_point(vhpiProcF, "vpy_result_read_reals", vhpi_vpy_result_read_reals);
  register_entry_point(vhpiProcF, "vpy_error_read", vhpi_vpy_error_read);
}

VPY_EXPORT void (*vhpi_startup_routines[])(void) = {register_entry_points, NULL};
