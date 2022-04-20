import flash.display.BitmapData;
import flash.geom.Point;
import flash.geom.Rectangle;
import com.nodename.geom.*;
import com.nodename.utils.*;
import com.nodename.Delaunay.*;
import Math.sqrt;
import Math.random;
	
class com.nodename.Delaunay.Voronoi {	
	private var _sites:SiteList;
	private var _sitesIndexedByLocation:Array; 
	private var _triangles:Array;
	private var _edges:Array;
	private var _plotBounds:Rectangle;
	
	public function get plotBounds():Rectangle {
		return _plotBounds;
	}
	
	public function get sitesLength():Number{
		return _sites.length;
	}
	
	public function get sites(){
		return _sites;
	}
	
	public function dispose():Void {
		var i:Number, n:Number;
		if (_sites)	{
			_sites.dispose();
			_sites = null;
		}
		if (_triangles)	{
			n = _triangles.length;
			for (i = 0; i < n; ++i)	{
				_triangles[i].dispose();
			}
			_triangles.length = 0;
			_triangles = null;
		}
		if (_edges)	{
			n = _edges.length;
			for (i = 0; i < n; ++i)
			{
				_edges[i].dispose();
			}
			_edges.length = 0;
			_edges = null;
		}
		_plotBounds = null;
		_sitesIndexedByLocation = null;
	}
	
	public function Voronoi(points:Array, colors:Array, plotBounds:Rectangle){
		_sites = new SiteList();
		_sitesIndexedByLocation = new Array(); 
		addSites(points, colors);
		_plotBounds = plotBounds;
		_triangles = new Array;
		_edges = new Array();
		fortunesAlgorithm();
	}
	
	private function addSites(points:Array, colors:Array):Void {
		var length:Number = points.length;
		for (var i:Number = 0; i < length; ++i) {
			addSite(points[i], colors ? colors[i] : 0, i);
		}
	}
		
	public function addSite(p:Point, color:Number, index:Number):Void {
		var weight:Number = Math.random() * 100;
		var site:Site = Site.create(p, index, weight, color);
		_sites.push(site);
		_sitesIndexedByLocation[p] = site;
	}
	
	public function edges():Array {
       return _edges;
    }
	
	public function region(p:Point):Array {
		var site:Site = _sitesIndexedByLocation[p];
		if (!site) {
			return new Array();
		}
		return site.region(_plotBounds);
	}
	
	 // TODO: bug: if you call this before you call region(), something goes wrong :(
	public function neighborSitesForSite(coord:Point):Array {
		var points:Array = new Array();
		var site:Site = _sitesIndexedByLocation[coord];
		if (!site) {
			return points;
		}
		var sites:Array = site.neighborSites();
		var neighbor:Site;
		for (var iter = 0; iter < sites.length; iter++){
			points.push(sites[iter].coord);
		}
		return points;
	}
	
	public function circles():Array	{
		return _sites.circles();
	}
	
	public function voronoiBoundaryForSite(coord:Point):Array {
		return visibleLineSegments(selectEdgesForSitePoint(coord, _edges));
	}

	public function delaunayLinesForSite(coord:Point):Array {
		return delaunayLinesForEdges(selectEdgesForSitePoint(coord, _edges));
	}
		
	public function voronoiDiagram():Array {
		return visibleLineSegments(_edges);
	}
		
	public function delaunayTriangulation(keepOutMask:BitmapData):Array {
		if (!keepOutMask){keepOutMask = null}
		return delaunayLinesForEdges(selectNonIntersectingEdges(keepOutMask, _edges));
	}
		
	public function hull():Array {
			return delaunayLinesForEdges(hullEdges());
	}
	
	private function hullEdges():Array {
			return _edges.filter(myTest);
		
			function myTest(edge:Edge, index:Number, vector:Array):Boolean {
				return (edge.isPartOfConvexHull());
			}
		}

	public function hullPointsInOrder():Array {
		var hullEdges:Array = hullEdges();
			
		var points:Array = new Array();
		if (hullEdges.length == 0) {
			return points;
		}
			
		var reorder:EdgeReorder = new EdgeReorder(hullEdges, Site);
		hullEdges = reorder.edges;
		var orientations:Array = reorder.edgeOrientations;
		reorder.dispose();
			
		var orientation:LR;

		var n:Number = hullEdges.length;
		for (var i:Number = 0; i < n; ++i) {
			var edge:Edge = hullEdges[i];
			orientation = orientations[i];
			points.push(edge.site(orientation).coord);
		}
		return points;
	}
	
	public function spanningTree(type:String, keepOutMask:BitmapData):Array{
		if (!type){type = "minimum"};
		if (!keepOutMask){keepOutMask = null};
		var edges:Array = selectNonIntersectingEdges(keepOutMask, _edges);
		var segments:Array = delaunayLinesForEdges(edges);
		return kruskal(segments, type);
	}

	
	public function regions():Array {
			return _sites.regions(_plotBounds);
	}
		
	public function siteColors(referenceImage:BitmapData):Array {
		if (!referenceImage){referenceImage = null};
		return _sites.siteColors(referenceImage);
	}
	
	/**
		 * 
		 * @param proximityMap a BitmapData whose regions are filled with the site index values; see PlanePointsCanvas::fillRegions()
		 * @param x
		 * @param y
		 * @return coordinates of nearest Site to (x, y)
		 * 
		 */
	public function nearestSitePoint(proximityMap:BitmapData, x:Number, y:Number):Point {
		return _sites.nearestSitePoint(proximityMap, x, y);
	}
	
	public function siteCoords():Array {
		return _sites.siteCoords();
	}
	
	private function fortunesAlgorithm():Void {
		var newSite:Site, bottomSite:Site, topSite:Site, tempSite:Site;
		var v:Vertex, vertex:Vertex;
		var newintstar:Point;
		var leftRight:LR;
		var lbnd:Halfedge, rbnd:Halfedge, llbnd:Halfedge, rrbnd:Halfedge, bisector:Halfedge;
		var edge:Edge;
			
		var dataBounds:Rectangle = _sites.getSitesBounds();
			
		var sqrt_nsites:Number = Math.floor((Math.sqrt(_sites.length + 4)));
		var heap:HalfedgePriorityQueue = new HalfedgePriorityQueue(dataBounds.y, dataBounds.height, sqrt_nsites);
		var edgeList:EdgeList = new EdgeList(dataBounds.x, dataBounds.width, sqrt_nsites);
		var halfEdges:Array = new Array();
		var vertices:Array = new Array();
			
		var bottomMostSite:Site = _sites.next();
		newSite = _sites.next();
		var loopIterVal:Number = 0;
		
		for (;;) { // double semicolons indicate to keep running until a break statement is encountered; almost a glorified while loop
		++loopIterVal;
		
		
			if (heap.empty() == false) {
				newintstar = heap.min();
			}
		
			if (newSite != null &&  (heap.empty() || compareByYThenX(newSite, newintstar) < 0))	{
				
				lbnd = edgeList.edgeListLeftNeighbor(newSite.coord);	
				rbnd = lbnd.edgeListRightNeighbor;
				bottomSite = rightRegion(lbnd);		
				edge = Edge.createBisectingEdge(bottomSite, newSite);
				
				_edges.push(edge);
				
				bisector = Halfedge.create(edge, LR.LEFT);
				halfEdges.push(bisector);
				edgeList.insert(lbnd, bisector);
				
				if ((vertex = Vertex.intersect(lbnd, bisector)) != null) {
					vertices.push(vertex);
					heap.remove(lbnd);
					lbnd.vertex = vertex;
					lbnd.ystar = vertex.y + newSite.dist(vertex);
					heap.insert(lbnd);
				}
				
				lbnd = bisector;
				bisector = Halfedge.create(edge, LR.RIGHT);
				halfEdges.push(bisector);
				edgeList.insert(lbnd, bisector);
				
				if ((vertex = Vertex.intersect(bisector, rbnd)) != null) {					
					vertices.push(vertex);
					bisector.vertex = vertex;
					bisector.ystar = vertex.y + newSite.dist(vertex);
					heap.insert(bisector);	
				}
				
				newSite = _sites.next();	
			} else if (heap.empty() == false) {
				lbnd = heap.extractMin();
				llbnd = lbnd.edgeListLeftNeighbor;
				rbnd = lbnd.edgeListRightNeighbor;
				rrbnd = rbnd.edgeListRightNeighbor;
				bottomSite = leftRegion(lbnd);
				topSite = rightRegion(rbnd);
				
				v = lbnd.vertex;
				v.setIndex();
				lbnd.edge.setVertex(lbnd.leftRight, v);
				rbnd.edge.setVertex(rbnd.leftRight, v);
				edgeList.remove(lbnd); 
				heap.remove(rbnd);
				edgeList.remove(rbnd); 
				leftRight = LR.LEFT;
				
				if (bottomSite.y > topSite.y) {
					tempSite = bottomSite; bottomSite = topSite; topSite = tempSite; leftRight = LR.RIGHT;
				}
				edge = Edge.createBisectingEdge(bottomSite, topSite);
				_edges.push(edge);
				bisector = Halfedge.create(edge, leftRight);
				halfEdges.push(bisector);
				edgeList.insert(llbnd, bisector);
				edge.setVertex(LR.other(leftRight), v);
				
				if ((vertex = Vertex.intersect(llbnd, bisector)) != null) {
					vertices.push(vertex);
					heap.remove(llbnd);
					llbnd.vertex = vertex;
					llbnd.ystar = vertex.y + bottomSite.dist(vertex);
					heap.insert(llbnd);
				}
				
				if ((vertex = Vertex.intersect(bisector, rrbnd)) != null) {
					vertices.push(vertex);
					bisector.vertex = vertex;
					bisector.ystar = vertex.y + bottomSite.dist(vertex);
					heap.insert(bisector);
				}
			} else {
				break;
			}
		}
		
		function leftRegion(he:Halfedge):Site{
			var edge:Edge = he.edge;
			if (edge == null){
				return bottomMostSite;
			}
			return edge.site(he.leftRight);
		}
		
		function rightRegion(he:Halfedge):Site {
			var edge:Edge = he.edge;
			if (edge == null) {
				return bottomMostSite;
			}
			return edge.site(LR.other(he.leftRight));
		}
		
		heap.dispose();
		edgeList.dispose();
		
		for (var iter = 0; iter < halfEdges; iter++){
			halfEdges[iter].reallyDispose();
		}
		halfEdges.length = 0;
		
		
		for (var i = 0; i < _edges.length; i++){
			_edges[i].clipVertices(_plotBounds);
		}
		
		for (var i = 0; i < vertices.length; i++){
			vertices[i].dispose();
		}
		vertices.length = 0;
		
	}

	static function compareByYThenX(s1:Site, s2):Number{
		if (s1.y < s2.y) return -1;
		if (s1.y > s2.y) return 1;
		if (s1.x < s2.x) return -1;
		if (s1.x > s2.x) return 1;
		return 0;
	}
	
	/* everything below this line is its own file in AS3, BUT needed to be a function here in AS2.
	 That's because .as files can ONLY be class files in AS2.*/
	
	function visibleLineSegments(edges:Array):Array	{
		var segments:Array = new Array();
	
		for (var i = 0; i < edges.length; i++){
			if (edges[i].visible) {
				var p1:Point = edges[i].clippedEnds.LR_LEFT;
				var p2:Point = edges[i].clippedEnds.LR_RIGHT;
				segments.push(new LineSegment(p1, p2));
			}	
			
		}
		
		return segments;
	}
	
	function kruskal(lineSegments:Array, type:String):Array{
		if (!type){type = "minimum"};
		
		var nodes:Array = new Array();
		var mst:Array = new Array();
		var nodePool:Array = Node.pool;
		
		switch (type) {
			case "maximum":
				lineSegments.sort(LineSegment.compareLengths);
				break;
			default:
				lineSegments.sort(LineSegment.compareLengths_MAX);
				break;
		}
		
		for (var i:Number = lineSegments.length; --i > -1;)	{
			var lineSegment:LineSegment = lineSegments[i];
			
			var node0:Node = nodes[lineSegment.p0];
			var rootOfSet0:Node;
			if (node0 == null)	{
				node0 = nodePool.length > 0 ? nodePool.pop() : new Node();
				// intialize the node:
				rootOfSet0 = node0.parent = node0;
				node0.treeSize = 1;
			
				nodes[lineSegment.p0] = node0;
			} else	{
				rootOfSet0 = find(node0);
			}
			
			var node1:Node = nodes[lineSegment.p1];
			var rootOfSet1:Node;
			if (node1 == null)	{
				node1 = nodePool.length > 0 ? nodePool.pop() : new Node();
				// intialize the node:
				rootOfSet1 = node1.parent = node1;
				node1.treeSize = 1;
			
				nodes[lineSegment.p1] = node1;
			} else	{
				rootOfSet1 = find(node1);
			}
			
			if (rootOfSet0 != rootOfSet1)	// nodes not in same set
			{
				mst.push(lineSegment);
				
				// merge the two sets:
				var treeSize0:Number = rootOfSet0.treeSize;
				var treeSize1:Number = rootOfSet1.treeSize;
				if (treeSize0 >= treeSize1)	{
					// set0 absorbs set1:
					rootOfSet1.parent = rootOfSet0;
					rootOfSet0.treeSize += treeSize1;
				} else {
					// set1 absorbs set0:
					rootOfSet0.parent = rootOfSet1;
					rootOfSet1.treeSize += treeSize0;
				}
			}
		}
		for (var i = 0; i < nodes.length; i++){
			nodePool.push(nodes[i]);
		}
		
		return mst;
		
	}
	
	function find(node:Node):Node {
		if (node.parent == node) {
			return node;
		} else {
			var root:Node = find(node.parent);
			// this line is just to speed up subsequent finds by keeping the tree depth low:
			node.parent = root;
			return root;
		}
	}
	
	function selectEdgesForSitePoint(coord:Point, edgesToTest:Array):Array{
		return edgesToTest.filter(myTest);
		
		function myTest(edge:Edge, index:Number, vector:Array):Boolean
		{
			return ((edge.leftSite && edge.leftSite.coord == coord)
			||  (edge.rightSite && edge.rightSite.coord == coord));
		}		
	}
	
	function selectNonIntersectingEdges(keepOutMask:BitmapData, edgesToTest:Array):Array{
		if (keepOutMask == null)
		{
			return edgesToTest;
		}
		
		var zeroPoint:Point = new Point();
		return edgesToTest.filter(myTest);
		
		function myTest(edge:Edge, index:Number, vector:Array):Boolean {
			var delaunayLineBmp:BitmapData = edge.makeDelaunayLineBmp();
			var notIntersecting:Boolean = !(keepOutMask.hitTest(zeroPoint, 1, delaunayLineBmp, zeroPoint, 1));
			delaunayLineBmp.dispose();
			return notIntersecting;
		}
	}
	
	function delaunayLinesForEdges(edges:Array):Array {
		var segments:Array = new Array();
		for (var i = 0; i < edges.length; i++){
			segments.push(edges[i].delaunayLine());
		}
		return segments;
	}
		
}



