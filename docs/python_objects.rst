.. _python_bridge:objects:

Python objects
--------------

A ``python_object_t`` is an instance of a Python class owned by VHDL. Every
object lives in a :ref:`session <python_bridge:sessions>` of its own, where it
is bound to ``obj``, so several objects, of the same class or not, never
share names or state. This makes an object the natural backend of a
verification component: every instance of the component gets an object of its
own, and a testbench can create one and give it to a component.

.. code-block:: vhdl

    constant model : python_object_t := new_python_object(
      "my_models.uart.UartModel", kwarg("baud", 115200), id => get_id("uart")
    );

    ...

    count := call(model, "push", arg(byte));   -- calls obj.push(byte)
    call(model, "reset");                      -- no return value
    check_true(eval_boolean(model, "obj.is_idle()"));
    exec(model, "obj.trace = True");

``new_python_object(class_name, args, id)``, or ``name`` instead of ``id``, names the class and the arguments
of its constructor, given like the arguments of ``call``, including groups made
with ``&``. The class is

* a dotted name like ``"package.module.Class"``, imported from the module it
  names, which is found like any other import: see :ref:`python_bridge:finding_code`.
  No file name is involved, so the class is found the same way wherever the
  object is created.
* the name of a class defined in the default session, like ``"Class"``, for
  example by ``exec`` or ``exec_file`` in the testbench, or reached through a
  name defined there, like ``"np.ndarray"`` after ``exec("import numpy as np")``.

A name that is neither, or that is not a class, is reported as an error of
the object.

``call(object, method, ...)`` calls a method, and ``eval(object, expr)`` and
``exec(object, code)`` evaluate an expression and execute code in the session
of the object, where the object is ``obj``. They have the same arguments,
result types and aliases as ``call``, ``eval`` and ``exec``, including the
procedure forms taking a ``std_ulogic_vector``, ``signed`` or ``unsigned``
result as an ``out`` parameter and the function forms taking its length or
``size_res``, for example ``byte := call_unsigned(model, "pop", byte'length)``.

new_python_object or create_python_object
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Both make an object and take the same arguments. They differ in when Python
constructs it:

.. list-table::
   :header-rows: 1
   :widths: 30 35 35

   * -
     - ``new_python_object``
     - ``create_python_object``
   * - Constructed
     - On first use: the first ``call``, ``eval`` or ``exec``
     - By the call itself
   * - Use it for
     - Constants, generics and the handles of verification components, made
       during elaboration
     - Variables in a process, for example in a test case
   * - A wrong class or constructor argument
     - Is reported at the first use
     - Is reported by ``create_python_object``
   * - During elaboration
     - Works: nothing runs in Python
     - Does not work: the simulator cannot run Python during elaboration

Use ``new_python_object`` wherever the object is declared outside a process: a
constant in an architecture or a package, a generic, or the record a
verification component's constructor returns. Nothing happens in Python until
the object is used, so it does not depend on the order of the processes or on
``test_runner_setup``.

Use ``create_python_object`` in a process when the object should exist, and
its errors be reported, at a known point, for example when a test case starts:

.. code-block:: vhdl

    if run("Test a transfer") then
      model := create_python_object("my_models.uart.UartModel", kwarg("baud", 115200));

Identity
~~~~~~~~

The ``id`` of an object names its session and its logger,
``get_logger(object)``, which reports the errors of its operations. It is
optional and mainly makes the log readable. Without an
``id``, objects are enumerated per class, the way VUnit enumerates
verification components: ``new_python_object("my_models.uart.UartModel")``
gives ``python_object:my_models.uart.UartModel:1``, then ``…:2`` and so on. The session of an object must
be its own, so ``new_python_object`` with an identity already used by another
object, or by a session made with ``new_session``, is reported as a failure on
the logger of the identity and returns ``null_python_object``. Using
``null_python_object`` is reported as a failure on ``python_logger``.

The identity can also be given by its full name, like ``get_logger(name)``:
``new_python_object("my_models.uart.UartModel", name => "tb:uart_model")`` is
``new_python_object("my_models.uart.UartModel", id => get_id("tb:uart_model"))``,
and so for ``create_python_object``.

``get_python_object(id)`` and ``get_python_object(name)`` return the object
made with that identity, so a testbench can reach the object of a component
without being given it:

.. code-block:: vhdl

    check_true(eval_boolean(get_python_object("tb:uart_model"), "obj.is_idle()"));

Unlike ``get_logger``, it does not make one, since that takes the class and
the arguments of its constructor: an identity without an object returns
``null_python_object``, and the object is made with ``new_python_object``.
An object is found once it is made, which for one made by another constant
during elaboration depends on the order of elaboration, so get it in a process.

From a model with module state to an object
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

A model loaded with ``exec_file`` and keeping its state in module globals is
shared by everything that calls it. Move the state into a class and give every
user an object:

.. code-block:: python

    # Before: packet_model.py, loaded with exec_file
    _packets = []

    def make_packets(seed, n):
        ...

    # After: the state belongs to the instance
    class PacketSource:
        def __init__(self, width):
            self.width = width
            self.packets = []

        def make_packets(self, seed, n):
            ...

.. code-block:: vhdl

    -- Before
    exec_file("packet_model.py");
    call("make_packets", arg(seed), arg(n));

    -- After: one object per source, found by module name
    constant source : python_object_t := new_python_object(
      "packet_model.PacketSource", kwarg("width", 32)
    );
    ...
    call(source, "make_packets", arg(seed), arg(n));

The class is found by its module name, so its directory must be on
``sys.path``, which for a model next to its testbench means adding that
directory to ``PYTHONPATH`` in the run script: see
:ref:`python_bridge:finding_code`.

Backends of verification components
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

A verification component usually makes its object in the constructor of its
handle, the way VUnit's own components make everything they need there. A
second constructor takes an object instead, for a testbench that gives the
component one:

.. code-block:: vhdl

    type uart_master_t is record
      p_std_cfg : std_cfg_t;
      p_model : python_object_t;
    end record;

    -- A UartModel of its own
    impure function new_uart_master(baud : positive; id : id_t := null_id) return uart_master_t is
      constant std_cfg : std_cfg_t := create_std_cfg(id, "my_vcs", "uart_master");
    begin
      return (
        p_std_cfg => std_cfg,
        p_model => new_python_object("my_vcs.uart.UartModel", kwarg("baud", baud), get_id(std_cfg))
      );
    end;

    -- A given model, e.g. shared with other components or the testbench
    impure function new_uart_master(model : python_object_t; id : id_t := null_id) return uart_master_t is
    begin
      return (p_std_cfg => create_std_cfg(id, "my_vcs", "uart_master"), p_model => model);
    end;

The component itself only calls the object of its handle:

.. code-block:: vhdl

    entity uart_master is
      generic(master : uart_master_t);
      ...

      process
      begin
        wait until rising_edge(clk) and start = '1';
        call(master.p_model, "transmit", arg(to_integer(data)));
      end process;

The handle is a constant made during elaboration, and so is its object, but
nothing happens in Python until the first call.

The identities follow from who makes the object:

* A component making its own object gives it its own identity: the ``id``
  given, or the one ``create_std_cfg`` numbers, ``my_vcs:uart_master:1``,
  ``my_vcs:uart_master:2`` and so on. The log of the component and of its
  object then share a name.
* A component given an object is named by its own ``id``, or numbered, never
  by the object. The object keeps the identity it was made with, since it is
  given in order to be shared, with the testbench or with other components,
  each with a name of its own.

``filter_vc`` of the `embedded_python example
<https://github.com/VUnit/vunit-python-bridge/tree/main/examples/embedded_python>`__
is a complete component of this kind: the handle is in ``filter_vc_pkg.vhd``,
the component in ``filter_vc.vhd`` and the Python model in ``filter_model.py``.
Its ``Test Python objects as backends of verification components`` test case
drives three instances, two with objects of their own and one sharing an object
with the testbench.

A component can also take the path of its instance, ``'path_name``, as the
identity when its handle has no ``id``. The object is then made in the
statement part of a process rather than in the constructor: GHDL leaves the
instance labels out of ``'path_name`` and ``'instance_name`` when they are
evaluated during elaboration, which would give all instances the same
identity. ``tests/path_counter_vc.vhd`` shows this:

.. code-block:: vhdl

    process
      variable vc_id : id_t := vc.p_id;
      variable backend : python_object_t;
    begin
      if vc_id = null_id then
        vc_id := get_id(path_counter_vc'path_name);
      end if;
      backend := new_python_object("models.counter_model.Counter", kwarg("step", vc.p_step), vc_id);
      ...

The testbench reaches such an object by the path of the instance, for example
``get_python_object("tb:counter_inst")``.

Several components can share an object, and so can a component and the
testbench: the testbench makes the object and gives it to each of them. A
memory model written by a bus slave and read back by the test is a typical
case:

.. code-block:: vhdl

    constant memory : python_object_t := new_python_object("my_models.Memory");

    ...

    slave_inst : entity work.my_bus_slave
      generic map (
        slave => new_my_bus_slave(model => memory)
      )
      port map (
        ...
      );

    ...

    check_equal(call_integer(memory, "read", arg(16#100#)), 16#cafe#);

In the same way, a component can let its user choose the class, by taking its
name as an argument of the constructor of its handle.

Errors and limitations
~~~~~~~~~~~~~~~~~~~~~~

* Errors are reported on the logger of the object, named after what failed:
  ``call("push") failed:`` for every form of ``call``, ``eval("<expr>", ...)
  failed:`` for ``eval`` and ``exec(...) failed:`` for ``exec``, followed by
  the Python error.
* An object that cannot be created, for example since its class is not
  found, reports the error once, as ``new_python_object("<class>") failed:``
  or ``create_python_object("<class>") failed:``.
  Every later use of the object, calls and assignments alike, fails with
  ``The <class> object could not be created: <error>``.
* The caveats of sessions apply: the module of a class, and any state kept in
  it, is shared by all objects.
* An ``integer_array_t`` argument is transferred to Python when it is made, so
  it cannot be a constructor argument of an object made during elaboration,
  before the simulation starts. Give the values to the object in a call
  instead: ``call(model, "load", arg(values))``. See `#17
  <https://github.com/VUnit/vunit-python-bridge/issues/17>`__.
* An object that holds resources, such as files or threads, is closed by a
  call like any other method: ``call(model, "close")``.
