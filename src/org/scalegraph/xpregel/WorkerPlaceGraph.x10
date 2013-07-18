package org.scalegraph.xpregel;

import x10.util.Team;
import x10.util.ArrayList;
import x10.util.concurrent.AtomicLong;

import org.scalegraph.util.GrowableMemory;
import org.scalegraph.util.MemoryChunk;
import org.scalegraph.util.tuple.Tuple2;
import org.scalegraph.util.Bitmap;
import org.scalegraph.util.Team2;
import org.scalegraph.util.Parallel;

import org.scalegraph.blas.DistSparseMatrix;
import org.scalegraph.blas.SparseMatrix;
import org.scalegraph.graph.id.OnedC;
import org.scalegraph.graph.id.IdStruct;

import org.scalegraph.xpregel.VertexContext;
import org.scalegraph.util.DistMemoryChunk;
import x10.compiler.Native;

class WorkerPlaceGraph[V,E] {V haszero, E haszero} {
	static val MAX_OUTPUT_NUMBER = 8;
	
	val mTeam :Team2;
	val mIds :IdStruct;

	val mVtoD :OnedC.VtoD;
	val mDtoV :OnedC.DtoV;
	val mDtoS :OnedC.DtoS;
	val mStoD :OnedC.StoD;
	val mStoV :OnedC.StoV;
	
	var mVertexValue :MemoryChunk[V];
	val mVertexActive :Bitmap;
	val mVertexShouldBeActive :Bitmap;
	
	val mOutEdge :GraphEdge[E];
	val mInEdge :GraphEdge[E];
	var mInEdgesMask :Bitmap;

	val numThreads = Runtime.NTHREADS;
	var mLastAggVal :Any;
	val mOutput :MemoryChunk[MemoryChunk[MemoryChunk[Any]]];
	
	public def this(team :Team, ids :IdStruct) {
		val rank_c = team.role()(0);
		mTeam = new Team2(team);
		mIds = ids;
		
		mVtoD = new OnedC.VtoD(ids);
		mDtoV = new OnedC.DtoV(ids);
		mDtoS = new OnedC.DtoS(ids);
		mStoD = new OnedC.StoD(ids, rank_c);
		mStoV = new OnedC.StoV(ids, rank_c);
		
		val numVertexes = mIds.numberOfLocalVertexes();
		
		mVertexValue = new MemoryChunk[V](numVertexes);
		mVertexActive = new Bitmap(numVertexes, true);
		mVertexShouldBeActive = new Bitmap(numVertexes, true);

		mOutEdge = new GraphEdge[E]();
		mInEdge = new GraphEdge[E]();
		
		mOutput = new MemoryChunk[MemoryChunk[MemoryChunk[Any]]](numThreads,
				(Long)=>new MemoryChunk[MemoryChunk[Any]](MAX_OUTPUT_NUMBER));
		
		if (here.id == 0) {
			Console.OUT.println("lgl = " + mIds.lgl);
			Console.OUT.println("lgc = " + mIds.lgc);
			Console.OUT.println("lgr = " + mIds.lgr);	
		}
	}
	
	public def this(team :Team, edgeIndexMatrix :DistSparseMatrix[Long]) {
		this(team, edgeIndexMatrix.ids());
		mOutEdge.offsets = edgeIndexMatrix().offsets;
		mOutEdge.vertexes = edgeIndexMatrix().vertexes;
	}
	
	public def updateInEdge() {
		val numThreads = Runtime.NTHREADS;
		val mesComm = new MessageCommunicator[Long](mTeam, mIds, numThreads);
		val numLocalVertexes = mIds.numberOfLocalVertexes();
		val StoD = new OnedC.StoD(mIds, mTeam.base.role()(0));
		
		Parallel.iter(0..(numLocalVertexes-1), (tid :Long, r :LongRange) => {
			val UCCMessages = mesComm.messageBuffer(tid);
			val offset = mOutEdge.offsets;
			val id = mOutEdge.vertexes;
			for(vid in r) {
				val vid_ = StoD(vid);
				for(i in offset(vid)..(offset(vid + 1) - 1)) {
					val mesBuf = UCCMessages(mesComm.mDtoV.c(id(i)));
					mesBuf.messages.add(vid_);
					mesBuf.dstIds.add(mesComm.mDtoS(id(i)));
				}
			}
		});
		
		mesComm.preProcess(null);
		mesComm.exchangeMessages(true, false);

		mInEdge.offsets = mesComm.mUCROffset;
		mInEdge.vertexes = mesComm.mUCRMessages;
		mesComm.mUCROffset = new MemoryChunk[Long]();
		mesComm.mUCRMessages = new MemoryChunk[Long]();
		mesComm.del();
	}
	
	public def updateInEdgeWithValue() {
		val numThreads = Runtime.NTHREADS;
		val mesComm = new MessageCommunicator[Tuple2[Long, E]](mTeam, mIds, numThreads);
		val numLocalVertexes = mIds.numberOfLocalVertexes();
		val StoD = new OnedC.StoD(mIds, mTeam.base.role()(0));
		
		Parallel.iter(0..(numLocalVertexes-1), (tid :Long, r :LongRange) => {
			val UCCMessages = mesComm.messageBuffer(tid);
			val offset = mOutEdge.offsets;
			val id = mOutEdge.vertexes;
			val value = mOutEdge.value;
			for(vid in r) {
				val vid_ = StoD(vid);
				for(i in offset(vid)..(offset(vid + 1) - 1)) {
					val mesBuf = UCCMessages(mesComm.mDtoV.c(id(i)));
					mesBuf.messages.add(Tuple2[Long, E](vid_, value(i)));
					mesBuf.dstIds.add(mesComm.mDtoS(id(i)));
				}
			}
		});
		
		mesComm.preProcess(null);
		mesComm.exchangeMessages(true, false);
		
		val numEdges = mesComm.mUCRMessages.size();
		val id = new MemoryChunk[Long](numEdges);
		val value = new MemoryChunk[E](numEdges);
		Parallel.iter(0..(numEdges-1), (tid :Long, r :LongRange) => {
			for(i in r) {
				id(i) = mesComm.mUCRMessages(i).get1();
				value(i) = mesComm.mUCRMessages(i).get2();
			}
		});

		mInEdge.offsets = mesComm.mUCROffset;
		mInEdge.vertexes = id;
		mInEdge.value = value;
		
		mesComm.mUCROffset = new MemoryChunk[Long]();
		mesComm.del();
	}
	
	public def run(compute :(ctx :InitVertexContext[V,E]) => void)
	{
		val root = (mTeam.base.role()(0) == 0);
		val numThreads = Runtime.NTHREADS;
		val numLocalVertexes = mIds.numberOfLocalVertexes();
		val vctxs = new MemoryChunk[InitVertexContext[V, E]](numThreads,
				(i :Long) => new InitVertexContext[V, E](this));
		val edgeProviderList = new MemoryChunk[EdgeProvider[E]](numThreads,
				(i:Long) => vctxs(i).mEdgeProvider);
		
		Parallel.iter(0..(numLocalVertexes-1), (tid :Long, r :LongRange) => {
			val vc = vctxs(tid);
			val ep = vc.mEdgeProvider;
			for(srcid in r) {
				vc.mSrcid = srcid;
				if(mVertexShouldBeActive(srcid)) {
					
					compute(vc);

					if(ep.mEdgeChanged) ep.fixModifiedEdges(srcid);
				}
			}
		});
		
		// update out edges
		EdgeProvider.updateOutEdge[E](mOutEdge, edgeProviderList, mIds);
	}
	
	// src will be destroyed
	private static def computeAggregate[A](team :Team2, src :MemoryChunk[A], buffer :MemoryChunk[A],
			aggregator :(MemoryChunk[A])=>A) :A
	{
		val root = (team.base.role()(0) == 0);
		src(0) = aggregator(src);
		team.gather(0, src.subpart(0, 1), buffer);
		if(root) buffer(0) = aggregator(buffer);
		team.bcast(0, root ? buffer.subpart(0, 1) : buffer, src.subpart(0, 1));
		return src(0);
	}
	
	private static val STT_END_COUNT = 0;
	private static val STT_ACTIVE_VERTEX = 1;
	private static val STT_COMBINED_MESSAGE = 2;
	private static val STT_VERTEX_MESSAGE = 3;
	private static val STT_MAX = 4;

	private static def exchangeMessages[M](team :Team2,
			ectx :MessageCommunicator[M], statistics :MemoryChunk[Long]) { M haszero } :Boolean
	{
		// if end is satisfied, we skip message processing.
		if(statistics(STT_END_COUNT) == 0L) {
			// merge messages and combine if combiner is provided
			val [ numActive, numRawMessages, numCombinedMessages, numVertexMessages ]
					= ectx.preProcess(null);
			
			statistics(STT_ACTIVE_VERTEX) = numActive;
			statistics(STT_COMBINED_MESSAGE) = numCombinedMessages;
			statistics(STT_VERTEX_MESSAGE) = numVertexMessages;
		}
		else { // end is satisfied
			statistics(STT_ACTIVE_VERTEX) = 0L;
			statistics(STT_COMBINED_MESSAGE) = 0L;
			statistics(STT_VERTEX_MESSAGE) = 0L;
		}
		
		// check termination
		val recvStatistics = statistics.subpart(STT_MAX, STT_MAX);
		team.allreduce(statistics.subpart(0, STT_MAX), recvStatistics, Team.ADD);
		
		///
		if(here.id() == 0) {
			Console.OUT.println("TEAM_SIZE" + team.size());
			Console.OUT.println("STT_END_COUNT: " + recvStatistics(STT_END_COUNT));
			Console.OUT.println("STT_ACTIVE_VERTEX: " + recvStatistics(STT_ACTIVE_VERTEX));
			Console.OUT.println("STT_COMBINED_MESSAGE: " + recvStatistics(STT_COMBINED_MESSAGE));
			Console.OUT.println("STT_VERTEX_MESSAGE: " + recvStatistics(STT_VERTEX_MESSAGE));
		}
		
		
		if(recvStatistics(STT_END_COUNT) > 0) {
			// terminate
			return true;
		}
		// if there are no active vertex nor messages, we terminate computation.
		if(recvStatistics(STT_ACTIVE_VERTEX) == 0L &&
			recvStatistics(STT_COMBINED_MESSAGE) == 0L &&
			recvStatistics(STT_VERTEX_MESSAGE) == 0L)
		{
			return true;
		}
		
		// transfer messages
		ectx.exchangeMessages(
				recvStatistics(STT_COMBINED_MESSAGE) > 0L,
				recvStatistics(STT_VERTEX_MESSAGE) > 0L);
		
		return false;
	}
	
	public def run[M, A](compute :(ctx:VertexContext[V,E,M,A], messages:MemoryChunk[M]) => void, 
			aggregator :(MemoryChunk[A])=>A,
			end :(Int,A)=>Boolean) { M haszero, A haszero }
	{
		val root = (mTeam.base.role()(0) == 0);
		val numLocalVertexes = mIds.numberOfLocalVertexes();
		val ectx :MessageCommunicator[M] =
			new MessageCommunicator[M](mTeam, mIds, numThreads);
		val vctxs = new MemoryChunk[VertexContext[V, E, M, A]](numThreads,
				(i :Long) => new VertexContext[V, E, M, A](this, ectx, i));
		val edgeProviderList = new MemoryChunk[EdgeProvider[E]](numThreads,
				(i:Long) => vctxs(i).mEdgeProvider);
		val intermedAggregateValue = new MemoryChunk[A](numThreads);
		val aggregateBuffer = new MemoryChunk[A](root ? mTeam.size() : 0);
		val statistics = new MemoryChunk[Long](STT_MAX*2);

		ectx.mInEdgesOffset = mInEdge.offsets;
		ectx.mInEdgesVertex = mInEdge.vertexes;
		ectx.mInEdgesMask = mInEdgesMask;

		// initialize halt flag
		val vertexActvieBitmap = mVertexActive.raw();
		MemoryChunk.copy(mVertexShouldBeActive.raw(), 0L,
				vertexActvieBitmap, 0L, vertexActvieBitmap.size());
		
		for(ss in 0..10000) {
			ectx.mSuperstep = ss;
			
			Parallel.iter(0..(numLocalVertexes-1), (tid :Long, r :LongRange) => {
				val vc = vctxs(tid);
				val ep = vc.mEdgeProvider;
				val mesTempBuffer :GrowableMemory[M] = new GrowableMemory[M]();
				var numProcessed :Long = 0L;
				
				for(srcid in r) {
					vc.mSrcid = srcid;
					val mes = ectx.message(srcid, mesTempBuffer);
					if(mes.size() > 0 || mVertexActive(srcid)) {
						
						compute(vc, mes);

						if(ep.mEdgeChanged) ep.fixModifiedEdges(srcid);
						if(mVertexActive(srcid)) ++numProcessed;
					}
				}
				intermedAggregateValue(tid) = aggregator(vc.mAggregateValue.raw());
				vc.mAggregateValue.clear();
				vc.mNumActiveVertexes = numProcessed;
			});
			
			// gather statistics
			for(th in 0..(numThreads-1)) {
				ectx.sqweezeMessage(vctxs(th));
			}
			
			// update out edges
			EdgeProvider.updateOutEdge[E](mOutEdge, edgeProviderList, mIds);
			
			// aggregate
			val aggVal = computeAggregate[A](mTeam, intermedAggregateValue, aggregateBuffer, aggregator);
			for(i in vctxs.range()) vctxs(i).mAggregatedValue = aggVal;
			statistics(STT_END_COUNT) = end(ss, aggVal) ? 1L : 0L;
			
			// exchange messages
			if(exchangeMessages(mTeam, ectx, statistics)) {
				mLastAggVal = aggVal;
				break;
			}
		}
		
		mInEdgesMask = ectx.mInEdgesMask;
		
		ectx.del();
	}
	
	@Native("c++", "reinterpret_cast<org::scalegraph::util::MemoryChunk<#T > >(#v)")
	private static native def castTo[T](v :MemoryChunk[Any]) :MemoryChunk[T];
	
	public def stealOutput[T](index :Int) :MemoryChunk[T] {
		if(index > MAX_OUTPUT_NUMBER)
			throw new ArrayIndexOutOfBoundsException();
		
		var length :Long = 0L;
		for(i in 0..(numThreads-1)) {
			length += mOutput(i)(index).size();
		}
		
		val outMem = new MemoryChunk[T](length);
		var offset :Long = 0L;
		finish for(i in 0..(numThreads-1)) {
			val src_len = mOutput(i)(index).size();
			val offset_ = offset;
			async {
				MemoryChunk.copy(castTo[T](mOutput(i)(index)), 0L, outMem, offset_, src_len);
			}
			offset += src_len;
		}
		
		return outMem;
	}
}
