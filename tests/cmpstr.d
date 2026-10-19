module tests.cmpstr;

import minish.sh.cpu;
import minish.sh.cpus;

unittest {
    foreach (cpu; [cast(SHCPU)new SH2CPU(256, true),
                   new SH3CPU(256, true), new SH4CPU(256, true)]) {
        struct Case {
            uint lhs, rhs;
            ubyte expected;
        }
        foreach (c; [Case(0, 0x01020408, 0),
                     Case(0, 0xFFFFFFFF, 0),
                     Case(0x12345678, 0x12345678, 1),
                     Case(0x12345678, 0x12ABCDEF, 1),
                     Case(0x12345678, 0xAB34CDEF, 1),
                     Case(0x12345678, 0xABCD56EF, 1),
                     Case(0x12345678, 0xABCDEF78, 1),
                     Case(0x12345678, 0x78123456, 0)]) {
            foreach (initialT; [0, 1]) {
                cpu.PC = 0;
                cpu.R[1] = cast(int)c.lhs;
                cpu.R[2] = cast(int)c.rhs;
                cpu.SR = 0x300 | initialT;
                cpu.write!ushort(0, 0x221C); // cmp/str r1,r2
                assert(cpu.step());
                assert(cpu.T == c.expected,
                       "CMP/STR must test equality of corresponding whole bytes");
                assert(cpu.R[1] == cast(int)c.lhs && cpu.R[2] == cast(int)c.rhs);
                assert(cpu.SR == (0x300 | c.expected) && cpu.PC == 2);
            }
        }
    }
}
