keccak-verilog
==============

[![CI](https://github.com/jmoles/keccak-verilog/actions/workflows/ci.yml/badge.svg)](https://github.com/jmoles/keccak-verilog/actions/workflows/ci.yml)

A SystemVerilog implementation of the Keccak-f[1600] permutation and sponge construction, translated from the [Keccak team's reference VHDL distribution](https://keccak.team/hardware.html). Originally a SystemVerilog class project, presented on 6 June 2013 (slides [here](https://docs.google.com/presentation/d/1fEvkiKvQkEGiJ8LwQPkU6PK8SjZtGHqMSyf2X4v82iY/)) and validated at the time with QuestaSim and Mentor Veloce.

## What this implements

The core in this repo is the **Keccak-f[1600] permutation** wrapped in a sponge that absorbs **pre-padded** input blocks. The padding policy is the *caller's* responsibility — whatever bytes you put in the input blocks, the core absorbs.

That makes it usable for either flavor of Keccak-derived hash, depending on which domain-separator byte the caller inserts before applying `pad10*1`:

| Hash | Domain separator | Used by |
|---|---|---|
| Original Keccak (e.g. Keccak-256) | none / `0x01` | Ethereum, the original [Keccak submission](https://keccak.team/) |
| SHA-3 (SHA3-224/256/384/512) | `0x06` | NIST [FIPS 202](https://csrc.nist.gov/publications/detail/fips/202/final) (August 2015) |
| SHAKE128 / SHAKE256 | `0x1F` | NIST FIPS 202 |

The Keccak-f[1600] permutation itself is identical across all of these and is what FIPS 202 standardizes — only the pre-permutation padding differs.

The bundled test vectors in `test_vectors/` come directly from the Keccak team's reference VHDL distribution (`KeccakVHDL-3.1/new_test_vector/`), which validates against the **original Keccak** padding. The core has not been independently validated against NIST's [CAVP test vectors](https://csrc.nist.gov/projects/cryptographic-algorithm-validation-program/secure-hashing) for SHA-3 — that would be a worthwhile addition for anyone wanting to use it as a FIPS 202 implementation.

I updated this design in April 2021 to run with [Verilator](https://verilator.org/). Prior to then, it ran with QuestaSim. The original design also targeted Mentor Veloce for emulation, but I no longer have access to that environment.

The state of the repository as originally submitted for the class — including the QuestaSim testbenches and Veloce TBX wrapper — is preserved at the [`class-submission-2013`](https://github.com/jmoles/keccak-verilog/releases/tag/class-submission-2013) tag.

See [CHANGELOG.md](CHANGELOG.md) for the history of changes since.

## Usage
Verify you have the latest version of [Verilator](https://verilator.org/) and its dependencies. Running

```shell
make
```

will generate the following output files in `logs`:

 - `coverage.dat` — Coverage data
 - `output.txt` — Output from the Keccak test routines. Meant for comparison against the [reference file](test_vectors/keccak_ref_out.txt).