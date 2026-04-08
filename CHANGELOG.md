# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-04-08

First versioned release. Modernizes the toolchain, fixes a latent stack-corruption bug in the testbench, and removes long-dead files. The hardware design is unchanged.

### Added

- GitHub Actions CI workflow (`.github/workflows/ci.yml`) running on `ubuntu-latest`: installs Verilator from apt, runs `make lint`, builds, diffs against the reference vectors, and uploads `logs/` as an artifact.
- `make lint` target running `verilator --lint-only -Wall` over the SystemVerilog sources.
- Annotated git tag `class-submission-2013` (and matching GitHub Release) pointing at commit `614e0a5` (4 June 2013), preserving the state of the repo as originally presented in class.
- This `CHANGELOG.md`.

### Changed

- README: replaced the dead Travis CI badge with a GitHub Actions badge; corrected the "not-yet-finalized SHA-3 winner" line to reference FIPS 202 (August 2015); added a pointer to the `class-submission-2013` tag and to this changelog; dropped the stale reference to `vlt_dump.vcd` in the Usage section; updated stale `veripool.org/wiki/verilator` links to `verilator.org`.
- `Makefile`: `-Os` → `-O3` (Verilator 5 dropped `-Os`); consolidated the duplicated source-file lists into a single `VERILATOR_SV_INPUT` used by both `lint` and `run`; deleted a commented-out QuestaSim-era `Vtb_keccak` rule block; fixed `Speicfy`/`abount` typos in comments.
- `prog_keccak.cpp`: removed dead locals (`result`, `numTests`, `data_file_in`, `line_out`), the unused `LAST_BLOCK_LOW` enum value, the duplicate `Verilated::mkdir("logs")` call, and the `if (false && argc...)` warning-suppression hack; corrected a stale comment that referred to the deleted `Vtb_keccak.sv`.
- `.gitignore`: removed the stale `output.txt` entry (output now lives under `logs/`, which is already ignored).
- Bumped `actions/checkout` and `actions/upload-artifact` to v5 and set `FORCE_JAVASCRIPT_ACTIONS_TO_NODE24=true` to opt the workflow into Node 24.

### Fixed

- **Stack buffer overflow** in `prog_keccak.cpp`: `char line_in[16]` was being filled with 16-character hex tokens, clobbering the stack canary and tripping `__stack_chk_fail` at exit on newer toolchains. Bumped to `[32]`.
- `prog_keccak.cpp`: replaced an early `return` from inside the state machine (which broke destructor ordering under Verilator 5) with a `done` flag and a clean `return` at the end of `main`.
- `prog_keccak.cpp`: corrected `printf` format specifiers for `vluint64_t main_time` (`%d` → `%llu`) and added explicit `unsigned long long` casts on `QData` printf arguments, eliminating six `-Wformat` warnings.
- Trailing newlines added to `keccak_round.sv` and `keccak_round_constants_gen.sv` to satisfy Verilator 5's `EOFNEWLINE` warning under `-Wall`.

### Removed

- `.travis.yml` — Travis CI configuration. travis-ci.com is effectively dead for OSS and the build had been broken for years.
- `--trace` from `VERILATOR_FLAGS` — `prog_keccak.cpp` never wires up a `VerilatedVcdC`, so the flag only produced a runtime "previous dump at t=N" warning and slowed the build with no payoff.
- Dead `$dumpfile`/`$dumpvars` initial block in `keccak.sv` (gated on `+trace`) — Verilator no-ops these calls when `--trace` isn't passed, so the entire branch was unreachable. Bumped reported coverage from 90% to 92%.
- `tbx/` directory — Mentor Veloce TBX wrapper from the original 2013 class demo. Untested and unbuildable since 2013; preserved at the `class-submission-2013` tag.
- `prog_keccak.sv` and `tb_keccak.sv` — original QuestaSim-era SystemVerilog testbenches, superseded by `prog_keccak.cpp` in the 2021 Verilator port.

### Notes

- Reported Verilator coverage is **92%**, not 100%. The remaining 8% gap is dominated by toggle-coverage points on bits of the Keccak round-constant LUT that are mathematically constant by design (e.g. high bits that are always 0 across all 24 round constants), plus a couple of unreachable branches on the rounds counter. These cannot be hit without changing the algorithm; reaching 100% would require masking them with `// verilator coverage_off` pragmas, which would be cosmetic.

## [0.2.0] - 2021-04-12

### Added

- Verilator support and a C++ testbench (`prog_keccak.cpp`) replacing the QuestaSim-era SystemVerilog testbenches.
- Travis CI integration (later removed in 1.0.0).

### Changed

- README updated to reflect the move to Verilator and the loss of QuestaSim/Veloce.

## [0.1.1] - 2021-03-18

### Added

- Parameterized input and output buffer sizes ([#1] from @chris4795), with the original testbench restored afterwards.

## [0.1.0] - 2013-06-13

### Added

- Initial public release. SystemVerilog implementation of Keccak translated from the Keccak team's reference VHDL distribution. Validated with QuestaSim; emulated on Mentor Veloce via a TBX wrapper for the 6 June 2013 class presentation.

Preserved at the [`class-submission-2013`](https://github.com/jmoles/keccak-verilog/releases/tag/class-submission-2013) tag.

[1.0.0]: https://github.com/jmoles/keccak-verilog/releases/tag/v1.0.0
[0.2.0]: https://github.com/jmoles/keccak-verilog/compare/b9301d2...a3b09aa
[0.1.1]: https://github.com/jmoles/keccak-verilog/pull/1
[0.1.0]: https://github.com/jmoles/keccak-verilog/releases/tag/class-submission-2013
[#1]: https://github.com/jmoles/keccak-verilog/pull/1
