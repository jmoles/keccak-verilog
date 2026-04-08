keccak-verilog
==============

[![CI](https://github.com/jmoles/keccak-verilog/actions/workflows/ci.yml/badge.svg)](https://github.com/jmoles/keccak-verilog/actions/workflows/ci.yml)

A Verilog (specifically, SystemVerilog) implementation of Keccak, the algorithm standardized as SHA-3 in [FIPS 202](https://csrc.nist.gov/publications/detail/fips/202/final) (August 2015). This is for a SystemVerilog class project. This design was validated with Questa and Veloce. I presented it as part of class on 6 June 2013 and the presentation is available [here](https://docs.google.com/presentation/d/1fEvkiKvQkEGiJ8LwQPkU6PK8SjZtGHqMSyf2X4v82iY/).

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