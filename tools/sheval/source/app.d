import minish;
import std.path;
import std.conv;
import std.file;
import std.stdio;
import commandr;
import filesizes;

string getCPUForEndian(Module mod, bool littleEndian) {
	foreach(cpu; getCPUs) {
		if (mod.isLittleEndian() && cpu.name[$-1] == 'l')
			return cpu.name;
	
		if (!mod.isLittleEndian() && cpu.name[$-1] != 'l')
			return cpu.name;
	}
	return null;
}

int main(string[] args) {
	auto pargs = new Program("sheval", "1.0")
		.summary("Evaluate SuperH machine code")
		.author("Luna the Foxgirl")
		.add(new Option("m", "cpu", "The CPU to simulate").acceptsValues(getCPUNames()))
		.add(new Option("e", "entry", "The program's entry point").defaultValue("start"))
		.add(new Option(null, "memory", "Size of the address space").defaultValue("16 MiB"))
		.add(new Argument("path", "Path to ELF file to execute"))
		.parse(args);

	Module mod = Module.load(pargs.arg("path"));
	auto entry = mod.findSymbol(pargs.option("entry"));
	uint mem = cast(uint)parseFilesize(pargs.option("memory"));


	// If no CPU is selected, select the first one that matches
	// the file's endianness.
	CPU cpu;
	if (!pargs.option("cpu")) {
		cpu = createCPU(mod.getCPUForEndian(mod.isLittleEndian), mem);
	} else {
		cpu = createCPU(pargs.option("cpu"), mem);
	}

	cpu.GPR(15) = 0x0000FFFF;
	cpu.load(mod);
	writeln(cast(int)cpu.eval(entry.vaddr)[0]);
	return 0;
}
