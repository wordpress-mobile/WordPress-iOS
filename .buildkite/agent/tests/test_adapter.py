import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest


ADAPTER = Path(__file__).resolve().parents[1]
UUID = "11111111-1111-1111-1111-111111111111"
BOOTED_UUID = "22222222-2222-2222-2222-222222222222"
CREATED_UUID = "33333333-3333-3333-3333-333333333333"
RUNTIME = "com.apple.CoreSimulator.SimRuntime.iOS-26-0"
PHONE = "com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro"


class AdapterTest(unittest.TestCase):
    def setUp(self):
        directory = tempfile.TemporaryDirectory(prefix="wpios adapter ")
        self.addCleanup(directory.cleanup)
        self.root = Path(directory.name)
        self.repo = self.root / "checkout"
        self.bin = self.root / "bin"
        self.adapter = self.root / "snapshot"
        for path in (self.repo, self.bin, self.adapter, self.root / "home"):
            path.mkdir()
        for script in ADAPTER.glob("*.sh"):
            shutil.copy2(script, self.adapter)
        for name in ("python3", "git"):
            executable = sys.executable if name == "python3" else shutil.which(name)
            self.assertIsNotNone(executable, f"{name} is required for adapter tests")
            (self.bin / name).symlink_to(executable)
        for name in ("xcrun", "xcodebuild", "sleep"):
            path = self.bin / name
            path.write_text("#!/usr/bin/env python3\n" + (ADAPTER / "tests/fake_tool.py").read_text())
            path.chmod(0o755)
        self.env = {
            "HOME": str(self.root / "home"),
            "PATH": f"{self.bin}:/usr/bin:/bin",
            "LANG": "C",
            "GIT_CONFIG_NOSYSTEM": "1",
            "GIT_CONFIG_GLOBAL": os.devnull,
            "AGENT_OUTPUT_DIR": str(self.root / "output"),
            "AGENT_STATE_DIR": str(self.root / "state"),
            "TRACE": str(self.root / "trace.jsonl"),
            "CREATED_UDID": CREATED_UUID,
        }
        subprocess.run(["git", "init", "--quiet", str(self.repo)], env=self.env, check=True)
        self.simulators = {
            "devices": {
                RUNTIME: [{
                    "udid": UUID, "name": "Custom named simulator",
                    "deviceTypeIdentifier": PHONE, "state": "Shutdown", "isAvailable": True,
                }],
                "com.apple.CoreSimulator.SimRuntime.iOS-18-0": [{
                    "udid": BOOTED_UUID, "name": "iPhone 16",
                    "deviceTypeIdentifier": PHONE, "state": "Booted", "isAvailable": True,
                }],
            },
            "runtimes": [{
                "identifier": RUNTIME, "platform": "iOS", "version": "26.0", "isAvailable": True,
                "supportedDeviceTypes": [{"identifier": PHONE, "productFamily": "iPhone"}],
            }],
        }

    def run_adapter(self, script, *arguments, status=0, worker_log=False):
        self.env["SIMULATORS"] = json.dumps(self.simulators)
        command = ["/bin/bash", str(self.adapter / script), *arguments]
        if worker_log:
            path = self.root / "output/evidence/prepare.log"
            path.parent.mkdir(parents=True, exist_ok=True)
            with path.open("w") as stream:
                stream.write("Worker log prefix\n")
                stream.flush()
                result = subprocess.run(command, cwd=self.repo, env=self.env, text=True,
                                        stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=15)
                stream.write(result.stdout)
            output = path.read_text()
        else:
            result = subprocess.run(command, cwd=self.repo, env=self.env, text=True,
                                    stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=15)
            output = result.stdout
        self.assertEqual(status, result.returncode, output)
        return output

    def commands(self):
        trace = self.root / "trace.jsonl"
        return [json.loads(line) for line in trace.read_text().splitlines()] if trace.exists() else []

    def prepare(self):
        self.run_adapter("prepare.sh")

    def test_snapshot_and_default_smoke(self):
        self.prepare()
        self.assertEqual(BOOTED_UUID, (self.root / "state/simulator-udid").read_text().strip())
        self.run_adapter("verify.sh")
        commands = self.commands()
        build = next(command for command in commands if command[-1] == "build")
        self.assertIn("CODE_SIGNING_ALLOWED=NO", build)
        self.assertIn("-disableAutomaticPackageResolution", build)
        self.assertIn(str(self.root / "state/DerivedData"), build)
        self.assertFalse(any(command[1:3] == ["simctl", "boot"] for command in commands))
        self.assertTrue(any(command[1:3] == ["simctl", "install"] for command in commands))
        self.assertTrue(list((self.root / "output/evidence").glob("simulator-*.png")))

    def test_requested_device_is_booted(self):
        self.run_adapter("prepare.sh", "--simulator-udid", UUID)
        self.assertIn(["xcrun", "simctl", "boot", UUID], self.commands())

    def test_prepare_keeps_worker_log_intact(self):
        output = self.run_adapter("prepare.sh", worker_log=True)
        self.assertTrue(output.startswith("Worker log prefix\n"), output)
        logs = list((self.root / "output/evidence").glob("prepare-*.log"))
        self.assertEqual(1, len(logs))
        self.assertIn("Simulator ready:", logs[0].read_text())

    def test_fresh_user_creates_compatible_simulator(self):
        self.simulators["devices"] = {}
        self.simulators["runtimes"] += [
            {**self.simulators["runtimes"][0], "version": "18.0", "identifier": "older"},
            {**self.simulators["runtimes"][0], "version": "27.0", "isAvailable": False},
            {**self.simulators["runtimes"][0], "version": "28.0", "platform": "watchOS"},
        ]
        self.prepare()
        create = next(command for command in self.commands() if command[1:3] == ["simctl", "create"])
        self.assertEqual([PHONE, RUNTIME], create[-2:])
        self.assertIn(["xcrun", "simctl", "boot", CREATED_UUID], self.commands())
        self.assertEqual(CREATED_UUID, (self.root / "state/simulator-udid").read_text().strip())

    def test_no_runtime_fails_without_state(self):
        self.simulators = {"devices": {}, "runtimes": []}
        self.run_adapter("prepare.sh", status=1)
        self.assertFalse((self.root / "state/simulator-udid").exists())
        self.assertFalse(any(command[1:3] == ["simctl", "create"] for command in self.commands()))

    def test_no_compatible_iphone_type_fails_without_creating(self):
        self.simulators["devices"] = {}
        self.simulators["runtimes"][0]["supportedDeviceTypes"] = [{"productFamily": "iPad"}]
        self.run_adapter("prepare.sh", status=1)
        self.assertFalse(any(command[1:3] == ["simctl", "create"] for command in self.commands()))

    def test_creation_failure_does_not_publish_state(self):
        self.simulators["devices"] = {}
        self.env["CREATE_STATUS"] = "21"
        self.run_adapter("prepare.sh", status=1)
        self.assertFalse((self.root / "state/simulator-udid").exists())
        self.assertFalse(any(command[1:3] == ["simctl", "boot"] for command in self.commands()))

    def test_missing_requested_device_never_creates_replacement(self):
        self.run_adapter("prepare.sh", "--simulator-udid", CREATED_UUID, status=1)
        self.assertFalse(any(command[1:3] == ["simctl", "create"] for command in self.commands()))

    def test_invalid_requested_uuid_rejected_before_tools(self):
        for value in ("", "invalid", "../../anything"):
            self.run_adapter("prepare.sh", "--simulator-udid", value, status=2)
        self.assertEqual([], self.commands())

    def test_boot_failure_does_not_publish_state(self):
        self.env["BOOT_STATUS"] = "7"
        self.run_adapter("prepare.sh", "--simulator-udid", UUID, status=7)
        self.assertFalse((self.root / "state/simulator-udid").exists())

    def test_build_failure_is_propagated_before_install(self):
        self.prepare()
        self.env["BUILD_STATUS"] = "65"
        self.run_adapter("verify.sh", status=65)
        self.assertFalse(any(command[1:3] == ["simctl", "install"] for command in self.commands()))

    def test_scoped_tests_preserve_each_selector(self):
        self.prepare()
        self.run_adapter("verify.sh", "--test", "WordPressTest/One", "--test", "WordPressTest/Two/testMethod")
        command = next(command for command in self.commands() if command[-1] == "test")
        self.assertIn("-only-testing:WordPressTest/One", command)
        self.assertIn("-only-testing:WordPressTest/Two/testMethod", command)
        self.assertIn("WordPressUnitTests", command)
        self.assertFalse(any(command[1:3] == ["simctl", "install"] for command in self.commands()))

    def test_invalid_or_unscoped_tests_rejected_before_build(self):
        for selector in ("WordPressTest", "*", "Target/Suite --skip-testing:Other", "-workspace/Other"):
            self.run_adapter("verify.sh", "--test", selector, status=2)
        self.assertEqual([], self.commands())

    def test_missing_or_malformed_state_fails(self):
        self.run_adapter("verify.sh", status=1)
        (self.root / "state/simulator-udid").write_text("not-a-uuid")
        self.run_adapter("verify.sh", status=1)
        self.assertEqual([], self.commands())

    def test_build_only_has_no_simulator_operations(self):
        self.prepare()
        (self.root / "trace.jsonl").unlink()
        self.run_adapter("verify.sh", "--build-only")
        self.assertEqual(1, len(self.commands()))
        self.assertEqual("xcodebuild", self.commands()[0][0])

    def test_screenshot_does_not_rebuild(self):
        self.prepare()
        (self.root / "trace.jsonl").unlink()
        self.run_adapter("verify.sh", "--screenshot")
        self.assertEqual(1, len(self.commands()))
        self.assertEqual(["xcrun", "simctl", "io", BOOTED_UUID, "screenshot"], self.commands()[0][:5])

    def test_output_inside_checkout_rejected(self):
        self.env["AGENT_OUTPUT_DIR"] = str(self.repo / "unwanted-evidence")
        self.run_adapter("prepare.sh", status=1)
        self.assertFalse((self.repo / "unwanted-evidence").exists())

    def test_conflicting_modes_rejected(self):
        self.run_adapter("verify.sh", "--screenshot", "--test", "Target/Suite", status=2)
        self.run_adapter("verify.sh", "--build-only", "--launch", status=2)

    def test_secrets_cli_refused_without_execution(self):
        tool = self.bin / "a8c-secrets"
        tool.write_text("#!/bin/bash\necho must-not-run\nexit 99\n")
        tool.chmod(0o755)
        output = self.run_adapter("prepare.sh", status=1)
        self.assertNotIn("must-not-run", output)
        self.assertEqual([], self.commands())


if __name__ == "__main__":
    unittest.main(verbosity=2)
