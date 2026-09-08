//module minish.core.instrinfo;
//import minish.core.cpu;

///**
//	Instruction info
//*/
//struct InstrInfo {

//    /**
//        Name of the instruction
//    */
//    string name;

//    /**
//        Name of the instruction
//    */
//    string asmstr;
	
//	/**
//		The instruction's opcode
//	*/
//	uint opcode;

//	/**
//		The instruction's mask.
//	*/
//	uint mask;

//	/**
//		The instruction's operands
//	*/
//	Operand[] operands;
//}

///**
//	Information about an operand.
//*/
//struct Operand {

//	/**
//		Name of the operand.
//	*/
//	string name;

//	/**
//		Size of the operand in bits.
//	*/
//	uint size;

//	/**
//		Offset of the operand into the instruction
//	*/
//	uint offset;
//}

//struct Instr {
//public:

//    /**
//        Name of the instruction
//    */
//    string name;
		
//	/**
//		Assembly string of the instruction
//	*/
//    string asmstr;

//	/**
//		The instruction's opcode
//	*/
//	uint opcode;

//	/**
//		The instruction's mask.
//	*/
//	uint mask;

//	/**
//		Gets the operands of the instruction
//	*/
//	int[] function(uint op) getOperands;

//    /**
//        Executes the instruction.
//    */
//    void function(VCPU cpu, uint op) exec;
//}

///**
//	A materialized instruction.
//*/
//template InstrDef(InstrInfo info, CPUT, alias execfn) {
//	template getOperandType(InstrInfo info) {
//		import std.meta;

//		alias ArgT = AliasSeq!();
//		static foreach(operand; info.operands) {
//			alias ArgT = AliasSeq!(ArgT, int);
//		}

//		alias getOperandType = ArgT;
//	}

//    pragma(mangle, "INSTR_"~info.name)
//	__gshared const immutable(Instr) __INSTR = Instr(
//		name: info.name,
//		asmstr: info.asmstr,
//		opcode: info.opcode,
//		mask: info.mask,
//		getOperands: (uint op) {
//			int[] result = new int[info.length];
//			static foreach(i, opinfo; info.operands) {
//				result[i] = (op >> opinfo.offset) & ((1<<size)-1);
//			}
//			return result;
//		},
//		exec: (VCPU cpu, uint op) {
//			getOperandType!(info) operands;
//			foreach(i, opr; __INSTR.getOperands(op)) {
//				operands[i] = opr;
//			}

//			execfn(cast(CPUT)cpu, operands);
//		}
//	);
//    alias InstrDef = __INSTR;
//}