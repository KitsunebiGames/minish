# Instruction regression tests

These tests execute encoded instructions through `step()` on SH2, SH3, and SH4.
They require LDC (`ldc2`) and do not require a SuperH cross-compiler or `sheval`.

From the repository root, run:

```sh
(
    set -eu
    scratch=$(mktemp -d /tmp/minish-tests.XXXXXX)
    trap 'rm -rf "$scratch"' EXIT
    for test in multiply cmpstr; do
        TMPDIR=/tmp ldc2 -i -Isource -unittest -main "tests/$test.d" -of="$scratch/$test"
        "$scratch/$test"
    done
)
```

`multiply.d` covers signed and unsigned products, both halves of the result,
zero, and signed/unsigned boundaries. `cmpstr.d` covers false matches caused by
bitwise AND, equality in each byte position, and replacement of the previous T
bit. Both check that input registers and unrelated status bits are preserved
and that the program counter advances by two bytes.
