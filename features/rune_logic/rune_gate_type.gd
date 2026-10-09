## Gate types used by rune circuit levels.
class_name RuneGateType
extends RefCounted


## Supported rune gate types. XOR and NAND are intentionally not implemented.
enum Type { INPUT, AND, OR, NOT, OUTPUT, EMPTY_SLOT }