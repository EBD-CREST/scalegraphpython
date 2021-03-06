#
# This file is part of the ScaleGraph project (https://sites.google.com/site/scalegraph/).
# 
#  This file is licensed to You under the Eclipse Public License (EPL);
#  You may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#      http://www.opensource.org/licenses/eclipse-1.0.php
# 
#  (C) Copyright ScaleGraph Team 2011-2016.
#

import sys
import io
import os
import array
import pickle
import config
import x10xpregeladapter
import xpregel

class Bitmap():

    bitsPerWord = 64
    
    def __init__(self, size):
        self.numWords = round((size + self.bitsPerWord - 1) / self.bitsPerWord - 0.5);
        self.size = size


class XPregelContext():

    def __init__(self, logfile):

        # setup logfile
        self.logfile = logfile
        
        # get runtime information
        self.place_id = x10xpregeladapter.place_id()
        self.thread_id = x10xpregeladapter.thread_id()
        self.num_threads = x10xpregeladapter.num_threads()

        # get number of vertices
        self.numGlobalVertices = x10xpregeladapter.numGlobalVertices()
        self.numLocalVertices = x10xpregeladapter.numLocalVertices()
        self.numVertices = self.numGlobalVertices

        # prepare prefix for log output
        self.log_prefix = "[" + str(self.place_id) + ":" + str(self.thread_id) +":" + str(os.getpid()) + "]"

        # get type information
        self.vertexValue_type = x10xpregeladapter.vertexValue_type()
        self.vertexValue_format = x10xpregeladapter.get_format(self.vertexValue_type)
        self.message_value_type = x10xpregeladapter.message_value_type()
        self.message_value_format = x10xpregeladapter.get_format(self.message_value_type)
        
        # get graph
        self.outEdge_offsets = x10xpregeladapter.outEdge_offsets().cast('q')
        self.outEdge_vertices = x10xpregeladapter.outEdge_vertices().cast('q')
        self.inEdge_offsets = x10xpregeladapter.inEdge_offsets().cast('q')
        self.inEdge_vertices = x10xpregeladapter.inEdge_vertices().cast('q')

        # get vertex values
        self.vertexValue = x10xpregeladapter.vertexValue().cast(self.vertexValue_format)

        # setup place local range of vertices 
        self.rangePlaceLocalVertices = range(0, self.numLocalVertices)
        self.log("rangePlaceLocalVertices", self.rangePlaceLocalVertices)
        
        # setup thread local range of vertices
        numWords = Bitmap(self.numLocalVertices).numWords
        chunkWords = max(round((numWords + self.num_threads - 1) / self.num_threads - 0.5), 1)
        rangeWords_min = min(numWords, self.thread_id * chunkWords)
        rangeWords_max = min(numWords, rangeWords_min + chunkWords)
        rangeThreadLocalVertices_min = min(self.numLocalVertices, rangeWords_min * Bitmap.bitsPerWord)
        rangeThreadLocalVertices_max = min(self.numLocalVertices, rangeWords_max * Bitmap.bitsPerWord)
        self.rangeThreadLocalVertices = range(rangeThreadLocalVertices_min, rangeThreadLocalVertices_max)
        self.log("rangeThreadLocalVertices", self.rangeThreadLocalVertices)
        
        # get acitve flags
        self.vertexActive = x10xpregeladapter.vertexActive().cast('Q')
        self.vertexShouldBeActive = x10xpregeladapter.vertexShouldBeActive().cast('Q')

    def log(self, *objs):
        print(self.log_prefix, *objs, file=self.logfile)

    def logFlush(self):
        pass
#        self.logfile.flush()

    def outEdges(self, vertex_id):
        return self.outEdge_vertices[self.outEdge_offsets[vertex_id]:
                                     self.outEdge_offsets[vertex_id + 1]]

    def inEdges(self, vertex_id):
        return self.inEdge_vertices[self.inEdge_offsets[vertex_id]:
                                    self.inEdge_offsets[vertex_id + 1]]

    def receivedMessages(self, vertex_id):
        return self.message_values[self.message_offsets[vertex_id]:
                                   self.message_offsets[vertex_id + 1]]

    def newReceiveMessageBuffer(self):
        self.message_values = x10xpregeladapter.message_values().cast(self.message_value_format)
        self.message_offsets = x10xpregeladapter.message_offsets().cast('q')

    def newSendMessageBuffer(self):
        self.send_message_values = array.array(self.message_value_format)
        self.send_message_dstIds = array.array('q')

    def newSendMessageToAllNeighborsBuffer(self):
        self.send_msgN_values = array.array(self.message_value_format)
        self.send_msgN_srcIds = array.array('q')

    def sendMessage(self, src_vertex_id, dst_vertex_id, message):
        self.send_message_values.append(message)
        self.send_message_dstIds.append(dst_vertex_id)

    def sendMessageToAllNeighbors(self, src_vertex_id, message):
        self.send_msgN_values.append(message)
        self.send_msgN_srcIds.append(src_vertex_id)

    def writeSendMessageBuffer(self):
        x10xpregeladapter.write_buffer_to_shmem("sendMsg_values", self.send_message_values)
        x10xpregeladapter.write_buffer_to_shmem("sendMsg_dstIds", self.send_message_dstIds)

    def writeSendMessageToAllNeighborsBuffer(self):
        x10xpregeladapter.write_buffer_to_shmem("sendMsgN_values", self.send_msgN_values)
        x10xpregeladapter.write_buffer_to_shmem("sendMsgN_srcIds", self.send_msgN_srcIds)
        
    def threadLocalAggregate(self, value):
        self.threadLocalAggregateValues.append(value)

    def returnValue(self, format, value):
        arraybuf = array.array(format)
        arraybuf.append(value)
        x10xpregeladapter.write_buffer_to_stdout(arraybuf)
        self.log("return:", format, value)
        
    def beforeSuperstep(self):
        self.threadLocalAggregateValues = []
        self.numProcessed = 0
        self.newReceiveMessageBuffer()
        self.newSendMessageBuffer()
        self.newSendMessageToAllNeighborsBuffer()
        
    def afterSuperstep(self, aggregator):
        self.log("len aggregated value:", len(self.threadLocalAggregateValues))
#        self.log(self.threadLocalAggregateValues)

        # Aggregate
        threadLocalAggregatedValue = aggregator(self.threadLocalAggregateValues)
        self.log("aggregated value =", threadLocalAggregatedValue)

        # Write send messages to shmem
        self.writeSendMessageBuffer()
        self.writeSendMessageToAllNeighborsBuffer()
        
        self.returnValue('d', float(threadLocalAggregatedValue))
        self.returnValue('q', int(self.numProcessed))
        self.returnValue('q', len(self.send_message_values))
        self.returnValue('q', len(self.send_msgN_values))

class VertexContext():

    def __init__(self, superstepId, xpregelContext, vertexId):
        self.superstep = superstepId
        self.xpregelContext = xpregelContext
        self.vertexId = vertexId
        self.numVertices = xpregelContext.numVertices
        self.outEdges = xpregelContext.outEdges(vertexId)
        self.inEdges = xpregelContext.inEdges(vertexId)
        
    def sendMessage(self, dst_vertexId, message):
        self.xpregelContext.sendMessage(self.vertexId, dst_vertexId, message)

    def sendMessageToAllNeighbors(self, message):
        self.xpregelContext.sendMessageToAllNeighbors(self.vertexId, message)

    def getVertexValue(self):
        return self.xpregelContext.vertexValue[self.vertexId]

    def setVertexValue(self, value):
        self.xpregelContext.vertexValue[self.vertexId] = value

    def aggregate(self, value):
        self.xpregelContext.threadLocalAggregate(value)

    def log(self, *objs):
        self.xpregelContext.log(*objs)
        
        
def test_context(ctx):
    for value in ctx.outEdge_offsets:
        ctx.log(value)
    for value in ctx.vertexValue:
        ctx.log(value)


def test_outEdges(ctx):
    size_total_edges = 0
    size_max_edges = 0
    for vid in ctx.rangePlaceLocalVertices:
        size = len(ctx.outEdges(vid))
        size_total_edges += size
        size_max_edges = max(size_max_edges, size)
    ctx.log("outEdges", len(ctx.outEdge_vertices), size_total_edges, size_max_edges)

    
def test_inEdges(ctx):
    size_total_edges = 0
    size_max_edges = 0
    for vid in ctx.rangePlaceLocalVertices:
        size = len(ctx.inEdges(vid))
        size_total_edges += size
        size_max_edges = max(size_max_edges, size)
    ctx.log("inEdges", len(ctx.inEdge_vertices), size_total_edges, size_max_edges)

    
def test_receivedMessages(ctx):
    size_total_msgs = 0
    size_max_msgs = 0
    for vid in ctx.rangePlaceLocalVertices:
        size = len(ctx.receivedMessages(vid))
        size_total_msgs += size
        size_max_msgs = max(size_max_msgs, size)
    ctx.log("receivedMessages", len(ctx.message_values), size_total_msgs, size_max_msgs)

def test_write_buffer(ctx):
    ctx.sendMessage(0, 8, 3.1415)
    ctx.sendMessage(0, 7, 3.1415 * 2)
    ctx.sendMessage(0, 6, 3.1415 * 3)
    ctx.writeSendMessageBuffer();
    send_messages = x10xpregeladapter.new_memoryview_from_shmem_buffer("sendMsg_values", 24).cast('d')
    for i in range(0, len(send_messages)):
        ctx.log(i, send_messages[i])

def loadClosureFromShmem(ctx):
    closures = x10xpregeladapter.new_memoryview_from_shmem("closure", 0).cast('b')
#    ctx.log("closure size =", len(closures))
    (pickled_compute, pickled_aggregator, pickled_terminator) = pickle.loads(closures)
    compute = pickle.loads(pickled_compute)
    aggregator = pickle.loads(pickled_aggregator)
    terminator = pickle.loads(pickled_terminator)
    return (compute, aggregator, terminator)

def loadClosureFromFile(ctx):
    f = open(config.work_dir + '_xpregel_closure.bin', 'rb')
    (pickled_compute, pickled_aggregator, pickled_terminator)=pickle.load(f)
    f.close()
    compute=pickle.loads(pickled_compute)
    aggregator=pickle.loads(pickled_aggregator)
    terminator=pickle.loads(pickled_terminator)
    return (compute, aggregator, terminator)

def superstep(superstepId, xpregelContext, compute, aggregator):
    xpregelContext.log("superstep:", superstepId)
    sys.stderr.flush()
    xpregelContext.beforeSuperstep()
    xpregelContext.log("numVertives:", xpregelContext.numVertices)
#    xpregelContext.log(xpregelContext.vertexValue.tolist())
    rmsgs = []
    for vertexId in xpregelContext.rangeThreadLocalVertices:
        vertexContext = VertexContext(superstepId, xpregelContext, vertexId)
        messages = xpregelContext.receivedMessages(vertexId)
        compute(vertexContext, messages)
        xpregelContext.numProcessed += 1
        rmsgs.append(len(messages))
    xpregelContext.log("num received messages:", rmsgs);
    xpregelContext.afterSuperstep(aggregator)
    xpregelContext.logFlush()
    
    
def run():
#    logfile = sys.stderr
    logfile = open(config.work_dir + 'log_' + str(os.getpid()) + '.txt', 'w')
    xpctx = XPregelContext(logfile)
#    (compute, aggregator, terminator) = loadClosureFromFile(xpctx)
    (compute, aggregator, terminator) = loadClosureFromShmem(xpctx)
#    test_outEdges(xpctx)
#    test_inEdges(xpctx)
#    test_receivedMessages(xpctx)
#    test_write_buffer(xpctx)
    xpctx.log("START")
    input_stream = io.TextIOWrapper(sys.stdin.buffer)
    while 1:
        line = input_stream.readline()
        if line == '':
            break
        xpctx.log("command: ", line)
        args = line.split()
        if len(args) == 0:
            continue
        if args[0] == 'superstep':
            superstep(int(args[1]), xpctx, compute, aggregator)
        elif args[0] == 'compute':
            compute(xpctx, [])
        elif args[0] == 'test':
            test_outEdges(xpctx)
            test_inEdges(xpctx)
            test_receivedMessages(xpctx)
            test_write_buffer(xpctx)
        elif args[0] == 'end':
            break
        else:
            xpctx.log("ERROR:", args)
    xpctx.log("END")
    sys.stderr.flush()
    
