module minish.sh.cpus.sh2;
import minish.sh.inst;
import minish.sh.cpu;
import minish.sh.mem;
import minish.core.registry;
import minish.cpu;

/**
    A SH2 CPU.
*/
class SH2CPU : SHCPU {
public:

    /**
        Constructs a new SH2 CPU.

        Params:
            memSize = The size of the main memory, in bytes.
    */
    this(uint memSize, bool isLittleEndian) {
        super(new SHMemory(memSize), isLittleEndian);
    }

    // Generate the instruction set.
    mixin GenInstrSelect!(SH2Inst);
}
mixin RegisterType!(CPUs, SH2CPU, "sh2", (uint size) => new SH2CPU(size, false));
mixin RegisterType!(CPUs, SH2CPU, "sh2l", (uint size) => new SH2CPU(size, true));

__gshared const immutable(SHInst)[] SH2Inst = [




    //
    //                                     Data Transfer Instructions
    //

    OpN4M4!("MOV",       "mov Rm,Rn",                0b0110000000000011, (SHCPU cpu, int m, int n) {
        cpu.R[n] = cpu.R[m];
        cpu.PC += 2;
    }),
    OpN4I8!("MOVI",      "mov #imm,Rn",              0b1110000000000000, (SHCPU cpu, int i, int n) {
        if ((i & 0x80) == 0)
            cpu.R[n] = (0x000000FF & i);
        else
            cpu.R[n] = (0xFFFFFF00 | i);
;
        cpu.PC += 2;
    }),
    OpD8!("MOVA",        "mova @(disp,pc),r0",       0b1100011100000000, (SHCPU cpu, int d) {
        uint disp = cast(uint)(0x000000FF & d);
        cpu.R[0] = (cpu.PC & 0xFFFFFFFC) + 4 + (disp << 2);
        cpu.PC += 2;
    }),
    OpN4D8!("MOVWI",     "mov.w @(disp,pc),Rn",      0b1001000000000000, (SHCPU cpu, int d, int n) {
        uint disp = cast(uint)(0x000000FF & d);
        cpu.R[n] = cpu.read!ushort(cpu.PC + 4 + (disp << 1));
        if ((cpu.R[n] & 0x8000) == 0)
            cpu.R[n] &= 0x0000FFFF;
        else
            cpu.R[n] |= 0xFFFF0000;

        cpu.PC += 2;
    }),
    OpN4D8!("MOVLI",     "mov.l @(disp,pc),Rn",      0b1101000000000000, (SHCPU cpu, int d, int n) {
        uint disp = cast(uint)(0x000000FF & d);

        cpu.R[n] = cpu.read!int((cpu.PC & 0xFFFFFFFC) + 4 + (disp << 2));
        cpu.PC += 2;
    }),
    OpN4M4!("MOVBL",     "mov.b @Rm,Rn",             0b0110000000000000, (SHCPU cpu, int m, int n) {
        cpu.R[n] = cpu.read!ubyte(cpu.R[m]);
        if ((cpu.R[n] & 0x80) == 0)
            cpu.R[n] &= 0x000000FF;
        else
            cpu.R[n] |= 0xFFFFFF00;

        cpu.PC += 2;
    }),
    OpN4M4!("MOVWL",     "mov.w @Rm,Rn",             0b0110000000000001, (SHCPU cpu, int m, int n) {
        cpu.R[n] = cpu.read!ushort(cpu.R[m]);
        if ((cpu.R[n] & 0x80) == 0)
            cpu.R[n] &= 0x0000FFFF;
        else
            cpu.R[n] |= 0xFFFF0000;
        
        cpu.PC += 2;
    }),
    OpN4M4!("MOVLL",     "mov.l @Rm,Rn",             0b0110000000000010, (SHCPU cpu, int m, int n) {
        cpu.R[n] = cpu.read!int(cpu.R[m]);
        cpu.PC += 2;
    }),
    OpN4M4!("MOVBS",     "mov.b Rm,@Rn",             0b0010000000000000, (SHCPU cpu, int m, int n) {
        cpu.write!ubyte(cpu.R[n], cpu.R[m]);
        cpu.PC += 2;
    }),
    OpN4M4!("MOVWS",     "mov.w Rm,@Rn",             0b0010000000000001, (SHCPU cpu, int m, int n) {
        cpu.write!ushort(cpu.R[n], cpu.R[m]);
        cpu.PC += 2;
    }),
    OpN4M4!("MOVLS",     "mov.l Rm,@Rn",             0b0010000000000010, (SHCPU cpu, int m, int n) {
        cpu.write!int(cpu.R[n], cpu.R[m]);
        cpu.PC += 2;
    }),
    OpN4M4!("MOVBP",     "mov.b @Rm+,Rn",            0b0110000000000100, (SHCPU cpu, int m, int n) {
        cpu.R[n] = cpu.read!ubyte(cpu.R[m]);
        if ((cpu.R[n] & 0x80) == 0)
            cpu.R[n] &= 0x000000FF;
        else
            cpu.R[n] |= 0xFFFFFF00;

        if (n != m)
            cpu.R[m] += 1;

        cpu.PC += 2;
    }),
    OpN4M4!("MOVWP",     "mov.w @Rm+,Rn",            0b0110000000000101, (SHCPU cpu, int m, int n) {
        cpu.R[n] = cpu.read!ushort(cpu.R[m]);
        if ((cpu.R[n] & 0x80) == 0)
            cpu.R[n] &= 0x0000FFFF;
        else
            cpu.R[n] |= 0xFFFF0000;

        if (n != m)
            cpu.R[m] += 1;
        
        cpu.PC += 2;
    }),
    OpN4M4!("MOVLP",     "mov.l @Rm+,Rn",            0b0110000000000110, (SHCPU cpu, int m, int n) {
        cpu.R[n] = cpu.read!int(cpu.R[m]);
        if (n != m)
            cpu.R[m] += 4;

        cpu.PC += 2;
    }),
    OpN4M4!("MOVBM",     "mov.b Rm,@-Rn",            0b0010000000000100, (SHCPU cpu, int m, int n) {
        cpu.write!ubyte(cpu.R[n] - 1, cpu.R[m]);
        cpu.R[n] -= 1;
        cpu.PC += 2;
    }),
    OpN4M4!("MOVWM",     "mov.w Rm,@-Rn",            0b0010000000000101, (SHCPU cpu, int m, int n) {
        cpu.write!ushort(cpu.R[n] - 2, cpu.R[m]);
        cpu.R[n] -= 2;
        cpu.PC += 2;
    }),
    OpN4M4!("MOVLM",     "mov.l Rm,@-Rn",            0b0010000000000110, (SHCPU cpu, int m, int n) {
        cpu.write!int(cpu.R[n] - 4, cpu.R[m]);
        cpu.R[n] -= 4;
        cpu.PC += 2;
    }),
    OpM4D4!("MOVBL4",    "mov.b @(disp,Rm),r0",      0b1000010000000000, (SHCPU cpu, int m, int d) {
        int disp = cast(int)(0x0000000F & d);
        cpu.R[0] = cpu.read!ubyte(cpu.R[m] + disp);
        if ((cpu.R[0] & 0x80) == 0)
            cpu.R[0] &= 0x000000FF;
        else
            cpu.R[0] |= 0xFFFFFF00;

        cpu.PC += 2;
    }),
    OpM4D4!("MOVWL4",    "mov.w @(disp,Rm),r0",      0b1000010100000000, (SHCPU cpu, int m, int d) {
        int disp = cast(int)(0x0000000F & d);
        cpu.R[0] = cpu.read!ushort(cpu.R[m] + (disp << 1));
        if ((cpu.R[0] & 0x80) == 0)
            cpu.R[0] &= 0x0000FFFF;
        else
            cpu.R[0] |= 0xFFFF0000;

        cpu.PC += 2;
    }),
    OpN4M4D4!("MOVLL4",  "mov.l @(disp,Rm),Rn",      0b0101000000000000, (SHCPU cpu, int m, int d, int n) {
        int disp = cast(int)(0x0000000F & d);
        cpu.R[n] = cpu.read!int(cpu.R[m] + (disp << 2));
        cpu.PC += 2;
    }),
    OpN4D4!("MOVBS4",    "mov.b r0,@(disp,Rn)",      0b1000000000000000, (SHCPU cpu, int d, int n) {
        int disp = cast(int)(0x0000000F & d);
        cpu.write!ubyte(cpu.R[n] + disp, cpu.R[0]);
        cpu.PC += 2;
    }),
    OpN4D4!("MOVWS4",    "mov.w r0,@(disp,Rn)",      0b1000000100000000, (SHCPU cpu, int d, int n) {
        int disp = cast(int)(0x0000000F & d);
        cpu.write!ushort(cpu.R[n] + (disp << 1), cpu.R[0]);
        cpu.PC += 2;
    }),
    OpN4M4D4!("MOVLS4",  "mov.l Rm,@(disp,Rn)",      0b0001000000000000, (SHCPU cpu, int m, int d, int n) {
        int disp = cast(int)(0x0000000F & d);
        cpu.write!int(cpu.R[n] + (disp << 2), cpu.R[m]);
        cpu.PC += 2;
    }),
    OpN4M4!("MOVBL0",    "mov.b @(r0,Rm),Rn",        0b0000000000001100, (SHCPU cpu, int m, int n) {
        cpu.R[n] = cpu.read!ubyte(cpu.R[m] + cpu.R[0]);
        if ((cpu.R[n] & 0x80) == 0)
            cpu.R[n] &= 0x000000FF;
        else
            cpu.R[n] |= 0xFFFFFF00;

        cpu.PC += 2;
    }),
    OpN4M4!("MOVWL0",    "mov.w @(r0,Rm),Rn",        0b0000000000001101, (SHCPU cpu, int m, int n) {
        cpu.R[n] = cpu.read!ushort(cpu.R[m] + cpu.R[0]);
        if ((cpu.R[n] & 0x80) == 0)
            cpu.R[n] &= 0x0000FFFF;
        else
            cpu.R[n] |= 0xFFFF0000;

        cpu.PC += 2;
    }),
    OpN4M4!("MOVLL0",    "mov.l @(r0,Rm),Rn",        0b0000000000001110, (SHCPU cpu, int m, int n) {
        cpu.R[n] = cpu.read!int(cpu.R[m] + cpu.R[0]);
        cpu.PC += 2;
    }),
    OpN4D4!("MOVBS0",    "mov.b Rm,@(r0,Rn)",        0b0000000000000100, (SHCPU cpu, int m, int n) {
        cpu.write!ubyte(cpu.R[n] + cpu.R[0], cpu.R[m]);
        cpu.PC += 2;
    }),
    OpN4D4!("MOVWS0",    "mov.w Rm,@(r0,Rn)",        0b0000000000000101, (SHCPU cpu, int m, int n) {
        cpu.write!ushort(cpu.R[n] + cpu.R[0], cpu.R[m]);
        cpu.PC += 2;
    }),
    OpN4M4!("MOVLS0",    "mov.l Rm,@(r0,Rn)",        0b0000000000000110, (SHCPU cpu, int m, int n) {
        cpu.write!int(cpu.R[n] + cpu.R[0], cpu.R[m]);
        cpu.PC += 2;
    }),
    OpD8!("MOVBLG",      "mov.b @(disp,gbr),r0",     0b1100010000000000, (SHCPU cpu, int d) {
        int disp = cast(int)(0x000000FF & d);
        cpu.R[0] = cpu.read!ubyte(cpu.GBR + disp);
        if ((cpu.R[0] & 0x80) == 0)
            cpu.R[0] &= 0x000000FF;
        else
            cpu.R[0] |= 0xFFFFFF00;

        cpu.PC += 2;
    }),
    OpD8!("MOVWLG",      "mov.w @(disp,gbr),r0",     0b1100010100000000, (SHCPU cpu, int d) {
        int disp = cast(int)(0x000000FF & d);
        cpu.R[0] = cpu.read!ushort(cpu.GBR + (disp << 1));
        if ((cpu.R[0] & 0x80) == 0)
            cpu.R[0] &= 0x0000FFFF;
        else
            cpu.R[0] |= 0xFFFF0000;

        cpu.PC += 2;
    }),
    OpD8!("MOVLLG",      "mov.l @(disp,gbr),r0",     0b1100011000000000, (SHCPU cpu, int d) {
        int disp = cast(int)(0x000000FF & d);
        cpu.R[0] = cpu.read!int(cpu.GBR + (disp << 2));
        cpu.PC += 2;
    }),
    OpD8!("MOVBSG",      "mov.b r0,@(disp,gbr)",     0b1100000000000000, (SHCPU cpu, int d) {
        int disp = cast(int)(0x000000FF & d);
        cpu.write!ubyte(cpu.GBR + disp, cpu.R[0]);
        cpu.PC += 2;
    }),
    OpD8!("MOVWSG",      "mov.w r0,@(disp,gbr)",     0b1100000100000000, (SHCPU cpu, int d) {
        int disp = cast(int)(0x000000FF & d);
        cpu.write!ushort(cpu.GBR + disp, cpu.R[0]);
        cpu.PC += 2;
    }),
    OpD8!("MOVLSG",      "mov.l r0,@(disp,gbr)",     0b1100001000000000, (SHCPU cpu, int d) {
        int disp = cast(int)(0x000000FF & d);
        cpu.write!int(cpu.GBR + disp, cpu.R[0]);
        cpu.PC += 2;
    }),
    OpN4!("MOVT",        "movt Rn",                  0b0000000000101001, (SHCPU cpu, int n) {
        cpu.R[n] = cpu.T;
        cpu.PC += 2;
    }),
    OpN4M4!("SWAPB",     "swap.b Rm,Rn",             0b0110000000001000, (SHCPU cpu, int m, int n) {
        uint temp0 = cpu.R[m] & 0xFFFF0000;
        uint temp1 = (cpu.R[m] & 0x000000FF) << 8;
        cpu.R[n] = (cpu.R[m] & 0x0000FF00) >> 8;
        cpu.R[n] = cpu.R[n] | temp1 | temp0;
        cpu.PC += 2;
    }),
    OpN4M4!("SWAPW",     "swap.w Rm,Rn",             0b0110000000001001, (SHCPU cpu, int m, int n) {
        uint temp = (cpu.R[m] >> 16) & 0x0000FFFF;
        cpu.R[n] = cpu.R[m] << 16;
        cpu.R[n] |= temp;
        cpu.PC += 2;
    }),
    OpN4M4!("XTRCT",     "xtrct Rm,Rn",              0b0010000000001101, (SHCPU cpu, int m, int n) {
        uint high = (cpu.R[m] << 16) & 0xFFFF0000;
        uint low = (cpu.R[n] >> 16) & 0x0000FFFF;
        cpu.R[n] = high | low;
        cpu.PC += 2;
    }),




    //
    //                                   Arithmetic Operation Instructions
    //

    OpN4M4!("ADD",       "add Rm,Rn",                0b0011000000001100, (SHCPU cpu, int m, int n) {
        cpu.R[n] += cpu.R[m];
        cpu.PC += 2;
    }),
    OpN4I8!("ADDI",      "add #imm,Rn",              0b0111000000000000, (SHCPU cpu, int i, int n) {
        if ((i & 0x80) == 0)
            cpu.R[n] += (0x000000FF & i);
        else
            cpu.R[n] += (0xFFFFFF00 | i);

        cpu.PC += 2;
    }),
    OpN4M4!("ADDC",      "addc Rm,Rn",               0b0011000000001110, (SHCPU cpu, int m, int n) {
        uint tmp0 = cpu.R[n];
        uint tmp1 = cpu.R[n] + cpu.R[m];
        cpu.R[n] = tmp1 + cpu.T;
        cpu.T = (tmp0 > tmp1) | (tmp1 > cpu.R[n]);
        cpu.PC += 2;
    }),
    OpN4M4!("ADDV",      "addv Rm,Rn",               0b0011000000001111, (SHCPU cpu, int m, int n) {
        int dst = cpu.R[n] >= 0;
        int src = cpu.R[m] >= 0;

        src += dst;
        cpu.R[n] += cpu.R[m];

        int ans = !(cpu.R[m] >= 0) + dst;
        if (src == 0 || src == 2)
            cpu.T = ans == 1;
        else
            cpu.T = 0;

        cpu.PC += 2;
    }),
    OpI8!("CMPIM",       "cmp/eq #imm,r0",           0b1000100000000000, (SHCPU cpu, int i) {
        long imm;
        if ((i & 0x80) == 0)
            imm = (0x000000FF & i);
        else
            imm = (0xFFFFFF00 | i);

        cpu.T = cpu.R[0] == imm;
        cpu.PC += 2;
    }),
    OpN4M4!("CMPEQ",     "cmp/eq Rm,Rn",             0b0011000000000000, (SHCPU cpu, int m, int n) {
        cpu.T = cpu.R[n] == cpu.R[m];
        cpu.PC += 2;
    }),
    OpN4M4!("CMPHS",     "cmp/hs Rm,Rn",             0b0011000000000010, (SHCPU cpu, int m, int n) {
        cpu.T = cast(uint)cpu.R[n] >= cast(uint)cpu.R[m];
        cpu.PC += 2;
    }),
    OpN4M4!("CMPGE",     "cmp/ge Rm,Rn",             0b0011000000000011, (SHCPU cpu, int m, int n) {
        cpu.T = cpu.R[n] >= cpu.R[m];
        cpu.PC += 2;
    }),
    OpN4M4!("CMPHI",     "cmp/hi Rm,Rn",             0b0011000000000110, (SHCPU cpu, int m, int n) {
        cpu.T = cast(uint)cpu.R[n] > cast(uint)cpu.R[m];
        cpu.PC += 2;
    }),
    OpN4M4!("CMPGT",     "cmp/gt Rm,Rn",             0b0011000000000111, (SHCPU cpu, int m, int n) {
        cpu.T = cpu.R[n] > cpu.R[m];
        cpu.PC += 2;
    }),
    OpN4!("CMPPL",       "cmp/pl Rn",                0b0100000000010101, (SHCPU cpu, int n) {
        cpu.T = cpu.R[n] > 0;
        cpu.PC += 2;
    }),
    OpN4!("CMPPZ",       "cmp/pz Rn",                0b0100000000010001, (SHCPU cpu, int n) {
        cpu.T = cpu.R[n] >= 0;
        cpu.PC += 2;
    }),
    OpN4M4!("CMPSTR",    "cmp/str Rm,Rn",            0b0010000000001100, (SHCPU cpu, int m, int n) {
        int tmp = cpu.R[n] ^ cpu.R[m];
        cpu.T = !(
            ((tmp >>> 24) & 0xFF) &
            ((tmp >>> 16) & 0xFF) &
            ((tmp >>> 8) & 0xFF) &
            ((tmp) & 0xFF)
        );
        cpu.PC += 2;
    }),
    OpN4M4!("DIV0S",     "div0s Rm,Rn",              0b0010000000000111, (SHCPU cpu, int m, int n) {
        cpu.M = ((cpu.R[m] & 0x80000000) != 0);
        cpu.Q = ((cpu.R[n] & 0x80000000) != 0);
        cpu.T = !(cpu.M == cpu.Q);
        cpu.PC += 2;
    }),
    Op!("DIV0U",         "div0u",                    0b0000000000011001, (SHCPU cpu) {
        cpu.M = 0;
        cpu.Q = 0;
        cpu.T = 0;
        cpu.PC += 2;
    }),
    OpN4M4!("DIV1",      "div1 Rm,Rn",               0b0011000000000100, (SHCPU cpu, int m, int n) {
        uint tmp0, tmp2;
        ubyte old_q, tmp1;
        ubyte Q = cpu.Q;
        ubyte M = cpu.M;
        ubyte T = cpu.T;

        old_q = Q;
        Q = (0x80000000 & cpu.R[n]) != 0;
        tmp2 = cpu.R[m];
        cpu.R[n] <<= 1;
        cpu.R[n] |= cast(uint)T;

        if (old_q == 0) {
            if (M == 0) {
                tmp0 = cpu.R[n];
                cpu.R[n] -= tmp2;
                tmp1 = cpu.R[n] > tmp0;
                Q = Q == 0 ? tmp1 : tmp1 == 0;

            } else {
                tmp0 = cpu.R[n];
                cpu.R[n] += tmp2;
                tmp1 = cpu.R[n] < tmp0;
                Q = Q == 0 ? tmp1 : tmp1 == 0;
            }
        } else {
            if (M == 0) {
                tmp0 = cpu.R[n];
                cpu.R[n] += tmp2;
                tmp1 = cpu.R[n] < tmp0;
                Q = Q == 0 ? tmp1 : tmp1 == 0;
            } else {
                tmp0 = cpu.R[n];
                cpu.R[n] -= tmp2;
                tmp1 = cpu.R[n] > tmp0;
                Q = Q == 0 ? tmp1 : tmp1 == 0;
            }
        }

        cpu.M = M;
        cpu.Q = Q;
        cpu.T = (Q == M);
        cpu.PC += 2;
    }),
    OpN4M4!("DMULS",     "dmuls.l Rm,Rn",            0b0011000000001101, (SHCPU cpu, int m, int n) {
        cpu.PC += 2;
    }),
    OpN4M4!("DMULU",     "dmulu.l Rm,Rn",            0b0011000000000101, (SHCPU cpu, int m, int n) {
        cpu.PC += 2;
    }),
    OpN4!("DT",          "dt Rn",                    0b0100000000010000, (SHCPU cpu, int n) {
        cpu.R[n]--;

        cpu.T = cpu.R[n] == 0;
        cpu.PC += 2;
    }),
    OpN4M4!("EXTSB",     "exts.b Rm,Rn",             0b0110000000001110, (SHCPU cpu, int m, int n) {
        cpu.R[n] = cpu.R[m];
        if ((cpu.R[m] & 0x00000080) == 0)
            cpu.R[n] &= 0x000000FF;
        else
            cpu.R[n] |= 0xFFFFFF00;

        cpu.PC += 2;
    }),
    OpN4M4!("EXTSW",     "exts.w Rm,Rn",             0b0110000000001111, (SHCPU cpu, int m, int n) {
        cpu.R[n] = cpu.R[m];
        if ((cpu.R[m] & 0x00008000) == 0)
            cpu.R[n] &= 0x0000FFFF;
        else
            cpu.R[n] |= 0xFFFF0000;

        cpu.PC += 2;
    }),
    OpN4M4!("EXTUB",     "extu.b Rm,Rn",             0b0110000000001100, (SHCPU cpu, int m, int n) {
        cpu.R[n] = cpu.R[m];
        cpu.R[n] &= 0x000000FF;
        cpu.PC += 2;
    }),
    OpN4M4!("EXTUW",     "extu.w Rm,Rn",             0b0110000000001101, (SHCPU cpu, int m, int n) {
        cpu.R[n] = cpu.R[m];
        cpu.R[n] &= 0x0000FFFF;
        cpu.PC += 2;
    }),
    OpN4M4!("MACW",      "mac.w @Rm+,@Rn+",          0b0100000000001111, (SHCPU cpu, int m, int n) {
        cpu.PC += 2;
    }),
    OpN4M4!("MACL",      "mac.l @Rm+,@Rn+",          0b0000000000001111, (SHCPU cpu, int m, int n) {
        cpu.PC += 2;
    }),
    OpN4M4!("MULL",      "mul.l Rm,Rn",              0b0000000000000111, (SHCPU cpu, int m, int n) {
        cpu.MACL = cpu.R[n] * cpu.R[m];
        cpu.PC += 2;
    }),
    OpN4M4!("MULSW",     "muls.w Rm,Rn",             0b0010000000001111, (SHCPU cpu, int m, int n) {
        cpu.MACL = cast(short)cpu.R[n] * cast(short)cpu.R[m];
        cpu.PC += 2;
    }),
    OpN4M4!("MULUW",     "mulu.w Rm,Rn",             0b0010000000001110, (SHCPU cpu, int m, int n) {
        cpu.MACL = cast(ushort)cpu.R[n] * cast(ushort)cpu.R[m];
        cpu.PC += 2;
    }),
    OpN4M4!("NEG",       "neg Rm,Rn",                0b0110000000001011, (SHCPU cpu, int m, int n) {
        cpu.R[n] = 0 - cpu.R[m];
        cpu.PC += 2;
    }),
    OpN4M4!("NEGC",      "negc Rm,Rn",               0b0110000000001010, (SHCPU cpu, int m, int n) {
        uint tmp = 0 - cpu.R[m];
        cpu.R[n] = tmp - cpu.T;
        cpu.T = (0 < tmp) | (tmp < cpu.R[n]);
        cpu.PC += 2;
    }),
    OpN4M4!("SUB",       "sub Rm,Rn",                0b0011000000001000, (SHCPU cpu, int m, int n) {
        cpu.R[n] -= cpu.R[m];
        cpu.PC += 2;
    }),
    OpN4M4!("SUBC",      "subc Rm,Rn",               0b0011000000001010, (SHCPU cpu, int m, int n) {
        uint tmp0 = cpu.R[n];
        uint tmp1 = cpu.R[n] - cpu.R[m];
        cpu.R[n] = tmp1 - cpu.T;
        cpu.T = (tmp0 < tmp1) | (tmp1 < cpu.R[n]);
        cpu.PC += 2;
    }),
    OpN4M4!("SUBV",      "subv Rm,Rn",               0b0011000000001011, (SHCPU cpu, int m, int n) {
        int dst = !(cpu.R[n] >= 0);
        int src = !(cpu.R[m] >= 0);

        src += dst;
        cpu.R[n] -= cpu.R[m];

        int ans = (cpu.R[m] >= 0) + dst;
        if (src == 1)
            cpu.T = ans == 1;
        else
            cpu.T = 0;

        cpu.PC += 2;
    }),




    //
    //                                      Logic Operation Instructions
    //

    OpN4M4!("AND",       "and Rm,Rn",                0b0010000000001001, (SHCPU cpu, int m, int n) {
        cpu.R[n] &= cpu.R[m];
        cpu.PC += 2;
    }),
    OpI8!("ANDI",        "and #imm,Rn",              0b1100100100000000, (SHCPU cpu, int i) {
        cpu.R[0] &= (0x000000FF & i);
        cpu.PC += 2;
    }),
    OpI8!("ANDM",        "and.b #imm,@(r0,gbr)",     0b1100110100000000, (SHCPU cpu, int i) {
        int tmp = cpu.read!ubyte(cpu.GBR + cpu.R[0]);
        tmp &= 0x000000FF & i;
        cpu.write!ubyte(cpu.GBR + cpu.R[0], tmp);
        cpu.PC += 2;
    }),
    OpN4M4!("NOT",       "not Rm,Rn",                0b0110000000000111, (SHCPU cpu, int m, int n) {
        cpu.R[n] = ~cpu.R[m];
        cpu.PC += 2;
    }),
    OpN4M4!("OR",        "or Rm,Rn",                 0b0010000000001011, (SHCPU cpu, int m, int n) {
        cpu.R[n] |= cpu.R[m];
        cpu.PC += 2;
    }),
    OpI8!("ORI",         "or #imm,r0",               0b1100101100000000, (SHCPU cpu, int i) {
        cpu.R[0] |= (0x000000FF & i);
        cpu.PC += 2;
    }),
    OpI8!("ORM",         "or.b #imm,@(r0,gbr)",      0b1100111100000000, (SHCPU cpu, int i) {
        int tmp = cpu.read!ubyte(cpu.GBR + cpu.R[0]);
        tmp |= 0x000000FF & i;
        cpu.write!ubyte(cpu.GBR + cpu.R[0], tmp);
        cpu.PC += 2;
    }),
    OpN4!("TAS",         "tas.b @Rn",                0b0100000000011011, (SHCPU cpu, int n) {
        int tmp = cpu.read!ubyte(cpu.R[n]); // Bus lock
        cpu.T = tmp == 0;

        tmp |= 0x00000080;
        cpu.write!ubyte(cpu.R[n], tmp); // Bus unlock
        cpu.PC += 2;
    }),
    OpN4M4!("TST",       "tst Rm,Rn",                0b0010000000001000, (SHCPU cpu, int m, int n) {
        cpu.T = (cpu.R[n] & cpu.R[m]) == 0;
        cpu.PC += 2;
    }),
    OpI8!("TSTI",        "and #imm,Rn",              0b1100100000000000, (SHCPU cpu, int i) {
        cpu.T = (cpu.R[0] & (0x000000FF & i)) == 0;
        cpu.PC += 2;
    }),
    OpI8!("TSTM",        "and.b #imm,@(r0,gbr)",     0b1100110000000000, (SHCPU cpu, int i) {
        int tmp = cpu.read!ubyte(cpu.GBR + cpu.R[0]);
        tmp &= 0x000000FF & i;
        cpu.T = tmp == 0;
        cpu.PC += 2;
    }),
    OpN4M4!("XOR",       "xor Rm,Rn",                0b0010000000001010, (SHCPU cpu, int m, int n) {
        cpu.R[n] ^= cpu.R[m];
        cpu.PC += 2;
    }),
    OpI8!("XORI",        "xor #imm,Rn",              0b1100101000000000, (SHCPU cpu, int i) {
        cpu.R[0] ^= (0x000000FF & i);
        cpu.PC += 2;
    }),
    OpI8!("XORM",        "xor.b #imm,@(r0,gbr)",     0b1100111000000000, (SHCPU cpu, int i) {
        int tmp = cpu.read!ubyte(cpu.GBR + cpu.R[0]);
        tmp ^= 0x000000FF & i;
        cpu.write!ubyte(cpu.GBR + cpu.R[0], tmp);
        cpu.PC += 2;
    }),




    //
    //                                          Shift Instructions
    //

    OpN4!("ROTCL",       "rotcl Rn",                 0b0100000000100100, (SHCPU cpu, int n) {
        ubyte tmp = (cpu.R[n] & 0x80000000) != 0;
        cpu.R[n] <<= 1;

        if (cpu.T)
            cpu.R[n] |= 0x00000001;
        else
            cpu.R[n] &= 0xFFFFFFFE;

        cpu.T = tmp;

        cpu.PC += 2;
    }),
    OpN4!("ROTCR",       "rotcr Rn",                 0b0100000000100101, (SHCPU cpu, int n) {
        ubyte tmp = (cpu.R[n] & 0x00000001) != 0;
        cpu.R[n] >>= 1;
        if (cpu.T)
            cpu.R[n] |= 0x80000000;
        else
            cpu.R[n] &= 0x7FFFFFFF;

        cpu.T = tmp;

        cpu.PC += 2;
    }),
    OpN4!("ROTL",        "rotl Rn",                  0b0100000000000100, (SHCPU cpu, int n) {
        cpu.T = (cpu.R[n] & 0x80000000) != 0;
        cpu.R[n] <<= 1;

        if (cpu.T)
            cpu.R[n] |= 0x00000001;
        else
            cpu.R[n] &= 0xFFFFFFFE;

        cpu.PC += 2;
    }),
    OpN4!("ROTR",        "rotr Rn",                  0b0100000000000101, (SHCPU cpu, int n) {
        cpu.T = (cpu.R[n] & 0x00000001) != 0;
        cpu.R[n] >>= 1;
        if (cpu.T)
            cpu.R[n] |= 0x80000000;
        else
            cpu.R[n] &= 0x7FFFFFFF;

        cpu.PC += 2;
    }),
    OpN4!("SHAL",        "shal Rn",                  0b0100000000100000, (SHCPU cpu, int n) {
        cpu.T = (cpu.R[n] & 0x80000000) != 0;
        cpu.R[n] <<= 1;

        cpu.PC += 2;
    }),
    OpN4!("SHAR",        "shar Rn",                  0b0100000000100001, (SHCPU cpu, int n) {
        cpu.T = (cpu.R[n] & 0x00000001) != 0;
        cpu.R[n] >>= 1;
        cpu.PC += 2;
    }),
    OpN4!("SHLL",        "shll Rn",                  0b0100000000000000, (SHCPU cpu, int n) {
        cpu.T = (cpu.R[n] & 0x80000000) != 0;
        cpu.R[n] <<= 1;

        cpu.PC += 2;
    }),
    OpN4!("SHLL2",       "shll2 Rn",                 0b0100000000001000, (SHCPU cpu, int n) {
        cpu.R[n] <<= 2;
        cpu.PC += 2;
    }),
    OpN4!("SHLL8",       "shll8 Rn",                 0b0100000000011000, (SHCPU cpu, int n) {
        cpu.R[n] <<= 8;
        cpu.PC += 2;
    }),
    OpN4!("SHLL16",      "shll16 Rn",                0b0100000000101000, (SHCPU cpu, int n) {
        cpu.R[n] <<= 16;
        cpu.PC += 2;
    }),
    OpN4!("SHLR",        "shlr Rn",                  0b0100000000000001, (SHCPU cpu, int n) {
        cpu.T = (cpu.R[n] & 0x80000000) != 0;
        cpu.R[n] >>= 1;
        cpu.R[n] &= 0x7FFFFFFF;
        cpu.PC += 2;
    }),
    OpN4!("SHLR2",       "shlr2 Rn",                 0b0100000000001001, (SHCPU cpu, int n) {
        cpu.R[n] >>= 2;
        cpu.R[n] &= 0x3FFFFFFF;
        cpu.PC += 2;
    }),
    OpN4!("SHLR8",       "shlr8 Rn",                 0b0100000000011001, (SHCPU cpu, int n) {
        cpu.R[n] >>= 8;
        cpu.R[n] &= 0x00FFFFFF;
        cpu.PC += 2;
    }),
    OpN4!("SHLR16",      "shlr16 Rn",                0b0100000000101001, (SHCPU cpu, int n) {
        cpu.R[n] >>= 16;
        cpu.R[n] &= 0x0000FFFF;
        cpu.PC += 2;
    }),




    //
    //                                          Branch Instructions
    //
    OpD8!("BF",          "bf @(disp,pc)",            0b1000101100000000, (SHCPU cpu, int d) {
        int disp =  (d & 0x80) == 0 ? 
                    (0x000000FF & d) : 
                    (0xFFFFFF00 | d);

        cpu.PC = !cpu.T ? 
            cpu.PC + 4 + (disp << 1) :
            cpu.PC + 2;
    }),
    OpD8!("BFS",         "bf/s @(disp,pc)",          0b1000111100000000, (SHCPU cpu, int d) {
        int tmp = cpu.PC;
        int disp =  (d & 0x80) == 0 ? 
                    (0x000000FF & d) : 
                    (0xFFFFFF00 | d);

        cpu.PC = !cpu.T ? 
            cpu.PC + 4 + (disp << 1) :
            cpu.PC + 2;

        cpu.delaySlot(tmp+2);
    }),
    OpD8!("BT",          "bt @(disp,pc)",            0b1000100100000000, (SHCPU cpu, int d) {
        int disp =  (d & 0x80) == 0 ? 
                    (0x000000FF & d) : 
                    (0xFFFFFF00 | d);

        cpu.PC = cpu.T ? 
            cpu.PC + 4 + (disp << 1) :
            cpu.PC + 2;
    }),
    OpD8!("BTS",         "bt/s @(disp,pc)",          0b1000110100000000, (SHCPU cpu, int d) {
        int tmp = cpu.PC;
        int disp =  (d & 0x80) == 0 ? 
                    (0x000000FF & d) : 
                    (0xFFFFFF00 | d);
        
        cpu.PC = cpu.T ? 
            cpu.PC + 4 + (disp << 1) :
            cpu.PC + 2;

        cpu.delaySlot(tmp+2);
    }),
    OpD12!("BRA",        "bra @(disp,pc)",           0b1010000000000000, (SHCPU cpu, int d) {
        int tmp = cpu.PC;
        int disp =  (d & 0x800) == 0 ? 
                    (0x00000FFF & d) : 
                    (0xFFFFF000 | d);
        
        cpu.PC = cpu.PC + 4 + (disp << 1);
        cpu.delaySlot(tmp+2);
    }),
    OpM4!("BRAF",        "braf Rm",                  0b0000000000100011, (SHCPU cpu, int m) {
        int tmp = cpu.PC;
        cpu.PC += 4 + cpu.R[m];
        cpu.delaySlot(tmp+2);
    }),
    OpD12!("BSR",        "bsr @(disp,pc)",           0b1011000000000000, (SHCPU cpu, int d) {
        int tmp = cpu.PC;
        int disp =  (d & 0x800) == 0 ? 
                    (0x00000FFF & d) : 
                    (0xFFFFF000 | d);
        
        cpu.PR = cpu.PC + 4;
        cpu.PC = cpu.PC + 4 + (disp << 1);
        cpu.delaySlot(tmp+2);
    }),
    OpM4!("BSRF",        "bsrf Rm",                  0b0000000000000011, (SHCPU cpu, int m) {
        uint tmp = cpu.PC;
        cpu.PR = cpu.PC + 4;
        cpu.PC += 4 + cpu.R[m];
        cpu.delaySlot(tmp+2);
    }),
    OpM4!("JMP",         "jmp @Rm",                  0b0100000000101011, (SHCPU cpu, int m) {
        uint tmp = cpu.PC;
        cpu.PC = cpu.R[m];
        cpu.delaySlot(tmp+2);
    }),
    OpM4!("JSR",         "jsr @Rm",                  0b0100000000001011, (SHCPU cpu, int m) {
        uint tmp = cpu.PC;
        cpu.PR = cpu.PC + 4;
        cpu.PC = cpu.R[m];
        cpu.delaySlot(tmp+2);
    }),
    Op!("RTS",           "rts",                      0b0000000000001011, (SHCPU cpu) {
        int tmp = cpu.PC;
        cpu.PC = cpu.PR;
        cpu.delaySlot(tmp+2);
    }),




    //
    //                                      System Control Instructions
    //

    Op!("CLRMAC",        "clrmac",                   0b0000000000101000, (SHCPU cpu) {
        cpu.MACL = 0;
        cpu.MACH = 0;
        cpu.PC += 2;
    }),
    Op!("CLRT",          "clrt",                     0b0000000000001000, (SHCPU cpu) {
        cpu.T = 0;
        cpu.PC += 2;
    }),
    OpM4!("LDCSR",       "ldc Rm,sr",                0b0100000000001110, (SHCPU cpu, int m) {
        cpu.SR = cpu.R[m];
        cpu.PC += 2;
    }),
    OpM4!("LDCMSR",      "ldc.l @Rm+,sr",            0b0100000000000111, (SHCPU cpu, int m) {
        cpu.SR = cpu.read!uint(cpu.R[m]);
        cpu.R[m] += 4;
        cpu.PC += 2;
    }),
    OpM4!("LDCGBR",      "ldc Rm,gbr",               0b0100000000011110, (SHCPU cpu, int m) {
        cpu.GBR = cpu.R[m];
        cpu.PC += 2;
    }),
    OpM4!("LDCMGBR",     "ldc.l @Rm+,gbr",           0b0100000000010111, (SHCPU cpu, int m) {
        cpu.GBR = cpu.read!uint(cpu.R[m]);
        cpu.R[m] += 4;
        cpu.PC += 2;
    }),
    OpM4!("LDCVBR",      "ldc Rm,vbr",               0b0100000000101110, (SHCPU cpu, int m) {
        cpu.VBR = cpu.R[m];
        cpu.PC += 2;
    }),
    OpM4!("LDCMVBR",     "ldc.l @Rm+,vbr",           0b0100000000100111, (SHCPU cpu, int m) {
        cpu.VBR = cpu.read!uint(cpu.R[m]);
        cpu.R[m] += 4;
        cpu.PC += 2;
    }),
    OpM4!("LDSMACH",     "lds Rm,mach",              0b0100000000001010, (SHCPU cpu, int m) {
        cpu.MACH = cpu.R[m];
        cpu.PC += 2;
    }),
    OpM4!("LDSMMACH",    "lds.l @Rm+,mach",          0b0100000000000110, (SHCPU cpu, int m) {
        cpu.MACH = cpu.read!uint(cpu.R[m]);
        cpu.R[m] += 4;
        cpu.PC += 2;
    }),
    OpM4!("LDSMACL",     "lds Rm,macl",              0b0100000000011010, (SHCPU cpu, int m) {
        cpu.MACL = cpu.R[m];
        cpu.PC += 2;
    }),
    OpM4!("LDSMMACL",    "lds.l @Rm+,macl",          0b0100000000010110, (SHCPU cpu, int m) {
        cpu.MACL = cpu.read!uint(cpu.R[m]);
        cpu.R[m] += 4;
        cpu.PC += 2;
    }),
    OpM4!("LDSPR",       "lds Rm,pr",                0b0100000000101010, (SHCPU cpu, int m) {
        cpu.PR = cpu.R[m];
        cpu.PC += 2;
    }),
    OpM4!("LDSMPR",      "lds.l @Rm+,pr",            0b0100000000100110, (SHCPU cpu, int m) {
        cpu.PR = cpu.read!uint(cpu.R[m]);
        cpu.R[m] += 4;
        cpu.PC += 2;
    }),
    Op!("NOP",           "nop",                      0b0000000000001001, (SHCPU cpu) {
        cpu.PC += 2;
    }),
    Op!("RTE",           "rte",                      0b0000000000101011, (SHCPU cpu) {
        int tmp = cpu.PC;
        cpu.SR = cpu.SSR;
        cpu.PC = cpu.SPC;
        cpu.delaySlot(tmp+2);
    }),
    Op!("SETT",          "sett",                     0b0000000000011000, (SHCPU cpu) {
        cpu.T = 1;
        cpu.PC += 2;
    }),
    Op!("SLEEP",         "sleep",                    0b0000000000011011, (SHCPU cpu) {
        cpu.PC += 2;
    }),
    OpN4!("STCSR",       "stc sr,Rn",                0b0000000000000010, (SHCPU cpu, int n) {
        cpu.R[n] = cpu.SR;
        cpu.PC += 2;
    }),
    OpN4!("STCMSR",      "stc.l sr,@-Rn",            0b0100000000000011, (SHCPU cpu, int n) {
        cpu.R[n] -= 4;
        cpu.write!uint(cpu.R[n], cpu.SR);
        cpu.PC += 2;
    }),
    OpN4!("STCGBR",      "stc gbr,Rn",               0b0000000000010010, (SHCPU cpu, int n) {
        cpu.R[n] = cpu.GBR;
        cpu.PC += 2;
    }),
    OpN4!("STCMGBR",     "stc.l gbr,@-Rn",           0b0100000000010011, (SHCPU cpu, int n) {
        cpu.R[n] -= 4;
        cpu.write!uint(cpu.R[n], cpu.GBR);
        cpu.PC += 2;
    }),
    OpN4!("STCVBR",      "stc vbr,Rn",               0b0000000000100010, (SHCPU cpu, int n) {
        cpu.R[n] = cpu.GBR;
        cpu.PC += 2;
    }),
    OpN4!("STCMVBR",     "stc.l vbr,@-Rn",           0b0100000000100011, (SHCPU cpu, int n) {
        cpu.R[n] -= 4;
        cpu.write!uint(cpu.R[n], cpu.VBR);
        cpu.PC += 2;
    }),
    OpN4!("STSMACH",     "sts mach,Rn",              0b0000000000001010, (SHCPU cpu, int n) {
        cpu.R[n] = cpu.MACH;
        cpu.PC += 2;
    }),
    OpN4!("STSMMACH",    "sts.l mach,@-Rn",          0b0100000000000010, (SHCPU cpu, int n) {
        cpu.R[n] -= 4;
        cpu.write!uint(cpu.R[n], cpu.MACH);
        cpu.PC += 2;
    }),
    OpN4!("STSMACL",     "sts macl,Rn",              0b0000000000011010, (SHCPU cpu, int n) {
        cpu.R[n] = cpu.MACL;
        cpu.PC += 2;
    }),
    OpN4!("STSMMACL",    "sts.l macl,@-Rn",          0b0100000000010010, (SHCPU cpu, int n) {
        cpu.R[n] -= 4;
        cpu.write!uint(cpu.R[n], cpu.MACL);
        cpu.PC += 2;
    }),
    OpN4!("STSPR",       "sts pr,Rn",                0b0000000000101010, (SHCPU cpu, int n) {
        cpu.R[n] = cpu.PR;
        cpu.PC += 2;
    }),
    OpN4!("STSMPR",      "sts.l pr,@-Rn",            0b0100000000100010, (SHCPU cpu, int n) {
        cpu.R[n] -= 4;
        cpu.write!uint(cpu.R[n], cpu.PR);
        cpu.PC += 2;
    }),
    OpI8!("TRAPA",       "trapa #imm",               0b1100001100000000, (SHCPU cpu, int i) {
        cpu.PC += 2;
    }),
];