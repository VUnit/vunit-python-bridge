.. _python_bridge:simulator_packages:

Simulator packages
------------------

A simulator can be provided by a VUnit package, whose ``vunit_pkg.toml`` names
its simulator interface class. The bridge does not list such simulators.
It collects them from VUnit, which knows the simulator interface classes of the
packages added before the bridge. A class says how the bridge is served with
two attributes:

``foreign_language_interface``
  How the simulator calls the bridge library: ``"VHPIDIRECT"``, ``"FLI"`` or
  ``"VHPI"``.

  * ``"VHPIDIRECT"``: the foreign attributes are
    ``VHPIDIRECT <library file name> <entry point>``, with the file name
    only, so the simulator has to load the library itself, from the flags or
    the environment the hooks below give it.
  * ``"FLI"``: the attributes of the FLI variant of the library, built against
    the ``mti.h`` of the simulator installation, as for Questa/ModelSim.
  * ``"VHPI"``: the attributes of the VHPI variant, built against the
    ``vhpi_user.h`` of the simulator installation, as for Riviera-PRO.

``native_library_hooks(library_file)``
  A static or class method returning how the simulator loads the given
  library: a ``dict`` of keyword arguments for
  ``context.register_simulator_hooks``, that is any of ``elab_flags``,
  ``run_flags``, ``process_flags`` and ``run_env``, each a function as
  described under "Simulator Hooks" in the VUnit documentation of packages.
  The bridge registers them for the simulator, with its own ``run_env`` on top
  of the one returned, which adds ``VUNIT_PYTHON_BRIDGE_CONFIG`` to the
  environment. The simulator interface must therefore apply the run
  environment hooks to the simulation.

For example, for a simulator that loads a library given with ``--load`` when
it runs a test:

.. code-block:: python

   class MySimulatorInterface(SimulatorInterface):
       name = "mysim"
       foreign_language_interface = "VHPIDIRECT"

       @staticmethod
       def native_library_hooks(library_file):
           return {"run_flags": lambda simulator_interface: [f"--load={library_file}"]}

The simulators of these classes are added to the built-in ones the bridge
serves, and take precedence over a built-in simulator of the same ``name``.
Only the selected simulator is checked and has its hooks called. Selecting a
simulator that is not among them fails when the package is added, with an
error naming the simulators the bridge serves and the two attributes. So do
an unknown interface name, only one of the two attributes, and hooks that are
not a ``dict`` of the keys above. A class defining only one of the attributes
is ignored when another simulator is selected.
