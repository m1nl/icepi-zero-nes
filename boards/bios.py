"""Configure a target's boot manifest without modifying the LiteX checkout."""

from pathlib import Path
import shutil

from litex.soc.integration.builder import soc_directory


def configure_bios(builder, manifest):
    source = Path(soc_directory) / "software" / "bios"
    # Keep sources outside software/, which LiteX can delete on a full rebuild.
    destination = Path(builder.output_dir) / "bios-source"

    original = (
        '\t\tprintf("Booting from boot.json...\\n");\n'
        '\t\tfatfsboot_from_json("boot.json");'
    )
    replacement = (
        '\t\tprintf("Booting from %s...\\n", BIOS_BOOT_JSON);\n'
        '\t\tfatfsboot_from_json(BIOS_BOOT_JSON);'
    )
    text = (source / "boot.c").read_text()
    if text.count(original) != 1:
        raise RuntimeError("LiteX BIOS changed: review the boot manifest patch.")
    text = text.replace(original, replacement)

    shutil.copytree(source, destination, dirs_exist_ok=True)
    (destination / "boot.c").write_text(text)

    builder.soc.add_constant("BIOS_BOOT_JSON", manifest)
    builder.software_packages = [
        (name, path)
        for name, path in builder.software_packages
        if name != "bios"
    ]
    builder.add_software_package("bios", str(destination))
