import flash.geom.Point;
import com.nodename.utils.*;
import com.nodename.Delaunay.*;
import com.nodename.geom.*;

class com.nodename.Delaunay.Vertex {	
	static var VERTEX_AT_INFINITY:Vertex = new Vertex(PrivateConstructorEnforcer, NaN, NaN);	
	private static var _pool:Array = new Array();
	private var _vertexIndex:Number;
	private static var _nvertices:Number = 0;	
	private var _coord:Point;
	
	private static function create(x:Number, y:Number):Vertex {
		if (isNaN(x) || isNaN(y)) {
			return VERTEX_AT_INFINITY;
		}
		
		if (_pool.length > 0) {
			return _pool.pop().init(x, y);
		} else {
			return new Vertex(PrivateConstructorEnforcer, x, y);
		}
	}	
		
	
	
	public function get coord():Point {
		return this._coord;
	}
	
	public function get vertexIndex():Number {
		return _vertexIndex;
	}
	
	public function Vertex(lock, x:Number, y:Number) {	
			init(x, y);
	}
	
	private function init(x:Number, y:Number):Vertex{
			_coord = new Point(x, y);
			this.setIndex();
			return this;
	}
	
	public function dispose():Void {
			_coord = null;
			_pool.push(this);
	}
		
	public function setIndex():Void {
		_vertexIndex = _nvertices++;
	}
	
	public function toString():String {
		return "Vertex (of index #" + _vertexIndex + "), coord: " + _coord;
	}
	
	public static function intersect(halfedge0:Halfedge, halfedge1:Halfedge):Vertex	{
			var edge0:Edge, edge1:Edge, edge:Edge;
			var halfedge:Halfedge;
			var determinant:Number, intersectionX:Number, intersectionY:Number;
			var rightOfSite:Boolean;
		
			edge0 = halfedge0.edge;
			edge1 = halfedge1.edge;
			
			if (edge0 == null || edge1 == null)	{
				return null;
			}
			if (edge0.rightSite == edge1.rightSite)	{
				return null;
			}
		
			determinant = edge0.a * edge1.b - edge0.b * edge1.a;
			if (-1.0e-10 < determinant && determinant < 1.0e-10)
			{
				return null;
			}
		
			intersectionX = (edge0.c * edge1.b - edge1.c * edge0.b)/determinant;
			intersectionY = (edge1.c * edge0.a - edge0.c * edge1.a)/determinant;		
				
				 	
			if (Voronoi.compareByYThenX(edge0.rightSite, edge1.rightSite) < 0){
				halfedge = halfedge0; edge = edge0;
			}	else {
				halfedge = halfedge1; edge = edge1;
			}
			rightOfSite = intersectionX >= edge.rightSite.x;
			if ((rightOfSite && halfedge.leftRight == LR.LEFT)
			||  (!rightOfSite && halfedge.leftRight == LR.RIGHT)) {
				return null;
			}
			var verTest:Vertex = Vertex.create(intersectionX, intersectionY);
			return verTest;
		}
		
		public function get x():Number {
			return _coord.x;
		}
		public function get y():Number {
			return _coord.y;
		}		
}