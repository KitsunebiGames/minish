module minish.sh.cpus.sh4;
import minish.sh.cpus.sh3;
import minish.sh.inst;
import minish.sh.cpu;
import minish.sh.mem;
import minish.core.registry;
import minish.cpu;
import std.math;

/**
    A SH4 CPU.
*/
class SH4CPU : SHCPU {
public:

    /// General Purpose Register
    union {
        float[32]  FSR;
        double[16] FDR;
    }

    /**
        Constructs a new SH4 CPU.

        Params:
            memSize = The size of the main memory, in bytes.
    */
    this(uint memSize, bool isLittleEndian) {
        super(new SHMemory(memSize), isLittleEndian);
    }

    // Gets banked FR register
    override ref float FS(int i) => FSR[i];

    // Gets banked XF register
    override ref float XS(int i) => FSR[i];

    // Gets banked DR register
    override ref double FD(int i) => FDR[i];

    // Gets banked XD register
    override ref double XD(int i) => FDR[i];

    /**
        Gets a reference to the data of a floating point
        register.

        Params:
            i = The index of the register.

        Returns:
            A reference to the FPR register's data.
    */
    override ref float FPR(ubyte i) {
        return FSR[i];
    }

    // Generate the instruction set.
    mixin GenInstrSelect!(SH4Inst);
}
mixin RegisterType!(CPUs, SH4CPU, "sh4", (uint size) => new SH4CPU(size, false));
mixin RegisterType!(CPUs, SH4CPU, "sh4l", (uint size) => new SH4CPU(size, true));


__gshared const immutable(SHInst)[] SH4Inst = SH3Inst~[
    



    //
    //              32 Bit Floating-Point Data Transfer Instructions (FPSCR.SZ = 0)
    //
    OpN4M4!("FMOV",      "fmov FRm,FRn",                0b1111000000001100, (SHCPU cpu, int m, int n) {
        cpu.FS(n) = cpu.FS(m);
        cpu.PC += 2;
    }),
    OpN4M4!("FMOVSL",    "fmov.s @Rm,FRn",              0b1111000000001000, (SHCPU cpu, int m, int n) {
        cpu.FS(n) = cpu.read!float(cpu.R[m]);
        cpu.PC += 2;
    }),
    OpN4M4!("FMOVSS",    "fmov.s FRm,@Rn",              0b1111000000001010, (SHCPU cpu, int m, int n) {
        cpu.write!float(cpu.R[n], cpu.FS(m));
        cpu.PC += 2;
    }),
    OpN4M4!("FMOVSDL",   "fmov.s @Rm+,FRn",             0b1111000000001001, (SHCPU cpu, int m, int n) {
        cpu.FS(n) = cpu.read!float(cpu.R[m]);
        cpu.R[m] += 4;
        cpu.PC += 2;
    }),
    OpN4M4!("FMOVSDS",   "fmov.s FRm,@-Rn",             0b1111000000001011, (SHCPU cpu, int m, int n) {
        cpu.R[n] -= 4;
        cpu.write!float(cpu.R[n], cpu.FS(m));
        cpu.PC += 2;
    }),
    OpN4M4!("FMOVSL0",   "fmov.s @(R0,Rm),FRn",         0b1111000000000110, (SHCPU cpu, int m, int n) {
        cpu.FS(n) = cpu.read!float(cpu.R[0] + cpu.R[m]);
        cpu.PC += 2;
    }),
    OpN4M4!("FMOVSS0",   "fmov.s FRm,@(R0,Rn)",         0b1111000000000111, (SHCPU cpu, int m, int n) {
        cpu.write!float(cpu.R[0] + cpu.R[n], cpu.FS(m));
        cpu.PC += 2;
    }),

    // TODO: Handle 64-bit



    //
    //              Floating-Point Single-Precision Instructions (FPSCR.PR = 0)
    //
    OpN4!("FLDI0",      "fldi0 FRn",                    0b1111000010001101, (SHCPU cpu, int n) {
        cpu.FS(n) = 0;
        cpu.PC += 2;
    }),
    OpN4!("FLDI1",      "fldi1 FRn",                    0b1111000010011101, (SHCPU cpu, int n) {
        cpu.FS(n) = 1;
        cpu.PC += 2;
    }),
    OpM4!("FLDS",       "flds FRm,fpul",                0b1111000000011101, (SHCPU cpu, int m) {
        cpu.FPUL = *cast(int*)&cpu.FS(m);
        cpu.PC += 2;
    }),
    OpN4!("FSTS",       "fsts fpul,FRn",                0b1111000000001101, (SHCPU cpu, int n) {
        cpu.FS(n) = *cast(float*)&cpu.FPUL;
        cpu.PC += 2;
    }),
    OpN4!("FABS",       "fabs FRn",                     0b1111000001011101, (SHCPU cpu, int n) {
        cpu.FS(n) = abs(cpu.FS(n));
        cpu.PC += 2;
    }),
    OpN4!("FNEG",       "fneg FRn",                     0b1111000001001101, (SHCPU cpu, int n) {
        cpu.FS(n) = -cpu.FS(n);
        cpu.PC += 2;
    }),
    OpN4M4!("FADD",     "fadd FRm,FRn",                 0b1111000000000000, (SHCPU cpu, int m, int n) {
        cpu.FS(n) = cpu.FS(n) + cpu.FS(m);
        cpu.PC += 2;
    }),
    OpN4M4!("FSUB",     "fsub FRm,FRn",                 0b1111000000000001, (SHCPU cpu, int m, int n) {
        cpu.FS(n) = cpu.FS(n) - cpu.FS(m);
        cpu.PC += 2;
    }),
    OpN4M4!("FMUL",     "fmul FRm,FRn",                 0b1111000000000010, (SHCPU cpu, int m, int n) {
        cpu.FS(n) = cpu.FS(n) * cpu.FS(m);
        cpu.PC += 2;
    }),
    OpN4M4!("FMAC",     "fmac fr0,FRm,FRn",             0b1111000000001110, (SHCPU cpu, int m, int n) {
        cpu.FS(n) = cpu.FS(0) * cpu.FS(m) + cpu.FS(n);
        cpu.PC += 2;
    }),
    OpN4M4!("FDIV",     "fdiv FRm,FRn",                 0b1111000000000011, (SHCPU cpu, int m, int n) {
        cpu.FS(n) = cpu.FS(n) / cpu.FS(m);
        cpu.PC += 2;
    }),
    OpN4!("FSQRT",      "fsqrt FRn",                    0b1111000001101101, (SHCPU cpu, int n) {
        cpu.FS(n) = sqrt(cpu.FS(n));
        cpu.PC += 2;
    }),
    OpN4M4!("FCMPEQ",     "fcmp/eq FRm,FRn",            0b1111000000000100, (SHCPU cpu, int m, int n) {
        cpu.T = cpu.FS(n) == cpu.FS(m);
        cpu.PC += 2;
    }),
    OpN4M4!("FCMPGT",     "fcmp/gt FRm,FRn",            0b1111000000000101, (SHCPU cpu, int m, int n) {
        cpu.T = cpu.FS(n) > cpu.FS(m);
        cpu.PC += 2;
    }),
    OpN4!("FLOAT",        "float FPUL,FRn",             0b1111000000101101, (SHCPU cpu, int n) {
        cpu.FS(n) = cast(float)cpu.FPUL;
        cpu.PC += 2;
    }),
    OpM4!("FRTC",        "ftrc FPUL,FRn",               0b1111000000111101, (SHCPU cpu, int m) {
        cpu.FPUL = cast(int)cpu.FS(m);
        cpu.PC += 2;
    }),

    // TODO: FIPR & FTRV



    //
    //                                  Floating-Point Control Instructions
    //
    Op!("FRCHG" ,           "frchg",                    0b1111101111111101, (SHCPU cpu) {
        if (cpu.FP_PR)
            cpu.FP_FR = cast(ubyte)~cpu.FP_FR;
        cpu.PC += 2;
    }),
    Op!("FSCHG" ,           "fschg",                    0b1111001111111101, (SHCPU cpu) {
        if (cpu.FP_PR)
            cpu.FP_SZ = cast(ubyte)~cpu.FP_SZ;
        cpu.PC += 2;
    }),
    OpM4!("LDSFPSCR",       "lds Rm,fpscr",             0b0100000001101010, (SHCPU cpu, int m) {
        cpu.FPSCR = cpu.R[m] & 0x003FFFFF;
        cpu.PC += 2;
    }),
    OpM4!("LDSMFPSCR",      "lds.l @Rm+,fpscr",         0b0100000001100110, (SHCPU cpu, int m) {
        cpu.FPSCR = cpu.read!uint(cpu.R[m]) & 0x003FFFFF;
        cpu.R[m] += 4;
        cpu.PC += 2;
    }),
    OpM4!("LDSFPUL",        "lds Rm,fpul",              0b0100000001011010, (SHCPU cpu, int m) {
        cpu.FPUL = cpu.R[m];
        cpu.PC += 2;
    }),
    OpM4!("LDSMFPUL",       "lds.l @Rm+,fpul",          0b0100000001010110, (SHCPU cpu, int m) {
        cpu.FPUL = cpu.read!uint(cpu.R[m]);
        cpu.R[m] += 4;
        cpu.PC += 2;
    }),
    OpN4!("STSFPSCR",       "sts fpscr,Rn",             0b0000000001101010, (SHCPU cpu, int n) {
        cpu.R[n] = cpu.FPSCR;
        cpu.PC += 2;
    }),
    OpN4!("STSMFPSCR",      "sts.l fpscr,@-Rn",         0b0100000001100010, (SHCPU cpu, int n) {
        cpu.R[n] -= 4;
        cpu.write!uint(cpu.R[n], cpu.FPSCR);
        cpu.PC += 2;
    }),
    OpN4!("STSFPUL",        "sts fpul,Rn",              0b0000000001011010, (SHCPU cpu, int n) {
        cpu.R[n] = cpu.FPUL;
        cpu.PC += 2;
    }),
    OpN4!("STSMFPUL",       "sts.l fpul,@-Rn",          0b0100000001010010, (SHCPU cpu, int n) {
        cpu.R[n] -= 4;
        cpu.write!uint(cpu.R[n], cpu.FPUL);
        cpu.PC += 2;
    }),

];