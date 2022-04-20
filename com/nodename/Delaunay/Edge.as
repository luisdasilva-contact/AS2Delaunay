import flash.display.BitmapData;
import flash.display.CapsStyle;
import flash.display.Graphics;
import flash.display.LineScaleMode;
import flash.geom.Point;
import flash.geom.Rectangle;
import com.nodename.Delaunay.*;
import com.nodename.utils.*;
import com.nodename.geom.*;
import Math.ceil;
import Math.max;

class com.nodename.Delaunay.Edge {
	private var _leftVertex:Vertex;
	private var _rightVertex:Vertex;
	private var _clippedVertices:Array;
	private var _sites:Array;
	private var _edgeIndex:Number;	
	private static var _pool:Array = new Array();
	private static var _nedges:Number = 0;		
	static var DELETED:Edge = new Edge(PrivateConstructorEnforcer);
	var a:Number, b:Number, c:Number;
	
	static function createBisectingEdge(site0:Site, site1:Site):Edge {
			var dx:Number, dy:Number, absdx:Number, absdy:Number;
			var a:Number, b:Number, c:Number;
		
			dx = site1.x - site0.x;
			dy = site1.y - site0.y;
			absdx = dx > 0 ? dx : -dx;
			absdy = dy > 0 ? dy : -dy;
			c = site0.x * dx + site0.y * dy + (dx * dx + dy * dy) * 0.5;
			
			if (absdx > absdy) {
				a = 1.0; b = dy/dx; c /= dx;
			} else {
				b = 1.0; a = dx/dy; c /= dy;
			}
			
			var edge:Edge = Edge.create();
		
			edge.leftSite = site0;
			edge.rightSite = site1;
			site0.addEdge(edge);
			site1.addEdge(edge);
			
			
			
			edge._leftVertex = null;
			edge._rightVertex = null;
			
			edge.a = a; edge.b = b; edge.c = c;
			
			return edge;
		}
		
		private static function create():Edge {
			var edge:Edge;
			if (_pool.length > 0)
			{
				edge = Edge(_pool.pop());
				edge.init();
			}
			else {
				edge = new Edge(PrivateConstructorEnforcer);
			}
			return edge;
		}
		
		public function Edge(lock){			
			_edgeIndex = _nedges++;
			init();
		}
		
		private function init():Void {	
			_sites = new Array();
		}
		
		private var _delaunayLineBmp:BitmapData;
		function get delaunayLineBmp():BitmapData {
			if (!_delaunayLineBmp)
			{
				_delaunayLineBmp = makeDelaunayLineBmp();
			}
			return _delaunayLineBmp;
		}
		
		function makeDelaunayLineBmp():BitmapData {
			var p0:Point = leftSite.coord();
			var p1:Point = rightSite.coord();
			var bmp:BitmapData = new BitmapData();
			return bmp;
		}
		
		
		public function delaunayLine():LineSegment {
			var lineSeg:LineSegment = new LineSegment(leftSite.coord, rightSite.coord);
			return lineSeg;
		}
		
		public function voronoiEdge():LineSegment {
		  if (!visible) {
		  	return new LineSegment(null, null);
		  	return new LineSegment(_clippedVertices.LR_LEFT, _clippedVertices.LR_RIGHT);
		  }
         }
		 
		
		
		public function get leftVertex():Vertex	{
			return _leftVertex;
		}
		
		public function get rightVertex():Vertex {
			return _rightVertex;
		}
		
		function vertex(leftRight:LR):Vertex {
			return (leftRight == LR.LEFT) ? _leftVertex : _rightVertex;
		}
		
		function setVertex(leftRight:LR, v:Vertex):Void	{
			if (leftRight == LR.LEFT){
				_leftVertex = v;
			} else {
				_rightVertex = v;
			}
		}		
		
		function isPartOfConvexHull():Boolean {
			return (_leftVertex == null || _rightVertex == null);
		}
		
		public function sitesDistance():Number {
			return Point.distance(leftSite.coord, rightSite.coord);
		}
		
		public static function compareSitesDistances_MAX(edge0:Edge, edge1:Edge):Number	{
			var length0:Number = edge0.sitesDistance();
			var length1:Number = edge1.sitesDistance();
			if (length0 < length1)
			{
				return 1;
			}
			if (length0 > length1)
			{
				return -1;
			}
			return 0;
		}
		
		public static function compareSitesDistances(edge0:Edge, edge1:Edge):Number	{
			return - compareSitesDistances_MAX(edge0, edge1);
		}		
		
		public function get clippedEnds():Array {
			return _clippedVertices;
		}
		
		public function get visible():Boolean {
			return _clippedVertices != null;
		}
		
		function get leftSite():Site {
			return _sites.LR_LEFT;
		}
		
		function set leftSite(s:Site):Void{
			_sites.LR_LEFT = s;
		}
				
		function get rightSite():Site {
			return _sites.LR_RIGHT;
		}
		
		function set rightSite(s:Site):Void {
			_sites.LR_RIGHT = s;
		}
		
		function site(leftRight:LR):Site {
			var leftRightStrConv:String = leftRight.toString()
			if (leftRightStrConv == "left"){				
				return _sites.LR_LEFT;
			} else if (leftRightStrConv == "right"){
				return _sites.LR_RIGHT;
			} else {
				return null;
			}
		}
		
		public function dispose():Void {
			/** hiding anything to do w bitmap for now, no need for this...
			if (_delaunayLineBmp) {
				_delaunayLineBmp.dispose();
				_delaunayLineBmp = null;
			}
			*/
			_leftVertex = null;
			_rightVertex = null;
			if (_clippedVertices) {
				_clippedVertices.LR_LEFT = null;
				_clippedVertices.LR_RIGHT = null;
				_clippedVertices = null;
			}
			_sites.LR_LEFT = null;
			_sites.LR_RIGHT = null;
			_sites = null;
			
			_pool.push(this);
		}		
		
		
		
		public function toString():String {
			return "Edge " + _edgeIndex + "; sites " + _sites.LR_LEFT + ", " + _sites.LR_RIGHT
					+ "; endVertices " + (_leftVertex ? _leftVertex.vertexIndex : "null") + ", "
					 + (_rightVertex ? _rightVertex.vertexIndex : "null") + "LVertex: " + _leftVertex
					 + ", Rvertex: " + _rightVertex;
		}
		
		function clipVertices(bounds:Rectangle):Void {
			var xmin:Number = bounds.x;
			var ymin:Number = bounds.y;
			var xmax:Number = bounds.right;
			var ymax:Number = bounds.bottom;
			
			var vertex0:Vertex, vertex1:Vertex;
			var x0:Number, x1:Number, y0:Number, y1:Number;
			
			if (a == 1.0 && b >= 0.0) {
				vertex0 = _rightVertex;
				vertex1 = _leftVertex;
			} else {
				vertex0 = _leftVertex;
				vertex1 = _rightVertex;
			}
		
			if (a == 1.0){
				y0 = ymin;
				if (vertex0 != null && vertex0.y > ymin) {
					 y0 = vertex0.y;
				}
				if (y0 > ymax) {
					return;
				}
				x0 = c - b * y0;
				
				y1 = ymax;
				if (vertex1 != null && vertex1.y < ymax) {
					y1 = vertex1.y;
				}
				if (y1 < ymin) {
					return;
				}
				x1 = c - b * y1;
				
				if ((x0 > xmax && x1 > xmax) || (x0 < xmin && x1 < xmin)) {
					return;
				}
				
				if (x0 > xmax) {
					x0 = xmax; y0 = (c - x0)/b;
				} else if (x0 < xmin) {
					x0 = xmin; y0 = (c - x0)/b;
				}
				
				if (x1 > xmax) {
					x1 = xmax; y1 = (c - x1)/b;
				} else if (x1 < xmin) {
					x1 = xmin; y1 = (c - x1)/b;
				}
			} else {
				x0 = xmin;
				if (vertex0 != null && vertex0.x > xmin) {
					x0 = vertex0.x;
				}
				if (x0 > xmax) {
					return;
				}
				y0 = c - a * x0;
				
				x1 = xmax;
				if (vertex1 != null && vertex1.x < xmax) {
					x1 = vertex1.x;
				}
				if (x1 < xmin) {
					return;
				}
				y1 = c - a * x1;
				
				if ((y0 > ymax && y1 > ymax) || (y0 < ymin && y1 < ymin)) {
					return;
				}
				
				if (y0 > ymax) {
					y0 = ymax; x0 = (c - y0)/a;
				}
				else if (y0 < ymin) {
					y0 = ymin; x0 = (c - y0)/a;
				}
				
				if (y1 > ymax) {
					y1 = ymax; x1 = (c - y1)/a;
				}
				else if (y1 < ymin) {
					y1 = ymin; x1 = (c - y1)/a;
				}
			}

			_clippedVertices = new Array();
			if (vertex0 == _leftVertex)	{				
				_clippedVertices.LR_LEFT = new Point(x0, y0);
				_clippedVertices.LR_RIGHT = new Point(x1, y1);
			} else {
				
				_clippedVertices.LR_RIGHT = new Point(x0, y0);
				_clippedVertices.LR_LEFT = new Point(x1, y1);
			}
		}
		
	
}