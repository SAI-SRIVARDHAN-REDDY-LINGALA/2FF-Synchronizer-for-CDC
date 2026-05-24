# Double Flip-Flop Synchronizer (2FF Synchronizer) for Clock Domain Crossing (CDC)

A simple Verilog implementation of a **Double Flip-Flop Synchronizer** used to safely transfer a **single-bit asynchronous signal** from one clock domain to another while reducing the probability of metastability.

This project demonstrates:

- Clock Domain Crossing (CDC)
- Metastability concepts
- Slow → Fast clock crossing
- Equal clock crossing
- Fast → Slow limitations
- RTL simulation behavior
- Industry-standard synchronizer structure

---

# What is Clock Domain Crossing (CDC)?

CDC occurs whenever a signal generated in one clock domain is sampled by logic running in another clock domain.

Example:

```text
Source Domain                  Destination Domain

clk_src --------------------> clk_dst

async_signal ---------------> synchronization logic
```

Since both clocks are independent, there is no guarantee that the signal changes will align with destination clock edges.

This can cause:

- Metastability
- Missed pulses
- Data corruption
- Glitches
- Unpredictable behavior

---

# What is Metastability?

A flip-flop expects data to be stable around the clock edge.

If data changes too close to the sampling clock edge:

```text
Setup/Hold Violation
         ↓
Metastability
```

The flip-flop temporarily enters an unstable state where the output is neither a valid `0` nor a valid `1`.

Eventually the output settles, but the settling time is unpredictable.

---

# Why Use a Double Flip-Flop Synchronizer?

A double flip-flop synchronizer provides an extra destination clock cycle for metastability to settle.

Conceptually:

```text
Asynchronous Signal
         ↓
      FF1
         ↓
      FF2
         ↓
Synchronized Output
```

Operation:

1. FF1 samples the asynchronous input.
2. FF1 may become metastable.
3. FF2 samples FF1 one destination clock later.
4. By this time FF1 has usually settled.
5. Output becomes significantly more reliable.

The synchronizer does **not eliminate metastability**.

It only reduces its probability to an extremely low value.

---

# Understanding the Signal Flow

When the asynchronous input changes:

```text
async_in = 1
```

At the first destination clock edge:

```text
FF1 captures async_in
FF2 still contains previous value
```

At the next destination clock edge:

```text
FF2 captures FF1
```

Therefore the synchronized output appears approximately **two destination clock cycles later**.

This latency is expected and is the cost of safe synchronization.

---

# What is ASYNC_REG?

FPGA implementations often mark synchronizer registers using:

```text
ASYNC_REG = TRUE
```

This tells FPGA implementation tools that:

- These registers are CDC synchronizer registers
- They should not be optimized away
- They should not be retimed
- They should be placed physically close together
- CDC analysis tools should recognize them as synchronizers

Benefits:

- Improved reliability
- Better MTBF
- Better CDC implementation quality

RTL simulators ignore this attribute.

It mainly affects synthesis and implementation tools such as Vivado and Quartus.

---

# Simulation Scenarios Tested

## Case 1: Source Clock = Destination Clock

```text
clk_src = 100 MHz
clk_dst = 100 MHz
```

Result:

- Signal transfers correctly
- Output delayed by synchronizer stages
- No pulse loss

This is the easiest case.

---

## Case 2: Source Clock < Destination Clock (Slow → Fast)

Example:

```text
clk_src = 100 MHz
clk_dst = 200 MHz
```

Result:

- Recommended use case
- Every transition is captured
- Synchronizer works reliably

This is the ideal condition for a 2FF synchronizer.

---

## Case 3: Source Clock > Destination Clock (Fast → Slow)

Example:

```text
clk_src = 100 MHz
clk_dst = 38 MHz
```

Result:

- Short pulses may be missed
- Destination may never sample the pulse
- Synchronizer alone is insufficient

This is the major limitation of a simple 2FF synchronizer.

---

# Why Fast → Slow Crossing Can Fail

Suppose:

```text
Source Pulse Width = 10 ns
Destination Clock Period = 25 ns
```

Pulse:

```text
____|‾‾|____
```

If no destination clock edge occurs during that pulse:

```text
pulse completely missed
```

The synchronizer cannot recover a pulse that was never sampled.

Therefore:

```text
2FF Synchronizer ≠ Pulse Capture Circuit
```

---

# Why 2FF Synchronizer Is Not Suitable for Multi-Bit Data

The 2FF synchronizer is intended for **single-bit signals only**.

Example:

```text
8-bit Bus

00000000
   ↓
11111111
```

In real hardware:

- Different bits have different routing delays
- Different bits may settle at different times
- Different bits may experience metastability differently

Destination may capture:

```text
10110110
```

even though that value never existed in the source domain.

This leads to:

- Bus corruption
- Invalid values
- Unpredictable behavior

Therefore:

| Signal Type | Use 2FF Synchronizer |
|------------|----------------------|
| Single-bit control | ✅ |
| Enable signal | ✅ |
| Interrupt signal | ✅ |
| Reset signal | ✅ |
| Multi-bit data bus | ❌ |
| Address bus | ❌ |
| Data stream | ❌ |

---

# Can RTL Simulation Show Metastability?

No.

Traditional RTL simulators assume ideal flip-flops.

They do not model:

- Analog behavior
- Internal transistor effects
- Real setup time violations
- Real hold time violations

Therefore actual metastability cannot be observed in:

- Icarus Verilog
- ModelSim
- QuestaSim
- Vivado XSIM

What you can observe:

- Functional delay
- Synchronizer latency
- Signal propagation

What you cannot observe:

```text
0 → unstable analog state → 1
```

---

# Then How Is CDC Verified in Industry?

CDC is typically verified using:

## Static CDC Analysis

Tools check:

- Missing synchronizers
- Unsafe crossings
- Reconvergence issues
- Reset crossings
- Multi-bit CDC violations

Popular tools:

- Synopsys VC CDC
- Siemens Questa CDC
- Cadence Jasper CDC

---

## Gate-Level Simulation

Performed after synthesis and implementation.

Includes:

- Actual routing delays
- Timing information
- Setup/hold timing checks

Can reveal:

- Setup violations
- Hold violations
- Timing failures

---

## MTBF Analysis

Engineers estimate:

```text
Mean Time Between Failures (MTBF)
```

This predicts how often metastability-related failures may occur.

Good synchronizers target extremely large MTBF values.

Example:

```text
1 failure in hundreds of years
```

---

# Can Metastability Be Observed on an FPGA?

Partially.

Metastability itself is analog and extremely short-lived.

Typically engineers observe its effects:

- Random glitches
- Missing pulses
- Unexpected counter values
- Rare failures
- Illegal FSM states

Useful FPGA experiments:

- Push-button synchronizer
- Toggle synchronizer
- Pulse synchronizer
- Asynchronous clock crossing
- Async FIFO

These demonstrate CDC behavior much more clearly than RTL simulation.

---

# Limitations of the Double Flip-Flop Synchronizer

The 2FF synchronizer is excellent for:

- Single-bit control signals
- Slow → Fast crossings
- Simple CDC problems

However it is not suitable for:

- Multi-bit buses
- High-speed data streams
- Guaranteed pulse capture in Fast → Slow crossings

For those cases more advanced CDC techniques are required.

---

# Other CDC Techniques

## Pulse Synchronizer

Used when transferring short pulses between clock domains.

---

## Toggle Synchronizer

Used for reliable event transfer.

Converts events into toggles which are easier to detect across domains.

---

## Handshake Synchronizer

Uses:

```text
Request
Acknowledgement
```

to ensure data is safely transferred.

Provides guaranteed delivery.

---

## Asynchronous FIFO

Industry-standard solution for continuous multi-bit data transfer.

Uses:

- Separate read/write clocks
- Gray-code pointers
- Full/Empty detection
- Pointer synchronizers

Best solution for high-throughput CDC.

---

# Key Takeaways

- CDC occurs when signals cross clock domains.
- Metastability results from setup/hold violations.
- A 2FF synchronizer reduces metastability probability.
- It is intended for single-bit signals only.
- Slow → Fast crossings work well.
- Fast → Slow crossings may miss pulses.
- Multi-bit buses require different CDC techniques.
- RTL simulation cannot show actual metastability.
- Industry relies on CDC analysis, timing verification, and MTBF calculations.
- Async FIFOs are the preferred solution for multi-bit continuous data transfer.

---

# Future Improvements

Recommended progression:

1. Double Flip-Flop Synchronizer
2. Pulse Synchronizer
3. Toggle Synchronizer
4. Handshake Synchronizer
5. Asynchronous FIFO
6. Gray-Code Pointer Synchronization
7. CDC Verification Flows

This sequence covers the most common CDC concepts encountered in FPGA, RTL Design, Digital Design, and VLSI Front-End Engineering.
