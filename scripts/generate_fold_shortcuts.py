"""Rebuild the two bundled, Apple-signed Shortcuts files on macOS."""

import argparse
import json
from pathlib import Path
import plistlib
import struct
import subprocess
import tempfile
import uuid


ROOT = Path(__file__).resolve().parents[1]
DESTINATION = ROOT / "App" / "FoldShortcuts"


def workflow(direction, mode, bundle_id, team_id):
    intent = f"Get{direction}SoundIntent"
    action_id = f"{bundle_id}.{intent}"
    output_id = str(uuid.uuid5(uuid.NAMESPACE_URL, action_id)).upper()
    trigger_id = str(uuid.uuid5(uuid.NAMESPACE_URL, action_id + "/trigger")).upper()
    return {
        "WFWorkflowClientVersion": "5114.0.12",
        "WFWorkflowMinimumClientVersion": 900,
        "WFWorkflowMinimumClientVersionString": "900",
        "WFWorkflowIcon": {"WFWorkflowIconStartColor": 463140863, "WFWorkflowIconGlyphNumber": 61465},
        "WFWorkflowTypes": ["WFWorkflowTypeShowInSearch"],
        "WFWorkflowInputContentItemClasses": [],
        "WFWorkflowOutputContentItemClasses": [],
        "WFWorkflowTriggers": [{
            "WFTriggerIdentifier": "WFMultiTaskingArrangementTrigger",
            "WFTriggerUUID": trigger_id,
            "WFTriggerSerializedParameters": {"WFArrangementMode": mode},
        }],
        "WFWorkflowActions": [
            {
                "WFWorkflowActionIdentifier": action_id,
                "WFWorkflowActionParameters": {
                    "AppIntentDescriptor": {
                        "AppIntentIdentifier": intent,
                        "BundleIdentifier": bundle_id,
                        "TeamIdentifier": team_id,
                        "Name": "Hingy",
                    },
                    "UUID": output_id,
                },
            },
            {
                "WFWorkflowActionIdentifier": "is.workflow.actions.playsound",
                "WFWorkflowActionParameters": {
                    "WFInput": {
                        "WFSerializationType": "WFTextTokenAttachment",
                        "Value": {"Type": "ActionOutput", "OutputUUID": output_id},
                    },
                },
            },
        ],
    }


def verify_signed(asset, expected, scratch):
    # An older Shortcuts signer can succeed while silently stripping the automation.
    data = asset.read_bytes()
    if data[:4] != b"AEA1":
        raise ValueError(f"{asset.name} is not a signed shortcut")
    header_length = struct.unpack_from("<I", data, 8)[0]
    header = plistlib.loads(data[12:12 + header_length])
    certificate = header["SigningCertificateChain"][0]
    key = subprocess.check_output(["/usr/bin/openssl", "x509", "-inform", "DER", "-pubkey", "-noout"],
                                  input=certificate)
    public_key = scratch / "signer.pem"
    public_key.write_bytes(key)
    archive = scratch / "workflow.aar"
    subprocess.run(["/usr/bin/aea", "decrypt", "-i", asset, "-o", archive,
                    "-sign-pub", public_key], check=True)
    subprocess.run(["/usr/bin/aa", "extract", "-i", archive, "-d", scratch,
                    "-include-path", "Shortcut.wflow"], check=True)
    signed = plistlib.loads((scratch / "Shortcut.wflow").read_bytes())
    for field in ("WFWorkflowTriggers", "WFWorkflowActions"):
        if signed.get(field) != expected[field]:
            raise ValueError(f"{asset.name}: {field} changed during signing. Use an OS 27 signer.")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--verify", action="store_true", help="Verify the bundled files without signing")
    args = parser.parse_args()
    owner = json.loads((ROOT / "release/readiness.json").read_text())["owner"]
    with tempfile.TemporaryDirectory() as tmp:
        signed = []
        for direction, mode in (("Opening", "ModeA"), ("Closing", "ModeB")):
            name = f"Hingy {direction} Sound.shortcut"
            scratch = Path(tmp) / direction
            scratch.mkdir()
            spec = workflow(direction, mode, owner["bundle_id"], owner["team_id"])
            if args.verify:
                verify_signed(DESTINATION / name, spec, scratch)
                continue
            source = scratch / name
            result = Path(tmp) / name
            source.write_bytes(plistlib.dumps(spec, fmt=plistlib.FMT_BINARY))
            subprocess.run(["/usr/bin/shortcuts", "sign", "--mode", "anyone",
                            "--input", source, "--output", result], check=True)
            verify_signed(result, spec, scratch)
            signed.append(result)
        if signed:
            DESTINATION.mkdir(exist_ok=True)
        for result in signed:
            (DESTINATION / result.name).write_bytes(result.read_bytes())


if __name__ == "__main__":
    main()
