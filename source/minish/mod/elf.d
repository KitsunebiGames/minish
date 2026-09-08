module minish.mod.elf;
import minish.mod;
import minish.core.endian;
import core.sys.elf;
import std.string : fromStringz;

/**
	An ELF Module
*/
class ELFModule : Module {
private:
	void* imageBase;
	Elf32_Ehdr* header;
	Segment[] loadable;
	Symbol entry;
	bool el;

	// Symbol resolution
	Elf32_Shdr*[] 	stab;
	Elf32_Sym[] 	symtab;
	const(char)*	strtab;

	// Loads the ELF buffer.
	void load(ubyte[] buffer) {
		this.imageBase = buffer.ptr;
		this.header = (cast(ubyte[])buffer).getELFHeader();
		this.el = header.isLittleEndian();

		if (!header)
			throw new Exception("Not a 32-bit ELF file!");

		if (header.e_machine.toNativeEndian(el) != EM_SH)
			throw new Exception("Not a SuperH ELF file!");

		this.loadSymbolTable();
		this.loadProgramTable();

		uint e_entry = header.e_entry.toNativeEndian(el);
		if (e_entry != 0)
			this.entry = this.findSymbol(e_entry);
	}

	void loadSymbolTable() {
		this.stab = header.getSectionHeaders(el);
		uint e_shstrndx = 	header.e_shstrndx.toNativeEndian(el);
		foreach(i, shdr; stab) {
			uint sh_offset = 	shdr.sh_offset.toNativeEndian(el);
			uint sh_size = 		shdr.sh_size.toNativeEndian(el);
			uint sh_entsize = 	shdr.sh_entsize.toNativeEndian(el);
			uint sh_type = 		shdr.sh_type.toNativeEndian(el);

			// We don't need section names.
			if (i == e_shstrndx)
				continue;

			switch(sh_type) {
				case SHT_SYMTAB:
					symtab ~= (cast(Elf32_Sym*)(imageBase+sh_offset))[0..sh_size/sh_entsize];
					break;

				case SHT_STRTAB:
					strtab = (cast(const(char)*)imageBase+sh_offset);
					break;

				default:
					break;
			}
		}
	}

	void loadProgramTable() {
		auto phdrs = header.getProgramHeaders(el);
		foreach(phdr; phdrs) {
			uint p_filesz = phdr.p_filesz.toNativeEndian(el);
			uint p_offset = phdr.p_offset.toNativeEndian(el);
			uint p_vaddr = phdr.p_vaddr.toNativeEndian(el);
			uint p_type = phdr.p_type.toNativeEndian(el);

			switch(p_type & PN_XNUM) {
				default: break;
				case PT_LOAD:
					loadable ~= Segment(
						vaddr: p_vaddr,
						data: (cast(ubyte*)(imageBase+p_offset))[0..p_filesz]
					);
					break;
			}
		}
	}

public:

	/**
		Creates a new ELF module.

		Params:
			buffer = The buffer to load the ELF file from.
	*/
	this(ubyte[] buffer) {
		this.load(buffer);
	}

	/**
		Whether the module is little endian.
	*/
	override @property bool isLittleEndian() => el;

	/**
		Segments that can be loaded from the module.
	*/
	override @property Segment[] segments() => loadable;

	/**
		The entrypoint symbol of the module.
	*/
	override @property Symbol entrySymbol() => entry;

	/**
		Finds a symbol by its virtual address.

		Params:
			addr = The virtual address of the symbol.

		Returns:
			A filled out $(D Symbol) on success,
			empty symbol otherwise.
	*/
	override Symbol findSymbol(uint addr) {
		foreach(sym; symtab) {
			uint st_value = sym.st_value.toNativeEndian(el);
			uint st_name = sym.st_name.toNativeEndian(el);
			string symname;

			if (st_name != STN_UNDEF)
				symname = cast(string)(&strtab[st_name]).fromStringz();

			if (st_value == addr) {
				return Symbol(
					name: symname,
					vaddr: st_value
				);
			}
		}
		return Symbol.init;
	}

	/**
		Gets a symbol from the module.

		Params:
			name =	The name of the symbol to get.

		Returns:
			A symbol.
	*/
	override Symbol findSymbol(string name) {
		if (name.length < 1)
			return Symbol.init;
		
		// Handle trailing underscore, some compilers generate
		// it.
		if (name[0] == '_')
			name = name[1..$];

		foreach(sym; symtab) {
			uint st_name = sym.st_name.toNativeEndian(el);
			uint st_value = sym.st_value.toNativeEndian(el);
			if (st_name == STN_UNDEF)
				continue;

			string symname = cast(string)(&strtab[st_name]).fromStringz();
			if (symname.length < 1)
				continue;
		
			// Handle trailing underscore, some compilers generate
			// it.
			if (symname[0] == '_')
				symname = symname[1..$];

			if (symname == name) {
				return Symbol(
					name: symname,
					vaddr: st_value
				);
			}
		}
		return Symbol.init;
	}
}

/**
	Gets whether the buffer contains an ELF file.

	Params:
		buffer = The buffer to check.
*/
bool isELF(ubyte[] buffer) {
	import std.bitmanip : swapEndian;
	uint MAGIC = *cast(uint*)(&buffer[0]);
	uint ELFMAGIC = cast(uint)ELFMAG;

	return 	MAGIC == ELFMAGIC || 
			swapEndian(MAGIC) == ELFMAGIC;
}




//
//					IMPLEMENTATION DETAILS
//
private:

/**
	Gets the 32-bit ELF header from the buffer if it's
	a 32-bit ELF file.

	Params:
		buffer = The buffer to get the header from.

	Returns:
		An ELF header or $(D null) if it's not a 32-bit
		ELF file.
*/

// Gets the 32-bit ELF header from the buffer if it's
// a 32-bit ELF file.
Elf32_Ehdr* getELFHeader(ubyte[] buffer) {
	if (buffer.isELF && buffer[4] == ELFCLASS32) {
		return cast(Elf32_Ehdr*)&buffer[0];
	}
	return null;
}

/// Gets whether the ELF file is little endian.
bool isLittleEndian(Elf32_Ehdr* hdr) {
	return hdr.e_ident[5] == 1;
}

// Gets a list of section headers.
Elf32_Shdr*[] getSectionHeaders(Elf32_Ehdr* hdr, bool el) {
	Elf32_Shdr*[] result;
	uint e_shoff = hdr.e_shoff.toNativeEndian(el);
	if (e_shoff == 0)
		return null;

	uint e_shentsize = hdr.e_shentsize.toNativeEndian(el);
	uint e_shnum = hdr.e_shnum.toNativeEndian(el);
	void* base = cast(void*)hdr;
	foreach(pi; 0..e_shnum) {
		auto shdr = 
		result ~= cast(Elf32_Shdr*)(base+e_shoff+(e_shentsize*pi));
	}
	return result;
}

// Gets a list of program headers.
Elf32_Phdr*[] getProgramHeaders(Elf32_Ehdr* hdr, bool el) {
	Elf32_Phdr*[] result;
	uint e_phoff = hdr.e_phoff.toNativeEndian(el);
	if (e_phoff == 0)
		return null;

	uint e_phentsize = hdr.e_phentsize.toNativeEndian(el);
	uint e_phnum = hdr.e_phnum.toNativeEndian(el);
	void* base = cast(void*)hdr;
	foreach(pi; 0..e_phnum) {
		result ~= cast(Elf32_Phdr*)(base+e_phoff+(e_phentsize*pi));
	}
	return result;
}