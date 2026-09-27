# Embedded Python example

`tb_example.vhd` calls Python from a VHDL testbench: `exec` and `eval`, function calls, NumPy
arrays, Python models and verification components, error reporting and plots. See the
[user guide](../../docs/user_guide.rst) for the API.

## Running

```bash
python run.py --without-attributes .expected_failure --without-attributes .optional_deps
```

runs every test that needs no extra Python packages and no user input. Without the options,
`run.py` also runs the tests that fail by design and says which packages the others need.

The three PySimpleGUI tests are interactive: they open dialogs and wait for an answer, so they
need a display and someone to answer them.
