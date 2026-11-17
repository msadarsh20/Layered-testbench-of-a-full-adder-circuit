# Layered Testbench of a Full Adder Circuit

## Project Overview
This project implements a 1-bit Full Adder using SystemVerilog and verifies its functionality using a layered testbench architecture.

The testbench follows a modular verification approach consisting of Generator, Driver, Monitor, Scoreboard, and Environment components.

## Design Details
The Full Adder takes three inputs:
- A
- B
- Carry-in (Cin)

It produces two outputs:
- Sum
- Carry-out (Cout)

### Boolean Expressions
- Sum = A XOR B XOR Cin
- Cout = (A AND B) OR (B AND Cin) OR (A AND Cin)

## Testbench Architecture

1. **Transaction:** Stores input and output data.
2. **Generator:** Generates 8 exhaustive test cases and 20 random transactions.
3. **Driver:** Applies generated inputs to the DUT.
4. **Monitor:** Observes DUT inputs and outputs.
5. **Scoreboard:** Compares actual outputs with expected results.
6. **Environment:** Connects and manages all verification components.

## Project Files

| File | Description |
|---|---|
| design.sv | Full Adder RTL design |
| testbench.sv | Layered SystemVerilog testbench |

## Verification
- Exhaustive testing of all 8 input combinations.
- 20 additional random test transactions.
- Automatic output checking using a scoreboard.
- Final PASS/FAIL report with error count.

## Simulation Platform
EDA Playground

Project Link: https://edaplayground.com/x/tptE

## Expected Result
The testbench displays the number of checked transactions, error count, and final test status.

## Technologies Used
- SystemVerilog
- RTL Design
- Functional Verification
- Layered Testbench Architecture
- EDA Playground

## Author
Adarsh M S
