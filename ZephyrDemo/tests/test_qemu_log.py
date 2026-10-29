import importlib.util
from pathlib import Path
import tempfile
import unittest


spec = importlib.util.spec_from_file_location(
    "qemu_log", Path(__file__).resolve().parents[1] / "scripts/normalize_qemu_log.py"
)
qemu_log = importlib.util.module_from_spec(spec)
spec.loader.exec_module(qemu_log)


class QemuLogTests(unittest.TestCase):
    def test_newlines_preserve_alert_bytes_and_are_idempotent(self):
        with tempfile.TemporaryDirectory() as directory:
            log = Path(directory) / "session with spaces.log"
            # Payload-like bytes, a lone CR, LF and already-correct CRLF survive.
            log.write_bytes(b"boot\r\r\nDFM:AP8=\r\r\r\nfault\r\nreset\n\x00\xff\rX")
            expected = b"boot\r\nDFM:AP8=\r\nfault\r\nreset\n\x00\xff\rX"
            qemu_log.normalize_log(log)
            self.assertEqual(log.read_bytes(), expected)
            qemu_log.normalize_log(log)
            self.assertEqual(log.read_bytes(), expected)

    def test_failed_launch_without_log(self):
        with tempfile.TemporaryDirectory() as directory:
            log = Path(directory) / "missing.log"
            qemu_log.normalize_log(log)
            self.assertFalse(log.exists())


if __name__ == "__main__":
    unittest.main()
