Types
=====

Type mapping
------------

* ``integer`` ↔ ``int``. Results outside the VHDL integer range fail.
* ``real`` ↔ ``float``. Strict: an ``int`` result is not accepted.
* ``string`` ↔ ``str``. UTF-8.
* ``boolean`` ↔ ``bool``/``numpy.bool_`` (Python bridge only).
* ``integer_vector`` ↔ ``list`` of ``int``.
* ``real_vector`` ↔ ``list`` of ``float`` (``call_real_vector`` needs the bridge).
* ``integer_vector_ptr_t`` ↔ ``list`` of ``int``.
* ``std_ulogic``/``std_ulogic_vector`` ↔ ``str``, one character per element
  out of ``U X 0 1 Z W L H -``, left to right (results only).
* ``signed``/``unsigned`` ↔ ``int`` (procedure results only).
* ``integer_array_t`` ↔ ``numpy.ndarray``, see
  :ref:`python_bridge:integer_array`.

Results are strict: a value that does not fit the VHDL type, or is of the
wrong Python type, is an error. Values are never silently truncated or
wrapped.

.. _python_bridge:integer_array:

integer_array_t and NumPy
--------------------------

An ``integer_array_t`` argument is transferred to Python and referred to by
the expression as a NumPy array of dtype ``int32``, so it can be reused in
several calls. It is indexed like VUnit, so that elements correspond
directly:

============= ================================ ===========================
Array         VHDL                             Python
============= ================================ ===========================
1D            ``get(a, i)``                    ``a[i]``, shape ``(length,)``
2D            ``get(a, x, y)``                 ``a[x, y]``, shape ``(width, height)``
3D            ``get(a, x, y, z)``              ``a[x, y, z]``, shape ``(width, height, depth)``
============= ================================ ===========================

Image libraries such as Pillow and OpenCV, and ``numpy.loadtxt`` of a CSV file
written by VUnit's ``save_csv``, index rows first, ``[y, x]``. Swap the first two
axes of such an array with ``a.swapaxes(0, 1)``, or ``a.T`` for a 2D array, before
returning it to VHDL, and of an argument before passing it to them.

``integer_array_t`` does not record its number of dimensions. An argument is
treated as 3D if its depth is larger than one, else as 2D if its height is
larger than one, else as 1D.

A returned array (or nested list of integers) becomes a new
``integer_array_t`` with the corresponding width, height and depth. Its
``bit_width`` and ``is_signed`` are those of the argument, if the function
returns one of its ``integer_array_t`` arguments (possibly modified in
place), else given by the dtype: ``bool`` is 1 bit unsigned, ``int8``/``uint8``
8 bit, ``int16``/``uint16`` 16 bit and all other integer dtypes 32 bit
signed. All values must fit that word size, otherwise the call fails.
Floating point arrays are rejected; convert them explicitly with ``astype``.
As usual, the returned ``integer_array_t`` is owned by the caller and can be
freed with ``deallocate``.
