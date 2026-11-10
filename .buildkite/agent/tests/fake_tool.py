import json
import os
from pathlib import Path
import sys

name = Path(sys.argv[0]).name
arguments = sys.argv[1:]
with open(os.environ["TRACE"], "a") as stream:
    stream.write(json.dumps([name, *arguments]) + "\n")

if name == "xcodebuild":
    print("fake xcodebuild")
    status = os.environ.get("BUILD_STATUS", "0") if "-version" not in arguments else "0"
    sys.exit(int(status))
if name == "sleep":
    sys.exit(0)
if arguments[:2] == ["simctl", "list"]:
    data = json.loads(os.environ["SIMULATORS"])
    if arguments[2] == "devices":
        data = {"devices": data["devices"]}
    print(json.dumps(data))
elif arguments[:2] == ["simctl", "create"]:
    print(os.environ["CREATED_UDID"])
    sys.exit(int(os.environ.get("CREATE_STATUS", "0")))
elif arguments[:2] == ["simctl", "boot"]:
    sys.exit(int(os.environ.get("BOOT_STATUS", "0")))
elif len(arguments) > 3 and arguments[1] == "io" and arguments[3] == "screenshot":
    Path(arguments[4]).write_bytes(b"fake png")
