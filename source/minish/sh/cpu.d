module minish.sh.cpu;
import minish.sh.inst;
import minish.sh.mem;
import minish.cpu;
import minish.mod;
import minish.core.endian;

public import minish.sh.cpus;

/// Bit offset of the T bit.
enum SH_T_BIT = 1;

/// Bit offset of the Q bit.
enum SH_Q_BIT = 8;

/// Bit offset of the M bit.
enum SH_M_BIT = 9;

struct CPUInfo {
	string name;
}

/**
	A SuperH processor.
*/
abstract class SHCPU : CPU {
private:
	bool shle;

protected:

	/**
		Constructs a new SuperH CPU.

		Params:
			mem = The memory controller to instantiate with.
	*/
	this(SHMemory mem, bool isLittleEndian) {
		super(mem);
		this.shle = isLittleEndian;
		this.memory = mem;
	}

public:

	/// Memory Controller.
	SHMemory memory;

	/// General Purpose Register
	int[16] R;

	/// Program Counter
	uint PC = 0xA0000000;

	/// Saved Program Counter
	uint SPC;
	
	/// Status Register
	uint SR;

	/// Saved Status Register
	uint SSR;

	/// Floating Point Status Register
	uint FPSCR;

	/// Global Base Register
	uint GBR;

	/// Vector Base Register
	uint VBR = 0x00000000;

	/// Saved General Register 15
	uint SGR;

	/// Debug Base Register
	uint DBR;

	/// Multiply-and-accumulate Register
	uint MACL;
	uint MACH; /// ditto

	/// Procedure Register
	uint PR;

	/**
		The virtual CPU's program counter.
	*/
	override @property ref uint programCounter() => PC;

	/**
		Utility function that gets the stack pointer.
	*/
	@property ref int SP() => R[15];

	/**
		Utility function that gets the frame pointer.
	*/
	@property ref int FP() => R[14];

	/// The status register's T bit.
	@property ubyte T() => getbit!SH_T_BIT(SR);
	@property void T(ubyte value) => setbit!SH_T_BIT(SR, value);

	/// The status register's M bit.
	@property ubyte M() => getbit!SH_M_BIT(SR);
	@property void M(ubyte value) => setbit!SH_M_BIT(SR, value);

	/// The status register's Q bit.
	@property ubyte Q() => getbit!SH_Q_BIT(SR);
	@property void Q(ubyte value) => setbit!SH_Q_BIT(SR, value);

	/**
		Whether the processor is little endian.
	*/
	override @property bool isLittleEndian() => shle;

	/**
		Whether the delay slot is filled.
	*/
	@property bool isDelaySlotFilled() => iqueue.length > 1;


	/**
		Reads value at given address if possible.

		Params:
			addr = The address to read from.

		Returns:
			The value at that address or $(D T.init).
	*/
	T read(T)(uint addr) {
		if (auto v = memory.read(addr, T.sizeof))
			return (cast(T[])v)[0].toNativeEndian(shle);
		return T.init;
	}

	/**
		Writes the value to the given address.

		Params:
			addr = 	The address to write to.
			value =	The value to write.
	*/
	void write(T, Y)(uint addr, Y value) {
		Y[1] v = [value.toOtherEndian(shle)];
		memory.write(addr, v[0..$]);
	}

	/**
		Adds the given address to the delay slot.

		Params:
			addr = Address of the next instruction.
	*/
	void delaySlot(uint addr) {
		this.addToQueue(this.read!ushort(addr));
		PC -= 2;
	}

	/**
		Loads a module into the CPU's address space.

		Params:
			mod = The module to load.
	*/
	override void load(Module mod) {
		if (mod.isLittleEndian != this.isLittleEndian)
			throw new Exception("Incompatible endianness!");

		foreach(seg; mod.segments) {
			memory.write(seg.vaddr, seg.data);
		}

		// Set PC to entry symbol if any is present.
		auto entry = mod.entrySymbol;
		if (entry != Symbol.init) {
			this.PC = entry.vaddr;
		}
	}

	/**
		Runs the CPU from the given address until it
		returns to address 0.

		Params:
			addr = The address of the function to execute.

		Returns:
			The values of all the general purpose registers at the
			end of execution.
	*/
	override ulong[] eval(uint addr) {
		this.PC = addr;

		while (step()) { }
		return [R[0], R[1], R[2], R[3]];
	}

	/**
		Gets a reference to the data of a general purpose
		register.

		Params:
			i = The index of the register.

		Returns:
			A reference to the GPR register's data.
	*/
	override ref int GPR(ubyte i) => R[i];

	/**
		Gets a reference to the data of a floating point
		register.

		Params:
			i = The index of the register.

		Returns:
			A reference to the FPR register's data.
	*/
	override ref float FPR(ubyte i) {
		throw new Exception("Not implemented.");
	}
}

/**
	Gets a bit in a given value.

	Params:
		src = The source to get the bit in.

	Returns:
		The value of the bit at that location.
*/
pragma(inline, true)
bool getbit(uint offset, T)(ref T src) {
	return src>>offset & 1;
}

/**
	Gets a bit in a given value.

	Params:
		src = 	The source to get the bit in.
		value =	The value to set the bit to.
*/
pragma(inline, true)
void setbit(uint offset, T)(ref T src, uint value) {
	enum uint MASK = (1U<<offset);
	src = (src & ~MASK) | (cast(uint)value << offset);
}

/**
    Template that generates the instruction that selects an instruction to execute.
*/
mixin template GenInstrSelect(SHInst[] inst) {
    
    /// The different opcode category masks that was found in the instruction set.
    enum OpcodeCategories = (SHInst[] inst) {
        uint[] result;
        bool[ushort] found; 
        foreach(ref instr; inst) {
            if (instr.mask !in found) {
                result ~= instr.mask;
                found[instr.mask] = 1;
            }
        }

        return result;
    }(inst);

    /**
        Executes a single CPU step.
    
        Returns:
            Whether a valid instruction was executed.
    */
    override bool step() {
    	ushort op = cast(ushort)getNextInstruction();
    	if (op == 0) {
    		this.addToQueue(this.read!ushort(PC));
    		op = cast(ushort)getNextInstruction();
    	}


    	while (op) {
	        static foreach(CATEGORY; OpcodeCategories) {
	            switch(op & CATEGORY) {
	                default: break;

	                static foreach(i; 0..inst.length) {{
	                    static if (inst[i].mask == CATEGORY) {
	                        case inst[i].opcode:
	                            inst[i].op(this, op);
	                            return true;
	                    }
	                }}
	            }
	        }
    	}

        return false;
    }
}