"""Statically audit BO7 VM 0x1a GSCC native imports without loading the game.

Usage: python audit_imports.py --exe <installed-game.exe> [--output <json>] <file.gscc>...
Only --output is written. Script imports are listed separately and are not
misreported as unresolved native imports. No game bytes are emitted.
"""
from pathlib import Path
import argparse
import hashlib
import json
import mmap
import struct
import sys

CUSTOM_BUILTINS = {
    0x3E8529C542975D6F: "nengine_store_set",
    0x4DF476D19AE585CC: "nengine_store_save",
    0x7CF94832DCA3AFAE: "nengine_store_clear",
}
KNOWN_NAMES = {
    **CUSTOM_BUILTINS,
    0xE74B28DB80881244: "getxhashsourcename",
    0xF05BC0DF46279746: "isxhash",
    0x31A5979FA4F6239A: "isscriptabledefined",
    0x0284FE2713CE0368: "getxhashhexname",
}


def read_imports(path):
    data = path.read_bytes()
    if data[:8] != b"\x1aGSC\r\n\0\0":
        raise ValueError(f"{path}: only verified BO7 VM 0x1a layout is supported")
    count = struct.unpack_from("<H", data, 0x1E)[0]
    position = struct.unpack_from("<I", data, 0x2C)[0]
    rows = []
    for _ in range(count):
        if position + 24 > len(data):
            raise ValueError(f"{path}: import record exceeds file")
        name, namespace, sites, arity, flags = struct.unpack_from("<QQHBB", data, position)
        position += 24 + sites * 4
        if position > len(data):
            raise ValueError(f"{path}: import call-site list exceeds file")
        rows.append({"name_hash": f"{name:016x}", "namespace_hash": f"{namespace:016x}",
                     "arity": arity, "flags": f"{flags:02x}", "call_sites": sites,
                     "known_name": KNOWN_NAMES.get(name)})
    return rows


def audit(exe, scripts):
    with exe.open("rb") as stream, mmap.mmap(stream.fileno(), 0, access=mmap.ACCESS_READ) as image:
        pe = struct.unpack_from("<I", image, 0x3C)[0]
        image_base = struct.unpack_from("<Q", image, pe + 48)[0]
        table = pe + 24 + struct.unpack_from("<H", image, pe + 20)[0]
        sections = []
        for index in range(struct.unpack_from("<H", image, pe + 6)[0]):
            offset = table + 40 * index
            label = image[offset:offset + 8].split(b"\0")[0].decode()
            virtual_size, virtual, size, raw = struct.unpack_from("<4I", image, offset + 8)
            sections.append((label, virtual, raw, size))
        _, _, start, length = next(section for section in sections if section[0] == ".data")

        def native_entry(value):
            position = start
            while True:
                position = image.find(value.to_bytes(8, "little"), position, start + length)
                if position < 0:
                    return None
                pointer = struct.unpack_from("<Q", image, position + 8)[0]
                dev, minimum, maximum = image[position + 16:position + 19]
                valid_pointer = any(label == ".text" and virtual <= pointer - image_base < virtual + size
                                    for label, virtual, raw, size in sections)
                if valid_pointer and dev in (0, 1) and minimum <= maximum:
                    return {"table_file_offset": f"0x{position:x}", "function_va": f"0x{pointer:x}",
                            "developer_only": bool(dev), "min_args": minimum, "max_args": maximum}
                position += 1

        modules = []
        for path in scripts:
            native, scripted, issues = [], [], []
            for row in read_imports(path):
                opcode_class = int(row["flags"], 16) & 15
                if opcode_class not in (8, 9):
                    row["kind"] = "script_import"
                    row["resolution"] = "requires separate local/loaded-script export audit"
                    scripted.append(row)
                    continue
                row["kind"] = "builtin_method" if opcode_class == 9 else "builtin_function"
                value = int(row["name_hash"], 16)
                found = native_entry(value)
                if found:
                    row["resolution"] = "stock_native_table"
                    row.update(found)
                    if found["developer_only"]:
                        issues.append({"name_hash": row["name_hash"], "kind": "developer_only_builtin"})
                    if not found["min_args"] <= row["arity"] <= found["max_args"]:
                        issues.append({"name_hash": row["name_hash"], "kind": "native_arity_out_of_range",
                                       "arity": row["arity"], "min_args": found["min_args"], "max_args": found["max_args"]})
                elif value in CUSTOM_BUILTINS and opcode_class == 8:
                    row["resolution"] = "allowlisted_kronos_v141_custom_builtin"
                else:
                    row["resolution"] = "unresolved_native_builtin"
                    issues.append({"name_hash": row["name_hash"], "kind": "unresolved_native_builtin"})
                native.append(row)
            modules.append({"path": str(path), "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
                            "native_imports": native, "script_imports": scripted, "issues": issues,
                            "native_audit_passed": not issues})
        return {
            "scope": "Static builtin-table, developer flag and arity audit; script linking and gameplay unverified",
            "exe": str(exe), "exe_sha256": hashlib.sha256(image).hexdigest(),
            "table_layout_source": "https://github.com/ate47/atian-cod-tools/blob/fd6348d4cf729587703fee08b488a95424e413d3/src/core/acts/tools/bo6/bo6.cpp#L124-L130",
            "custom_builtin_allowlist": {f"{key:016x}": value for key, value in CUSTOM_BUILTINS.items()},
            "modules": modules,
            "all_native_audits_passed": all(module["native_audit_passed"] for module in modules),
        }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--exe", required=True, type=Path)
    parser.add_argument("--output", type=Path)
    parser.add_argument("gscc", nargs="+", type=Path)
    arguments = parser.parse_args()
    report = audit(arguments.exe, arguments.gscc)
    rendered = json.dumps(report, indent=2) + "\n"
    if arguments.output:
        arguments.output.write_text(rendered, encoding="utf-8")
        for module in report["modules"]:
            print(module["path"], "PASS" if module["native_audit_passed"] else "FAIL", json.dumps(module["issues"]))
    else:
        print(rendered, end="")
    return 0 if report["all_native_audits_passed"] else 1


if __name__ == "__main__":
    sys.exit(main())
