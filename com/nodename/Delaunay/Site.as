import com.nodename.geom.*;
import com.nodename.utils.*;
import com.nodename.Delaunay.*;
import flash.geom.Point;
import flash.geom.Rectangle;

class com.nodename.Delaunay.Site {
	private static var EPSILON:Number = .005;
	private static var _pool:Array = new Array;
	var color:Number;
	var weight:Number;		
	private var _siteIndex:Number;
	private var _edges:Array;
	private var _edgeOrientations:Array;
	private var _region:Array;
	private var _coord:Point;	
	
	public static function create(p:Point, index:Number, weight:Number, color:Number):Site {
		if (_pool.length > 0) {
			return _pool.pop().init(p, index, weight, color);
		}
		else {
			return new Site(PrivateConstructorEnforcer, p, index, weight, color);
		}
	}
	
	static function sortSites(sites:Array):Void {
			sites.sort(Site.compare);
		}
		
	private static function compare(s1:Site, s2:Site):Number {		
		var returnValue:Number = Voronoi.compareByYThenX(s1, s2);
			
		var tempIndex:Number;
		if (returnValue == -1) {
			if (s1._siteIndex > s2._siteIndex) {
				tempIndex = s1._siteIndex;
				s1._siteIndex = s2._siteIndex;
				s2._siteIndex = tempIndex;
			}
		}
		else if (returnValue == 1) {
			if (s2._siteIndex > s1._siteIndex)	{
				tempIndex = s2._siteIndex;
				s2._siteIndex = s1._siteIndex;
				s1._siteIndex = tempIndex;
			}
			
		}
			
		return returnValue;
	}	
	
	private static function closeEnough(p0:Point, p1:Point):Boolean {
		return Point.distance(p0, p1) < EPSILON;
	}	
	
	public function get coord():Point {
		return _coord;
	}
	
	public function get siteIndex() {
		return _siteIndex;
	}

	
	function edges():Array {
		return _edges;
	}
	
	
	
	public function Site(lock, p:Point, index:Number, weight:Number, color:Number)	{
			init(p, index, weight, color);
		}
		
	private function init(p:Point, index:Number, weight:Number, color:Number):Site {
			_coord = p;
			_siteIndex = index;
			this.weight = weight;
			this.color = color;
			_edges = new Array();
			_region = null;
			return this;
		}
	
	public function toString():String {
			return "Site " + _siteIndex + ": " + coord;
		}
		
	private function move(p:Point):Void	{
		clear();
		_coord = p;
	}
	
	public function dispose():Void {
			_coord = null;
			clear();
			_pool.push(this);
		}
		
	private function clear():Void {
		if (_edges)	{
			_edges.length = 0;
			_edges = null;
		}
		if (_edgeOrientations){
			_edgeOrientations.length = 0;
			_edgeOrientations = null;
		}
		if (_region){
			_region.length = 0;
			_region = null;
		}
	}
	
	function addEdge(edge:Edge):Void {
			_edges.push(edge);
		}
	
	
	function nearestEdge():Edge {
		_edges.sort(Edge.compareSitesDistances);
		return _edges[0];
	}
	
	function neighborSites():Array	{
		if (_edges == null || _edges.length == 0){
			return new Array();
		}
		if (_edgeOrientations == null)
		{ 
			reorderEdges();
		}
		var list:Array = new Array();
		var edge:Edge;
		for (var i = 0; i < _edges.length; i++){
			list.push(neighborSite(edge));
		}
		return list;
	}
	
	private function neighborSite(edge:Edge):Site {
		if (this == edge.leftSite) {
			return edge.rightSite;
		}
		if (this == edge.rightSite) {
			return edge.leftSite;
		}
		return null;
	}
	
	function region(clippingBounds:Rectangle):Array {
		if (_edges == null || _edges.length == 0) {
			return new Array();
		} 
		if (_edgeOrientations == null) { 
			reorderEdges();
			_region = clipToBounds(clippingBounds);
			var newPolyTest:Polygon = new Polygon(_region);
			if ((new Polygon(_region)).winding() == Winding.CLOCKWISE)	{				
				_region.reverse();
			}
		}
		
		return _region;
	}	
	
	
	private function reorderEdges():Void {
		var reorder:EdgeReorder = new EdgeReorder(_edges, Vertex);
		_edges = reorder.edges;
		_edgeOrientations = reorder.edgeOrientations;
		reorder.dispose();
	}
	
	private function clipToBounds(bounds:Rectangle):Array {
		var points:Array = new Array;
		var n:Number = _edges.length;
		var i:Number = 0;
		var edge:Edge;
		
		while (i < n && (_edges[i].visible == false)) {
			++i;
		}
		
		if (i == n)	{
			// no edges visible
			return points;
		}
		edge = _edges[i];
		var orientation:LR = _edgeOrientations[i];
		
		if (orientation.toString() == "left"){
			points.push(edge.clippedEnds.LR_LEFT);
			points.push(edge.clippedEnds.LR_RIGHT);
		} else if (orientation.toString() == "right"){			
			points.push(edge.clippedEnds.LR_RIGHT);
			points.push(edge.clippedEnds.LR_LEFT);
		}
		
		for (var j:Number = i + 1; j < n; ++j)	{
			edge = _edges[j];
			if (edge.visible == false)	{				
				continue;
			}
			connect(points, j, bounds);
		}
		connect(points, i, bounds, true);
		return points;
	}
	
	private function connect(points:Array, j:Number, bounds:Rectangle, closingUp:Boolean):Void {
			if (!closingUp){closingUp = false}
			var rightPoint:Point = points[points.length - 1];
			var newEdge:Edge = _edges[j]; 
			var newOrientation:LR = _edgeOrientations[j];
			var newPoint:Point = (String(newOrientation) == "left") ? newEdge.clippedEnds.LR_LEFT : newEdge.clippedEnds.LR_RIGHT;

			if (!closeEnough(rightPoint, newPoint))	{				
				if (rightPoint.x != newPoint.x &&  rightPoint.y != newPoint.y) {					
					var rightCheck:Number = BoundsCheck.check(rightPoint, bounds);
					var newCheck:Number = BoundsCheck.check(newPoint, bounds);
					var px:Number, py:Number;
					if (rightCheck & BoundsCheck.RIGHT) {
						px = bounds.right;
						if (newCheck & BoundsCheck.BOTTOM) {
							py = bounds.bottom;
							points.push(new Point(px, py));
						} else if (newCheck & BoundsCheck.TOP) {
							py = bounds.top;
							points.push(new Point(px, py));
						} else if (newCheck & BoundsCheck.LEFT)	{
							if (rightPoint.y - bounds.y + newPoint.y - bounds.y < bounds.height){
								py = bounds.top;
							} else {
								py = bounds.bottom;
							}
							points.push(new Point(px, py));
							points.push(new Point(bounds.left, py));
						}
					} else if (rightCheck & BoundsCheck.LEFT) {
						px = bounds.left;
						if (newCheck & BoundsCheck.BOTTOM) {
							py = bounds.bottom;
							points.push(new Point(px, py));
						} else if (newCheck & BoundsCheck.TOP) {
							py = bounds.top;
							points.push(new Point(px, py));
						} else if (newCheck & BoundsCheck.RIGHT) {
							if (rightPoint.y - bounds.y + newPoint.y - bounds.y < bounds.height) {
								py = bounds.top;
							} else {
								py = bounds.bottom;
							}
							points.push(new Point(px, py));
							points.push(new Point(bounds.right, py));
						}
					} else if (rightCheck & BoundsCheck.TOP) {
						py = bounds.top;
						if (newCheck & BoundsCheck.RIGHT) {
							px = bounds.right;
							points.push(new Point(px, py));
						} else if (newCheck & BoundsCheck.LEFT) {
							px = bounds.left;
							points.push(new Point(px, py));
						} else if (newCheck & BoundsCheck.BOTTOM) {
							if (rightPoint.x - bounds.x + newPoint.x - bounds.x < bounds.width)	{
								px = bounds.left;
							} else {
								px = bounds.right;
							}
							points.push(new Point(px, py));
							points.push(new Point(px, bounds.bottom));
						}
					}
					else if (rightCheck & BoundsCheck.BOTTOM) {
						py = bounds.bottom;
						if (newCheck & BoundsCheck.RIGHT) {
							px = bounds.right;
							points.push(new Point(px, py));
						} else if (newCheck & BoundsCheck.LEFT)	{
							px = bounds.left;
							points.push(new Point(px, py));
						} else if (newCheck & BoundsCheck.TOP){
							if (rightPoint.x - bounds.x + newPoint.x - bounds.x < bounds.width)	{
								px = bounds.left;
							} else {
								px = bounds.right;
							}
							points.push(new Point(px, py));
							points.push(new Point(px, bounds.top));
						}
					}
				}
				if (closingUp) {
					// newEdge's ends have already been added
					return;
				}
				points.push(newPoint);
			}
			var newRightPoint:Point = (String(newOrientation) == "left") ? newEdge.clippedEnds.LR_RIGHT : newEdge.clippedEnds.LR_LEFT; 
		

			if (!closeEnough(points[0], newRightPoint))	{
				points.push(newRightPoint);
			}
		}
								
		function get x():Number {
			return _coord.x;
		}
		function get y():Number	{
			return _coord.y;
		}
		
		function dist(p):Number	{
			var distVal:Number = Point.distance(p.coord, this._coord);
			return distVal;
		}	
		
}