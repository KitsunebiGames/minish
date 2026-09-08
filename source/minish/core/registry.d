module minish.core.registry;
import std.traits;

/**
	A registry for types.
*/
struct TypeRegistry(T, ArgsT...) {
private:
	TypeInfo!(T, ArgsT)[string] infos_;

public:

	/**
		Names registered in the registry.
	*/
	@property string[] registeredNames() => infos_.keys;

	/**
		Types registered
	*/
	@property TypeInfo!(T, ArgsT)[] registeredTypes() => infos_.values;

	/**
		Registers a type with the registry

		Params:
			info = The type information to register.
	*/
	void register(Y)(string name, Y function(ArgsT) ctor) {
		auto ti = TypeInfo!(T, ArgsT)(
			name: name,
			create: ctor,
		);
		infos_[ti.name] = ti;
	}

	/**
		Creates a new
	*/
	T create(string name, ArgsT args) {
		return name in infos_ ? 
				infos_[name].create(args) : 
				null;
	}
}

/**
	Type information.
*/
struct TypeInfo(T, ArgsT...) {

	/**
		Name of the type.
	*/
	string name;

	/**
		Creates an instance of the type.
	*/
	T function(ArgsT) create;
	
}

mixin template RegisterType(alias registry, T, string name, alias ctorfn) {
	import core.attribute : standalone;
	import std.traits;
	import core.stdc.stdio;

	@standalone
	shared static this() @trusted {
		registry.register(name, ctorfn);
	}
}