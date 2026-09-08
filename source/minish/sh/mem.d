module minish.sh.mem;
import minish.mem;

enum P0ADDR = 0x00000000u;
enum P1ADDR = 0x80000000u;
enum P2ADDR = 0xA0000000u;
enum P3ADDR = 0xC0000000u;
enum P4ADDR = 0xE0000000u;

/**
	SH1-4 Memory Unit.
*/
class SHMemory : MemoryController {
private:
	ubyte[] memory;

	// 64 megabytes of control register data
	ubyte[67_108_863] ctrlregs;

	uint toP0Area(uint addr) {
		if (addr >= P4ADDR)
			return P4ADDR-addr;
		else if (addr >= P3ADDR)
			return P3ADDR-addr;
		else if (addr >= P2ADDR)
			return P2ADDR-addr;
		else if (addr >= P1ADDR)
			return P1ADDR-addr;
		else
			return addr;
	}
	uint getPArea(uint addr) {
		if (addr >= P4ADDR)
			return P4ADDR;
		else if (addr >= P3ADDR)
			return P3ADDR;
		else if (addr >= P2ADDR)
			return P2ADDR;
		else if (addr >= P1ADDR)
			return P1ADDR;
		else
			return P0ADDR;
	}

	uint translateAddr(uint addr) { return toP0Area(addr) % memory.length; }
	void* getAddress(uint addr) {

		// Control Registers
		if (addr >= 0xFC000000)
			return cast(void*)&ctrlregs[addr-0xFC000000];

		// Translate from P1+ to P0 area.
		addr = translateAddr(addr);

		// Normal addresses.
		if (addr < memory.length)
			return cast(void*)&memory[addr];
		return null;
	}

protected:

	/**
		Reads data from the given address.

		Params:
			addr = 		The address to read.
			length =	The length of the data.

		Returns:
			The data at the address.
	*/
	override
	void[] onRead(uint addr, uint length) {
		return this.getAddress(addr)[0..length];
	}

	/**
		Write the given data to the given address in
		memory.

		Params:
			addr = The address to write
			data = The data to write.
	*/
	override
	void onWrite(uint addr, void[] data) {
		this.getAddress(addr)[0..data.length] = data[0..$];
	}

public:

	/**
		Gets whether the given address is in DMA range.

		Params:
			addr = The address to check

		Returns:
			$(D true) if the address is in DMA range,
			$(D false) otherwise.
	*/
	override
	bool isInDMARange(uint addr) {
		foreach(dev; devices)
			if (dev.respondsToAddress(addr))
				return true;

		return false;
	}

	/**
		Gets whether a buffer of the given size will fit at the 
		given address.

		Params:
			addr = 		Address the buffer would be loaded at.
			length = 	Size of buffer in bytes.

		Returns:
			$(D true) if the buffer fits,
			$(D false) otherwise.
	*/
	override
	bool doesBufferFit(uint addr, uint length) {
		
		// Cross area borders.
		if (getPArea(addr) != getPArea(addr+length))
			return false;

		addr = translateAddr(addr);
		return addr+length < memory.length;
	}

	/**
		Constructs a new SH memory controller

		Params:
			memSize = 	The size of main memory.
			hasMMU = 	Whether a MMU is present.
	*/
	this(uint memSize) {
		this.memory = new ubyte[memSize];
	}
}