/* 
 *  This file is part of the ScaleGraph project (http://scalegraph.org).
 * 
 *  This file is licensed to You under the Eclipse Public License (EPL);
 *  You may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *      http://www.opensource.org/licenses/eclipse-1.0.php
 * 
 *  (C) Copyright ScaleGraph Team 2011-2016.
 */

#ifndef __ORG_SCALEGRAPH_PYTHON_NATIVEPYOBJECT_H
#define __ORG_SCALEGRAPH_PYTHON_NATIVEPYOBJECT_H

#include <Python.h>
#include <x10rt.h>

namespace org { namespace scalegraph { namespace python {

struct NativePyObject {
  public:
    RTT_H_DECLS_CLASS;

    PyObject*   FMGL(pointer);

    NativePyObject() {}

    static NativePyObject _make();
    void _constructor();
    NativePyObject* operator->() { return this; }

    void incref() {
        Py_INCREF(FMGL(pointer));
    }

    void xincref() {
        Py_XINCREF(FMGL(pointer));
    }

    void decref() {
        Py_DECREF(FMGL(pointer));
    }

    void xdecref() {
        Py_XDECREF(FMGL(pointer));
    }

    void clear() {
        Py_CLEAR(FMGL(pointer));
    }

	// Serialization
	static void _serialize(NativePyObject this_, x10aux::serialization_buffer& buf) {
		assert (false);
	}
	static NativePyObject _deserializer(x10aux::deserialization_buffer& buf) {
		assert (false);
	}
};
            
}}} // namespace org { namespace scalegraph { namespace python {

#endif // __ORG_SCALEGRAPH_PYTHON_NATIVEPYOBJECT_H
