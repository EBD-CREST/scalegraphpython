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

package test;

import x10.util.Team;

import org.scalegraph.test.STest;
import org.scalegraph.io.SimpleText;
import org.scalegraph.io.CSV;
import org.scalegraph.util.tuple.*;
import org.scalegraph.fileread.DistributedReader;
import org.scalegraph.util.Dist2D;
import org.scalegraph.util.MathAppend;
import org.scalegraph.util.MemoryChunk;
import org.scalegraph.util.DistMemoryChunk;
import org.scalegraph.util.SString;
import org.scalegraph.graph.Graph;
import org.scalegraph.blas.GIMV;

final class GIMVGraphTest extends STest {
	public static def main(args: Rail[String]) {
		new GIMVGraphTest().execute(args);
	}
	
	public static inputFormat_g1 = (s :SString)=> {
		val elements = s.split(",").iterator_();
		val v0 = elements.next().toLong();
		val v1 = elements.next().toLong();
		elements.next();
		val wgt = elements.next().toDouble();
		return Tuple3[Long, Long, Double](v0, v1, wgt);
	};
	public static inpurFormat_g2 = (s :SString)=> {
		val elements = s.split(",").iterator_();
		val v0 = elements.next().toLong();
		val v1 = elements.next().toLong();
		val wgt = elements.next().toDouble();
		return Tuple3[Long, Long, Double](v0, v1, wgt);
	};
	
	public static def read_graph(srcfile :String, team :Team, useTranslator :Boolean) : Graph{self.vertexType==Graph.VertexType.Long} {
		Console.OUT.println("Reading file: " + srcfile + " ...");
		
		val format = srcfile.endsWith(".txt") ? inputFormat_g1 : inpurFormat_g2;
		val g = Graph.make(SimpleText.read[Double](srcfile, format));
		
		// chech results
		Console.OUT.println("# of Verteices: " + g.numberOfVertices() + ", # of Edges: " + g.numberOfEdges());
		
		return g;
	}
	
	public static def ditributed_2dcsr_test(srcfile :String, RC :String) {
		val team = Team.WORLD;
		val g = read_graph(srcfile, team, true);
		
		val rxc = RC.split("x");
		val R = Int.parse(rxc(0));
		val C = Int.parse(rxc(1));
		val dist2d = Dist2D.make2D(team, R, C);
		
		Console.OUT.println("Constructing 2DCSR [directed, inner] ...");
		
		// undirected, inner edge
		val csr1 = g.createDistEdgeIndexMatrix(dist2d, true, false);
		val att1 = g.createDistAttribute[Double](csr1, false, "weight");

		// chech results
		for(p in team.placeGroup()) at (p) {
			val matrix = csr1();
			Console.OUT.println("Place: " + p.id + ", # of vertices: " + matrix.offsets.size() + ", # of edges: " + matrix.vertexes.size() + ", # of weights: " + att1().size());
		}
		
		Console.OUT.println("Constructing 2DCSR [undirected, outer] ...");
		
		// undirected, inner edge
		val csr2 = g.createDistEdgeIndexMatrix(dist2d, false, true);
		val att2 = g.createDistAttribute[Double](csr2, false, "weight");

		// chech results
		for(p in team.placeGroup()) at (p) {
			val matrix = csr2();
			Console.OUT.println("Place: " + p.id + ", # of vertices: " + matrix.offsets.size() + ", # of edges: " + matrix.vertexes.size() + ", # of weights: " + att2().size());
		}
		
		
		Console.OUT.println("Complete!!!");
	}
	public static def ditributed_1dcsr_test(srcfile :String, RC :String) {
		val team = Team.WORLD;
		val g = read_graph(srcfile, team, true);
		
		val distRow = Dist2D.make1D(team, Dist2D.DISTRIBUTE_ROWS);
		
		Console.OUT.println("Constructing Row-Distributed CSR [directed, inner] ...");
		
		// undirected, inner edge
		val csr1 = g.createDistEdgeIndexMatrix(distRow, true, false);
		val att1 = g.createDistAttribute[Double](csr1, false, "weight");

		// chech results
		for(p in team.placeGroup()) at (p) {
			val matrix = csr1();
			Console.OUT.println("Place: " + p.id + ", # of vertices: " + matrix.offsets.size() + ", # of edges: " + matrix.vertexes.size() + ", # of weights: " + att1().size());
		}

		val distColumn = Dist2D.make1D(team, Dist2D.DISTRIBUTE_COLUMNS);
		
		Console.OUT.println("Constructing Column-Distributed CSR [undirected, outer] ...");
		
		// undirected, inner edge
		val csr2 = g.createDistEdgeIndexMatrix(distColumn, false, true);
		val att2 = g.createDistAttribute[Double](csr2, false, "weight");

		// chech results
		for(p in team.placeGroup()) at (p) {
			val matrix = csr2();
			Console.OUT.println("Place: " + p.id + ", # of vertices: " + matrix.offsets.size() + ", # of edges: " + matrix.vertexes.size() + ", # of weights: " + att2().size());
		}
		
		Console.OUT.println("Complete!!!");
	}
	
	public static def normalize_columns_weights(g : Graph) {
		val team = Team.WORLD;
		
		Console.OUT.println("Constructing column distributed graph ...");
		
		val distColumn = Dist2D.make1D(team, Dist2D.DISTRIBUTE_COLUMNS);
		// directed, outer
		val columnDistGraph = g.createDistEdgeIndexMatrix(distColumn, true, true);
		val columnDistWeight = g.createDistAttribute[Double](columnDistGraph, false, "weight");
		
		Console.OUT.println("Normalizing weights ...");
		
		team.placeGroup().broadcastFlat(() => {
			val localsize = 1L << columnDistGraph.ids().lgl;
			val m = columnDistGraph();
			val w = columnDistWeight();
			
			for(i in 0L..(localsize-1)) {
				val wl = m.attribute[Double](w, i);
				val inv = 1.0 / MathAppend.sum(wl);
				for(j in wl.range()) wl(j) *= inv;
			}
		});
		
		Console.OUT.println("Writing back the weights ...");
		
		g.setEdgeAttribute("normalized_weight", columnDistGraph, columnDistWeight);
		
		Console.OUT.println("Deleting objects ...");
		
		team.placeGroup().broadcastFlat(() => {
			columnDistWeight.del();
			columnDistGraph.del();
			distColumn.del();
		});
	}
	
	private static def print_attribute_list(g :Graph) {
		var str :String = "Vertex attribute: [";
		for(key in g.vertexAttributeKeys())
			str += key + ",";
		str += "]";
		Console.OUT.println(str);
		str = "Edge attribute: [";
		for(key in g.edgeAttributeKeys())
			str += key + ",";
		str += "]";
		Console.OUT.println(str);
	}
	
	public static def ditributed_gimv_test(srcfile :String, RC :String) {
		val team = Team.WORLD;
		val useTranslator = true;
		val g = read_graph(srcfile, team, useTranslator);

		Console.OUT.println("Constructing 2DCSR [directed, inner] ...");
		
		val rxc = RC.split("x");
		val R = Int.parse(rxc(0));
		val C = Int.parse(rxc(1));
		val dist2d = Dist2D.make2D(team, R, C);
		
		// undirected, inner edge
		val csr = g.createDistEdgeIndexMatrix(dist2d, true, false);
		val weight = g.createDistAttribute[Double](csr, false, "weight");

		// check results
		for(p in team.placeGroup()) at (p) {
			val matrix = csr();
			Console.OUT.println("Place: " + p.id + ", # of vertices: " + matrix.offsets.size() + ", # of edges: " + matrix.vertexes.size() + ", # of weights: " + weight().size());
		}

		val map = (mij :Double , vj :Double) => 1.0;
		val combine = (index :Long, xs :MemoryChunk[Double]) => MathAppend.sum(xs);
		val assign = (i :Long, prev :Double , next :Double) => next;
		val end = (diff :Double) => true;
		
		val vector = new DistMemoryChunk[Double](team.placeGroup(),
				() => MemoryChunk.make[Double](csr.ids().numberOfLocalVertexes2N()));
		
		GIMV.main2DCSR(csr, weight, vector, map, combine, assign, end);
		
		g.setVertexAttribute("degree", csr, vector);
		print_attribute_list(g);

		val att_pagerank = g.getVertexAttribute[Double]("degree");
		if(useTranslator)
			DistributedReader.write("degree-%d.txt", g.getVertexAttribute[Long]("name"), att_pagerank);
		else
			DistributedReader.write("degree-%d.txt", att_pagerank);
		
		Console.OUT.println("Complete!!!");
	}
	
	public static def ditributed_sssp_test(srcfile :String, RC :String) {
		val team = Team.WORLD;
		val g = read_graph(srcfile, team, true);
		print_attribute_list(g);
		
		Console.OUT.println("Constructing 2DCSR [directed, inner] ...");
		
		val rxc = RC.split("x");
		val R = Int.parse(rxc(0));
		val C = Int.parse(rxc(1));
		val dist2d = Dist2D.make2D(team, R, C);
		
		// directed, inner edge
		val csr = g.createDistEdgeIndexMatrix(dist2d, true, false);
		val weight = g.createDistAttribute[Double](csr, false, "weight");

		// check results
		for(p in team.placeGroup()) at (p) {
			val matrix = csr();
			Console.OUT.println("Place: " + p.id + ", # of vertices: " + matrix.offsets.size() + ", # of edges: " + matrix.vertexes.size() + ", # of weights: " + weight().size());
		}

		val initValue = 1000.0;
		val map = (mij :Double , vj :Double) => mij + vj;
		val combine = (index :Long, xs :MemoryChunk[Double]) =>
				xs.size() == 0L ? initValue : MathAppend.min(xs);
		val assign = (i :Long, prev :Double , next :Double) => Math.min(prev, next);
		val end = (diff :Double) => diff == 0.0;//Math.sqrt(diff) < 0.0001;
		
		val vector = new DistMemoryChunk[Double](team.placeGroup(),
				() => MemoryChunk.make[Double](csr.ids().numberOfLocalVertexes2N()));
		
		team.placeGroup().broadcastFlat(() => {
			val v = vector();
			for(i in v.range()) v(i) = initValue;
			if(team.role()(0) == 0n) v(0) = 0.0;
		});
		
		if(C == 1n) { // 1D
			Console.OUT.println("Using 1D GIM-V Engine ...");
			GIMV.main1DCSR(csr, weight, vector, map, combine, assign, end);
		}
		else {
			Console.OUT.println("Using 2D GIM-V Engine ...");
			GIMV.main2DCSR(csr, weight, vector, map, combine, assign, end);
		}
		
		g.setVertexAttribute("distance", csr, vector);
		print_attribute_list(g);

		val att_names = g.getVertexAttribute[Long]("name");
		val att_pagerank = g.getVertexAttribute[Double]("distance");
		DistributedReader.write("output-%d.txt", att_names, att_pagerank);
		
		Console.OUT.println("Complete!!!");
	}
	
	public static def ditributed_pagerank_test(srcfile :String, RC :String) {
		val team = Team.WORLD;
		val g = read_graph(srcfile, team, true);
		print_attribute_list(g);
		
		val att_names = g.getVertexAttribute[Long]("name");
		
		// normalize weight //
		normalize_columns_weights(g);
		print_attribute_list(g);

		//	val att_norm = g.getEdgeAttribute[Double]("normalized_weight");
		//	DistributedReader.write("norm-%d.txt", team, null, att_norm);
		
		Console.OUT.println("Constructing 2DCSR [directed, inner] ...");
		
		val rxc = RC.split("x");
		val R = Int.parse(rxc(0));
		val C = Int.parse(rxc(1));
		val dist2d = Dist2D.make2D(team, R, C);
		
		// directed, inner edge
		val csr = g.createDistEdgeIndexMatrix(dist2d, true, false);
		val weight = g.createDistAttribute[Double](csr, false, "normalized_weight");

		// check results
		for(p in team.placeGroup()) at (p) {
			val matrix = csr();
			Console.OUT.println("Place: " + p.id + ", # of vertices: " + matrix.offsets.size() + ", # of edges: " + matrix.vertexes.size() + ", # of weights: " + weight().size());
		}

		val n = g.numberOfVertices();
		val c = 0.85;
		val map = (mij :Double , vj :Double) => c * mij * vj;
		val combine = (index :Long, xs :MemoryChunk[Double]) => MathAppend.sum(xs);
		val assign = (i :Long, prev :Double , next :Double) => (1.0 - c) / n + next;
		val end = (diff :Double) => false;//Math.sqrt(diff) < 0.0001;
		
		val vector = new DistMemoryChunk[Double](team.placeGroup(),
				() => MemoryChunk.make[Double](csr.ids().numberOfLocalVertexes2N()));
		
		team.placeGroup().broadcastFlat(() => {
			val iv = 1.0 / n;
			val v = vector();
			for(i in v.range()) v(i) = iv;
		});
		
		if(C == 1n) { // 1D
			Console.OUT.println("Using 1D GIM-V Engine ...");
			GIMV.main1DCSR(csr, weight, vector, map, combine, assign, end);
		}
		else {
			Console.OUT.println("Using 2D GIM-V Engine ...");
			GIMV.main2DCSR(csr, weight, vector, map, combine, assign, end);
		}
		
		g.setVertexAttribute("pagerank", csr, vector);
		print_attribute_list(g);
		
		val att_pagerank = g.getVertexAttribute[Double]("pagerank");
		DistributedReader.write("output-%d.txt", att_names, att_pagerank);
		
		Console.OUT.println("Complete!!!");
	}
	
    public def run(args: Rail[String]): Boolean {
        val file = "/nfs/data0/testdata/WEIGHTED_COMMA_SPLIT_RMAT_SCALE_20";
        val parttition = "1x" + Place.MAX_PLACES;
        ditributed_sssp_test(file, parttition);
        
        return true;
    }
    
}
