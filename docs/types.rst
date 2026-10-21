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
* ``dict_t`` ↔ ``dict``, see
  :ref:`python_bridge:dict`.

Results are strict: a value that does not fit the VHDL type, or is of the
wrong Python type, is an error. Values are never silently truncated or
wrapped.

.. _python_bridge:dict:

dict_t and dict
---------------

A ``dict_t`` from VUnit's ``dict_pkg`` (string keys, values of mixed types) is
a Python ``dict``. As an argument, ``arg(dict)`` and ``kwarg("name", dict)``
write the ``dict`` as the Python literal ``{"key": value, ...}``. The values
are ``integer``, ``real``, ``string``, ``boolean``, ``std_ulogic``,
``integer_vector``, ``real_vector``,
``integer_vector_ptr_t``, ``integer_array_t`` and nested ``dict_t``. Any
other value type is reported like any other argument that cannot be
converted. An ``integer_array_t`` value becomes a NumPy array as described in
:ref:`python_bridge:integer_array`. The keys are
visited in the order of ``get_key``, which VUnit does not specify.

.. code-block:: vhdl

    constant cfg : dict_t := new_dict;
    set_integer(cfg, "taps", 8);
    set_real(cfg, "gain", 0.5);
    call("model.configure", arg(cfg));

``eval_dict`` and ``call_dict`` (aliased ``eval`` and ``call``) convert a
Python ``dict`` with ``str`` keys to a new ``dict_t`` that the caller owns and
deallocates. The values are converted strictly: ``int`` to ``integer``,
``float`` to ``real``, ``str`` to ``string``, ``bool`` to ``boolean``, a
``list`` of ``int`` to ``integer_vector_ptr_t``, a NumPy array of integers to
``integer_array_t`` and a ``dict`` to a nested ``dict_t``, the last three
stored with ``set_integer_vector_ptr_t_ref``, ``set_integer_array_t_ref`` and
``set_dict_t_ref``. The bit width and signedness of an ``integer_array_t``
follow the dtype of the array like for ``eval_integer_array``, see
:ref:`python_bridge:integer_array`. ``None``, an ``int`` outside the VHDL integer range, a key
that is not a ``str`` or any other value is an error, and ``eval_dict`` then
returns an empty ``dict_t`` after reporting it.

.. code-block:: vhdl

    constant result : dict_t := eval("{'name': 'fir', 'taps': [1, 2, 1], 'gain': 0.5}");
    check_equal(get_string(result, "name"), "fir");

.. _python_bridge:integer_array:

integer_array_t and NumPy
--------------------------

An ``integer_array_t`` argument is transferred to Python and referred to by
the expression as a NumPy array of dtype ``int32``, so it can be reused in
several calls. Since it is transferred when the argument is made, the
argument must be made after ``test_runner_setup``, not during elaboration, for
example in a constant. Otherwise ``arg`` and ``kwarg`` report a failure, see
`#17 <https://github.com/VUnit/vunit-python-bridge/issues/17>`__. It is
indexed like VUnit, so that elements correspond directly:

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
