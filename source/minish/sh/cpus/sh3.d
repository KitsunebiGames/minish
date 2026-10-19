module minish.sh.cpus.sh3;
import minish.sh.cpus.sh2;
import minish.sh.inst;
import minish.sh.cpu;
import minish.sh.mem;
import minish.core.registry;
import minish.cpu;

/**
    A SH3 CPU.
*/
class SH3CPU : SHCPU {
public:

    /**
        Constructs a new SH3 CPU.

        Params:
            memSize = The size of the main memory, in bytes.
    */
    this(uint memSize, bool isLittleEndian) {
        super(new SHMemory(memSize), isLittleEndian);
    }

    // Generate the instruction set.
    mixin GenInstrSelect!(SH3Inst);
}
mixin RegisterType!(CPUs, SH3CPU, "sh3", (uint size) => new SH3CPU(size, false));
mixin RegisterType!(CPUs, SH3CPU, "sh3l", (uint size) => new SH3CPU(size, true));


__gshared const immutable(SHInst)[] SH3Inst = SH2Inst~[




    //
    //                                          Shift Instructions
    //
    OpN4M4!("SHAD",      "shad Rm,Rn",               0b0100000000001100, (SHCPU cpu, int m, int n) {
        int sgn = cpu.R[m] & 0x80000000;

        if (sgn == 0) {
            cpu.R[n] <<= (cpu.R[m] & 0x1F);
        } else if ((cpu.R[m] & 0x1F) == 0) {
            if ((cpu.R[n] & 0x80000000) == 0)
                cpu.R[n] = 0;
            else
                cpu.R[n] = 0xFFFFFFFF;
        } else {
            cpu.R[n] = cpu.R[n] >> ((~cpu.R[m] & 0x1F) + 1);
        }

        cpu.PC += 2;
    }),
    OpN4M4!("SHLD",      "shad Rm,Rn",               0b0100000000001101, (SHCPU cpu, int m, int n) {
        int sgn = cpu.R[m] & 0x80000000;

        if (sgn == 0) {
            cpu.R[n] <<= (cpu.R[m] & 0x1F);
        } else if ((cpu.R[m] & 0x1F) == 0) {
            cpu.R[n] = 0;
        } else {
            cpu.R[n] = cast(uint)cpu.R[n] >>> ((~cpu.R[m] & 0x1F) + 1);
        }

        cpu.PC += 2;
    }),




    //
    //                                      System Control Instructions
    //
    Op!("CLRS" ,            "clrs",                 0b0000000001001000, (SHCPU cpu) {
        cpu.S = 0;
        cpu.PC += 2;
    }),
    Op!("SETS" ,            "sets",                 0b0000000001011000, (SHCPU cpu) {
        cpu.S = 1;
        cpu.PC += 2;
    }),
    OpM4!("LDCSSR",         "ldc Rm,ssr",           0b0100000000111110 , (SHCPU cpu, int m) {
        cpu.SSR = cpu.R[m];
        cpu.PC += 2;
    }),
    OpM4!("LDCMSSR",        "ldc.l @Rm+,ssr",       0b0100000000110111, (SHCPU cpu, int m) {
        cpu.SSR = cpu.read!uint(cpu.R[m]);
        cpu.R[m] += 4;
        cpu.PC += 2;
    }),
    OpM4!("LDCSPC",         "ldc Rm,spc",           0b0100000001001110, (SHCPU cpu, int m) {
        cpu.SPC = cpu.R[m];
        cpu.PC += 2;
    }),
    OpM4!("LDCMSPC",        "ldc.l @Rm+,spc",       0b0100000001000111, (SHCPU cpu, int m) {
        cpu.SPC = cpu.read!uint(cpu.R[m]);
        cpu.R[m] += 4;
        cpu.PC += 2;
    }),
    OpN4!("STCSSR",         "stc ssr,Rn",           0b0000000000110010, (SHCPU cpu, int n) {
        cpu.SSR = cpu.R[n];
        cpu.PC += 2;
    }),
    OpN4!("STCMSSR",        "stc.l ssr,@-Rn",       0b0100000000110011, (SHCPU cpu, int n) {
        cpu.R[n] -= 4;
        cpu.write!uint(cpu.R[n], cpu.SSR);
        cpu.PC += 2;
    }),
    OpN4!("STCSPC",         "stc spc,Rn",           0b0000000001000010, (SHCPU cpu, int n) {
        cpu.SPC = cpu.R[n];
        cpu.PC += 2;
    }),
    OpN4!("STCMSPC",        "stc.l spc,@-Rn",       0b0100000001000011, (SHCPU cpu, int n) {
        cpu.R[n] -= 4;
        cpu.write!uint(cpu.R[n], cpu.SPC);
        cpu.PC += 2;
    }),

    // TODO: Add Banked Registers
    OpM4N3!("LDCRn_BANK",   "ldc Rm,Rn_BANK",       0b0100000010001110, (SHCPU cpu, int m, int n) {
        // cpu.SPC = cpu.R[m];
        cpu.PC += 2;
    }),
    OpM4N3!("LDCRn_BANK",   "ldc.l @Rm+,Rn_BANK",   0b0100000010000111, (SHCPU cpu, int m, int n) {
        // cpu.SPC = cpu.R[m];
        cpu.R[m] += 4;
        cpu.PC += 2;
    }),
    OpN4M3!("STCRn_BANK",   "ldc Rm_BANK,Rn",       0b0000000010000010, (SHCPU cpu, int m, int n) {
        // cpu.SPC = cpu.R[m];
        cpu.PC += 2;
    }),
    OpN4M3!("STCRn_BANK",   "stc.l Rm_BANK,@-Rn",   0b0100000010000011, (SHCPU cpu, int m, int n) {
        cpu.R[n] -= 4;
        // cpu.SPC = cpu.R[m];
        cpu.PC += 2;
    }),

    // TODO: Add extended MMU
    Op!("LDTLB",            "ldtlb",                0b0000000000111000, (SHCPU cpu) {
        cpu.PC += 2;
    }),
    OpN4!("PREF",           "pref @Rn",             0b0000000010000011, (SHCPU cpu, int n) {
        cpu.PC += 2;
    }),
];