/* 
 *  This file is part of the ScaleGraph project (http://scalegraph.org).
 * 
 *  This file is licensed to You under the Eclipse Public License (EPL);
 *  You may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *      http://www.opensource.org/licenses/eclipse-1.0.php
 * 
 *  (C) Copyright ScaleGraph Team 2011-2012.
 */

package org.scalegraph.xpregel;

import x10.xrx.Runtime;
import x10.util.Team;
import x10.util.ArrayList;
import x10.compiler.Ifdef;

import org.scalegraph.Config;

import org.scalegraph.util.Algorithm;
import org.scalegraph.util.GrowableMemory;
import org.scalegraph.util.MemoryChunk;
import org.scalegraph.util.tuple.Tuple2;
import org.scalegraph.util.tuple.Tuple3;
import org.scalegraph.util.Bitmap;
import org.scalegraph.util.Team2;
import org.scalegraph.util.Parallel;
import org.scalegraph.util.Utils;
import org.scalegraph.util.ProfilingDB;
import org.scalegraph.util.LogPrinter;

import org.scalegraph.blas.DistSparseMatrix;
import org.scalegraph.blas.SparseMatrix;
import org.scalegraph.graph.id.OnedR;
import org.scalegraph.graph.id.IdStruct;

import org.scalegraph.io.FilePath;
import org.scalegraph.io.FileAccess;
import org.scalegraph.io.FileMode;
import org.scalegraph.io.GenericFile;
import org.scalegraph.api.NativePyXPregelAdapter;
import org.scalegraph.api.PyXPregelPipe;
import org.scalegraph.api.PyXPregel;
import org.scalegraph.id.Type;

import org.scalegraph.xpregel.PyVertexContext;
import org.scalegraph.util.DistMemoryChunk;
import x10.compiler.Native;
//import x10.io.Printer;
//import org.scalegraph.test.STest;
import org.scalegraph.id.Type;
import org.scalegraph.util.SString;

import org.scalegraph.python.NativePython;
import org.scalegraph.python.NativePyObject;
import org.scalegraph.python.NativePyException;

import org.scalegraph.util.Logger;

// "haszero" cause x10compiler to type incomprehensibility.
// when you want to get DUMMY value(may not be default), use Utils.getDummyZeroValue[T]();.

final class PyWorkerPlaceGraph[V,E] /* { V haszero, E haszero } */ {

	static val MAX_OUTPUT_NUMBER = 8;
	private static type XP = org.scalegraph.id.ProfilingID.XPregel;
	
	val mTeam :Team2;
	var mIds :IdStruct;

	val mVtoD :OnedR.VtoD;
	val mDtoV :OnedR.DtoV;
	val mDtoS :OnedR.DtoS;
	val mStoD :OnedR.StoD;
	val mStoV :OnedR.StoV;
	
	var mVertexValue :MemoryChunk[V];
	var mVertexActive :Bitmap;
	var mVertexShouldBeActive :Bitmap;
	
	val mOutEdge :GraphEdge[E];
	val mInEdge :GraphEdge[E];
	var mInEdgesMask :Bitmap;

	val numThreads = Runtime.NTHREADS as Int;
	var mLastAggVal :Any;
	val mOutput :MemoryChunk[GrowableMemory[Int]];
	
	var mLogLevel :Int;
	var mLogPrinter :LogPrinter;
	var mEnableStatistics :Boolean = true;
	//not using
	var mNeedsAllUpdateInEdge :Boolean = true;

	// Python Process
	var mPythonWorkers :MemoryChunk[PyXPregelPipe];
	// Integrated Python runtime (in this process)
	val mPythonIntegrated = new NativePython();
	var mPythonDictGlobals :NativePyObject;
	var mPythonDictLocals :NativePyObject;

	public def this(team :Team, ids :IdStruct) {
		val rank_r = team.role()(0);
		mTeam = new Team2(team);
		mIds = ids;
		val numLocalVertexes = mIds.numberOfLocalVertexes();
		
		mVtoD = new OnedR.VtoD(ids);
		mDtoV = new OnedR.DtoV(ids);
		mDtoS = new OnedR.DtoS(ids);
		mStoD = new OnedR.StoD(ids, rank_r);
		mStoV = new OnedR.StoV(ids, rank_r);
		
		mVertexValue = MemoryChunk.make[V](numLocalVertexes);
		mVertexActive = new Bitmap(numLocalVertexes, true);
		mVertexShouldBeActive = new Bitmap(numLocalVertexes, true);

		mOutEdge = new GraphEdge[E]();
		mInEdge = new GraphEdge[E]();
		
		mOutput = MemoryChunk.make[GrowableMemory[Int]](numThreads * MAX_OUTPUT_NUMBER, 0n, true);
		
		/// if (here.id == 0) {
		///	Console.OUT.println("lgl = " + mIds.lgl);
		///	Console.OUT.println("lgc = " + mIds.lgc);
		///	Console.OUT.println("lgr = " + mIds.lgr);	
		/// }

		integratePython();
	}

	def integratePython() {
		
		val SCALEGRAPHPYTHONLIB :String = "../../../python/scalegraph";

		mPythonIntegrated.initialize();
		mPythonIntegrated.sysPathAppend(SCALEGRAPHPYTHONLIB);

		val loadedClosures = PyXPregel.closures();

		try {
			val main = mPythonIntegrated.importAddModule("__main__");
			mPythonDictGlobals = mPythonIntegrated.moduleGetDict(main);
			mPythonDictLocals = mPythonIntegrated.dictNew();
			val pobj = mPythonIntegrated.memoryViewFromMemoryChunk(loadedClosures);
			mPythonIntegrated.dictSetItemString(mPythonDictLocals, "closures", pobj);
			mPythonIntegrated.runString(
				"import array\n" +
				"import pickle\n" +
				"import xpregel\n" +
				"(pickled_compute, pickled_aggregator, pickled_terminator)=pickle.loads(closures.tobytes())\n" +
				"compute=pickle.loads(pickled_compute)\n" +
				"aggregator=pickle.loads(pickled_aggregator)\n" +
				"terminator=pickle.loads(pickled_terminator)\n",
				mPythonDictGlobals, mPythonDictLocals);
		} catch (exception :NativePyException) {
			exception.extractExcInfo();
			Logger.print("catched exception");
			Logger.print(exception.strValue);
			Logger.print(exception.strTraceback);
			exception.DECREF();
		}
	}
	
	public def setOutEdge(edgeIndexMatrix :DistSparseMatrix[Long]) {
		if(edgeIndexMatrix.ids().equals(mIds) == false) {
			throw new Exception("Number of vertexes in the graph or the distribution of the graph is different.");
		}
		mOutEdge.offsets = edgeIndexMatrix().offsets;
		mOutEdge.vertexes = edgeIndexMatrix().vertexes;
		if(mOutEdge.values.size() != edgeIndexMatrix().vertexes.size()) {
			mOutEdge.values = MemoryChunk.make[E](edgeIndexMatrix().vertexes.size());
		}
	}

	public def setOutEdgeWithValue(graph :DistSparseMatrix[E]) {
		if(graph.ids().equals(mIds) == false) {
			throw new Exception("Number of vertexes in the graph or the distribution of the graph is different.");
		}
		mOutEdge.offsets = graph().offsets;
		mOutEdge.vertexes = graph().vertexes;
		mOutEdge.values = graph().values;
//		mOutEdge.set(graph());
	}

	public def updateFewInEdge(list :MemoryChunk[EdgeProvider[E]]){
		val numTeam = mTeam.size();
		val numLocalVertexes = mIds.numberOfLocalVertexes();
		val threadRange = 0n..(numThreads-1n);
		var f :Boolean = true;

		//---------- pre process ( prepare for exchanging edge difference ) ----------
		val diffInEdgeCountPerThread = MemoryChunk.make[MemoryChunk[Int]](
				numThreads, (i:Long)=> MemoryChunk.make[Int](numTeam,0n,true));
		
		val outModReqRange = MemoryChunk.make[LongRange](numThreads,0n,true);
		//place goto ni otodoke suru data no kazu wo shiraberu
		Parallel.iter(threadRange, (tid:Int)=> {
			if(list(tid).mEdgeModifyReqOffset.size()>0){
				assert(list(tid).mEdgeModifyReqWithAR.size() == list(tid).mEdgeModifyReqOffset(list(tid).mEdgeModifyReqOffset.size()-1L));
			}
			outModReqRange(tid) = list(tid).mEdgeModifyReqWithAR.range();
			
			for(i in outModReqRange(tid))//mOutEdgeModifyReqsWithAR(tid).range()
				++diffInEdgeCountPerThread(tid)(mDtoV.r(list(tid).mEdgeModifyReqWithAR(i).val1));	//TODO: r de ii noka
		});
		
		//diffInEdgeCount	(kansei)
		val diec = MemoryChunk.make[Int](numTeam,0n,true);
		for(team in diec.range()){								//Team range
			for(thread in threadRange)	//Thread range
				diec(team) += diffInEdgeCountPerThread(thread)(team);	//sum
		}
		
		//...Tuple3[Long,Long,E] diffInEdgeDataPerThread[numThreads][teamNum][diffInEdgeCountPerThread(i)(j)]
		val diffInEdgeDataPerThread = MemoryChunk.make[MemoryChunk[MemoryChunk[Tuple3[Long,Long,E]]]](
				numThreads, (i:Long)=> MemoryChunk.make[MemoryChunk[Tuple3[Long,Long,E]]](
						numTeam, (j:Long) => MemoryChunk.make[Tuple3[Long,Long,E]](diffInEdgeCountPerThread(i)(j),0n,true)
				)
		);
		
		Parallel.iter(threadRange, (tid:Int)=> {
			val e = list(tid);
			val workdata = diffInEdgeDataPerThread(tid);	//"work(teamNum)(index)" de access
			val workoff = list(tid).mEdgeModifyReqOffset;
			val maxSrcid = workoff.size()-2L;	//tettoribayai
			val index = MemoryChunk.make[Int](numTeam,0n,true);
			var srcid :Long = 0L;
			for(i in outModReqRange(tid)){//mOutEdgeModifyReqsWithAR(tid).range()
				val target = list(tid).mEdgeModifyReqWithAR(i);
				val dstid = target.val1;	//inEdge's dst(dstid with ARM)
				val team = mDtoV.r(dstid);
				while(srcid < maxSrcid && workoff(srcid+1)<=i)
					srcid++;
				workdata(team)(index(team)++) = new Tuple3[Long,Long,E](
						dstid & EdgeProvider.req_NOINFO,
						mStoD(e.mStartSrcid+srcid) | (dstid & EdgeProvider.req_INFO),
						target.val2);
				//this Tuple3 means: [inEdge's src(dstid), inEdge's dst(dstid,withARM), inEdge's value]
				//attention: StoD(as this place) => valid,  DtoS(as foreign place) => invalid
			}
		});

		//diffInEdgeData
		var dataNum :Long = 0L;
		for(team in diec.range())	//Team range
			dataNum += diec(team);
		val died = MemoryChunk.make[Tuple3[Long,Long,E]](dataNum);
		var dataIndex :Long = 0;
		for (team in 0..(numTeam-1)) {
			for (thread in threadRange){
				val src = diffInEdgeDataPerThread(thread)(team);
				MemoryChunk.copy(src, 0L, died, dataIndex, src.size());
				dataIndex += src.size();
			}
		}
		assert (dataIndex == dataNum);
		
		//exchange differences
		val result = mTeam.alltoallv(died, diec).val1;
		diffInEdgeCountPerThread.del();	diec.del();
		diffInEdgeDataPerThread.del();		died.del();

		//---------- post process ( apply differences ) ----------
		
		//foreach differences
		foreachVertexes(result.size(),(tid :Long, range :LongRange)=>{	//Irregular usage! DO NOT COPY this line!
			for(i in range)	{//optimize? overwrite val1 directory
				result(i) = new Tuple3(mDtoS(result(i).val1),result(i).val2,result(i).val3);	//DtoS
			}
		});
		
		//sort (optimize => sort order (srcid --> (subdivided)dstid))
		Algorithm.maskedStableSortTupleKey2(result);	//dstid
		Algorithm.stableSortTupleKey1(result);		//srcid
		
		//EdgeProvider no code wo sai riyou suru tame ni offset to reqs wo wazawaza tsukuru
		//offset
		val InEdgeModifyReqOffsets = MemoryChunk.make[MemoryChunk[Long]](numThreads,
				(tid:Long) => MemoryChunk.make[Long](list(tid).mEdgeModifyReqOffset.size(),0n,true));
		//reqs
		val InEdgeModifyReqsWithAR = MemoryChunk.make[GrowableMemory[Tuple2[Long,E]]](numThreads, 0n, true);

		//copy to mInEdgeModify*
		foreachVertexes(numLocalVertexes,(tid :Long, vrange :LongRange)=>{
			val resrange = result.range();
			var start :Long = resrange.max + 1L;
			var end :Long = resrange.max;
			val e = list(tid);
			val reqoff = InEdgeModifyReqOffsets(tid);
			val reqs = InEdgeModifyReqsWithAR(tid);
			assert(vrange.min == e.mStartSrcid);
			
			//search index
			//optimize? lower_bound
			for(i in resrange)
				if(result(i).val1 >= vrange.min){
					start = i;
					break;
				}
			//optimize? upper_bound
			for(i in start..resrange.max){
				if(result(i).val1 > vrange.max){
					end = i-1L;
					break;
				}
			}
			if(start>end){			//there is no diffInEdge at this tid
				reqs.setSize(0L);
				return;				//no need to run following process
			}else{
				//reqs initialize
				val size = end - start + 1L;
				reqs.setSize(size);	//hundle it like MemoryChunk
			}
			var reqsIndex :Long = 0L;
			val ssrc = e.mStartSrcid;		// == vrange.min
			var tsrcid :Long = ssrc - 1L;	//saisyo ni "tsrcid < result(i).val1" hantei wo saseru tame "-1L"
			for(i in start..end){
				//make offset
				while(tsrcid < result(i).val1){//==srcid	//zenkai no val1 to ima no val1 ga tigatta ra offset no kawarime
					++tsrcid;
					reqoff(tsrcid - ssrc) = reqsIndex;
				}
				//make reqs
				reqs(reqsIndex++) = new Tuple2(result(i).val2,result(i).val3);	//[dstid withARM,value]
			}
			//offset ume
			++tsrcid;
			for(i in (tsrcid - ssrc)..(reqoff.size()-1L))
				reqoff(i) = reqsIndex;
		});
		EdgeProvider.updateInEdge[V,E](mInEdge, list, mIds, InEdgeModifyReqOffsets, InEdgeModifyReqsWithAR);
		InEdgeModifyReqOffsets.del();
		InEdgeModifyReqsWithAR.del();
	}
	
	/**
	 * Add new vertices in the graph
	 */
	public def addVertex(newIds :IdStruct, newVal :V) {
		val numOldVertexes = mIds.numberOfLocalVertexes();
		val numNewVertexes = newIds.numberOfLocalVertexes();
		
		val newVertexValue = MemoryChunk.make[V](numNewVertexes);
		MemoryChunk.copy(mVertexValue, newVertexValue.subpart(0, numOldVertexes));
		mVertexValue = newVertexValue;
		mVertexActive = new Bitmap(numNewVertexes, true);
		mVertexShouldBeActive = new Bitmap(numNewVertexes, true);
		
		// initialize new vertex with newVal
		for(i in numOldVertexes..(numNewVertexes-1)) {
			mVertexValue(i) = newVal;
		}

		growEdge(mOutEdge, mIds, newIds);
		if(mInEdge.offsets.size() > 0)
			growEdge(mInEdge, mIds, newIds);
		
		mIds = newIds;
	}
	
	private static def growEdge[E](edge :GraphEdge[E], oldIds :IdStruct, newIds :IdStruct) {
		val numNewVertices = newIds.numberOfLocalVertexes();
		val DtoV = new OnedR.DtoV(oldIds);
		val VtoD = new OnedR.VtoD(newIds);
		val newOffsets = MemoryChunk.make[Long](numNewVertices+1);
		MemoryChunk.copy(edge.offsets, newOffsets.subpart(0l, edge.offsets.size()));
		val lastIndex = edge.vertexes.size();
		for(i in edge.offsets.size()..numNewVertices) {
			newOffsets(i) = lastIndex;
		}
		for(i in edge.vertexes.range()) {
			edge.vertexes(i) = VtoD(DtoV(edge.vertexes(i)));
		}
		edge.offsets = newOffsets;
	}

	public def updateInEdge() {
		
		@Ifdef("PROF_XP") val mtimer = Config.get().profXPregel().timer(XP.MAIN_FRAME as Int, 0n);
		@Ifdef("PROF_XP") { mtimer.start(); }
		val sw = Config.get().stopWatch();
		if(here.id == 0) sw.lap("start to update in edge");
		
		val numThreads = Runtime.NTHREADS;
		val mesComm = new MessageCommunicator[Long](mTeam, mInEdge, mIds, numThreads);
		val numLocalVertexes = mIds.numberOfLocalVertexes();
		val StoD = new OnedR.StoD(mIds, mTeam.base.role()(0));
		@Ifdef("PROF_XP") { mtimer.lap(XP.MAIN_INIT as Int); }
		if(here.id == 0) sw.lap("vertex processing start");
		
		foreachVertexes(numLocalVertexes, (tid :Long, r :LongRange) => {
			@Ifdef("PROF_XP") val thtimer = Config.get().profXPregel().timer(XP.MAIN_TH_FRAME as Int, tid as Int);
			@Ifdef("PROF_XP") { thtimer.start(); }
			val UCCMessages = mesComm.messageBuffer(tid);
			val offset = mOutEdge.offsets;
			val id = mOutEdge.vertexes;
			for(vid in r) {
				val vid_ = StoD(vid);
				for(i in offset(vid)..(offset(vid + 1) - 1)) {
					val mesBuf = UCCMessages(mesComm.mDtoV.r(id(i)));
					mesBuf.messages.add(vid_);
					mesBuf.dstIds.add(mesComm.mDtoS(id(i)));
				}
			}
			@Ifdef("PROF_XP") { thtimer.lap(XP.MAIN_TH_COMPUTE as Int); }
		});
		@Ifdef("PROF_XP") { mtimer.lap(XP.MAIN_COMPUTE as Int); }
		if(here.id == 0) sw.lap("vertex processing finished");
		
		mesComm.preProcess();
		@Ifdef("PROF_XP") { mtimer.lap(XP.MAIN_PRE_PROCESS as Int); }
		mesComm.process(null, true, false);
		@Ifdef("PROF_XP") { mtimer.lap(XP.MAIN_PROCESS as Int); }
		mesComm.exchangeMessages(true, false);

		mInEdge.offsets = mesComm.mUCROffset;
		mInEdge.vertexes = mesComm.mUCRMessages;
		//sort mInEdge.vertexes (needed for fewInEdgeUpdate)
				Parallel.iter(0L..(numLocalVertexes-1L), (i :Long) => {
					Algorithm.sort(mInEdge.vertexes.subpart(mInEdge.offsets(i), mInEdge.offsets(i+1) - mInEdge.offsets(i)));
				});
		mesComm.mUCROffset = MemoryChunk.make[Long]();
		mesComm.mUCRMessages = MemoryChunk.make[Long]();
		mesComm.del();
		@Ifdef("PROF_XP") { mtimer.lap(XP.MAIN_UPDATEINEDGE as Int); }
		if(here.id == 0) sw.lap("finished to update in edge");
	}
	
	public def updateInEdgeWithValue() {E haszero} {
		@Ifdef("PROF_XP") val mtimer = Config.get().profXPregel().timer(XP.MAIN_FRAME, 0n);
		@Ifdef("PROF_XP") { mtimer.start(); }
		val numThreads = Runtime.NTHREADS;
		val mesComm = new MessageCommunicator[Tuple2[Long, E]](mTeam, mInEdge, mIds, numThreads);
		val numLocalVertexes = mIds.numberOfLocalVertexes();
		val StoD = new OnedR.StoD(mIds, mTeam.base.role()(0));
		@Ifdef("PROF_XP") { mtimer.lap(XP.MAIN_INIT); }
		
		foreachVertexes(numLocalVertexes, (tid :Long, r :LongRange) => {
			@Ifdef("PROF_XP") val thtimer = Config.get().profXPregel().timer(XP.MAIN_TH_FRAME, tid as Int);
			@Ifdef("PROF_XP") { thtimer.start(); }
			val UCCMessages = mesComm.messageBuffer(tid);
			val offset = mOutEdge.offsets;
			val id = mOutEdge.vertexes;
			val value = mOutEdge.values;
			for(vid in r) {
				val vid_ = StoD(vid);
				for(i in offset(vid)..(offset(vid + 1) - 1)) {
					val mesBuf = UCCMessages(mesComm.mDtoV.r(id(i)));
					mesBuf.messages.add(Tuple2[Long, E](vid_, value(i)));
					mesBuf.dstIds.add(mesComm.mDtoS(id(i)));
				}
			}
			@Ifdef("PROF_XP") { thtimer.lap(XP.MAIN_TH_COMPUTE); }
		});
		@Ifdef("PROF_XP") { mtimer.lap(XP.MAIN_COMPUTE); }

		mesComm.preProcess();
		@Ifdef("PROF_XP") { mtimer.lap(XP.MAIN_PRE_PROCESS); }
		mesComm.process(null, true, false);
		@Ifdef("PROF_XP") { mtimer.lap(XP.MAIN_PROCESS); }
		mesComm.exchangeMessages(true, false);
		
		val numEdges = mesComm.mUCRMessages.size();
		val id = MemoryChunk.make[Long](numEdges);
		val value = MemoryChunk.make[E](numEdges);
		Parallel.iter(0..(numEdges-1), (tid :Long, r :LongRange) => {
			for(i in r) {
				id(i) = mesComm.mUCRMessages(i).get1();
				value(i) = mesComm.mUCRMessages(i).get2();
			}
		});

		mInEdge.offsets = mesComm.mUCROffset;
		mInEdge.vertexes = id;
		mInEdge.values = value;
		
		mesComm.mUCROffset = MemoryChunk.make[Long]();
		mesComm.del();
		@Ifdef("PROF_XP") { mtimer.lap(XP.MAIN_UPDATEINEDGE); }
	}
	
	
/*
	// src will be destroyed
	private static def computeAggregate[A](team :Team2, src :MemoryChunk[A], buffer :MemoryChunk[A],
			aggregator :(MemoryChunk[A])=>A) :A
*/			/*{A haszero }*/	//added
/*	{
		@Ifdef("PROF_XP") val mtimer = Config.get().profXPregel().timer(XP.MAIN_FRAME, 0n);
		val root = (team.base.role()(0) == 0n);
		src(0) = aggregator(src);
		@Ifdef("PROF_XP") { mtimer.lap(XP.MAIN_AGGREGATE_COMPUTE); }
		team.gather(0n, src.subpart(0, 1), buffer);
		if(root) buffer(0) = aggregator(buffer);
		team.bcast(0n, root ? buffer.subpart(0, 1) : buffer, src.subpart(0, 1));
		@Ifdef("PROF_XP") { mtimer.lap(XP.MAIN_AGGREGATE_COMM); }
		return src(0);
	}
*/
	
	private static val STT_END_COUNT = 0;
	private static val STT_ACTIVE_VERTEX = 1;
	private static val STT_RAW_MESSAGE = 2;
	private static val STT_VERTEX_MESSAGE = 3;
	private static val STT_PRE = 4;
	
	private static val STT_COMBINED_MESSAGE = 4;
	private static val STT_VERTEX_TRANSFERED_MESSAGE = 5;
	private static val STT_POST = 2;
	
	private static val STT_MAX = 6;

	private static def gatherInformation[M](team :Team2,
			ectx :MessageCommunicator[M], stt :MemoryChunk[Long], enableStatistics :Boolean,
			combiner :(messages:MemoryChunk[M]) => M) { M haszero } :Boolean
	{
		@Ifdef("PROF_XP") val mtimer = Config.get().profXPregel().timer(XP.MAIN_FRAME, 0n);
		val recvStt = stt.subpart(STT_MAX, STT_MAX);
		
		// compute the number of messages to determin communication strategy
		//val [ numActive, numRawMessages, numVertexMessages ] = ectx.preProcess();
		val tmpRail = ectx.preProcess();
		val numActive = tmpRail(0);
		val numRawMessages = tmpRail(1);
		val numVertexMessages = tmpRail(2);
		@Ifdef("PROF_XP") { mtimer.lap(XP.MAIN_PRE_PROCESS); }
		
		stt(STT_ACTIVE_VERTEX) = numActive;
		stt(STT_RAW_MESSAGE) = numRawMessages;
		stt(STT_VERTEX_MESSAGE) = numVertexMessages;
		
		// aggregate statistics to determin communication strategy
		team.allreduce(stt.subpart(0, STT_PRE), recvStt.subpart(0, STT_PRE), Team.ADD);
		@Ifdef("PROF_XP") { mtimer.lap(XP.MAIN_ALLGATHER_1); }

		if(recvStt(STT_END_COUNT) > 0) {
			// terminate
			return true;
		}
		
		// if there are no active vertex nor messages, we terminate computation.
		if(recvStt(STT_ACTIVE_VERTEX) == 0L &&
				recvStt(STT_RAW_MESSAGE) == 0L &&
				recvStt(STT_VERTEX_MESSAGE) == 0L){
			return true;
		}
		
		// merge messages and combine if combiner is provided
		//val [  numCombinedMessages, numTransferedVertexMessages ]
		//		= ectx.process(combiner, recvStt(STT_RAW_MESSAGE) > 0, recvStt(STT_VERTEX_MESSAGE) > 0);
		val tmpRail2 = ectx.process(combiner, recvStt(STT_RAW_MESSAGE) > 0, recvStt(STT_VERTEX_MESSAGE) > 0);
		val numCombinedMessages = tmpRail2(0);
		val numTransferedVertexMessages = tmpRail2(1);
		@Ifdef("PROF_XP") { mtimer.lap(XP.MAIN_PROCESS); }
		
		stt(STT_COMBINED_MESSAGE) = numCombinedMessages;
		stt(STT_VERTEX_TRANSFERED_MESSAGE) = numTransferedVertexMessages;

		// aggregate statictics just for print information
		// This communication can be omitted !
		if(enableStatistics)
			team.allreduce(stt.subpart(STT_PRE, STT_POST), recvStt.subpart(STT_PRE, STT_POST), Team.ADD);
		@Ifdef("PROF_XP") { mtimer.lap(XP.MAIN_ALLGATHER_2); }
		
		return false;
	}
	
	// This method doesn't necessarilly split all works to all threads.
	// Use this method to initialize containers used in this method.
	static def foreachVertexes(numLocalVertexes :Long, task :(Long, LongRange) => void) {
		// Split the range of bitmat words to ensure the processing thread-safe.
		Parallel.iter(0..(Bitmap.numWords(numLocalVertexes)-1), (tid :Long, r_word :LongRange) => {
			val r = new LongRange(
					Math.min(numLocalVertexes, r_word.min * Bitmap.BitsPerWord),
					Math.min(numLocalVertexes, (r_word.max+1) * Bitmap.BitsPerWord) - 1);
			task(tid, r);
		});
	}

	public def run[M, A]() { M haszero, A haszero } {

		val ectx :MessageCommunicator[M] =
			new MessageCommunicator[M](mTeam, mInEdge, mIds, numThreads);

		val numGlobalVertexes = mIds.numberOfGlobalVertexes();
		val numLocalVertexes = mIds.numberOfLocalVertexes();
		NativePyXPregelAdapter.setProperty_numGlobalVertices(numGlobalVertexes);
		NativePyXPregelAdapter.setProperty_numLocalVertices(numLocalVertexes);

		// This is required to construct PyVertexContext
		val localSrcids = MemoryChunk.make[Long](numThreads,0n,true);
		foreachVertexes(numLocalVertexes, (tid :Long, r :LongRange) => {
			localSrcids(tid) = r.min;
		});

		// debugging <-- but it is required for creating PyVertexContext
		val mOutEdgeModifyReqOffsets = MemoryChunk.make[MemoryChunk[Long]](numThreads);

		foreachVertexes(numLocalVertexes, (tid :Long, r :LongRange) => {
			mOutEdgeModifyReqOffsets(tid) = MemoryChunk.make[Long]((r.max - r.min +1L) +1L, 0n, true);
		});

		// This is also required to construct PyVertexContext
		val mOutEdgeModifyReqsWithAR = MemoryChunk.make[GrowableMemory[Tuple2[Long,E]]](
				numThreads, (i :Long) => new GrowableMemory[Tuple2[Long,E]](0L));
		// new PyVertexContext
		val vctxs = MemoryChunk.make[PyVertexContext[V, E, M, A]](numThreads,
				(i : Long)=>new PyVertexContext[V, E, M, A](
				this, ectx, i, 
				mOutEdgeModifyReqOffsets(i), mOutEdgeModifyReqsWithAR(i), 
				localSrcids(i)));

		val statistics = MemoryChunk.make[Long](STT_MAX*2);
		val recvStatistics = statistics.subpart(STT_MAX, STT_MAX);


		// Copy closure to shmem
		val closure = PyXPregel.closures();
		val shmemClosure = createShmemMemoryChunk("closure", closure);
		shmemClosure.copyToShmem(closure, closure.size());

		// initialize halt flag
		val vertexActvieBitmap = mVertexActive.raw();
		MemoryChunk.copy(mVertexShouldBeActive.raw(), 0L,
				vertexActvieBitmap, 0L, vertexActvieBitmap.size());

		val shmemOutEdge = createShmemOutEdge();
		val shmemInEdge = createShmemInEdge();
		updateShmemGraphEdge(shmemOutEdge, mOutEdge);
		updateShmemGraphEdge(shmemInEdge, mInEdge);

		Logger.print("Check mOutEdge");
		for (i in 0..(numLocalVertexes - 1)) {
			if (mOutEdge.offsets(i + 1) - mOutEdge.offsets(i) <= 0) {
				Logger.print("NO EDGES");
			}
		}
		Logger.print("Check Done");

		val shmemVertexValue = createShmemVertexValue[V]();
		updateShmemMemoryChunk(shmemVertexValue, mVertexValue);

		val shmemVertexActive = createShmemVertexActive();
		updateShmemBitmap(shmemVertexActive, mVertexActive);

		val shmemVertexShouldBeActive = createShmemVertexShouldBeActive();
		updateShmemBitmap(shmemVertexShouldBeActive, mVertexShouldBeActive);

		val shmemSendMessageToAllNeighborsFlag = createShmemMemoryChunk("sendMsgN_flags", ectx.mBCCHasMessage.mc);
		updateShmemMemoryChunk(shmemSendMessageToAllNeighborsFlag, ectx.mBCCHasMessage.mc);

		val shmemSendMessageToAllNeighborsValue = createShmemMemoryChunk("sendMsgN_values", ectx.mBCCMessages);
		updateShmemMemoryChunk(shmemSendMessageToAllNeighborsValue, ectx.mBCCMessages);
		

		exportShmemReceivedMessages(ectx, 0..(numLocalVertexes - 1));

		NativePyXPregelAdapter.createShmemProperty(here.id);
		NativePyXPregelAdapter.updateShmemProperty();

		// Fork Python workers
		mPythonWorkers = MemoryChunk.make[PyXPregelPipe](numThreads);
		try {
			for (i in 0..(numThreads - 1)) {
				mPythonWorkers(i) = NativePyXPregelAdapter.fork(here.id, i, numThreads);
			}
		} catch (exception :CheckedThrowable) {
			exception.printStackTrace();
			return;
		}
		for (i in 0..(numThreads - 1)) {
//			async redirectStderr(mPythonWorkers(i).stderr);
//			async redirectStderr(mPythonWorkers(i).stdout); /* debug code */
		}


		val numPlaces = mTeam.size();
		val mcAggregatedValueOnThread = MemoryChunk.make[A](numThreads);
		val mcAggregatedValueOnPlace = MemoryChunk.make[A](numPlaces);
		val mcAggregatedValueIntermediate = MemoryChunk.make[A](1);
		val mcAggregatedValue = MemoryChunk.make[A](1);
		val mcNumProcessed = MemoryChunk.make[Long](numThreads);
		val mcNumSentMessage = MemoryChunk.make[Long](numThreads);
		val mcNumSentMessageN = MemoryChunk.make[Long](numThreads);
		
		// Do Superstep
		for (ss in 0..10000n) {

			// Compute on child Python worker process
			val command = String.format("superstep %lld\n", [ss as Any]);
//			val command = "end\n";
			val len_command = command.length();
			val command_buff = SString(command);
			Logger.print("Send command:" + command + " length=" + len_command.toString() + " bufsize=" + command_buff.bytes().size().toString());

			try {
				for (i in 0..(numThreads - 1)) {
//					Logger.print("FD(" + i.toString() + ") = " + mPythonWorkers(i).stdin.getFd().toString() + " write " + command_buff.bytes().size().toString() + " bytes");
					mPythonWorkers(i).stdin.write(command_buff.bytes(), len_command as Long);
				}
			} catch (exception :CheckedThrowable) {
				Logger.printStackTrace(exception);
			}

			// Wait child process and get result
			finish for (i in 0..(numThreads - 1)) {
				async waitSuperStepOnThread[A](i, mcAggregatedValueOnThread, mcNumProcessed,
											   mcNumSentMessage, mcNumSentMessageN);
			}

			for (i in 0..(numThreads - 1)) {
				val vc = vctxs(i);
				vc.mNumActiveVertexes = mcNumProcessed(i);
				importSentMessagesOnShmem(i, vc, mcNumSentMessage(i), mcNumSentMessageN(i));
			}

			var flagHasMessage :Boolean = false;
			val rawHasMessage = ectx.mBCCHasMessage.mc;
			for (i in 0..(rawHasMessage.size()-1)) {
				if (rawHasMessage(i) != 0UL) {
					flagHasMessage = true;
					break;
				}
			}
			if (flagHasMessage) {
				Logger.print("BCCHasMessage has messages !!!!");
			} else {
				Logger.print("BCCHasMessage has NO message !!!!");
			}



			// delete existing (old) messages.
			ectx.deleteMessages();

			// gather statistics
			for(th in 0..(numThreads-1)) {
				//first message process is here 
				ectx.sqweezeMessage(vctxs(th));
			}
			//@Ifdef("PROF_XP") { mtimer.lap(XP.MAIN_SQWEEZMES as Int); }

			Logger.print("Dispatch BCC Messages");
			//-----directionOptimization
			Logger.print("call allreduce");
			val numAllBCSCount = mTeam.allreduce[Long](ectx.mBCSInputCount, Team.ADD);
			Logger.print("numAllBCSCount: " + numAllBCSCount.toString());
			if(0L < numAllBCSCount && numAllBCSCount  < (mIds.numberOfGlobalVertexes()/50)){	//TODO: modify /20
				val BCbmp=ectx.mBCCHasMessage;
				foreachVertexes(numLocalVertexes, (tid :Long, r :LongRange) => {
					val vc = vctxs(tid);
					for (dosrcid in r){
						if(BCbmp(dosrcid)){
							vc.mSrcid = dosrcid;
							val tempmes=ectx.mBCCMessages(dosrcid);
							for (edgeId in vc) {
								vc.sendMessage(edgeId, tempmes);
							}
						}
					}
				});
				ectx.mBCCHasMessage.clear(false);
				ectx.mBCCMessages.del();
				ectx.mBCCMessages = MemoryChunk.make[M](mIds.numberOfLocalVertexes());
				ectx.mBCSInputCount=0L;
				updateShmemMemoryChunk(shmemSendMessageToAllNeighborsFlag, ectx.mBCCHasMessage.mc);
			}
			//-----

			// aggregation of aggregated values
			Logger.print("Call aggregator");

			val root = (mTeam.base.role()(0) == 0n);
			mcAggregatedValueIntermediate(0) = callAggregator(mcAggregatedValueOnThread);
			Logger.print("Call gather");
			mTeam.gather(0n, mcAggregatedValueIntermediate, mcAggregatedValueOnPlace);
			if (root) {
				mcAggregatedValueIntermediate(0) = callAggregator(mcAggregatedValueOnPlace);
			}
			mTeam.bcast(0n, mcAggregatedValueIntermediate, mcAggregatedValue);
			val aggVal = mcAggregatedValue(0);
//			val aggVal = 0 as A;

			// call terminator on each place

			Logger.print("Call terminator");
			statistics(STT_END_COUNT) = callTerminator[A](ss as Int, aggVal) ? 1L : 0L;
			Logger.print("==> " + statistics(STT_END_COUNT).toString());
			// terminate when one of callTerminator returns true
			
			Logger.print("Call gatherInformation");
			val terminate = gatherInformation(mTeam, ectx, statistics, mEnableStatistics, null);
			Logger.print("returns " + terminate.toString());

			// update BCCHasMessage here because it is cleared inside gatherInformation
			updateShmemMemoryChunk(shmemSendMessageToAllNeighborsFlag, ectx.mBCCHasMessage.mc);

			if (here.id() == 0) {
				Logger.print("STT_END_COUNT: " + recvStatistics(STT_END_COUNT));
				Logger.print("STT_ACTIVE_VERTEX: " + recvStatistics(STT_ACTIVE_VERTEX));
				Logger.print("STT_RAW_MESSAGE: " + recvStatistics(STT_RAW_MESSAGE));
				Logger.print("STT_VERTEX_MESSAGE: " + recvStatistics(STT_VERTEX_MESSAGE));
				if(mEnableStatistics && terminate == false) {
					Logger.print("STT_COMBINED_MESSAGE: " + recvStatistics(STT_COMBINED_MESSAGE));
					Logger.print("STT_VERTEX_TRANSFERED_MESSAGE: " + recvStatistics(STT_VERTEX_TRANSFERED_MESSAGE));
				}
			}

			if (terminate) {

				Logger.print("TERMINATE");

				mLastAggVal = aggVal;
				mInEdgesMask = ectx.mInEdgesMask;
				ectx.del();

				mcAggregatedValueOnThread.del();
				mcAggregatedValueOnPlace.del();
				mcAggregatedValueIntermediate.del();
				mcAggregatedValue.del();
				mcNumProcessed.del();
				mcNumSentMessage.del();
				mcNumSentMessageN.del();

				Logger.print("KILL CHILD");

				// Child Python process ends when closing STDIN
				val endcmd = SString("end\n");
				try {
				for (i in 0..(numThreads - 1)) {
//					Logger.print(String.format("Send command %s to %lld", [endcmd.toString() as Any, i]));
//					Logger.print("FD(" + i.toString() + ") = " + mPythonWorkers(i).stdin.getFd().toString() + " write " + endcmd.bytes().size().toString() + " bytes");
//					mPythonWorkers(i).stdin.write(endcmd.bytes());
					mPythonWorkers(i).stdin.close();
					mPythonWorkers(i).stdout.close();
				}
				} catch (exception :CheckedThrowable) {
					Logger.printStackTrace(exception);
				}

				Logger.print("Exit");

//				mPythonWorkers.del();

				Logger.print("Last Aggregated Value: " + mLastAggVal.toString());

				return ;
			}

			// Exchange messages
			Logger.print("Exchange Messages");
			ectx.exchangeMessages(
					recvStatistics(STT_COMBINED_MESSAGE) > 0L,
					recvStatistics(STT_VERTEX_MESSAGE) > 0L);
			
			// Copy message to shared memory

			exportShmemReceivedMessages(ectx, 0..(numLocalVertexes - 1));
			NativePyXPregelAdapter.updateShmemProperty();
		}


/*
		exportInEdgeToShmem();
		exportVertexValueToShmem(mVertexValue);
		exportVertexActiveToShmem();
		exportVertexShouldBeActiveToShmem();
		exportReceivedMessagesToShmem(ectx, 0..(numLocalVertexes - 1));
*/
	}


	def callAggregator[A](valuesToAggregate :MemoryChunk[A]) :A { A haszero } {

		Logger.print("start callAggregator");
		try {
			val avalues = mPythonIntegrated.memoryViewFromMemoryChunk(valuesToAggregate);
			mPythonIntegrated.dictSetItemString(mPythonDictLocals,
												"avalues", avalues);
			Logger.print("runString");
			mPythonIntegrated.runString(
				"alist = avalues.cast('d')\n" +
				"val = aggregator(alist)\n" +
				"retval = array.array('d')\n" +
				"retval.append(val)",
				mPythonDictGlobals, mPythonDictLocals);
			val retval = mPythonIntegrated.dictGetItemString(mPythonDictLocals,
															 "retval");
			val mca = mPythonIntegrated.bufferAsMemoryChunk[A](retval);
			val aggVal = mca(0);
			mca.del();

			Logger.print("result: " + aggVal.toString());
			return aggVal;

		} catch (exception :NativePyException) {
			exception.extractExcInfo();
			Logger.print("catched exception");
			Logger.print(exception.strValue);
			Logger.print(exception.strTraceback);
			exception.DECREF();
		}
		return 0 as A;
	}


	def callTerminator[A](ss: Int, aggVal: A) :Boolean { A haszero } {

		try {
			// Using a MemoryChunk as a temprary (like boxing)
			// for future extension that supports non-primitive A
			val mca = MemoryChunk.make[A](1);
			mca(0) = aggVal;
			val pObjAggVal = mPythonIntegrated.memoryViewFromMemoryChunk(mca);
			val pObjSS = mPythonIntegrated.longFromLong(ss as Long);
			mPythonIntegrated.dictSetItemString(mPythonDictLocals,
												"tmpAggVal", pObjAggVal);
			mPythonIntegrated.dictSetItemString(mPythonDictLocals,
												"ss", pObjSS);
			mPythonIntegrated.runString(
				"aggVal = tmpAggVal.cast('d')[0]\n" +
				"if terminator(ss, aggVal):\n" +
				"    retval=1\n" +
				"else:\n" +
				"    retval=0\n",
				mPythonDictGlobals, mPythonDictLocals);
			val pObjRetval = mPythonIntegrated.dictGetItemString(mPythonDictLocals,
																 "retval");
			val retval = mPythonIntegrated.longAsLong(pObjRetval);

			mca.del();
			if (retval == 1) {
				return true;
			} else {
				return false;
			}
		} catch (exception :NativePyException) {
			exception.extractExcInfo();
			Logger.print("catched exception");
			Logger.print(exception.strValue);
			Logger.print(exception.strTraceback);
			exception.DECREF();
		}

		return true; // no reason to continue iteration
	}




/*
	public def run[M, A](
			compute :(VertexContext[V,E,M,A], MemoryChunk[M]) => void,
			aggregator :(MemoryChunk[A])=>A,
			combiner :(MemoryChunk[M]) => M,
			end :(Int,A)=>Boolean) { M haszero, A haszero }
	{
		@Ifdef("PROF_XP") { STest.bufferedPrintln("$ MEM-XPS0: place: " + here.id +
				": TotalMem: " + MemoryChunk.getMemSize() + ": GCMem: " + MemoryChunk.getGCMemSize() + ": ExpMem: " + MemoryChunk.getExpMemSize()); }
		@Ifdef("PROF_XP") val mtimer = Config.get().profXPregel().timer(XP.MAIN_FRAME as Int, 0n);
		@Ifdef("PROF_XP") { mtimer.start(); }
		val sw = Config.get().stopWatch();
		if(here.id == 0) sw.lap("start xpregel iteration");
		
		val root = (mTeam.base.role()(0) == 0n);
		val numLocalVertexes = mIds.numberOfLocalVertexes();
		val ectx :MessageCommunicator[M] =
			new MessageCommunicator[M](mTeam, mInEdge, mIds, numThreads);
		
		val localSrcids = MemoryChunk.make[Long](numThreads,0n,true);

		foreachVertexes(numLocalVertexes, (tid :Long, r :LongRange) => {
			localSrcids(tid) = r.min;
		});

		//debugging
		val mOutEdgeModifyReqOffsets = MemoryChunk.make[MemoryChunk[Long]](numThreads);

		foreachVertexes(numLocalVertexes, (tid :Long, r :LongRange) => {
			mOutEdgeModifyReqOffsets(tid) = MemoryChunk.make[Long]((r.max - r.min +1L) +1L, 0n, true);
		});

		val mOutEdgeModifyReqsWithAR = MemoryChunk.make[GrowableMemory[Tuple2[Long,E]]](
				numThreads, (i :Long) => new GrowableMemory[Tuple2[Long,E]](0L));
		val vctxs = MemoryChunk.make[VertexContext[V, E, M, A]](numThreads,
			(i : Long)=>new VertexContext[V, E, M, A](
				this, ectx, i, 
				mOutEdgeModifyReqOffsets(i), mOutEdgeModifyReqsWithAR(i), 
				localSrcids(i)));
				
		val intermedAggregateValue = MemoryChunk.make[A](numThreads);
		val aggregateBuffer = MemoryChunk.make[A](root ? mTeam.size() : 0);
		val statistics = MemoryChunk.make[Long](STT_MAX*2);
		val recvStatistics = statistics.subpart(STT_MAX, STT_MAX);

		//ectx.mInEdgesOffset = mInEdge.offsets;
		//ectx.mInEdgesVertex = mInEdge.vertexes;
		//ectx.mInEdgesMask = mInEdgesMask;

		// initialize halt flag
		val vertexActvieBitmap = mVertexActive.raw();
		MemoryChunk.copy(mVertexShouldBeActive.raw(), 0L,
				vertexActvieBitmap, 0L, vertexActvieBitmap.size());
		
		@Ifdef("PROF_XP") { mtimer.lap(XP.MAIN_INIT as Int); }
		
		for(ss in 0n..10000n) {
			ectx.mSuperstep = ss;

			@Ifdef("PROF_XP") { mtimer.start(); }
			if(here.id == 0) sw.lap("vertex processing started");
			foreachVertexes(numLocalVertexes, (tid :Long, r :LongRange) => {
				val vc = vctxs(tid);
				val ep = vc.mEdgeProvider;
				val mesTempBuffer :GrowableMemory[M] = new GrowableMemory[M]();
				var numProcessed :Long = 0L;

				@Ifdef("PROF_XP") val numLocalOutEdges = mOutEdge.offsets(r.max + 1) - mOutEdge.offsets(r.min);
				@Ifdef("PROF_XP") var numLocalMes :Long = 0L;

				@Ifdef("PROF_XP") val thtimer = Config.get().profXPregel().timer(XP.MAIN_TH_FRAME as Int, tid as Int);
				@Ifdef("PROF_XP") { thtimer.start(); }
				for(srcid in r) {
					vc.mSrcid = srcid;
					vc.releaseAllIterators();
					val mes = ectx.message(srcid, mesTempBuffer);
					@Ifdef("PROF_XP") { numLocalMes += mes.size(); }
					if(mes.size() > 0 || mVertexActive(srcid)) {
						ep.mEdgeChanged = false;
						
						compute(vc, mes);

						if(ep.mEdgeChanged) {
							ep.fixModifiedEdges(srcid);	//TODO: uncomment
							ep.mEdgeChangedUntilNow = true;
						}
						if(mVertexActive(srcid)) ++numProcessed;
					}
				}
				@Ifdef("PROF_XP") { thtimer.lap(XP.MAIN_TH_COMPUTE as Int); }
				if(aggregator != null) {
					intermedAggregateValue(tid) = aggregator(vc.mAggregateValue.raw());
				}
				@Ifdef("PROF_XP") { thtimer.lap(XP.MAIN_TH_AGGREGATE as Int); }
				vc.mAggregateValue.clear();
				vc.mNumActiveVertexes = numProcessed;
				@Ifdef("PROF_XP") { STest.bufferedPrintln("$ XPS1: place: " + here.id + ": th: " + tid + ": ss: " + ss +
						": OutEdge: " + numLocalOutEdges + ": Mes: " + numLocalMes); }
			});
			@Ifdef("PROF_XP") { mtimer.lap(XP.MAIN_COMPUTE as Int); }
			@Ifdef("PROF_XP") { STest.bufferedPrintln("$ MEM-XPS2: place: " + here.id + ": ss: " + ss +
					": TotalMem: " + MemoryChunk.getMemSize() + ": GCMem: " + MemoryChunk.getGCMemSize() + ": ExpMem: " + MemoryChunk.getExpMemSize()); }
			if(here.id == 0) sw.lap("vertex processing finished");
		
			// delete existing (old) messages.
			ectx.deleteMessages();
			
			// gather statistics
			for(th in 0..(numThreads-1)) {
				//first message process is here 
				ectx.sqweezeMessage(vctxs(th));
			}
			@Ifdef("PROF_XP") { mtimer.lap(XP.MAIN_SQWEEZMES as Int); }
			
			// update out edges
			if(here.id == 0) sw.lap("update out edge");
			EdgeProvider.updateOutEdge[V,E,M,A](mOutEdge, vctxs, mIds);

			// update in edges
			// val edgeProviderList = MemoryChunk.make[EdgeProvider[E]](numThreads as Long,
			// 		(i:Long) => vctxs(i).mEdgeProvider);
			updateFewInEdge(MemoryChunk.make[EdgeProvider[E]](numThreads as Long,
					(i:Long) => vctxs(i).mEdgeProvider));

			// update messageCommunicator's inedge
			//ectx.mInEdgesOffset = mInEdge.offsets;
			//ectx.mInEdgesVertex = mInEdge.vertexes;
			
			EdgeProvider.reInitializeEdgeProvider[V,E,M,A](vctxs);
			
			//-----directionOptimization
			val numAllBCSCount = mTeam.allreduce[Long](ectx.mBCSInputCount, Team.ADD);
			if(0L < numAllBCSCount && numAllBCSCount  < (mIds.numberOfGlobalVertexes()/50)){	//TODO: modify /20
				val BCbmp=ectx.mBCCHasMessage;
				foreachVertexes(numLocalVertexes, (tid :Long, r :LongRange) => {
					val vc = vctxs(tid);
					for (dosrcid in r){
						if(BCbmp(dosrcid)){
							vc.mSrcid = dosrcid;
							val tempmes=ectx.mBCCMessages(dosrcid);
							for (edgeId in vc) {
								vc.sendMessage(edgeId, tempmes);
							}
						}
					}
				});
				ectx.mBCCHasMessage.clear(false);
				ectx.mBCCMessages.del();
				ectx.mBCCMessages = MemoryChunk.make[M](mIds.numberOfLocalVertexes());
				ectx.mBCSInputCount=0L;
			}
			//-----
1w			
			// aggregate
			if(here.id == 0) sw.lap("aggregate...");
			val aggVal = (aggregator != null)
				? computeAggregate[A](mTeam, intermedAggregateValue, aggregateBuffer, aggregator)
				: Zero.get[A]();
				
			for(i in vctxs.range()) vctxs(i).mAggregatedValue = aggVal;
			statistics(STT_END_COUNT) = end(ss, aggVal) ? 1L : 0L;

			val terminate = gatherInformation(mTeam, ectx, statistics, mEnableStatistics, combiner);

			if(here.id() == 0 && mLogPrinter != null) {
				mLogPrinter.println("STT_END_COUNT: " + recvStatistics(STT_END_COUNT));
				mLogPrinter.println("STT_ACTIVE_VERTEX: " + recvStatistics(STT_ACTIVE_VERTEX));
				mLogPrinter.println("STT_RAW_MESSAGE: " + recvStatistics(STT_RAW_MESSAGE));
				mLogPrinter.println("STT_VERTEX_MESSAGE: " + recvStatistics(STT_VERTEX_MESSAGE));
				if(mEnableStatistics && terminate == false) {
					mLogPrinter.println("STT_COMBINED_MESSAGE: " + recvStatistics(STT_COMBINED_MESSAGE));
					mLogPrinter.println("STT_VERTEX_TRANSFERED_MESSAGE: " + recvStatistics(STT_VERTEX_TRANSFERED_MESSAGE));
				}
			}
			
			if(terminate) {
				mLastAggVal = aggVal;
				mInEdgesMask = ectx.mInEdgesMask;
				ectx.del();
				return ;
			}

			// exchange messages
			ectx.exchangeMessages(
					recvStatistics(STT_COMBINED_MESSAGE) > 0L,
					recvStatistics(STT_VERTEX_MESSAGE) > 0L);
		}
		
		throw new Exception("Superstep limit exceeded. # of supterstep > 10000");
	}
*/ 

	@Native("c++", "reinterpret_cast<org::scalegraph::util::GrowableMemory<#T >*>(#v)")
	static native def castTo[T](v :GrowableMemory[Int]) :GrowableMemory[T];
	
	def outBuffer(tid :Long) = mOutput.subpart(tid * MAX_OUTPUT_NUMBER, MAX_OUTPUT_NUMBER);
	
	public def stealOutput[T](index :Int) :MemoryChunk[T] {
		if(index > MAX_OUTPUT_NUMBER)
			throw new ArrayIndexOutOfBoundsException();

		@Ifdef("PROF_XP") val mtimer = Config.get().profXPregel().timer(XP.MAIN_FRAME, 0n);
		@Ifdef("PROF_XP") { mtimer.start(); }
		
		var length :Long = 0L;
		for(i in 0..(numThreads-1)) {
			length += mOutput(i * MAX_OUTPUT_NUMBER + index).size();
		}
		
		val outMem = MemoryChunk.make[T](length);
		var offset :Long = 0L;
		finish for(i in 0n..(numThreads-1n)) {
			val buf = mOutput(i * MAX_OUTPUT_NUMBER + index);
			val src_len = buf.size();
			val offset_ = offset;
			async {
				// GrowableMemory must be declared as final.
				// If it is not, all method call to typed_buf
				// will invoke the method of GrowableMemory<int> 
				// through its virtual function table.
				@Ifdef("PROF_XP") val thtimer = Config.get().profXPregel().timer(XP.MAIN_TH_FRAME, i);
				@Ifdef("PROF_XP") { thtimer.start(); }
				val typed_buf = castTo[T](buf);
				MemoryChunk.copy(typed_buf.raw(), 0L, outMem, offset_, src_len);
				typed_buf.clear();
				@Ifdef("PROF_XP") { thtimer.lap(XP.MAIN_TH_COPY_OUT); }
			}
			offset += src_len;
		}
		@Ifdef("PROF_XP") { mtimer.lap(XP.MAIN_TH_COPY_OUT); }
		
		return outMem;
	}


	////////

	public def waitSuperStepOnThread[A](threadId :Long,
										mcAggregatedValue :MemoryChunk[A],
										mcNumProcessed :MemoryChunk[Long],
										mcNumSentMessage :MemoryChunk[Long],
										mcNumSentMessageN :MemoryChunk[Long]) {

		Logger.print(String.format("Wait Aggregated Value from Thread:%lld", [threadId as Any]));

		// Receive Aggregated Value
		val sizeBuff = MemoryChunk.make[Byte](Type.sizeOf[Long]());
		try {
			mPythonWorkers(threadId).stdout.read(sizeBuff);
		} catch (e :CheckedThrowable) {
			Logger.print("Error: waitSuperStepOnThread: read sizeBuff");
			Logger.printStackTrace(e);
		}
		val size = MemoryChunk.make[Long](1);
		NativePyXPregelAdapter.copyFromBuffer(sizeBuff, 0, (Type.sizeOf[Long]() as Long), size);
		assert(size(0) == (Type.sizeOf[A]()  as Long)); // Size is received for future extension
		val valueBuff = MemoryChunk.make[Byte](size(0));
		try {
			mPythonWorkers(threadId).stdout.read(valueBuff);
		} catch (e :CheckedThrowable) {
			Logger.print("Error: waitSuperStepOnThread: read valueBuff");
			Logger.printStackTrace(e);
		}
		val value = MemoryChunk.make[A](1);
		NativePyXPregelAdapter.copyFromBuffer(valueBuff, 0, size(0), value);
		mcAggregatedValue(threadId) = value(0);
		Logger.print(String.format("Reveived Aggregated Value from Thread:%lld = %s", [threadId as Any, value(0).toString()]));

		Logger.print(String.format("Wait numProcessed from Thread:%lld", [threadId as Any]));

		// Receive numProcessed on each thread
		try {
			mPythonWorkers(threadId).stdout.read(sizeBuff);
		} catch (e :CheckedThrowable) {
			Logger.print("Error: waitSuperStepOnThread: read sizeBuff for numBuff");
			Logger.printStackTrace(e);
		}
		NativePyXPregelAdapter.copyFromBuffer(sizeBuff, 0, (Type.sizeOf[Long]() as Long), size);
		assert(size(0) == (Type.sizeOf[Long]() as Long)); // Size is received for future extension
		val numBuff = MemoryChunk.make[Byte](size(0));
		try {
			mPythonWorkers(threadId).stdout.read(numBuff);
		} catch (e :CheckedThrowable) {
			Logger.print("Error: waitSuperStepOnThread: read numBuff");
			Logger.printStackTrace(e);
		}
		val numProcessed = MemoryChunk.make[Long](1);
		NativePyXPregelAdapter.copyFromBuffer(numBuff, 0, size(0), numProcessed);
		mcNumProcessed(threadId) = numProcessed(0);
		Logger.print(String.format("Reveived numProcessed from Thread:%lld = %s", [threadId as Any, numProcessed(0).toString()]));

		// Receive number of unicast messages from the thread(worker)
		try {
			mPythonWorkers(threadId).stdout.read(sizeBuff);
		} catch (e :CheckedThrowable) {
			Logger.print("Error: waitSuperStepOnThread: read sizeBuff for numMsgBuff");
			Logger.printStackTrace(e);
		}
		NativePyXPregelAdapter.copyFromBuffer(sizeBuff, 0, (Type.sizeOf[Long]() as Long), size);
		assert(size(0) == (Type.sizeOf[Long]() as Long)); // Size is received for future extension
		val numMsgBuff = MemoryChunk.make[Byte](size(0));
		try {
			mPythonWorkers(threadId).stdout.read(numMsgBuff);
		} catch (e :CheckedThrowable) {
			Logger.print("Error: waitSuperStepOnThread: read numMsgBuff");
			Logger.printStackTrace(e);
		}
		val numMsg = MemoryChunk.make[Long](1);
		NativePyXPregelAdapter.copyFromBuffer(numMsgBuff, 0, size(0), numMsg);
		mcNumSentMessage(threadId) = numMsg(0);
		Logger.print(String.format("Reveived NumMessage from Thread:%lld = %s", [threadId as Any, numMsg(0).toString()]));

		// Receive number of broadcast messages from the thread(worker)
		try {
			mPythonWorkers(threadId).stdout.read(sizeBuff);
		} catch (e :CheckedThrowable) {
			Logger.print("Error: waitSuperStepOnThread: read sizeBuff for numMsgNBuff");
			Logger.printStackTrace(e);
		}
		NativePyXPregelAdapter.copyFromBuffer(sizeBuff, 0, (Type.sizeOf[Long]() as Long), size);
		assert(size(0) == (Type.sizeOf[Long]() as Long)); // Size is received for future extension
		val numMsgNBuff = MemoryChunk.make[Byte](size(0));
		try {
			mPythonWorkers(threadId).stdout.read(numMsgNBuff);
		} catch (e :CheckedThrowable) {
			Logger.print("Error: waitSuperStepOnThread: read numMsgBuff");
			Logger.printStackTrace(e);
		}
		val numMsgN = MemoryChunk.make[Long](1);
		NativePyXPregelAdapter.copyFromBuffer(numMsgNBuff, 0, size(0), numMsgN);
		mcNumSentMessageN(threadId) = numMsgN(0);
		Logger.print(String.format("Reveived NumMessageN from Thread:%lld = %s", [threadId as Any, numMsgN(0).toString()]));

		// Receive BCSInputCount on each thread
/*
		try {
			mPythonWorkers(threadId).stdout.read(sizeBuff);
		} catch (e :CheckedThrowable) {
			Logger.print("Error: waitSuperStepOnThread: read sizeBuff for countBuff");
			Logger.printStackTrace(e);
		}
		NativePyXPregelAdapter.copyFromBuffer(sizeBuff, 0, (Type.sizeOf[Long]() as Long), size);
		assert(size(0) == (Type.sizeOf[Long]() as Long)); // Size is received for future extension
		val countBuff = MemoryChunk.make[Byte](size(0));
		try {
			mPythonWorkers(threadId).stdout.read(countBuff);
		} catch (e :CheckedThrowable) {
			Logger.print("Error: waitSuperStepOnThread: read countBuff");
			Logger.printStackTrace(e);
		}
		val count = MemoryChunk.make[Long](1);
		NativePyXPregelAdapter.copyFromBuffer(countBuff, 0, size(0), count);
		mcBCSInputCount(threadId) = count(0);
		Logger.print(String.format("Reveived BCSInputCount from Thread:%lld = %s", [threadId as Any, count(0).toString()]));
*/

		// Delete buffer
		sizeBuff.del();
		size.del();
		valueBuff.del();
		value.del();
		numMsgBuff.del();
		numMsg.del();
		numMsgNBuff.del();
		numMsgN.del();

		Logger.print(String.format("Wait OK Thread:%lld", [threadId as Any]));
	}

	public def importSentMessagesOnShmem[V, E, M, A](threadId :Long, vc: PyVertexContext[V, E, M, A],
													 numSentMessage: Long, numSentMessageN: Long) { M haszero, A haszero } {

		Logger.print("numSentMessage: " + numSentMessage.toString());
		Logger.print("numSentMessageN: " + numSentMessageN.toString());

		if (numSentMessage > 0) {

			val mcSentMessageValues = MemoryChunk.make[M](numSentMessage);
			val shmemSentMessageValues = openShmemMemoryChunk(threadId, "sendMsg_values",
															  mcSentMessageValues);
			readShmemMemoryChunk(shmemSentMessageValues, mcSentMessageValues);
			shmemSentMessageValues.close();
			
			val mcSentMessageDstIds = MemoryChunk.make[Long](numSentMessage);
			val shmemSentMessageDstIds = openShmemMemoryChunk(threadId, "sendMsg_dstIds",
															  mcSentMessageDstIds);
			readShmemMemoryChunk(shmemSentMessageDstIds, mcSentMessageDstIds);
			shmemSentMessageDstIds.close();
			
			vc.sendMessage(mcSentMessageDstIds, mcSentMessageValues);

			mcSentMessageValues.del();
			mcSentMessageDstIds.del();
		}

		if (numSentMessageN > 0) {

			val mcSentMessageNValues = MemoryChunk.make[M](numSentMessageN);
			val shmemSentMessageNValues = openShmemMemoryChunk(threadId, "sendMsgN_values",
														   mcSentMessageNValues);
			readShmemMemoryChunk(shmemSentMessageNValues, mcSentMessageNValues);
			shmemSentMessageNValues.close();
			
			val mcSentMessageNSrcIds = MemoryChunk.make[Long](numSentMessageN);
			val shmemSentMessageNSrcIds = openShmemMemoryChunk(threadId, "sendMsgN_srcIds",
															   mcSentMessageNSrcIds);
			readShmemMemoryChunk(shmemSentMessageNSrcIds, mcSentMessageNSrcIds);
			shmemSentMessageNSrcIds.close();
			
			for (i in (0..(numSentMessageN - 1))) {
				vc.mSrcid = i;
				vc.sendMessageToAllNeighbors(mcSentMessageNValues(i));
			} 

			mcSentMessageNValues.del();
			mcSentMessageNSrcIds.del();
		}
	}

	public static struct ShmemObjectEdge {
		public val offsets :GenericFile;
		public val vertices :GenericFile;
		public def this(_offsets :GenericFile, _vertices :GenericFile) {
			offsets = _offsets;
			vertices = _vertices;
		}
	}

	public def createShmemOutEdge() :ShmemObjectEdge {
		NativePyXPregelAdapter.setProperty_outEdge_offsets_size(mOutEdge.offsets.size());
		NativePyXPregelAdapter.setProperty_outEdge_vertices_size(mOutEdge.vertexes.size());
		return createShmemGraphEdge("outEdge", mOutEdge);
	}

	public def createShmemInEdge() :ShmemObjectEdge {
		NativePyXPregelAdapter.setProperty_inEdge_offsets_size(mInEdge.offsets.size());
		NativePyXPregelAdapter.setProperty_inEdge_vertices_size(mInEdge.vertexes.size());
		return createShmemGraphEdge("inEdge", mInEdge);
	}

	public def createShmemGraphEdge[E](name: String, graphEdge :GraphEdge[E]) : ShmemObjectEdge {
		val here_id = here.id.toString();
		val name_shmem_offsets = "/pyxpregel." + name + ".offsets." + here_id;
		val name_shmem_vertices = "/pyxpregel." + name + ".vertices." + here_id;
		val size_shmem_offsets = graphEdge.offsets.size() * Type.sizeOf[Long]();
		val size_shmem_vertices = graphEdge.vertexes.size() * Type.sizeOf[Long]();
		GenericFile.unlink(name_shmem_offsets);
		GenericFile.unlink(name_shmem_vertices);
		val file_shmem_offsets = new GenericFile(FilePath(FilePath.FILEPATH_FS_SHM,
														  name_shmem_offsets),
												 FileMode.Create, FileAccess.ReadWrite);
		val file_shmem_vertices = new GenericFile(FilePath(FilePath.FILEPATH_FS_SHM,
														   name_shmem_vertices),
												  FileMode.Create, FileAccess.ReadWrite);
		file_shmem_offsets.ftruncate(size_shmem_offsets);
		file_shmem_vertices.ftruncate(size_shmem_vertices);
		return ShmemObjectEdge(file_shmem_offsets, file_shmem_vertices);
	}

	public def updateShmemGraphEdge[E](shmem: ShmemObjectEdge, graphEdge :GraphEdge[E]) {
		shmem.offsets.copyToShmem(graphEdge.offsets, graphEdge.offsets.size() * Type.sizeOf[Long]());
		shmem.vertices.copyToShmem(graphEdge.vertexes, graphEdge.vertexes.size() * Type.sizeOf[Long]());
//		shmem.offsets.close();
//		shmem.vertexes.close();
	}

	public def createShmemVertexValue[V]() :GenericFile {
		NativePyXPregelAdapter.setProperty_vertexValue_type(Type.typeId[V]());
		return createShmemMemoryChunk("vertexValue", mVertexValue);
	}

	public def createShmemVertexActive() {
		NativePyXPregelAdapter.setProperty_vertexActive_mc_size(mVertexActive.mc.size());
		return createShmemBitmap("vertexA", mVertexActive);
	}

	public def createShmemVertexShouldBeActive() {
		NativePyXPregelAdapter.setProperty_vertexShouldBeActive_mc_size(mVertexShouldBeActive.mc.size());
		return createShmemBitmap("vertexSBA", mVertexShouldBeActive);
	}

	public def exportShmemReceivedMessages[M](ectx :MessageCommunicator[M], vertex_range :LongRange) { M haszero} :void {
		val range_min = vertex_range.min;
		val messages :GrowableMemory[M] = new GrowableMemory[M](128);
		val offsets :GrowableMemory[Long] = new GrowableMemory[Long](128);
		val buffer :GrowableMemory[M] = new GrowableMemory[M](16);
		offsets.add(0);
		for (dst in vertex_range) {
			val messages_to_dst = ectx.message(dst, buffer);
			if (messages_to_dst.size() > 0) {
				messages.add(messages_to_dst);
			}
			offsets.add(messages.size());
		}
		val message_values = messages.raw();
		val message_offsets = offsets.raw();
		val shmemMessageValues = createShmemMemoryChunk("message.values", message_values);
		val shmemMessageOffsets = createShmemMemoryChunk("message.offsets", message_offsets);
		updateShmemMemoryChunk(shmemMessageValues, message_values);
		updateShmemMemoryChunk(shmemMessageOffsets, message_offsets);
		shmemMessageValues.close();
		shmemMessageOffsets.close();
		
		NativePyXPregelAdapter.setProperty_message_values_size(message_values.size());
		NativePyXPregelAdapter.setProperty_message_offsets_size(message_offsets.size());
		NativePyXPregelAdapter.setProperty_message_value_type(Type.typeId[M]());
	}

/*
	public def exportReceivedMessagesToShmem[M](ectx :MessageCommunicator[M], vertex_range :LongRange) { M haszero } {
		val range_min = vertex_range.min;
		val messages :GrowableMemory[M] = new GrowableMemory[M](128);
		val offsets :GrowableMemory[Long] = new GrowableMemory[Long](128);
		val buffer :GrowableMemory[M] = new GrowableMemory[M](16);
		offsets.add(0);
		for (dst in vertex_range) {
			val messages_to_dst = ectx.message(dst, buffer);
			if (messages_to_dst.size() > 0) {
				messages.add(messages_to_dst);
			}
			offsets.add(messages.size());
		}
		val message_values = messages.raw();
		val message_offsets = offsets.raw();
		exportMemoryChunkToShmem("message.values", message_values);
		exportMemoryChunkToShmem("message.offsets", message_offsets);
		NativePyXPregelAdapter.setProperty_message_values_size(message_values.size());
		NativePyXPregelAdapter.setProperty_message_offsets_size(message_offsets.size());
		NativePyXPregelAdapter.setProperty_message_value_type(Type.typeId[Double]());
//		NativePyXPregelAdapter.writePropertyToShmem(here.id);
	}
*/

	public def createShmemBitmap(name :String, bitmap :Bitmap) =
		createShmemMemoryChunk(name, bitmap.mc);


	public def updateShmemBitmap(shmem :GenericFile, bitmap :Bitmap) {
		updateShmemMemoryChunk(shmem, bitmap.mc);
	}

//	public def writebackShmemBitmap(shmem :GenericFile, bitmap :Bitmap) {
//		writebackShmemMemoryChunk(shmem, bitmap.mc);
//	}

	public def createShmemMemoryChunk[T](name :String, mc :MemoryChunk[T]) :GenericFile {
		val here_id = here.id.toString();
		val name_shmem = "/pyxpregel." + name + "." + here_id;
		GenericFile.unlink(name_shmem);
		val file_shmem = new GenericFile(FilePath(FilePath.FILEPATH_FS_SHM,
												  name_shmem),
										 FileMode.Create, FileAccess.ReadWrite);
		file_shmem.ftruncate(mc.size() * Type.sizeOf[T]());
		return file_shmem;
	}

	public def openShmemMemoryChunk[T](threadId :Long, name :String, mc :MemoryChunk[T]) :GenericFile {
		val here_id = here.id.toString();
		val name_shmem = "/pyxpregel." + name + "." + here_id + "." + threadId.toString();
//		GenericFile.unlink(name_shmem);
		val file_shmem = new GenericFile(FilePath(FilePath.FILEPATH_FS_SHM,
												  name_shmem),
										 FileMode.Open, FileAccess.ReadWrite);
//		file_shmem.ftruncate(mc.size() * Type.sizeOf[T]());
		return file_shmem;
	}

	public def updateShmemMemoryChunk[T](shmem: GenericFile, mc :MemoryChunk[T]) {
		shmem.copyToShmem(mc, mc.size() * Type.sizeOf[T]());
//		shmem.close();
	}

	public def readShmemMemoryChunk[T](shmem: GenericFile, mc :MemoryChunk[T]) {
		shmem.copyFromShmem(mc, mc.size() * Type.sizeOf[T]());
//		shmem.close();
	}

	public def redirectStderr(file: GenericFile) {

		val stderr = new GenericFile(GenericFile.STDERR_FILENO);

		val buffSize = 32;
		val buff = MemoryChunk.make[Byte](buffSize);
		for (;;) {
			var sizeRead :Long = 0;
			try {
				sizeRead = file.read(buff);
			} catch (e :CheckedThrowable) {
				// do nothing
			}
			if (sizeRead <= 0) {
				break;
			} else {
				try {
					stderr.write(buff, sizeRead);
				} catch (e :CheckedThrowable) {
					// do nothing
				}
				stderr.flush();
			}
		}
	}

}
