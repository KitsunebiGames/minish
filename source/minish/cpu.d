module minish.cpu;
import minish.core.registry;
import minish.core.endian;
import minish.mod;
import minish.mem;

import minish.sh.cpus;

/**
	A virtual CPU.

	This provides a generic and safe interface to more specialized
	virtual CPU implementations.
*/
abstract class CPU {
protected:

	/**
		Instruction queue
	*/
	InstructionQueue iqueue;

	/**
		The memory controller of the CPU.
	*/
	MemoryController controller;

	/**
		Constructs a new CPU.

		Params:
			mem = The memory controller
	*/
	this(MemoryController mem) {
		this.controller = mem;
	}

	/**
		Gets the next instruction from the instruction queue.
	*/
	final uint getNextInstruction() {
		if (iqueue.length > 0)
			return iqueue.next();
		return 0;
	}

	/**
		Adds the given instruction to the instruction queue.
	*/
	final void addToQueue(uint instr) {
		this.iqueue.add(instr);
	}

public:

	/**
		The memory attached to the CPU.
	*/
	final @property MemoryController memory() => controller;

	/**
		Whether the processor is little endian.
	*/
	abstract @property bool isLittleEndian();

	/**
		The virtual CPU's program counter.
	*/
	abstract @property ref uint programCounter();

	/**
		Loads a module into the CPU's address space.

		Params:
			mod = The module to load.
	*/
	abstract void load(Module mod);

	/**
		Executes a single CPU step.
	
		Returns:
			Whether a valid instruction was executed.
	*/
	abstract bool step();

	/**
		Runs the CPU from the given address until it
		returns to address 0.

		Params:
			addr = The address of the function to execute.

		Returns:
			The values of all the general purpose registers at the
			end of execution.
	*/
	abstract ulong[] eval(uint addr);

	/**
		Gets a reference to the data of a general purpose
		register.

		Params:
			i = The index of the register.

		Returns:
			A reference to the GPR register's data.
	*/
	abstract ref int GPR(ubyte i);

	/**
		Gets a reference to the data of a floating point
		register.

		Params:
			i = The index of the register.

		Returns:
			A reference to the FPR register's data.
	*/
	abstract ref float FPR(ubyte i);

	/**
		Adds a device to the CPU's memory map.

		Params:
			device = The device to add.
	*/
	final void addDevice(DMADevice device) {
		controller.attachDevice(device);
	}
}

/**
	An instruction queue, used by a CPU to enqueue instructions for
	delay slots and pipelines.
*/
struct InstructionQueue {
private:
	uint[16] queueElements;
	uint ptr;

public:

	/**
		The length of the current queue.
	*/
	@property uint length() => ptr;

	/**
		Gets the next instruction in the stream.
	*/
	uint next() {
		return queueElements[--ptr];
	}

	/**
		Adds instruction to the queue.

		Params:
			instr = The instruction to add.
	*/
	void add(uint instr) {
		queueElements[ptr++] = instr;
	}

	/**
		Resets the instruction queue.
	*/
	void reset() {
		this.ptr = 0;
	}
}

/**
	Registered virtual CPUs
*/
__gshared TypeRegistry!(CPU, uint) CPUs;

/**
	Creates the given CPU
	
	Params:
		cpu = 			The name of the CPU family to create.
		memorySize =	The size of the main memory.
*/
CPU createCPU(string cpu, uint memorySize) {
	return CPUs.create(cpu, memorySize);
}

/**
	Gets all the registered virtual CPUs with the emulation
	engine.

	Returns:
		The registered types.
*/
auto getCPUs() {
	return CPUs.registeredTypes;
}

/**
	Gets the names of all of the registered 
	virtual CPUs with the emulation engine.

	Returns:
		The names of the registered CPUs.
*/
string[] getCPUNames() {
	string[] result;
	foreach(cpu; CPUs.registeredTypes)
		result ~= cpu.name;
	return result;
}

/**
	Gets whether a CPU with the following name is registered
	with minish.

	Params:
		name = The name to look up.

	Returns:
		$(D true) if the CPU is valid,
		$(D false) otherwise.
*/
bool hasCPU(string name) {
	foreach(cpu; CPUs.registeredTypes) {
		if (cpu.name == name)
			return true;
	}
	return false;
}