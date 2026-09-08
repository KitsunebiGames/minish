module minish.mem;

/**
	A virtual memory controller.
*/
abstract class MemoryController {
private:
	DMADevice[] devices_;

protected:

	/**
		Reads data from the given address.

		Params:
			addr = 		The address to read.
			length =	The length of the data.

		Returns:
			The data at the address.
	*/
	abstract void[] onRead(uint addr, uint length);

	/**
		Write the given data to the given address in
		memory.

		Params:
			addr = The address to write
			data = The data to write.
	*/
	abstract void onWrite(uint addr, void[] data);

public:

	/**
		The devices loaded in to the memory controller's
		address space. 
	*/
	@property DMADevice[] devices() => devices_;

	/**
		Gets whether the given address is in DMA range.

		Params:
			addr = The address to check

		Returns:
			$(D true) if the address is in DMA range,
			$(D false) otherwise.
	*/
	abstract bool isInDMARange(uint addr);

	/**
		Gets whether the given buffer fits in to the given
		address range.

		Params:
			addr = 		The start address of the range.
			length =	Length of the buffer.

		Returns:
			$(D true) if the buffer fits,
			$(D false) otherwise.
	*/
	abstract bool doesBufferFit(uint addr, uint length);

	/**
		Reads data from the given address.

		Params:
			addr = The address to read.

		Returns:
			The data at the address.
	*/
	final void[] read(uint addr, uint length) {
		if (isInDMARange(addr)) {
			foreach(DMADevice dev; devices_) {
				void[] data = dev.read(addr, length);
				if (data.length != 0)
					return data;
			}

			assert(0, "Failed to read from DMA devices!");
			return null;
		}
		return this.onRead(addr, length);
	}

	/**
		Write the given data to the given address in
		memory.

		Params:
			addr = The address to write
			data = The data to write.
	*/
	final void write(uint addr, void[] data) {
		if (isInDMARange(addr)) {
			foreach(DMADevice dev; devices_) {
				if (dev.write(addr, data))
					return;
			}

			assert(0, "Failed to write to DMA devices!");
			return;
		}

		this.onWrite(addr, data);
	}

	/**
		Attaches a device to the memory controller.

		The device's DMA ranges must not interfere
		with any existing devices attached.

		Params:
			device = The device to attach.
	*/
	void attachDevice(DMADevice device) {
		foreach(DMADevice dev; devices_) {
			if (!dev.canCoexistWith(device))
				throw new Exception(dev.name~" and "~device.name~"are incompatible!");
		}

		this.devices_ ~= device;
	}
}

/**
	A virtual device mapped in to memory.
*/
abstract class DMADevice {
public:

	/**
		Name of the device.
	*/
	abstract @property string name();

	/**
		The memory ranges the device is to be mapped to.
	*/
	abstract @property MemoryRange[] memoryRanges();

	/**
		Reads data from the given address.

		Params:
			addr = 		The address to read.
			length =	Length of the buffer.

		Returns:
			The data at the address.
	*/
	abstract void[] read(uint addr, uint length);

	/**
		Write the given data to the given address in
		memory.

		Params:
			addr = The address to write
			data = The data to write.
	
		Returns:
			$(D true) if the write succeeded,
			$(D false) otherwise.
	*/
	abstract bool write(uint addr, void[] data);

	/**
		Gets whether this DMA device can coexist with
		another device.

		Params:
			other = The other device.

		Returns:
			$(D true) if the devices can coexist,
			$(D false) otherwise.
	*/
	bool canCoexistWith(DMADevice other) {
		foreach(selfrange; memoryRanges) {
			foreach(otherrange; other.memoryRanges) {
				if (selfrange.overlapsWith(otherrange))
					return false;
			}
		}
		return true;
	}

	/**
		Gets whether this DMA device responds to the given
		memory address.

		Params:
			other = The other device.

		Returns:
			$(D true) if the devices can coexist,
			$(D false) otherwise.
	*/
	bool respondsToAddress(uint addr) {
		foreach(selfrange; memoryRanges) {
			if (selfrange.overlapsWith(addr))
				return true;
		}
		return false;
	}
}

/**
	A memory mapping.
*/
struct MemoryRange {

	/**
		Start address of a memory range.
	*/
	uint start;

	/**
		End address of a memory range.
	*/
	uint end;

	/**
		Gets whether this memory range overlaps
		with another.

		Params:
			other = The other range

		Returns:
			$(D true) if the ranges overlap,
			$(D false) otherwise.
	*/
	bool overlapsWith(MemoryRange other) {
		import std.algorithm : min, max;
		return max(this.start, other.start) < min(this.end, other.end);
	}

	/**
		Gets whether this memory range overlaps
		with another.

		Params:
			addr = The address

		Returns:
			$(D true) if the ranges overlap,
			$(D false) otherwise.
	*/
	bool overlapsWith(uint addr) {
		return addr >= start && addr <= end;
	}
}