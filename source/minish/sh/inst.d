module minish.sh.inst;
import minish.sh.cpu;

struct SHInst {

    /**
        Name of the instruction
    */
    string name;

    /**
        The opcode
    */
    ushort opcode;

    /**
        The mask to get the opcode from the instruction
        stream.
    */
    ushort mask;

    /**
        The operation to perform.
    */
    void function(SHCPU cpu, ushort op) op;
}

template Op(string name, string asmstr, ushort opcode, void function(SHCPU cpu) op) {
    
    pragma(mangle, "SH_INSTR_"~name)
    __gshared const immutable(SHInst) __INSTR = SHInst(
        name,
        opcode,
        0b11110000_11111111u,
        (SHCPU cpu, ushort opcode) {
            op(cpu);
        }
    );
    alias Op = __INSTR;
}

template OpM4(string name, string asmstr, ushort opcode, void function(SHCPU cpu, int m) op) {
    
    pragma(mangle, "SH_INSTR_"~name)
    __gshared const immutable(SHInst) __INSTR = SHInst(
        name,
        opcode,
        0b11110000_11111111u,
        (SHCPU cpu, ushort opcode) {
            int m = (opcode >> 8)&0x0F;
            op(cpu, m);
        }
    );
    alias OpM4 = __INSTR;
}

template OpN4(string name, string asmstr, ushort opcode, void function(SHCPU cpu, int n) op) {
    
    pragma(mangle, "SH_INSTR_"~name)
    __gshared const immutable(SHInst) __INSTR = SHInst(
        name,
        opcode,
        0b11110000_11111111u,
        (SHCPU cpu, ushort opcode) {
            int n = (opcode >> 8)&0x0F;
            op(cpu, n);
        }
    );
    alias OpN4 = __INSTR;
}

template OpN4M4(string name, string asmstr, ushort opcode, void function(SHCPU cpu, int m, int n) op) {
    
    pragma(mangle, "SH_INSTR_"~name)
    __gshared const immutable(SHInst) __INSTR = SHInst(
        name,
        opcode,
        0b11110000_00001111u,
        (SHCPU cpu, ushort opcode) {
            int n = (opcode >> 8)&0x0F;
            int m = (opcode >> 4)&0x0F;
            op(cpu, m, n);
        }
    );
    alias OpN4M4 = __INSTR;
}

template OpN4I8(string name, string asmstr, ushort opcode, void function(SHCPU cpu, int i, int n) op) {
    
    pragma(mangle, "SH_INSTR_"~name)
    __gshared const immutable(SHInst) __INSTR = SHInst(
        name,
        opcode,
        0b11110000_00000000u,
        (SHCPU cpu, ushort opcode) {
            int n = (opcode >> 8)&0x0F;
            int i = (opcode & 0xFF);
            op(cpu, i, n);
        }
    );
    alias OpN4I8 = __INSTR;
}

template OpN4D8(string name, string asmstr, ushort opcode, void function(SHCPU cpu, int d, int n) op) {
    
    __gshared auto __fn = op;

    pragma(mangle, "SH_INSTR_"~name)
    __gshared const SHInst __INSTR = SHInst(
        name,
        opcode,
        0b11110000_00000000u,
        (SHCPU cpu, ushort opcode) {
            int n = (opcode >> 8)&0x0F;
            int d = (opcode & 0xFF);
            op(cpu, d, n);
        }
    );
    alias OpN4D8 = __INSTR;
}

template OpI8(string name, string asmstr, ushort opcode, void function(SHCPU cpu, int i) op) {
    
    pragma(mangle, "SH_INSTR_"~name)
    __gshared const immutable(SHInst) __INSTR = SHInst(
        name,
        opcode,
        0b11111111_00000000u,
        (SHCPU cpu, ushort opcode) {
            int i = (opcode & 0xFF);
            op(cpu, i);
        }
    );
    alias OpI8 = __INSTR;
}

template OpD8(string name, string asmstr, ushort opcode, void function(SHCPU cpu, int d) op) {
    
    pragma(mangle, "SH_INSTR_"~name)
    __gshared const immutable(SHInst) __INSTR = SHInst(
        name,
        opcode,
        0b11111111_00000000u,
        (SHCPU cpu, ushort opcode) {
            int d = (opcode & 0xFF);
            op(cpu, d);
        }
    );
    alias OpD8 = __INSTR;
}

template OpD12(string name, string asmstr, ushort opcode, void function(SHCPU cpu, int d) op) {
    
    pragma(mangle, "SH_INSTR_"~name)
    __gshared const immutable(SHInst) __INSTR = SHInst(
        name,
        opcode,
        0b11110000_00000000u,
        (SHCPU cpu, ushort opcode) {
            int d = (opcode & 0xFFF);
            op(cpu, d);
        }
    );
    alias OpD12 = __INSTR;
}

template OpM4D4(string name, string asmstr, ushort opcode, void function(SHCPU cpu, int m, int d) op) {
    
    pragma(mangle, "SH_INSTR_"~name)
    __gshared const immutable(SHInst) __INSTR = SHInst(
        name,
        opcode,
        0b11111111_00000000u,
        (SHCPU cpu, ushort opcode) {
            int m = (opcode >> 4)&0xF;
            int d = (opcode & 0xF);
            op(cpu, m, d);
        }
    );
    alias OpM4D4 = __INSTR;
}

template OpN4D4(string name, string asmstr, ushort opcode, void function(SHCPU cpu, int d, int n) op) {
    
    pragma(mangle, "SH_INSTR_"~name)
    __gshared const immutable(SHInst) __INSTR = SHInst(
        name,
        opcode,
        0b11111111_00000000u,
        (SHCPU cpu, ushort opcode) {
            int n = (opcode >> 4)&0xF;
            int d = (opcode & 0xF);
            op(cpu, d, n);
        }
    );
    alias OpN4D4 = __INSTR;
}

template OpN4M4D4(string name, string asmstr, ushort opcode, void function(SHCPU cpu, int m, int d, int n) op) {
    
    pragma(mangle, "SH_INSTR_"~name)
    __gshared const immutable(SHInst) __INSTR = SHInst(
        name,
        opcode,
        0b11110000_00000000u,
        (SHCPU cpu, ushort opcode) {
            int n = (opcode >> 8)&0xF;
            int m = (opcode >> 4)&0xF;
            int d = (opcode & 0xF);
            op(cpu, m, d, n);
        }
    );
    alias OpN4M4D4 = __INSTR;
}