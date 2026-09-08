module minish.core.endian;
import std.bitmanip;

/**
	Gets the given value as the native endian.

	Params:
		in_ = 				The input value
		isLittleEndian =	Whether the value is little endian

	Returns:
		The value with its endianness swapped.
*/
T toNativeEndian(T)(T in_, bool isLittleEndian) {
	if (isLittleEndian) {

		ubyte[T.sizeof] tmp = (cast(ubyte*)&in_)[0..T.sizeof];
		return littleEndianToNative!T(tmp);
	} else {

		ubyte[T.sizeof] tmp = (cast(ubyte*)&in_)[0..T.sizeof];
		return bigEndianToNative!T(tmp);

	}
}

/**
	Gets the given value as the native endian.

	Params:
		in_ = 				The input value
		isLittleEndian =	Whether the value is little endian

	Returns:
		The value with its endianness swapped.
*/
T toOtherEndian(T)(T in_, bool isLittleEndian) {
	if (isLittleEndian) {

		void[T.sizeof] tmp = cast(void[T.sizeof])nativeToLittleEndian(in_);
		return (cast(T[])tmp)[0];
	} else {

		void[T.sizeof] tmp = cast(void[T.sizeof])nativeToBigEndian(in_);
		return (cast(T[])tmp)[0];
	}
}