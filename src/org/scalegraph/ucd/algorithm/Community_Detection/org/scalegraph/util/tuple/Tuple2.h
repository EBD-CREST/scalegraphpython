#ifndef __ORG_SCALEGRAPH_UTIL_TUPLE_TUPLE2_H
#define __ORG_SCALEGRAPH_UTIL_TUPLE_TUPLE2_H

#include <x10rt.h>


#define X10_LANG_ANY_H_NODEPS
#include <x10/lang/Any.h>
#undef X10_LANG_ANY_H_NODEPS
#define X10_LANG_ANY_H_NODEPS
#include <x10/lang/Any.h>
#undef X10_LANG_ANY_H_NODEPS
namespace x10 { namespace lang { 
class String;
} } 
namespace x10 { namespace compiler { 
class Native;
} } 
namespace x10 { namespace compiler { 
class NonEscaping;
} } 
namespace x10 { namespace lang { 
class Int;
} } 
namespace x10 { namespace lang { 
class Boolean;
} } 
namespace org { namespace scalegraph { namespace util { namespace tuple { 

template<class TPMGL(T1), class TPMGL(T2)> class Tuple2   {
    public:
    RTT_H_DECLS_STRUCT
    
    org::scalegraph::util::tuple::Tuple2<TPMGL(T1), TPMGL(T2)>* operator->() { return this; }
    
    static x10aux::itable_entry _itables[2];
    
    x10aux::itable_entry* _getITables() { return _itables; }
    
    static x10::lang::Any::itable<org::scalegraph::util::tuple::Tuple2<TPMGL(T1), TPMGL(T2)> > _itable_0;
    
    static x10aux::itable_entry _iboxitables[2];
    
    x10aux::itable_entry* _getIBoxITables() { return _iboxitables; }
    
    static org::scalegraph::util::tuple::Tuple2<TPMGL(T1), TPMGL(T2)> _alloc(){org::scalegraph::util::tuple::Tuple2<TPMGL(T1), TPMGL(T2)> t; return t; }
    
    TPMGL(T1) FMGL(val1);
    
    TPMGL(T2) FMGL(val2);
    
    void _constructor(TPMGL(T1) val1, TPMGL(T2) val2);
    
    static org::scalegraph::util::tuple::Tuple2<TPMGL(T1), TPMGL(T2)> _make(
             TPMGL(T1) val1, TPMGL(T2) val2);
    
    TPMGL(T1) get1();
    TPMGL(T2) get2();
    x10::lang::String* toString();
    x10::lang::String* typeName();
    x10_int hashCode();
    x10_boolean equals(x10::lang::Any* other);
    x10_boolean equals(org::scalegraph::util::tuple::Tuple2<TPMGL(T1), TPMGL(T2)> other);
    x10_boolean _struct_equals(x10::lang::Any* other);
    x10_boolean _struct_equals(org::scalegraph::util::tuple::Tuple2<TPMGL(T1), TPMGL(T2)> other);
    org::scalegraph::util::tuple::Tuple2<TPMGL(T1), TPMGL(T2)> org__scalegraph__util__tuple__Tuple2____this__org__scalegraph__util__tuple__Tuple2(
      );
    
    static void _serialize(org::scalegraph::util::tuple::Tuple2<TPMGL(T1), TPMGL(T2)> this_, x10aux::serialization_buffer& buf);
    
    static org::scalegraph::util::tuple::Tuple2<TPMGL(T1), TPMGL(T2)> _deserialize(x10aux::deserialization_buffer& buf) {
        org::scalegraph::util::tuple::Tuple2<TPMGL(T1), TPMGL(T2)> this_;
        this_->_deserialize_body(buf);
        return this_;
    }
    
    void _deserialize_body(x10aux::deserialization_buffer& buf);
    
};

template<class TPMGL(T1), class TPMGL(T2)> x10aux::RuntimeType org::scalegraph::util::tuple::Tuple2<TPMGL(T1), TPMGL(T2)>::rtt;
template<class TPMGL(T1), class TPMGL(T2)> void org::scalegraph::util::tuple::Tuple2<TPMGL(T1), TPMGL(T2)>::_initRTT() {
    const x10aux::RuntimeType *canonical = x10aux::getRTT<org::scalegraph::util::tuple::Tuple2<void, void> >();
    if (rtt.initStageOne(canonical)) return;
    const x10aux::RuntimeType* parents[2] = { x10aux::getRTT<x10::lang::Any>(), x10aux::getRTT<x10::lang::Any>()};
    const x10aux::RuntimeType* params[2] = { x10aux::getRTT<TPMGL(T1)>(), x10aux::getRTT<TPMGL(T2)>()};
    x10aux::RuntimeType::Variance variances[2] = { x10aux::RuntimeType::invariant, x10aux::RuntimeType::invariant};
    const char *baseName = "org.scalegraph.util.tuple.Tuple2";
    rtt.initStageTwo(baseName, x10aux::RuntimeType::struct_kind, 2, parents, 2, params, variances);
}

template <> class Tuple2<void, void> {
    public:
    static x10aux::RuntimeType rtt;
    static const x10aux::RuntimeType* getRTT() { return & rtt; }
    
};

} } } } 
#endif // ORG_SCALEGRAPH_UTIL_TUPLE_TUPLE2_H

namespace org { namespace scalegraph { namespace util { namespace tuple { 
template<class TPMGL(T1), class TPMGL(T2)> class Tuple2;
} } } } 

#ifndef ORG_SCALEGRAPH_UTIL_TUPLE_TUPLE2_H_NODEPS
#define ORG_SCALEGRAPH_UTIL_TUPLE_TUPLE2_H_NODEPS
#include <x10/lang/Any.h>
#include <x10/lang/String.h>
#include <x10/compiler/Native.h>
#include <x10/compiler/NonEscaping.h>
#include <x10/lang/Int.h>
#include <x10/lang/Boolean.h>
#ifndef ORG_SCALEGRAPH_UTIL_TUPLE_TUPLE2_H_GENERICS
#define ORG_SCALEGRAPH_UTIL_TUPLE_TUPLE2_H_GENERICS
#endif // ORG_SCALEGRAPH_UTIL_TUPLE_TUPLE2_H_GENERICS
#ifndef ORG_SCALEGRAPH_UTIL_TUPLE_TUPLE2_H_IMPLEMENTATION
#define ORG_SCALEGRAPH_UTIL_TUPLE_TUPLE2_H_IMPLEMENTATION
#include <org/scalegraph/util/tuple/Tuple2.h>

namespace org { namespace scalegraph { namespace util { namespace tuple { 
template<class TPMGL(T1), class TPMGL(T2)> class Tuple2_ibox0 : public x10::lang::IBox<org::scalegraph::util::tuple::Tuple2<TPMGL(T1), TPMGL(T2)> > {
public:
    static x10::lang::Any::itable<Tuple2_ibox0<TPMGL(T1), TPMGL(T2)> > itable;
    x10_boolean equals(x10::lang::Any* arg0) {
        return this->value->equals(arg0);
    }
    x10_int hashCode() {
        return this->value->hashCode();
    }
    x10::lang::String* toString() {
        return this->value->toString();
    }
    x10::lang::String* typeName() {
        return this->value->typeName();
    }
    
};
template<class TPMGL(T1), class TPMGL(T2)> x10::lang::Any::itable<Tuple2_ibox0<TPMGL(T1), TPMGL(T2)> >  Tuple2_ibox0<TPMGL(T1), TPMGL(T2)>::itable(&Tuple2_ibox0<TPMGL(T1), TPMGL(T2)>::equals, &Tuple2_ibox0<TPMGL(T1), TPMGL(T2)>::hashCode, &Tuple2_ibox0<TPMGL(T1), TPMGL(T2)>::toString, &Tuple2_ibox0<TPMGL(T1), TPMGL(T2)>::typeName);
} } } } 
template<class TPMGL(T1), class TPMGL(T2)> x10::lang::Any::itable<org::scalegraph::util::tuple::Tuple2<TPMGL(T1), TPMGL(T2)> >  org::scalegraph::util::tuple::Tuple2<TPMGL(T1), TPMGL(T2)>::_itable_0(&org::scalegraph::util::tuple::Tuple2<TPMGL(T1), TPMGL(T2)>::equals, &org::scalegraph::util::tuple::Tuple2<TPMGL(T1), TPMGL(T2)>::hashCode, &org::scalegraph::util::tuple::Tuple2<TPMGL(T1), TPMGL(T2)>::toString, &org::scalegraph::util::tuple::Tuple2<TPMGL(T1), TPMGL(T2)>::typeName);
template<class TPMGL(T1), class TPMGL(T2)> x10aux::itable_entry org::scalegraph::util::tuple::Tuple2<TPMGL(T1), TPMGL(T2)>::_itables[2] = {x10aux::itable_entry(&x10aux::getRTT<x10::lang::Any>, &org::scalegraph::util::tuple::Tuple2<TPMGL(T1), TPMGL(T2)>::_itable_0), x10aux::itable_entry(NULL, (void*)x10aux::getRTT<org::scalegraph::util::tuple::Tuple2<TPMGL(T1), TPMGL(T2)> >())};
template<class TPMGL(T1), class TPMGL(T2)> x10aux::itable_entry org::scalegraph::util::tuple::Tuple2<TPMGL(T1), TPMGL(T2)>::_iboxitables[2] = {x10aux::itable_entry(&x10aux::getRTT<x10::lang::Any>, &org::scalegraph::util::tuple::Tuple2_ibox0<TPMGL(T1), TPMGL(T2)>::itable), x10aux::itable_entry(NULL, (void*)x10aux::getRTT<org::scalegraph::util::tuple::Tuple2<TPMGL(T1), TPMGL(T2)> >())};

//#line 14 "/nfs/home/vinodmadaan/ScaleGraph_Stable_Version/scalegraph/src/org/scalegraph/util/tuple/Tuple2.x10": x10.ast.X10FieldDecl_c

//#line 15 "/nfs/home/vinodmadaan/ScaleGraph_Stable_Version/scalegraph/src/org/scalegraph/util/tuple/Tuple2.x10": x10.ast.X10FieldDecl_c

//#line 17 "/nfs/home/vinodmadaan/ScaleGraph_Stable_Version/scalegraph/src/org/scalegraph/util/tuple/Tuple2.x10": x10.ast.X10ConstructorDecl_c
template<class TPMGL(T1), class TPMGL(T2)> void org::scalegraph::util::tuple::Tuple2<TPMGL(T1), TPMGL(T2)>::_constructor(
                                             TPMGL(T1) val1, TPMGL(T2) val2) {
    
    //#line 17 "/nfs/home/vinodmadaan/ScaleGraph_Stable_Version/scalegraph/src/org/scalegraph/util/tuple/Tuple2.x10": x10.ast.AssignPropertyCall_c
    
    //#line 18 "/nfs/home/vinodmadaan/ScaleGraph_Stable_Version/scalegraph/src/org/scalegraph/util/tuple/Tuple2.x10": Eval of x10.ast.X10FieldAssign_c
    (*this)->FMGL(val1) = val1;
    
    //#line 19 "/nfs/home/vinodmadaan/ScaleGraph_Stable_Version/scalegraph/src/org/scalegraph/util/tuple/Tuple2.x10": Eval of x10.ast.X10FieldAssign_c
    (*this)->FMGL(val2) = val2;
}
template<class TPMGL(T1), class TPMGL(T2)> org::scalegraph::util::tuple::Tuple2<TPMGL(T1), TPMGL(T2)> org::scalegraph::util::tuple::Tuple2<TPMGL(T1), TPMGL(T2)>::_make(
                                             TPMGL(T1) val1,
                                             TPMGL(T2) val2)
{
    org::scalegraph::util::tuple::Tuple2<TPMGL(T1), TPMGL(T2)> this_; 
    this_->_constructor(val1, val2);
    return this_;
}



//#line 22 "/nfs/home/vinodmadaan/ScaleGraph_Stable_Version/scalegraph/src/org/scalegraph/util/tuple/Tuple2.x10": x10.ast.X10MethodDecl_c
template<class TPMGL(T1), class TPMGL(T2)> TPMGL(T1) org::scalegraph::util::tuple::Tuple2<TPMGL(T1), TPMGL(T2)>::get1(
  ) {
    
    //#line 22 "/nfs/home/vinodmadaan/ScaleGraph_Stable_Version/scalegraph/src/org/scalegraph/util/tuple/Tuple2.x10": x10.ast.X10Return_c
    return (*this)->FMGL(val1);
    
}

//#line 23 "/nfs/home/vinodmadaan/ScaleGraph_Stable_Version/scalegraph/src/org/scalegraph/util/tuple/Tuple2.x10": x10.ast.X10MethodDecl_c
template<class TPMGL(T1), class TPMGL(T2)> TPMGL(T2) org::scalegraph::util::tuple::Tuple2<TPMGL(T1), TPMGL(T2)>::get2(
  ) {
    
    //#line 23 "/nfs/home/vinodmadaan/ScaleGraph_Stable_Version/scalegraph/src/org/scalegraph/util/tuple/Tuple2.x10": x10.ast.X10Return_c
    return (*this)->FMGL(val2);
    
}

//#line 25 "/nfs/home/vinodmadaan/ScaleGraph_Stable_Version/scalegraph/src/org/scalegraph/util/tuple/Tuple2.x10": x10.ast.X10MethodDecl_c
template<class TPMGL(T1), class TPMGL(T2)> x10::lang::String*
  org::scalegraph::util::tuple::Tuple2<TPMGL(T1), TPMGL(T2)>::toString(
  ) {
    
    //#line 26 "/nfs/home/vinodmadaan/ScaleGraph_Stable_Version/scalegraph/src/org/scalegraph/util/tuple/Tuple2.x10": x10.ast.X10Return_c
    return x10::lang::String::__plus(x10::lang::String::__plus(x10::lang::String::__plus(x10::lang::String::__plus(x10aux::makeStringLit("Tuple2("), (*this)->
                                                                                                                                                       FMGL(val1)), x10aux::makeStringLit(",")), (*this)->
                                                                                                                                                                                                   FMGL(val2)), x10aux::makeStringLit(")"));
    
}

//#line 13 "/nfs/home/vinodmadaan/ScaleGraph_Stable_Version/scalegraph/src/org/scalegraph/util/tuple/Tuple2.x10": x10.ast.X10MethodDecl_c
template<class TPMGL(T1), class TPMGL(T2)> x10::lang::String*
  org::scalegraph::util::tuple::Tuple2<TPMGL(T1), TPMGL(T2)>::typeName(
  ){
    return x10aux::type_name((*this));
}

//#line 13 "/nfs/home/vinodmadaan/ScaleGraph_Stable_Version/scalegraph/src/org/scalegraph/util/tuple/Tuple2.x10": x10.ast.X10MethodDecl_c
template<class TPMGL(T1), class TPMGL(T2)> x10_int org::scalegraph::util::tuple::Tuple2<TPMGL(T1), TPMGL(T2)>::hashCode(
  ) {
    
    //#line 13 "/nfs/home/vinodmadaan/ScaleGraph_Stable_Version/scalegraph/src/org/scalegraph/util/tuple/Tuple2.x10": x10.ast.X10LocalDecl_c
    x10_int result = ((x10_int)1);
    
    //#line 13 "/nfs/home/vinodmadaan/ScaleGraph_Stable_Version/scalegraph/src/org/scalegraph/util/tuple/Tuple2.x10": Eval of x10.ast.X10LocalAssign_c
    result = ((x10_int) ((((x10_int) ((((x10_int)8191)) * (result)))) + (x10aux::hash_code((*this)->
                                                                                             FMGL(val1)))));
    
    //#line 13 "/nfs/home/vinodmadaan/ScaleGraph_Stable_Version/scalegraph/src/org/scalegraph/util/tuple/Tuple2.x10": Eval of x10.ast.X10LocalAssign_c
    result = ((x10_int) ((((x10_int) ((((x10_int)8191)) * (result)))) + (x10aux::hash_code((*this)->
                                                                                             FMGL(val2)))));
    
    //#line 13 "/nfs/home/vinodmadaan/ScaleGraph_Stable_Version/scalegraph/src/org/scalegraph/util/tuple/Tuple2.x10": x10.ast.X10Return_c
    return result;
    
}

//#line 13 "/nfs/home/vinodmadaan/ScaleGraph_Stable_Version/scalegraph/src/org/scalegraph/util/tuple/Tuple2.x10": x10.ast.X10MethodDecl_c
template<class TPMGL(T1), class TPMGL(T2)> x10_boolean org::scalegraph::util::tuple::Tuple2<TPMGL(T1), TPMGL(T2)>::equals(
  x10::lang::Any* other) {
    
    //#line 13 "/nfs/home/vinodmadaan/ScaleGraph_Stable_Version/scalegraph/src/org/scalegraph/util/tuple/Tuple2.x10": x10.ast.X10If_c
    if (!(x10aux::instanceof<org::scalegraph::util::tuple::Tuple2<TPMGL(T1), TPMGL(T2)> >(other)))
    {
        
        //#line 13 "/nfs/home/vinodmadaan/ScaleGraph_Stable_Version/scalegraph/src/org/scalegraph/util/tuple/Tuple2.x10": x10.ast.X10Return_c
        return false;
        
    }
    
    //#line 13 "/nfs/home/vinodmadaan/ScaleGraph_Stable_Version/scalegraph/src/org/scalegraph/util/tuple/Tuple2.x10": x10.ast.X10Return_c
    return (*this)->org::scalegraph::util::tuple::Tuple2<TPMGL(T1), TPMGL(T2)>::equals(
             x10aux::class_cast<org::scalegraph::util::tuple::Tuple2<TPMGL(T1), TPMGL(T2)> >(other));
    
}

//#line 13 "/nfs/home/vinodmadaan/ScaleGraph_Stable_Version/scalegraph/src/org/scalegraph/util/tuple/Tuple2.x10": x10.ast.X10MethodDecl_c
template<class TPMGL(T1), class TPMGL(T2)> x10_boolean org::scalegraph::util::tuple::Tuple2<TPMGL(T1), TPMGL(T2)>::equals(
  org::scalegraph::util::tuple::Tuple2<TPMGL(T1), TPMGL(T2)> other) {
    
    //#line 13 "/nfs/home/vinodmadaan/ScaleGraph_Stable_Version/scalegraph/src/org/scalegraph/util/tuple/Tuple2.x10": x10.ast.X10Return_c
    return (x10aux::struct_equals((*this)->FMGL(val1), other->
                                                         FMGL(val1))) &&
    (x10aux::struct_equals((*this)->FMGL(val2), other->FMGL(val2)));
    
}

//#line 13 "/nfs/home/vinodmadaan/ScaleGraph_Stable_Version/scalegraph/src/org/scalegraph/util/tuple/Tuple2.x10": x10.ast.X10MethodDecl_c
template<class TPMGL(T1), class TPMGL(T2)> x10_boolean org::scalegraph::util::tuple::Tuple2<TPMGL(T1), TPMGL(T2)>::_struct_equals(
  x10::lang::Any* other) {
    
    //#line 13 "/nfs/home/vinodmadaan/ScaleGraph_Stable_Version/scalegraph/src/org/scalegraph/util/tuple/Tuple2.x10": x10.ast.X10If_c
    if (!(x10aux::instanceof<org::scalegraph::util::tuple::Tuple2<TPMGL(T1), TPMGL(T2)> >(other)))
    {
        
        //#line 13 "/nfs/home/vinodmadaan/ScaleGraph_Stable_Version/scalegraph/src/org/scalegraph/util/tuple/Tuple2.x10": x10.ast.X10Return_c
        return false;
        
    }
    
    //#line 13 "/nfs/home/vinodmadaan/ScaleGraph_Stable_Version/scalegraph/src/org/scalegraph/util/tuple/Tuple2.x10": x10.ast.X10Return_c
    return (*this)->org::scalegraph::util::tuple::Tuple2<TPMGL(T1), TPMGL(T2)>::_struct_equals(
             x10aux::class_cast<org::scalegraph::util::tuple::Tuple2<TPMGL(T1), TPMGL(T2)> >(other));
    
}

//#line 13 "/nfs/home/vinodmadaan/ScaleGraph_Stable_Version/scalegraph/src/org/scalegraph/util/tuple/Tuple2.x10": x10.ast.X10MethodDecl_c
template<class TPMGL(T1), class TPMGL(T2)> x10_boolean org::scalegraph::util::tuple::Tuple2<TPMGL(T1), TPMGL(T2)>::_struct_equals(
  org::scalegraph::util::tuple::Tuple2<TPMGL(T1), TPMGL(T2)> other) {
    
    //#line 13 "/nfs/home/vinodmadaan/ScaleGraph_Stable_Version/scalegraph/src/org/scalegraph/util/tuple/Tuple2.x10": x10.ast.X10Return_c
    return (x10aux::struct_equals((*this)->FMGL(val1), other->
                                                         FMGL(val1))) &&
    (x10aux::struct_equals((*this)->FMGL(val2), other->FMGL(val2)));
    
}

//#line 13 "/nfs/home/vinodmadaan/ScaleGraph_Stable_Version/scalegraph/src/org/scalegraph/util/tuple/Tuple2.x10": x10.ast.X10MethodDecl_c
template<class TPMGL(T1), class TPMGL(T2)> org::scalegraph::util::tuple::Tuple2<TPMGL(T1), TPMGL(T2)>
  org::scalegraph::util::tuple::Tuple2<TPMGL(T1), TPMGL(T2)>::org__scalegraph__util__tuple__Tuple2____this__org__scalegraph__util__tuple__Tuple2(
  ) {
    
    //#line 13 "/nfs/home/vinodmadaan/ScaleGraph_Stable_Version/scalegraph/src/org/scalegraph/util/tuple/Tuple2.x10": x10.ast.X10Return_c
    return (*this);
    
}
template<class TPMGL(T1), class TPMGL(T2)> void org::scalegraph::util::tuple::Tuple2<TPMGL(T1), TPMGL(T2)>::_serialize(org::scalegraph::util::tuple::Tuple2<TPMGL(T1), TPMGL(T2)> this_, x10aux::serialization_buffer& buf) {
    buf.write(this_->FMGL(val1));
    buf.write(this_->FMGL(val2));
    
}

template<class TPMGL(T1), class TPMGL(T2)> void org::scalegraph::util::tuple::Tuple2<TPMGL(T1), TPMGL(T2)>::_deserialize_body(x10aux::deserialization_buffer& buf) {
    FMGL(val1) = buf.read<TPMGL(T1)>();
    FMGL(val2) = buf.read<TPMGL(T2)>();
}


#endif // ORG_SCALEGRAPH_UTIL_TUPLE_TUPLE2_H_IMPLEMENTATION
#endif // __ORG_SCALEGRAPH_UTIL_TUPLE_TUPLE2_H_NODEPS