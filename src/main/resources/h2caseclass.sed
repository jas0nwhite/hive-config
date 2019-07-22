s~(char)\W+(\w*[Uu]nused\w*)\[([0-9]+)\];~// \2: Vector[Byte],~g
s~(unsigned int)\W+(\w*[Vv]ersion\w*);~\2: VersionNumber,~g

s~(MYGUID)\W+(\w+);~\2: FileGUID,~g
s~(ABF_Section)\W+(\w+);~\2: Section,~g


s~(long long)\W+(\w+);~\2: Long,~g

s~(unsigned ABFLONG)\W+(\w+);~\2: Long,~g
s~(ABFLONG)\W+(\w+);~\2: Int,~g

s~(unsigned int)\W+(\w+);~\2: Long,~g
s~(int)\W+(\w+);~\2: Int,~g

s~(unsigned short)\W+(\w+)\[([0-9]+)\];~\2: Vector[Int],~g
s~(short)\W+(\w+)\[([0-9]+)\];~\2: Vector[Short],~g

s~(unsigned short)\W+(\w+);~\2: Int,~g
s~(short)\W+(\w+);~\2: Short,~g

s~(unsigned char)\W+(\w+)\[([0-9]+)\];~\2: Vector[Short],~g
s~(char)\W+(\w+)\[([0-9]+)\];~\2: Vector[Byte],~g

s~(unsigned char)\W+(\w+);~\2: Short,~g
s~(char)\W+(\w+);~\2: Byte,~g

s~(float)\W+(\w+)\[([0-9]+)\];~\2: Vector[Float],~g
s~(float)\W+(\w+);~\2: Float,~g

s~(bool)\W+(\w+);~\2: Boolean,~g

s~(\w+)\W+(\w+);~\2: \1,~g
