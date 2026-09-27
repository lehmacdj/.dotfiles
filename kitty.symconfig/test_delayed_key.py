"""Run with Kitty's Python:

kitty +runpy 'import runpy; runpy.run_path(
    "kitty.symconfig/test_delayed_key.py", run_name="__main__")'
"""

from pathlib import Path
import runpy
import unittest

from kittens.runner import import_kitten_main_module


class DelayedKeyLoadingTests(unittest.TestCase):
    def test_both_kitty_loaders(self):
        path = Path(__file__).resolve().with_name("delayed_key.py")
        keybinding = import_kitten_main_module(str(path.parent), path.name)
        keybinding_globals = keybinding["start"].__globals__
        self.assertNotIn("__file__", keybinding_globals)

        for mode, namespace in (
            ("keybinding", keybinding_globals),
            ("command line", runpy.run_path(str(path))),
        ):
            with self.subTest(mode=mode):
                parser = namespace["timespec"].resolve_time_arg
                self.assertEqual(parser("1h30m"), 5400)
                self.assertEqual(parser("1d"), 86400)
                self.assertEqual(parser("1w"), 604800)
                self.assertEqual(parser("1w2d3h"), 788400)


if __name__ == "__main__":
    unittest.main(argv=[__file__])
