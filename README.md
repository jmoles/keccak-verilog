keccak-verilog
==============

A Verilog (specifically, System Verilog) implementation of the not-yet-finalized SHA-3 winner, Keccak. This is for a SystemVerilog class project. This design was validated with Questa and Veloce. I presented it as part of class on 6 June 2013 and the presentation is available [here](https://docs.google.com/presentation/d/1fEvkiKvQkEGiJ8LwQPkU6PK8SjZtGHqMSyf2X4v82iY/).

I updated this design in April 2021 to run with [Verilator](https://www.veripool.org/wiki/verilator). Prior then, it ran with QuestaSim. This code was designed for use with Veloce, but I no longer have access to the system and have not tested the code since June 2013. I keep the code here for anyone interested in the [tbx directory](tbx).

## Usage
Verify you have the latest version of [Verilator](https://www.veripool.org/wiki/verilator) and its dependencies. Running

```shell
make
```

will generate the following output files in `logs`:

 - coverage.dat - Coverage data
 - output.txt - Output file from keccak test routines. Meant for comparison to [reference file](test_vectors/keccak_ref_out.txt).
 - vlt_dump.vcd - Traces meant for viewing in an application like [GTKWave](http://gtkwave.sourceforge.net/).