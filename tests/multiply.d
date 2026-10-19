module tests.multiply;

import minish.sh.cpu;
import minish.sh.cpus;

unittest {
    // Exercise decoding and execution on every CPU that inherits these handlers.
    foreach (cpu; [cast(SHCPU)new SH2CPU(256, true),
                   new SH3CPU(256, true), new SH4CPU(256, true)]) {
        struct Case {
            ushort opcode;
            uint lhs, rhs, high, low;
        }
        foreach (c; [Case(0x321D, 6, 7, 0, 42),
                     Case(0x321D, 0xFFFFFFFE, 3, 0xFFFFFFFF, 0xFFFFFFFA),
                     Case(0x321D, 0x80000000, 0xFFFFFFFF, 0, 0x80000000),
                     Case(0x321D, 0x80000000, 0x80000000, 0x40000000, 0),
                     Case(0x3215, 6, 7, 0, 42),
                     Case(0x3215, 0xFFFFFFFF, 2, 1, 0xFFFFFFFE),
                     Case(0x3215, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFE, 1),
                     Case(0x3215, 0, 0xFFFFFFFF, 0, 0)]) {
            cpu.PC = 0;
            cpu.R[1] = cast(int)c.lhs;
            cpu.R[2] = cast(int)c.rhs;
            cpu.MACH = cpu.MACL = 0xDEADBEEF;
            cpu.SR = 1;
            cpu.write!ushort(0, c.opcode);
            assert(cpu.step());
            assert(cpu.MACH == c.high && cpu.MACL == c.low,
                   "DMUL must multiply register contents and put the high half in MACH");
            assert(cpu.R[1] == cast(int)c.lhs && cpu.R[2] == cast(int)c.rhs);
            assert(cpu.SR == 1 && cpu.PC == 2);
        }
    }
}
