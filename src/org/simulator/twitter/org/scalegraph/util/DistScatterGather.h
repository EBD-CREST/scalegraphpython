#ifndef __ORG_SCALEGRAPH_UTIL_DISTSCATTERGATHER_H
#define __ORG_SCALEGRAPH_UTIL_DISTSCATTERGATHER_H

#include <x10rt.h>


#define X10_LANG_ANY_H_NODEPS
#include <x10/lang/Any.h>
#undef X10_LANG_ANY_H_NODEPS
#define X10_LANG_ANY_H_NODEPS
#include <x10/lang/Any.h>
#undef X10_LANG_ANY_H_NODEPS
#define ORG_SCALEGRAPH_UTIL_TEAM2_H_NODEPS
#include <org/scalegraph/util/Team2.h>
#undef ORG_SCALEGRAPH_UTIL_TEAM2_H_NODEPS
#define ORG_SCALEGRAPH_UTIL_TEAM2_H_NODEPS
#include <org/scalegraph/util/Team2.h>
#undef ORG_SCALEGRAPH_UTIL_TEAM2_H_NODEPS
#define X10_LANG_INT_H_NODEPS
#include <x10/lang/Int.h>
#undef X10_LANG_INT_H_NODEPS
#define X10_LANG_INT_H_NODEPS
#include <x10/lang/Int.h>
#undef X10_LANG_INT_H_NODEPS
#define ORG_SCALEGRAPH_UTIL_MEMORYCHUNK_H_NODEPS
#include <org/scalegraph/util/MemoryChunk.h>
#undef ORG_SCALEGRAPH_UTIL_MEMORYCHUNK_H_NODEPS
#define ORG_SCALEGRAPH_UTIL_MEMORYCHUNK_H_NODEPS
#include <org/scalegraph/util/MemoryChunk.h>
#undef ORG_SCALEGRAPH_UTIL_MEMORYCHUNK_H_NODEPS
#define X10_LANG_INT_H_NODEPS
#include <x10/lang/Int.h>
#undef X10_LANG_INT_H_NODEPS
namespace x10 { namespace util { 
class Team;
} } 
namespace x10 { namespace lang { 
class Runtime;
} } 
namespace x10 { namespace lang { 
class Math;
} } 
namespace org { namespace scalegraph { namespace util { 
template<class TPMGL(T)> class MemoryChunk__Distributor;
} } } 
namespace x10 { namespace lang { 
class Long;
} } 
namespace x10 { namespace lang { 
class LongRange;
} } 
namespace x10 { namespace lang { 
class Boolean;
} } 
namespace x10 { namespace lang { 
class IntRange;
} } 
namespace x10 { namespace compiler { 
class Ifndef;
} } 
namespace x10 { namespace lang { 
class String;
} } 
namespace x10 { namespace compiler { 
class Native;
} } 
namespace x10 { namespace compiler { 
class NonEscaping;
} } 
namespace org { namespace scalegraph { namespace util { 

class DistScatterGather   {
    public:
    RTT_H_DECLS_STRUCT
    
    org::scalegraph::util::DistScatterGather* operator->() { return this; }
    
    static x10aux::itable_entry _itables[2];
    
    x10aux::itable_entry* _getITables() { return _itables; }
    
    static x10::lang::Any::itable<org::scalegraph::util::DistScatterGather > _itable_0;
    
    static x10aux::itable_entry _iboxitables[2];
    
    x10aux::itable_entry* _getIBoxITables() { return _iboxitables; }
    
    static org::scalegraph::util::DistScatterGather _alloc(){org::scalegraph::util::DistScatterGather t; return t; }
    
    org::scalegraph::util::Team2 FMGL(team);
    
    x10_int FMGL(maxThreads);
    
    x10_int FMGL(bufferWidth);
    
    org::scalegraph::util::MemoryChunk<x10_int> FMGL(threadCounts);
    
    org::scalegraph::util::MemoryChunk<x10_int> FMGL(threadOffsets);
    
    org::scalegraph::util::MemoryChunk<x10_int> FMGL(sendCounts);
    
    org::scalegraph::util::MemoryChunk<x10_int> FMGL(sendOffsets);
    
    org::scalegraph::util::MemoryChunk<x10_int> FMGL(recvCounts);
    
    org::scalegraph::util::MemoryChunk<x10_int> FMGL(recvOffsets);
    
    x10_int FMGL(CACHE_LINE);
    
    void _constructor(x10::util::Team* team);
    
    static org::scalegraph::util::DistScatterGather _make(x10::util::Team* team);
    
    org::scalegraph::util::MemoryChunk<x10_int> getCounts(x10_int tid);
    org::scalegraph::util::MemoryChunk<x10_int> getOffsets(x10_int tid);
    void sum();
    x10_int sendCount();
    x10_int recvCount();
    template<class TPMGL(T)> org::scalegraph::util::MemoryChunk<TPMGL(T)>
      scatter(org::scalegraph::util::MemoryChunk<TPMGL(T)> sendData);
    template<class TPMGL(T)> org::scalegraph::util::MemoryChunk<TPMGL(T)>
      gather(org::scalegraph::util::MemoryChunk<TPMGL(T)> sendData);
    template<class TPMGL(T)> void gather(org::scalegraph::util::MemoryChunk<TPMGL(T)> sendData,
                                         org::scalegraph::util::MemoryChunk<TPMGL(T)> recvData);
    x10::lang::String* typeName();
    x10::lang::String* toString();
    x10_int hashCode();
    x10_boolean equals(x10::lang::Any* other);
    x10_boolean equals(org::scalegraph::util::DistScatterGather other) {
        
        //#line 26 "/home/mukul/ScaleGraph/scalegraph/src/org/scalegraph/util/DistScatterGather.x10": x10.ast.X10Return_c
        return (x10aux::struct_equals((*this)->FMGL(team), other->
                                                             FMGL(team))) &&
        (x10aux::struct_equals((*this)->FMGL(maxThreads), other->
                                                            FMGL(maxThreads))) &&
        (x10aux::struct_equals((*this)->FMGL(bufferWidth),
                               other->FMGL(bufferWidth))) &&
        (x10aux::struct_equals((*this)->FMGL(threadCounts),
                               other->FMGL(threadCounts))) &&
        (x10aux::struct_equals((*this)->FMGL(threadOffsets),
                               other->FMGL(threadOffsets))) &&
        (x10aux::struct_equals((*this)->FMGL(sendCounts),
                               other->FMGL(sendCounts))) &&
        (x10aux::struct_equals((*this)->FMGL(sendOffsets),
                               other->FMGL(sendOffsets))) &&
        (x10aux::struct_equals((*this)->FMGL(recvCounts),
                               other->FMGL(recvCounts))) &&
        (x10aux::struct_equals((*this)->FMGL(recvOffsets),
                               other->FMGL(recvOffsets))) &&
        (x10aux::struct_equals((*this)->FMGL(CACHE_LINE),
                               other->FMGL(CACHE_LINE)));
        
    }
    x10_boolean _struct_equals(x10::lang::Any* other);
    x10_boolean _struct_equals(org::scalegraph::util::DistScatterGather other) {
        
        //#line 26 "/home/mukul/ScaleGraph/scalegraph/src/org/scalegraph/util/DistScatterGather.x10": x10.ast.X10Return_c
        return (x10aux::struct_equals((*this)->FMGL(team),
                                      other->FMGL(team))) &&
        (x10aux::struct_equals((*this)->FMGL(maxThreads),
                               other->FMGL(maxThreads))) &&
        (x10aux::struct_equals((*this)->FMGL(bufferWidth),
                               other->FMGL(bufferWidth))) &&
        (x10aux::struct_equals((*this)->FMGL(threadCounts),
                               other->FMGL(threadCounts))) &&
        (x10aux::struct_equals((*this)->FMGL(threadOffsets),
                               other->FMGL(threadOffsets))) &&
        (x10aux::struct_equals((*this)->FMGL(sendCounts),
                               other->FMGL(sendCounts))) &&
        (x10aux::struct_equals((*this)->FMGL(sendOffsets),
                               other->FMGL(sendOffsets))) &&
        (x10aux::struct_equals((*this)->FMGL(recvCounts),
                               other->FMGL(recvCounts))) &&
        (x10aux::struct_equals((*this)->FMGL(recvOffsets),
                               other->FMGL(recvOffsets))) &&
        (x10aux::struct_equals((*this)->FMGL(CACHE_LINE),
                               other->FMGL(CACHE_LINE)));
        
    }
    org::scalegraph::util::DistScatterGather org__scalegraph__util__DistScatterGather____this__org__scalegraph__util__DistScatterGather(
      ) {
        
        //#line 26 "/home/mukul/ScaleGraph/scalegraph/src/org/scalegraph/util/DistScatterGather.x10": x10.ast.X10Return_c
        return (*this);
        
    }
    void __fieldInitializers50661() {
        
        //#line 26 "/home/mukul/ScaleGraph/scalegraph/src/org/scalegraph/util/DistScatterGather.x10": Eval of x10.ast.X10FieldAssign_c
        (*this)->FMGL(CACHE_LINE) = ((x10_int)64);
    }
    
    static void _serialize(org::scalegraph::util::DistScatterGather this_, x10aux::serialization_buffer& buf);
    
    static org::scalegraph::util::DistScatterGather _deserialize(x10aux::deserialization_buffer& buf) {
        org::scalegraph::util::DistScatterGather this_;
        this_->_deserialize_body(buf);
        return this_;
    }
    
    void _deserialize_body(x10aux::deserialization_buffer& buf);
    
};


} } } 
#endif // ORG_SCALEGRAPH_UTIL_DISTSCATTERGATHER_H

namespace org { namespace scalegraph { namespace util { 
class DistScatterGather;
} } } 

#ifndef ORG_SCALEGRAPH_UTIL_DISTSCATTERGATHER_H_NODEPS
#define ORG_SCALEGRAPH_UTIL_DISTSCATTERGATHER_H_NODEPS
#include <x10/lang/Any.h>
#include <org/scalegraph/util/Team2.h>
#include <x10/lang/Int.h>
#include <org/scalegraph/util/MemoryChunk.h>
#include <x10/util/Team.h>
#include <x10/lang/Runtime.h>
#include <x10/lang/Math.h>
#include <org/scalegraph/util/MemoryChunk__Distributor.h>
#include <x10/lang/Long.h>
#include <x10/lang/LongRange.h>
#include <x10/lang/Boolean.h>
#include <x10/lang/IntRange.h>
#include <x10/compiler/Ifndef.h>
#include <x10/lang/String.h>
#include <x10/compiler/Native.h>
#include <x10/compiler/NonEscaping.h>
#ifndef ORG_SCALEGRAPH_UTIL_DISTSCATTERGATHER_H_GENERICS
#define ORG_SCALEGRAPH_UTIL_DISTSCATTERGATHER_H_GENERICS
#ifndef ORG_SCALEGRAPH_UTIL_DISTSCATTERGATHER_H_scatter_590
#define ORG_SCALEGRAPH_UTIL_DISTSCATTERGATHER_H_scatter_590
template<class TPMGL(T)> org::scalegraph::util::MemoryChunk<TPMGL(T)> org::scalegraph::util::DistScatterGather::scatter(
  org::scalegraph::util::MemoryChunk<TPMGL(T)> sendData) {
    
    //#line 101 "/home/mukul/ScaleGraph/scalegraph/src/org/scalegraph/util/DistScatterGather.x10": x10.ast.X10LocalDecl_c
    x10_int width = (*this)->FMGL(bufferWidth);
    
    //#line 102 "/home/mukul/ScaleGraph/scalegraph/src/org/scalegraph/util/DistScatterGather.x10": x10.ast.X10LocalDecl_c
    x10_int teamSize = (*this)->FMGL(team)->org::scalegraph::util::Team2::size();
    {
        {
            
            //#line 105 "/home/mukul/ScaleGraph/scalegraph/src/org/scalegraph/util/DistScatterGather.x10": x10.ast.X10LocalDecl_c
            x10_int i51679min51680 = ((x10_int)0);
            
            //#line 105 "/home/mukul/ScaleGraph/scalegraph/src/org/scalegraph/util/DistScatterGather.x10": x10.ast.X10LocalDecl_c
            x10_int i51679max51681 = ((x10_int) ((teamSize) - (((x10_int)1))));
            
            //#line 105 "/home/mukul/ScaleGraph/scalegraph/src/org/scalegraph/util/DistScatterGather.x10": polyglot.ast.For_c
            {
                x10_int i51679;
                for (
                     //#line 105 "/home/mukul/ScaleGraph/scalegraph/src/org/scalegraph/util/DistScatterGather.x10": x10.ast.X10LocalDecl_c
                     i51679 = i51679min51680; ((i51679) <= (i51679max51681));
                     
                     //#line 105 "/home/mukul/ScaleGraph/scalegraph/src/org/scalegraph/util/DistScatterGather.x10": Eval of x10.ast.X10LocalAssign_c
                     i51679 = ((x10_int) ((i51679) + (((x10_int)1)))))
                {
                    
                    //#line 105 "/home/mukul/ScaleGraph/scalegraph/src/org/scalegraph/util/DistScatterGather.x10": x10.ast.X10LocalDecl_c
                    x10_int r = i51679;
                    
                    //#line 106 "/home/mukul/ScaleGraph/scalegraph/src/org/scalegraph/util/DistScatterGather.x10": polyglot.ast.Assert_c
                    #ifndef NO_ASSERTIONS
                    if (x10aux::x10__assertions_enabled)
                        x10aux::x10__assert((x10aux::struct_equals((*this)->
                                                                     FMGL(threadOffsets)->org::scalegraph::util::MemoryChunk<x10_int>::__apply(
                                                                     ((x10_int) ((((x10_int) ((((x10_int)0)) * (width)))) + (r)))),
                                                                   ((x10_int) (((*this)->
                                                                                  FMGL(sendOffsets)->org::scalegraph::util::MemoryChunk<x10_int>::__apply(
                                                                                  r)) + ((*this)->
                                                                                           FMGL(threadCounts)->org::scalegraph::util::MemoryChunk<x10_int>::__apply(
                                                                                           ((x10_int) ((((x10_int) ((((x10_int)0)) * (width)))) + (r))))))))));
                    #endif//NO_ASSERTIONS
                    
                    //#line 107 "/home/mukul/ScaleGraph/scalegraph/src/org/scalegraph/util/DistScatterGather.x10": x10.ast.X10LocalDecl_c
                    x10_int i51663min51725 = ((x10_int)1);
                    
                    //#line 107 "/home/mukul/ScaleGraph/scalegraph/src/org/scalegraph/util/DistScatterGather.x10": x10.ast.X10LocalDecl_c
                    x10_int i51663max51726 = ((x10_int) (((*this)->
                                                            FMGL(maxThreads)) - (((x10_int)1))));
                    
                    //#line 107 "/home/mukul/ScaleGraph/scalegraph/src/org/scalegraph/util/DistScatterGather.x10": polyglot.ast.For_c
                    {
                        x10_int i51727;
                        for (
                             //#line 107 "/home/mukul/ScaleGraph/scalegraph/src/org/scalegraph/util/DistScatterGather.x10": x10.ast.X10LocalDecl_c
                             i51727 = i51663min51725; ((i51727) <= (i51663max51726));
                             
                             //#line 107 "/home/mukul/ScaleGraph/scalegraph/src/org/scalegraph/util/DistScatterGather.x10": Eval of x10.ast.X10LocalAssign_c
                             i51727 = ((x10_int) ((i51727) + (((x10_int)1)))))
                        {
                            
                            //#line 107 "/home/mukul/ScaleGraph/scalegraph/src/org/scalegraph/util/DistScatterGather.x10": x10.ast.X10LocalDecl_c
                            x10_int t51728 = i51727;
                            
                            //#line 108 "/home/mukul/ScaleGraph/scalegraph/src/org/scalegraph/util/DistScatterGather.x10": polyglot.ast.Assert_c
                            #ifndef NO_ASSERTIONS
                            if (x10aux::x10__assertions_enabled)
                                x10aux::x10__assert((x10aux::struct_equals((*this)->
                                                                             FMGL(threadOffsets)->org::scalegraph::util::MemoryChunk<x10_int>::__apply(
                                                                             ((x10_int) ((((x10_int) ((t51728) * (width)))) + (r)))),
                                                                           ((x10_int) (((*this)->
                                                                                          FMGL(threadOffsets)->org::scalegraph::util::MemoryChunk<x10_int>::__apply(
                                                                                          ((x10_int) ((((x10_int) ((((x10_int) ((t51728) - (((x10_int)1))))) * (width)))) + (r))))) + ((*this)->
                                                                                                                                                                                         FMGL(threadCounts)->org::scalegraph::util::MemoryChunk<x10_int>::__apply(
                                                                                                                                                                                         ((x10_int) ((((x10_int) ((t51728) * (width)))) + (r))))))))));
                            #endif//NO_ASSERTIONS
                            
                        }
                    }
                    
                }
            }
            
        }
        
        //#line 111 "/home/mukul/ScaleGraph/scalegraph/src/org/scalegraph/util/DistScatterGather.x10": polyglot.ast.Assert_c
        #ifndef NO_ASSERTIONS
        if (x10aux::x10__assertions_enabled)
            x10aux::x10__assert((x10aux::struct_equals(((x10_int) (sendData->org::scalegraph::util::MemoryChunk<TPMGL(T)>::size())),
                                                       (*this)->
                                                         FMGL(sendOffsets)->org::scalegraph::util::MemoryChunk<x10_int>::__apply(
                                                         teamSize))));
        #endif//NO_ASSERTIONS
        
    }
    
    //#line 113 "/home/mukul/ScaleGraph/scalegraph/src/org/scalegraph/util/DistScatterGather.x10": Eval of x10.ast.X10Call_c
    (*this)->FMGL(team)->template alltoall<x10_int >((*this)->
                                                       FMGL(sendCounts),
                                                     (*this)->
                                                       FMGL(recvCounts));
    
    //#line 114 "/home/mukul/ScaleGraph/scalegraph/src/org/scalegraph/util/DistScatterGather.x10": Eval of x10.ast.X10Call_c
    org::scalegraph::util::Team2::template countOffsets<x10_int >(
      (*this)->FMGL(recvCounts), (*this)->FMGL(recvOffsets),
      ((x10_int)0));
    
    //#line 115 "/home/mukul/ScaleGraph/scalegraph/src/org/scalegraph/util/DistScatterGather.x10": x10.ast.X10LocalDecl_c
    org::scalegraph::util::MemoryChunk<TPMGL(T)> recvData =
      org::scalegraph::util::MemoryChunk<TPMGL(T) >::_make(((x10_long) ((*this)->
                                                                          FMGL(recvOffsets)->org::scalegraph::util::MemoryChunk<x10_int>::__apply(
                                                                          teamSize))), 0, false, (x10_byte*)(void*)__FILE__, __LINE__);
    
    //#line 116 "/home/mukul/ScaleGraph/scalegraph/src/org/scalegraph/util/DistScatterGather.x10": Eval of x10.ast.X10Call_c
    (*this)->FMGL(team)->template alltoallv<TPMGL(T) >(sendData,
                                                       (*this)->
                                                         FMGL(sendOffsets),
                                                       (*this)->
                                                         FMGL(sendCounts),
                                                       recvData,
                                                       (*this)->
                                                         FMGL(recvOffsets),
                                                       (*this)->
                                                         FMGL(recvCounts));
    
    //#line 117 "/home/mukul/ScaleGraph/scalegraph/src/org/scalegraph/util/DistScatterGather.x10": x10.ast.X10Return_c
    return recvData;
    
}
#endif // ORG_SCALEGRAPH_UTIL_DISTSCATTERGATHER_H_scatter_590
#ifndef ORG_SCALEGRAPH_UTIL_DISTSCATTERGATHER_H_gather_591
#define ORG_SCALEGRAPH_UTIL_DISTSCATTERGATHER_H_gather_591
template<class TPMGL(T)> org::scalegraph::util::MemoryChunk<TPMGL(T)>
  org::scalegraph::util::DistScatterGather::gather(org::scalegraph::util::MemoryChunk<TPMGL(T)> sendData) {
    
    //#line 121 "/home/mukul/ScaleGraph/scalegraph/src/org/scalegraph/util/DistScatterGather.x10": x10.ast.X10LocalDecl_c
    x10_int teamSize = (*this)->FMGL(team)->org::scalegraph::util::Team2::size();
    
    //#line 122 "/home/mukul/ScaleGraph/scalegraph/src/org/scalegraph/util/DistScatterGather.x10": x10.ast.X10LocalDecl_c
    org::scalegraph::util::MemoryChunk<TPMGL(T)> recvData =
      org::scalegraph::util::MemoryChunk<TPMGL(T) >::_make(((x10_long) ((*this)->
                                                                          FMGL(sendOffsets)->org::scalegraph::util::MemoryChunk<x10_int>::__apply(
                                                                          teamSize))), 0, false, (x10_byte*)(void*)__FILE__, __LINE__);
    
    //#line 123 "/home/mukul/ScaleGraph/scalegraph/src/org/scalegraph/util/DistScatterGather.x10": Eval of x10.ast.X10Call_c
    (*this)->FMGL(team)->template alltoallv<TPMGL(T) >(sendData,
                                                       (*this)->
                                                         FMGL(recvOffsets),
                                                       (*this)->
                                                         FMGL(recvCounts),
                                                       recvData,
                                                       (*this)->
                                                         FMGL(sendOffsets),
                                                       (*this)->
                                                         FMGL(sendCounts));
    
    //#line 124 "/home/mukul/ScaleGraph/scalegraph/src/org/scalegraph/util/DistScatterGather.x10": x10.ast.X10Return_c
    return recvData;
    
}
#endif // ORG_SCALEGRAPH_UTIL_DISTSCATTERGATHER_H_gather_591
#ifndef ORG_SCALEGRAPH_UTIL_DISTSCATTERGATHER_H_gather_592
#define ORG_SCALEGRAPH_UTIL_DISTSCATTERGATHER_H_gather_592
template<class TPMGL(T)> void org::scalegraph::util::DistScatterGather::gather(
  org::scalegraph::util::MemoryChunk<TPMGL(T)> sendData, org::scalegraph::util::MemoryChunk<TPMGL(T)> recvData) {
    
    //#line 128 "/home/mukul/ScaleGraph/scalegraph/src/org/scalegraph/util/DistScatterGather.x10": Eval of x10.ast.X10Call_c
    (*this)->FMGL(team)->template alltoallv<TPMGL(T) >(sendData,
                                                       (*this)->
                                                         FMGL(recvOffsets),
                                                       (*this)->
                                                         FMGL(recvCounts),
                                                       recvData,
                                                       (*this)->
                                                         FMGL(sendOffsets),
                                                       (*this)->
                                                         FMGL(sendCounts));
}
#endif // ORG_SCALEGRAPH_UTIL_DISTSCATTERGATHER_H_gather_592
#endif // ORG_SCALEGRAPH_UTIL_DISTSCATTERGATHER_H_GENERICS
#endif // __ORG_SCALEGRAPH_UTIL_DISTSCATTERGATHER_H_NODEPS
