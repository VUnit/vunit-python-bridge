Errors and semantics
====================

Errors
------

Python exceptions, syntax errors, type errors and undefined names are
reported as failures on the logger of the :ref:`session
<python_bridge:sessions>` the operation was performed in,
``get_logger(get_id(session))``, including the Python traceback. For the
default session that logger is named ``python_bridge:python:default`` and
``python_logger`` (named ``python_bridge:python``) is its parent. The test
fails and stops like for any other failure. The logger of the session can be
mocked to test error handling; when mocked, ``eval``/``call`` return a default
value (``0``, ``0.0``, ``""`` or an empty vector, depending on the type) after
the failure.

.. code-block:: text

    FAILURE - python_bridge:python:default - eval("1 / 0") failed:
    Traceback (most recent call last):
      File "<eval #3>", line 1, in <module>
        1 / 0
        ~~^~~
    ZeroDivisionError: division by zero

The default ``verbose`` format of the VUnit display handler indents the lines
of the traceback to the column where the message starts, after the time, the
logger name and the log level. With the long logger name of a session made from
an instance name and the absolute file paths of a traceback, the lines can be
wider than the terminal, which wraps them back to the first column and breaks
the alignment. The ``level`` format leaves out the time and the logger name and
indents the traceback by the width of the log level only:

.. code-block:: vhdl

    test_runner_setup(runner, runner_cfg);
    set_format(display_handler, level);

.. code-block:: text

    FAILURE - eval("1 / 0") failed:
              Traceback (most recent call last):
                File "<eval #3>", line 1, in <module>
                  1 / 0
                  ~~^~~
              ZeroDivisionError: division by zero

Output of ``print`` is written to the simulator output and flushed after
every operation.

.. _python_bridge:semantics:

Semantics to be aware of
-------------------------

.. important::

   * ``eval``/``eval_<type>`` are declared ``impure`` since they always read
     state from the Python interpreter.
   * Errors are reported as failures on the logger of the :ref:`session
     <python_bridge:sessions>`, including the Python traceback, rather than
     aborting the simulation.
   * ``python_setup`` and ``python_cleanup`` are optional, see
     :ref:`python_bridge:setup_and_cleanup`. ``python_cleanup`` does not
     finalize the interpreter.
   * ``real`` results have no float32 range limit: VHDL ``real`` is double
     precision where the Python bridge implements the API, so any finite
     Python ``float`` (also double precision) is in range. A value that is not
     finite, such as ``float("inf")`` or ``float("nan")``, has no VHDL ``real``
     representation and is reported as a failure.
   * ``string`` arguments are passed to Python as string literals: quotes,
     backslashes and control characters (such as line feed and tab) are
     escaped, so the Python function receives the text exactly as given.
     Pass plain text, not text already escaped for Python. Bytes >= 128 are
     kept as they are, so UTF-8 text arrives as the same Python characters.
.. _python_bridge:finding_code:

Where Python code is found
--------------------------

The interpreter in the simulator imports modules the way Python started on the
run script does. Without any setup, it finds:

* Modules in the directory of the run script, which is the first entry of
  ``sys.path``. This is also how ``import_run_script`` imports the run script.
* The packages of the Python environment VUnit runs in, for example an active
  virtual environment. That includes packages installed with ``pip install -e``.

Anything else has to be added to ``PYTHONPATH``. The simulator inherits the
environment of VUnit, so the run script can set it before VUnit starts the
simulations. A verification component that is used by many testbenches keeps
its Python code in a folder of its own, for example:

.. code-block:: text

    my_vc/
      my_vc.vhd
      python/
        my_vc_model/
          __init__.py

and the run script puts that folder on the path, after which the model is
``my_vc_model`` wherever the component is used:

.. code-block:: python

    import os
    from pathlib import Path
    from vunit import VUnit

    my_vc_python = Path(__file__).parent / "my_vc" / "python"
    os.environ["PYTHONPATH"] = os.pathsep.join(
        filter(None, [str(my_vc_python), os.environ.get("PYTHONPATH")])
    )

    vu = VUnit.from_argv()
    ...

Files given by name are found differently. A relative file name given to
``exec_file`` or ``import_module_from_file`` is relative to the directory of
the testbench file, ``tb_path``, and an absolute one is used as given.
``exec_file`` also puts the directory of the file on ``sys.path`` while it
executes, so the file can import the modules next to it.

There is one ``sys.path`` and one ``sys.modules`` per simulation, shared by all
:ref:`sessions <python_bridge:sessions>`. Two modules with the same name are
therefore the same module, so a package is best named after the component it
belongs to, and state kept at module level is shared by everything that
imports the module.

