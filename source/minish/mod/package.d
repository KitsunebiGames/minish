module minish.mod;
import std.file : read;

public import minish.mod.elf;

/**
	A module, loadable code from a file.
*/
abstract class Module {
public:

	/**
		Whether the module is little endian.
	*/
	abstract @property bool isLittleEndian();

	/**
		Segments that can be loaded from the module.
	*/
	abstract @property Segment[] segments();

	/**
		The entrypoint symbol of the module, if any.
	*/
	abstract @property Symbol entrySymbol();

	/**
		Finds a symbol by its virtual address.

		Params:
			addr = The virtual address of the symbol.

		Returns:
			A filled out $(D Symbol) on success,
			empty symbol otherwise.
	*/
	abstract Symbol findSymbol(uint addr);

	/**
		Gets a symbol from the module.

		Params:
			name =	The name of the symbol to get.

		Returns:
			A symbol.
	*/
	abstract Symbol findSymbol(string name);

	/**
		Load module from file.

		Params:
			file = The file to load.

		Returns:
			A $(D Module) on success,
			$(D null) on failure.
	*/
	static Module load(string file) {
		ubyte[] data = cast(ubyte[])read(file);
		if (data.isELF())
			return new ELFModule(data);
		return null;
	}
}

/**
	A symbol in a module.
*/
struct Symbol {

	/**
		Name of the symbol.
	*/
	string name;

	/**
		Virtual address of the symbol.
	*/
	uint vaddr;
}

/**
	A loadable segment.
*/
struct Segment {

	/**
		Virtual address to load the section at
	*/
	uint vaddr;

	/**
		Data to load.
	*/
	void[] data;
}