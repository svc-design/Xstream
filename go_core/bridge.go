package main

/*
#include <stdlib.h>
*/
import "C"
import "unsafe"

// FreeCString frees C strings returned from Go.
//
//export FreeCString
func FreeCString(str *C.char) {
	C.free(unsafe.Pointer(str))
}

func main() {}
