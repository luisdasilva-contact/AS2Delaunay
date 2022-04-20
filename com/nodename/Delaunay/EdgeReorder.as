import com.nodename.utils.*;
import com.nodename.geom.*;
import com.nodename.Delaunay.*;

class com.nodename.Delaunay.EdgeReorder {	
	private var _edges:Array;
	private var _edgeOrientations:Array;
	public function get edges():Array {
		return _edges;
	}
	
	public function get edgeOrientations():Array {
		return _edgeOrientations;
	}
	
	public function EdgeReorder(origEdges:Array, criterion)
	{
		_edges = new Array();
		_edgeOrientations = new Array();
		if (origEdges.length > 0)
		{
			_edges = reorderEdges(origEdges, criterion);
		}
	}
	
	public function dispose():Void {
		_edges = null;
		_edgeOrientations = null;
	}
	
	private function reorderEdges(origEdges:Array, criterion):Array {
		var i:Number;
		var j:Number;
		var n:Number = origEdges.length;
		var edge:Edge;
			
		var done:Array = new Array(n);
		var nDone:Number = 0;
		for (var iter = 0; iter < done.length; iter++){
			done[iter] = false;
		}
		var newEdges:Array = new Array();
			
		i = 0;
		edge = origEdges[i];
		newEdges.push(edge);
		_edgeOrientations.push(LR.LEFT);
		var firstPoint = (criterion == Vertex) ? edge.leftVertex : edge.leftSite;
		var lastPoint = (criterion == Vertex) ? edge.rightVertex : edge.rightSite;
			
		if (firstPoint == Vertex.VERTEX_AT_INFINITY || lastPoint == Vertex.VERTEX_AT_INFINITY){
			return new Array();
		}
			
		done[i] = true;
		++nDone;
			
		while (nDone < n){
			for (i = 1; i < n; ++i) {
				if (done[i]){
					continue;
				}
				edge = origEdges[i];
				var leftPoint = (criterion == Vertex) ? edge.leftVertex : edge.leftSite;
				var rightPoint = (criterion == Vertex) ? edge.rightVertex : edge.rightSite;
				if (leftPoint == Vertex.VERTEX_AT_INFINITY || rightPoint == Vertex.VERTEX_AT_INFINITY) {
					return new Array();
				}
				if (leftPoint == lastPoint) {
					lastPoint = rightPoint;
					_edgeOrientations.push(LR.LEFT);
					newEdges.push(edge);
					done[i] = true;
				} else if (rightPoint == firstPoint) {
					firstPoint = leftPoint;
					_edgeOrientations.unshift(LR.LEFT);
					newEdges.unshift(edge);
					done[i] = true;
				} else if (leftPoint == firstPoint) {
					firstPoint = rightPoint;
					_edgeOrientations.unshift(LR.RIGHT);
					newEdges.unshift(edge);
					done[i] = true;
				} else if (rightPoint == lastPoint) {
					lastPoint = leftPoint;
					_edgeOrientations.push(LR.RIGHT);
					newEdges.push(edge);
					done[i] = true;
				}
				if (done[i]){
						++nDone;
					}
				}
			}
			
			return newEdges;
		}
	
}