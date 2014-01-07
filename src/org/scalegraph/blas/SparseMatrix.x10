package org.scalegraph.blas;

import x10.util.Team;
import x10.compiler.Ifndef;
import x10.compiler.Ifdef;

import org.scalegraph.util.MemoryChunk;
import org.scalegraph.graph.id.IdStruct;
import org.scalegraph.graph.id.Twod;
import org.scalegraph.util.tuple.*;
import org.scalegraph.util.Parallel;
import org.scalegraph.util.Team2;
import org.scalegraph.util.Algorithm;
import org.scalegraph.test.STest;
import org.scalegraph.Config;

/** Sparse matrix representation.
 */
public final struct SparseMatrix[T] {
	public val offsets :MemoryChunk[Long];
	public val vertexes :MemoryChunk[Long];
	public val values :MemoryChunk[T];

	/** Returns the adjacency edge list for the specified vertex.
	 * @param localV The vertex ID in the local ID format.
	 */
	public def adjacency(localV :Long) =
		vertexes.subpart(offsets(localV), offsets(localV+1) - offsets(localV));

	/** Returns the edge values for the specified vertex.
	 * @param localV The vertex ID in the local ID format.
	 */
	public def attribute(localV :Long) =
		values.subpart(offsets(localV), offsets(localV+1) - offsets(localV));

	/** Returns the attribute values corresponds to the adjacency edges for the specified vertex.
	 * @param values Attribute values assigned for the current place.
	 * @param localV The vertex ID in the local ID format.
	 */
	public def attribute[T](values :MemoryChunk[T], localV :Long) =
		values.subpart(offsets(localV), offsets(localV+1) - offsets(localV));

	public def vertexRange() = 0..(offsets.size()-2);

	private def this(offsets :MemoryChunk[Long], vertexes :MemoryChunk[Long], values :MemoryChunk[T]) {
		this.offsets = offsets;
		this.vertexes = vertexes;
		this.values = values;
	}

	/** Constructs partial sparse matrix of the distributed sparse matrix.
	 * @param srcV This will be deleted.
	 * @param dstV This will be deleted.
	 * @param values The edge values corresponds to the edge list. This will be deleted.
	 * @param ids IdStruct that provides the distribution information.
	 */
	public def this(srcV :MemoryChunk[Long], dstV :MemoryChunk[Long], values: MemoryChunk[T], ids :IdStruct) {
		val sw = Config.get().stopWatch();

		if(srcV.size() == 0L) { // shortcut
			this.offsets = MemoryChunk.getNull[Long]();
			this.vertexes = MemoryChunk.getNull[Long]();
			this.values = MemoryChunk.getNull[T]();
			return ;
		}

		Parallel.iter(srcV.range(), (tid :Long, r :LongRange):void => {
			val VtoS = Twod.VtoS(ids);
			val VtoD = Twod.VtoD(ids);

			for(i in r) {
				srcV(i) = VtoS(srcV(i));
				dstV(i) = VtoD(dstV(i));
			}
		});
		if(here.id == 0) sw.lap("finished converting edge format");

		val offsetLength = 1L << (ids.lgl + ids.lgc);

		val offsets_ = new MemoryChunk[Long](offsetLength + 1);
		val origin = new MemoryChunk[Long](srcV.size());
		val target = new MemoryChunk[Long](srcV.size());
		val values_ = new MemoryChunk[T](srcV.size());
		// if gathering outer edges, origin is source and target is destination.
		// if gathering inner edges, origin is destination and target is source.

		@Ifdef("PROF_XP") { STest.bufferedPrintln("$ MEM-CONS-MAX: place: " + here.id +
				": TotalMem: " + MemoryChunk.getMemSize() + ": GCMem: " + MemoryChunk.getGCMemSize() + ": ExpMem: " + MemoryChunk.getExpMemSize()); }

		if(here.id == 0) sw.lap("start first step sorting");
		if(!ids.transpose)
			Parallel.sort(ids.lgl + ids.lgc, srcV, dstV, values, origin, target, values_);
		else
			Parallel.sort(ids.lgl + ids.lgc, dstV, srcV, values, origin, target, values_);
		if(here.id == 0) sw.lap("finished first step sorting");
		
		srcV.del();
		dstV.del();
		values.del();
		
		Parallel.makeOffset(origin, offsets_);
		origin.del();
		if(here.id == 0) sw.lap("finished making offsets");

		Parallel.iter(0L..(offsetLength-1), (tid :Long, r :LongRange) => {
			for(i in r) {
				val off = offsets_(i);
				val len = offsets_(i+1) - off;
				Algorithm.sort(target.subpart(off, len), values_.subpart(off, len));
			}
		});
		if(here.id == 0) sw.lap("finished second step sorting");

		this.offsets = offsets_;
		this.vertexes = target;
		this.values = values_;

		@Ifdef("PROF_XP") { STest.bufferedPrintln("$ MEM-CONS-FIN: place: " + here.id +
				": TotalMem: " + MemoryChunk.getMemSize() + ": GCMem: " + MemoryChunk.getGCMemSize() + ": ExpMem: " + MemoryChunk.getExpMemSize()); }
	}

	/** Constructs non-distributed sparse matrix.
	 * @param edges The edge list.
	 * @param indexes The indexes corresponds to the edge list.
	 * @param lgl The number of bits for the vertex ID.
	 */
	public def this(srcV :MemoryChunk[Long], dstV :MemoryChunk[Long], values: MemoryChunk[T], lgl :Int, transpose :Boolean) {

		if(srcV.size() == 0L) { // shortcut
			this.offsets = MemoryChunk.getNull[Long]();
			this.vertexes = MemoryChunk.getNull[Long]();
			this.values = MemoryChunk.getNull[T]();
			return ;
		}

		val offsetLength = 1L << lgl;

		val offsets_ = new MemoryChunk[Long](offsetLength + 1);
		val origin = new MemoryChunk[Long](srcV.size());
		val target = new MemoryChunk[Long](srcV.size());
		val values_ = new MemoryChunk[T](srcV.size());

		//if(!transpose)
			Parallel.sort(lgl, srcV, dstV, values, origin, target, values_);
		//else
		//	Parallel.sort(lgl, dstV, srcV, values, origin, target, values_);
		
		Parallel.makeOffset(origin, offsets_);

		Parallel.iter(1L..(offsetLength-1), (tid :Long, r :LongRange) => {
			for(i in r) {
				val off = offsets_(i);
				val len = offsets_(i+1) - off;
				Algorithm.sort(target.subpart(off, len), values.subpart(off, len));
			}
		});

		this.offsets = offsets_;
		this.vertexes = target;
		this.values = values;
	}

	/** Creates replica of the sparse matrix on each place of team.
	 * @param sparseMatrix The sparse matrix that will be copied.
	 * @param team The sparse matrix is created on each place of the team.
	 */
	public static def makeReplica[T](sparseMatrix :SparseMatrix[T], team :Team) {
		val root = team.role()(0);
		val numVerts = sparseMatrix.offsets.size();
		val numEdges = sparseMatrix.vertexes.size();
		val ref_matrix = new GlobalRef[Cell[SparseMatrix[T]]]
				(new Cell[SparseMatrix[T]](sparseMatrix));

		return PlaceLocalHandle.make[Cell[SparseMatrix[T]]](team.placeGroup(), () => {
			val offsets = new MemoryChunk[Long](numVerts);
			val vertexes = new MemoryChunk[Long](numEdges);
			val values = new MemoryChunk[T](numEdges);

			val team2 = new Team2(team);
			if(ref_matrix.home == here) { // root
				val m = ref_matrix.getLocalOrCopy()();
				team2.scatter(root, m.offsets, offsets);
				team2.scatter(root, m.vertexes, vertexes);
				team2.scatter(root, m.values, values);
			}
			else {
				team2.scatter(root, MemoryChunk.getNull[Long](), offsets);
				team2.scatter(root, MemoryChunk.getNull[Long](), vertexes);
				team2.scatter(root, MemoryChunk.getNull[T](), values);
			}

			return new Cell[SparseMatrix[T]](new SparseMatrix[T](offsets, vertexes, values));
		});
	}
	
	public def simplify(removeDuplicates :Boolean, removeSelfloops :Boolean, reduction :(MemoryChunk[T]) => T)
	{
		if(!removeDuplicates && !removeSelfloops) return ;
		
		var dstIdx :Long = 0L;
		var cachedOffset :Long = offsets(0);
		for(i in 1L..(offsets.size()-2)) {
			val off = cachedOffset;
			val next = offsets(i+1);
			var prev :Long = -1L;
			var prev_idx :Long = -1L;
			for(var ei :Long = off; ei < next;) {
				val v = vertexes(ei);
				if(removeSelfloops && v == i) ++ei;
				else if(removeDuplicates && v == prev) {
					for( ++ei; ei < next; ++ei) {
						if(vertexes(ei) != prev) break;
					}
					values(dstIdx-1) = reduction(values.subpart(prev_idx, ei - prev_idx));
					continue;
				} else {
					prev = v;
					prev_idx = ei;
					vertexes(dstIdx) = v;
					values(dstIdx) = values(ei);
					++dstIdx; ++ei;
				}
			}
			cachedOffset = next;
			offsets(i+1) = dstIdx;
		}
	}
}
