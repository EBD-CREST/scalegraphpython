package org.scalegraph.graph;

import x10.matrix.dist.DistDenseMatrix;
import x10.matrix.block.Grid;
import x10.util.Pair;
import x10.array.DistArray;
import x10.util.ArrayList;

import org.scalegraph.graph.GraphSizeCategory;
import org.scalegraph.util.Matrix;
import org.scalegraph.util.ScaleGraphMath;

/**
 * The class PlainGraph represents an Attribute-less graph. Any of the Vertices or Edges of this Graph do not contain attributes. The PlainGraph has been modeled in an Adjacency Matrix.
 * The PlainGraph can increase/decrease it's size on demand. If there are multiple edges between two vertices (E.g. n), then the cell corresponding to the egdes contains n as the value.
 */
public class PlainGraph implements Graph{
	private var isDirected:Boolean;						//Indicates whether the Graph is a directed one or not
	private var adjacencyList:DistArray[PlainGraphRecord]; 
	private var vertexIncrementFactor:Double = 3;		//This is the times the matrix is increased by its size
	private var sizeCategory:Short = -1;				//The size of the Graph
	private var nVertices:Int = -1;
	private var workerThreadCount:Int = 100;			//The number of threads that run simultaneously
	
	/**
     * Default constructor 
     */
    public def this() {
    	//By default the graph size category is set to SMALL
    	this.sizeCategory = GraphSizeCategory.SMALL;
    	
    	//Set the initial row, column sizes
    	vertexIncrementFactor = sizeCategory; //In this case it will be a small Graph created in one single node.
    	    	
    	nVertices = ScaleGraphMath.pow(2, vertexIncrementFactor as Int) as Int;
    	Console.OUT.println(nVertices);
    	
    	var R2:Region = (1..1)*(1..nVertices);
    	var b:Dist = Dist.makeBlock(R2);
    	adjacencyList = DistArray.make[PlainGraphRecord](b, new PlainGraphRecord());
    }
    
    /**
     * This constructor accepts the size category of the graph
     * @param sizeCat the size cateegory of the Graph. This is one of the fields from GraphSizeCategory class. 
     */
    public def this(val sizeCat:Short) {
    	if((sizeCat == GraphSizeCategory.SMALL) || (sizeCat == GraphSizeCategory.MEDIUM) || (sizeCat == GraphSizeCategory.LARGE)){
    		//Set the size category of the Graph
    		this.sizeCategory = sizeCat;
    		var R2:Region = null;
    		
    		Console.OUT.println(Place.MAX_PLACES);
    		
    		if(sizeCat == GraphSizeCategory.SMALL){
    			vertexIncrementFactor = sizeCat;
    			nVertices = ScaleGraphMath.pow(2, vertexIncrementFactor as Int) as Int;
    			R2 = (1..1)*(1..nVertices);
    		}else if((sizeCat == GraphSizeCategory.LARGE) || (sizeCat == GraphSizeCategory.MEDIUM)){
    			vertexIncrementFactor = GraphSizeCategory.MEDIUM;
    			nVertices = ScaleGraphMath.pow(2, vertexIncrementFactor as Int) as Int;
    			
    			Console.OUT.println("nVertices : " + nVertices);
    			
    			R2 = (1..Place.MAX_PLACES)*(1..nVertices);
    		}
    		    		
    		//Console.OUT.println("nVertices : " + nVertices);
    		//var R2:Region = (1..1)*(1..nVertices);
    		var b:Dist = Dist.makeBlock(R2);
    		Console.OUT.println("Start creating the array");
    		adjacencyList = DistArray.make[PlainGraphRecord](b, new PlainGraphRecord());
    		
    		Console.OUT.println("Init size : " + adjacencyList.getLocalPortion().size);
    		
    	}else{
    		throw new UnsupportedOperationException("Invalid Graph Size Category was specified : " + sizeCat);    		
    	}
    }
    
    public def init(){
    	finish for(p in adjacencyList.dist.places()){
    		val r:Region = adjacencyList.dist.get(p);
    		
    		async at(p){
    			for(point:Point in r){
    				adjacencyList(point) = new PlainGraphRecord();
    			}
    		}
    	}
    	
    	Console.OUT.println("Done Init... ");
    }
    
    /**
     * This constructor accepts the initial size of the Graph to be created. This can be used if the user has an idea the size
     * of the Graph he/she handles.
     * @param scale the scale of the graph to be created
     * @param sizeCat the size cateegory of the Graph. This is one of the fields from GraphSizeCategory class. 
     */
    public def this(val scale:Int, val sizeCat:Short){
    	
    	if((sizeCat == GraphSizeCategory.SMALL) || (sizeCat == GraphSizeCategory.MEDIUM) || (sizeCat == GraphSizeCategory.LARGE)){

    		if((sizeCat == GraphSizeCategory.SMALL) || (sizeCat == GraphSizeCategory.MEDIUM)){
    			if(scale > sizeCat){
    				throw new UnsupportedOperationException("The scale specified exceeds the Graph Size Category : " + sizeCat);    				
    			}
    		}
    		
    		if(sizeCat == GraphSizeCategory.SMALL){
    			vertexIncrementFactor = sizeCat;
    		}else if((sizeCat == GraphSizeCategory.LARGE) || (sizeCat == GraphSizeCategory.MEDIUM)){
    			vertexIncrementFactor = GraphSizeCategory.MEDIUM * Place.MAX_PLACES;
    		}
	    	
	    	nVertices = ScaleGraphMath.pow(2, vertexIncrementFactor as Int) as Int;
	    	var R2:Region = (1..1)*(1..nVertices);
	    	var b:Dist = Dist.makeBlock(R2);
	    	adjacencyList = DistArray.make[PlainGraphRecord](b, new PlainGraphRecord());
    	}else{
    		throw new UnsupportedOperationException("Invalid Graph Size Category was specified : " + sizeCat);
    	}
    }
    
    /**
     * This constructor accepts a Matrix having the graph contents
     * 
     * @param mat A Matrix holding the initial Graph contents
     */
    public def this(var mat:Matrix) { 	
    	//By default the graph size category is set to SMALL
    	
    	var lDim:Long = mat.getDimensions().first > mat.getDimensions().second ? mat.getDimensions().first:mat.getDimensions().second; 
    	
    	if((lDim < ScaleGraphMath.pow(2, GraphSizeCategory.SMALL))){
    		this.sizeCategory = GraphSizeCategory.SMALL;
    	}else if((lDim > ScaleGraphMath.pow(2, GraphSizeCategory.SMALL))&&(lDim < ScaleGraphMath.pow(2, GraphSizeCategory.MEDIUM))){
    		this.sizeCategory = GraphSizeCategory.MEDIUM;
    	}else{
    		this.sizeCategory = GraphSizeCategory.LARGE;
    	}
    	
    	//Set the initial row, column sizes
    	if((this.sizeCategory == GraphSizeCategory.MEDIUM)||((this.sizeCategory == GraphSizeCategory.LARGE))){
    		nVertices = (ScaleGraphMath.pow(2, GraphSizeCategory.MEDIUM) * Place.MAX_PLACES) as Int;
    	}else{
    		nVertices = ScaleGraphMath.pow(2, GraphSizeCategory.SMALL) as Int;
    	}
    	
    	var R2:Region = (1..1)*(1..nVertices);
    	var b:Dist = Dist.makeBlock(R2);
    	adjacencyList = DistArray.make[PlainGraphRecord](b, new PlainGraphRecord());
    }
    
    /**
     * This constructor accepts the size category of the graph and a Matrix having the graph contents
     * 
     * @param sizeCat the size cateegory of the Graph. This is one of the fields from GraphSizeCategory class.
     * @param mat A Matrix holding the initial Graph contents
     */
    public def this(val sizeCat:Short, var mat:Matrix) {
   	
    	if((mat.getDimensions().first > ScaleGraphMath.pow(2,sizeCat))&&(mat.getDimensions().second > ScaleGraphMath.pow(2,sizeCat))){
    		throw new UnsupportedOperationException("The input matrix's scale exceeds the Graph size category.");
    	}
    	
    	if((sizeCat == GraphSizeCategory.SMALL) || (sizeCat == GraphSizeCategory.MEDIUM) || (sizeCat == GraphSizeCategory.LARGE)){
    		//Set the size category of the Graph
    		this.sizeCategory = sizeCat;
    		//Set the initial row, column sizes
    		vertexIncrementFactor = ((Math.pow(2, vertexIncrementFactor) < Place.places().size)) ? Place.places().size as Double : vertexIncrementFactor;
    		
    		nVertices = ScaleGraphMath.pow(2, vertexIncrementFactor as Int) as Int;
    		var R2:Region = (1..nVertices)*(1..1);
    		var b:Dist = Dist.makeBlock(R2);
    		adjacencyList = DistArray.make[PlainGraphRecord](b, new PlainGraphRecord());
    	}else{
    		throw new UnsupportedOperationException("Invalid Graph Size Category was specified : " + sizeCat);    		
    	}
    }
    
    /**
     * This constructor accepts the initial size of the Graph to be created. This can be used if the user has an idea the size
     * of the Graph he/she handles.
     * 
     * @param  scale the scale of the graph to be created
     * @param sizeCat the size cateegory of the Graph. This is one of the fields from GraphSizeCategory class.
     * @param mat A Matrix holding the initial Graph contents
     */
    public def this(val scale:Int, val sizeCat:Short, var mat:Matrix){
    	
    	if((mat.getDimensions().first > scale)&&(mat.getDimensions().second > scale)){
    		throw new UnsupportedOperationException("The input matrix's scale exceeds the specified scale");
    	}
    	
    	if((sizeCat == GraphSizeCategory.SMALL) || (sizeCat == GraphSizeCategory.MEDIUM) || (sizeCat == GraphSizeCategory.LARGE)){
    		//Set the size category of the Graph
    		this.sizeCategory = sizeCat;
    		
    		//Set the initial row, column sizes
    		vertexIncrementFactor = scale;
    		
    		nVertices = ScaleGraphMath.pow(2, vertexIncrementFactor as Int) as Int;
    		var R2:Region = (1..1)*(1..nVertices);
    		var b:Dist = Dist.makeBlock(R2);
    		adjacencyList = DistArray.make[PlainGraphRecord](b, new PlainGraphRecord());
    	}else{
    		throw new UnsupportedOperationException("Invalid Graph Size Category was specified : " + sizeCat);
    	}
    }
    
    
    /**
     * This method returns the Vertex count of the PlainGraph
     */
    public def getVertexCount():Long{
    	val vCount = GlobalRef[Cell[Long]](new Cell[Long](0));
    	
    	finish for(p in adjacencyList.dist.places()){
    		at(p)async{
    			var l:Array[PlainGraphRecord] = adjacencyList.getLocalPortion();
    			
    			for(item in l){
    				vCount()() += l(item(0),item(1)).id > 0 ? 1:0;
    			}
    		}
    	}
    	
    	return vCount()();
    }    
    
    /**
     * This method is used to know whether the PlainGraph is directed or not
     * 
     * @return if true the PlainGraph is directed
     */
    public def isDirected():x10.lang.Boolean {
    	return isDirected;
    }

    /**
     * This method is used to set the PlainGraph as directed or undirected.
     * 
     * @param if true the Graph is considered as a directed PlainGraph
     */
    public def setDirected(var id:x10.lang.Boolean):void {
    	this.isDirected = id;
    }

    /**
     * Creates a new Graph having the same number of Vertices as the bigger Graph comparing this Graph with the input Graph.
     * 
     * @return a PlainGraph with the composition results
     */
    public def composition():org.igraphx10.graph.PlainGraph {
    	throw new UnsupportedOperationException("Not implemented.");
    }

    /**
     * The method compares this PlainGraph with another PlainGraph.
     * 
     * @parem A PlainGraph object which need to be compared with this
     * @return 0 - If this PlainGraph is equivalent to the input PlainGraph. Total Equivalency of two PlainGraphs is
     *             determined by considering the similarity of the two Adjacency Matrices.
     *         1 - If this PlainGraph has more Vertices than the input Graph
     *         -1 - If this PlainGraph has less Vertices compared to the input
     */
    public def compareTo(var id:org.igraphx10.graph.Graph):x10.lang.Int {
    	throw new UnsupportedOperationException("Not implemented.");
    }

    /**
     * Creates a new PlainGraph which complements this PlainGraph.
     * 
     * @return A complement version of this PlainGraph
     */
    public def complement():org.igraphx10.graph.PlainGraph {
    	throw new UnsupportedOperationException("Not implemented.");
    }

    /**
     * The method defines how this PlainGraph is Equal to another PlainGraph.
     * 
     * @param a PlainGraph that need to be compared with this
     * @return true if the two plain Graphs are equivalent
     */
    public def equals(var that:org.igraphx10.graph.Graph):x10.lang.Boolean {
    	if(this.compareTo(that as PlainGraph) == 0){
    		return true;
    	}else{
    		return false;
    	}
    }

    /**
     * Creates a new Graph by taking the difference between a Graph with this Graph object considering their Vertices.
     * 
     * @param the PlainGraph that need to be subtracted
     * @return a PlainGraph that contains the subtracted result
     */
    public def substract(var id:org.igraphx10.graph.Graph):org.igraphx10.graph.PlainGraph {
		throw new UnsupportedOperationException("Not implemented.");
    }

    /**
     * Adds a new Vertex object to the PlainGraph.
     * 
     * @param the Vertex that needs to be added to the PlainGraph
     */
    public def addVertex(var id:Object):void {
    	var e:String = id as String;
    	val vertex:Long = Long.parse(e);
    	val internal_vertex:Int;
    	  
    	if(sizeCategory == GraphSizeCategory.SMALL){
    		internal_vertex = vertex as Int; //In this case it is safe to cast the vertex to Int because it is in the scale of small Graph
    		
	    		if(here.id == 0)
	    		{
	    			var l:Array[PlainGraphRecord] = adjacencyList.getLocalPortion() as Array[PlainGraphRecord];
	    			
	    			if(l(1,internal_vertex).isEmpty()){
	    				l(1,internal_vertex).id = vertex;
	    				l(1,internal_vertex).edges = new ArrayList[Long]();
	    			}	    			
	    		}	
    		}else if(sizeCategory == GraphSizeCategory.MEDIUM){
    			if(vertex > (ScaleGraphMath.pow(2,sizeCategory) * Place.places().size())){
    				var message:String = "The vertex is not supported by the graph.";
    				message = message + " Current graph size is : " + sizeCategory;
    				throw new UnsupportedOperationException(message);
    			}else{
    				var v:Long = ScaleGraphMath.pow(2,sizeCategory);
    				val machine:Int = ScaleGraphMath.round(vertex/v) as Int;
    				internal_vertex = (vertex % v) as Int;
    				//internal_vertex = vertex as Int;

    				for(p in adjacencyList.dist.places()){
    					if(p.id == machine){
    						at(p){
    						val r:Region = adjacencyList.dist.get(p);
    						val pt:Point = Point.make(machine + 1, internal_vertex);
    						// Console.OUT.println("in machine : " + machine);
    						// Console.OUT.println("internal_vertex : " + internal_vertex);
    						if(r.size()==0){
    							throw new UnsupportedOperationException("region does not have any data points");
    						}
    						
    							var flag:Boolean = false;
    							var rec:PlainGraphRecord = null;
    							
    							if(r.contains(pt)){
//     								Console.OUT.println("found in machine : " + here.id);
// 
//     								Console.OUT.println("Creating the Vertex");
    								rec = new PlainGraphRecord();
    								rec.id = vertex;
    								rec.edges = new ArrayList[Long]();
    								adjacencyList(pt) = rec;
    								// Console.OUT.println("OK " + vertex);
    							}else{
    								throw new UnsupportedOperationException("Vertex " + vertex + " exists in the graph.");
    							}
    							
    							}
    						}
    					}
    				
    				
    				// if(here.id == machine){
    				// 	var l:Array[PlainGraphRecord] = adjacencyList.getLocalPortion() as Array[PlainGraphRecord];
    				// 	    					
    				// 	if(l.size == 0){
    				// 		l = new Array[PlainGraphRecord](ScaleGraphMath.pow(2,sizeCategory) as Int);
    				// 	}
    				// 	
    				// 	val p:PlainGraphRecord = l(internal_vertex);
    				// 	
	    			// 	if(p == null){
	    			// 		l(internal_vertex) = new PlainGraphRecord();
	    			// 		l(internal_vertex).id = vertex;
	    			// 		l(internal_vertex).edges = new ArrayList[Long]();
	    			// 		Console.OUT.println("OK " + vertex);
	    			// 		}else{
	    			// 			throw new UnsupportedOperationException("Vertex " + vertex + " exists in the graph.");
	    			// 		}
    				// }   
    				
    				// if(here.id == machine){
    				// 	val p:PlainGraphRecord = adjacencyList(internal_vertex);
    				// 	if(p == null){
    				// 		Console.OUT.println("Its NULL");
    				// 	}
    				// 	
    				// 	// if(l.size == 0){
    				// 	// 	l = new Array[PlainGraphRecord](ScaleGraphMath.pow(2,sizeCategory) as Int);
    				// 	// }
    				// 	// 
    				// 	// val p:PlainGraphRecord = l(internal_vertex);
    				// 	// 
    				// 	// if(p == null){
    				// 	// 	l(internal_vertex) = new PlainGraphRecord();
    				// 	// 	l(internal_vertex).id = vertex;
    				// 	// 	l(internal_vertex).edges = new ArrayList[Long]();
    				// 	// 	Console.OUT.println("OK " + vertex);
    				// 	// }else{
    				// 	// 	throw new UnsupportedOperationException("Vertex " + vertex + " exists in the graph.");
    				// 	// }
    				// }
    			}
    		}
    }
   
    /**
     * Returns the intersection of this graph with that Graph
     * 
     * @param the PlainGraph that needs to be intersected.
     * @return a PlainGraph that corresponds to the intersection.
     */
    public def intersect(var that:org.igraphx10.graph.Graph):org.igraphx10.graph.PlainGraph {
    	throw new UnsupportedOperationException("Not implemented.");
    }
    
    /**
     * Increase the size of the Graph
     */
    private def scaleUp(var mat:DistDenseMatrix, var vertex:Long):DistDenseMatrix{
    	// var M:Int = mat.M;
    	// var N:Int = mat.N;
    	// 
    	// vertexIncrementFactor = Math.ceil(Math.log10(vertex)/Math.log10(2)) > vertexIncrementFactor ? Math.ceil(Math.log10(vertex)/Math.log10(2)) : vertexIncrementFactor;
    	// 
    	// var gridG:Grid = new Grid((Math.pow(2, vertexIncrementFactor) as Int), (Math.pow(2,vertexIncrementFactor) as Int), Place.MAX_PLACES, 1);
    	// var adjacencyMatrix2:DistDenseMatrix = DistDenseMatrix.make(gridG);
    	// 
    	// 
    	// for(var m:Int = 0; m < M; m++){
    	// 	for(var n:Int = 0; n < N; n++){
    	// 		adjacencyMatrix2(m, n) =  mat(m, n);
    	// 	}
    	// }
    	// 
    	// return adjacencyMatrix2;
    	
    	return null;
    }
    
    /**
     * Adds a new Edge to a PlainGraph.
     * 
     * @param the id of the Edge to be added to the Graph
     */
    public def addEdge(var id:Object):void {
    	 var e:String = id as String;
    	     	
    	 var strArr:Array[String] = e.split(" ");
    	 val from:Long = Long.parse(strArr(0));
    	 val to:Long = Long.parse(strArr(1));
    	 var vertex:Long = from > to ? from:to;
    	 
    	 //Check to see whether the graph supports the Vertex
    	 if(sizeCategory == GraphSizeCategory.SMALL){
    		 if(vertex > ScaleGraphMath.pow(2,sizeCategory)){
    			 var message:String = "The vertices of the edge does not exist in the graph size.";
    			 message = message + " Current graph size is : " + sizeCategory;
    			 throw new UnsupportedOperationException(message);
    		 }
    	 }else if(sizeCategory == GraphSizeCategory.MEDIUM){
    		 if(vertex > (ScaleGraphMath.pow(2,sizeCategory))*adjacencyList.dist.places().size()){
    			 var message:String = "The vertices of the edge does not exist in the graph size.";
    			 message = message + " Current graph size is : 2^" + sizeCategory + " * " + adjacencyList.dist.places().size();
    			 throw new UnsupportedOperationException(message);
    		 } 
    	 }

    	 var v:Long = ScaleGraphMath.pow(2,sizeCategory);
    	 val machine:Int = ScaleGraphMath.round(from/v) as Int;
    	 val internal_vertex:Int = (from % v) as Int;

    	 for(p in adjacencyList.dist.places()){
    		 if(p.id == machine){
    			 at(p){
    				 val r:Region = adjacencyList.dist.get(p);
    				 val pt:Point = Point.make(machine + 1, internal_vertex);

    				 if(r.size()==0){
    					 throw new UnsupportedOperationException("region does not have any data points");
    				 }
    				 
    				 var flag:Boolean = false;
    				 var rec:PlainGraphRecord = null;
    				 
    				 if(r.contains(pt)){
    					 adjacencyList(pt).edges.add(to);
    				 }    				 
    			 }
    		 }
    	 }
    }

    /**
     * Get the Union of two Plain Graphs
     * 
     * @return a PlainGraph representing the union of this Graph with that
     */
    public def union(var that:org.igraphx10.graph.Graph):org.igraphx10.graph.PlainGraph {
    	throw new UnsupportedOperationException("Not implemented.");
    }
    
    /**
     * Test method
     * This method prints the contents of the Graph.
     */
    public def printCont(){
    	
    	finish for(p in adjacencyList.dist.places()){
    		async at(p){
    			//var l:Array[PlainGraphRecord] = adjacencyList.dist.get(p);
    			val r:Region = adjacencyList.dist.get(p);
    			var len:Int = r.size;
    			    			
    			for(point:Point in r){			   				
    				if (l(point).id != -1l){
    					var lst:ArrayList[Long] = (l(point).edges as ArrayList[Long]);
    					   					
    					Console.OUT.print("" + l(point).id + "->");
    					if(lst.size() != 0){
    						for (item in lst){
    							Console.OUT.print(item + ",");
    						}
    						Console.OUT.println();
    					}
    					Console.OUT.println();
    				}
    			}
    		}
    	}
    	Console.OUT.println("Done..");
    	
    	
    	// finish for(p in adjacencyList.dist.places()){
    	// 	at(p){
    	// 		var l:Array[PlainGraphRecord] = adjacencyList.getLocalPortion();
    	// 		val r:Region = l.region;
    	// 		var len:Int = l.size;
    	// 		
    	// 		Console.OUT.println("Size : " + len);
    	// 		var offset:Int = len/workerThreadCount;
    	// 		var next:Int = 1;
    	// 		Console.OUT.println("Offset : " + offset);
    	// 		
    	// 		for(var i:Int = 1; i < len ; i++){
    	// 			Console.OUT.println("Started at : " + i);
    	// 			finish async for(j:Int in i..next){
	    // 				if (l(1,i).id != -1l){
	    // 					var lst:ArrayList[Long] = (l(1,i).edges as ArrayList[Long]);
	    // 					
	    // 					Console.OUT.println("Size-->"+lst.size());
	    // 					
	    // 					Console.OUT.print("" + l(1,i).id + "->");
	    // 					if(lst.size() != 0){
	    // 						for (item in lst){
	    // 							Console.OUT.print(item + ",");
	    // 						}
	    // 						Console.OUT.println();
	    // 					}
	    // 				}
    	// 			}
    	// 			next = i + offset;
    	// 			i = next;
    	// 		}
    	// 	}
    	// }
    	// Console.OUT.println("Done..");
    	
    	
    }
    
    public def composition(var id$601122:org.igraphx10.graph.Graph):org.igraphx10.graph.Graph {
    // TODO: auto-generated method stub
return null;
}


}