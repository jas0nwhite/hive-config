s~(char)\W+(\w*[Uu]nused\w*)\[([0-9]+)\];.*~/* \1[\3] */ ("\2" | vectorOfN(provide(\3), byte).unit(Vector.fill(\3)(0))) ::~g
s~(unsigned int)\W+(\w*[Vv]ersion\w*);.*~/* \1 */ ("\2" | VersionNumber.codec) ::~g

s~(MYGUID)\W+(\w+);.*~/* \1 */ ("\2" | FileGUID.codec) ::~g
s~(ABF_Section)\W+(\w+);.*~/* \1 */ ("\2" | Section.codec) ::~g


s~(long long)\W+(\w+);.*~/* \1 */ ("\2" | longL(64)) ::~g

s~(unsigned ABFLONG)\W+(\w+);.*~/* \1 */ ("\2" | uint32L) ::~g
s~(ABFLONG)\W+(\w+);.*~/* \1 */ ("\2" | int32L) ::~g

s~(unsigned int)\W+(\w+);.*~/* \1 */ ("\2" | uint32L) ::~g
s~(int)\W+(\w+);.*~/* \1 */ ("\2" | int32L) ::~g

s~(unsigned short)\W+(\w+)\[([0-9]+)\];.*~/* \1[\3] */ ("\2" | vectorOfN(provide(\3), uint16L)) ::~g
s~(short)\W+(\w+)\[([0-9]+)\];.*~/* \1[\3] */ ("\2" | vectorOfN(provide(\3), short16L)) ::~g

s~(unsigned short)\W+(\w+);.*~/* \1 */ ("\2" | uint16L) ::~g
s~(short)\W+(\w+);.*~/* \1 */ ("\2" | short16L) ::~g

s~(unsigned char)\W+(\w+)\[([0-9]+)\];.*~/* \1[\3] */ ("\2" | vectorOfN(provide(\3), ushort8)) ::~g
s~(char)\W+(\w+)\[([0-9]+)\];.*~/* \1[\3] */ ("\2" | vectorOfN(provide(\3), byte)) ::~g

s~(unsigned char)\W+(\w+);.*~/* \1 */ ("\2" | ushort8) ::~g
s~(char)\W+(\w+);.*~/* \1 */ ("\2" | byte) ::~g

s~(float)\W+(\w+)\[([0-9]+)\];.*~/* \1[\3] */ ("\2" | vectorOfN(provide(\3), floatL)) ::~g
s~(float)\W+(\w+);.*~/* \1 */ ("\2" | floatL) ::~g

s~(bool)\W+(\w+);.*~/* \1 */ ("\2" | bool(8)) ::~g

s~(\w+)\W+(\w+);.*~/* \1 */ ("\2" | \1.codec) ::~g
