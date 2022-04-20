import flash.geom.Point;
import com.nodename.Delaunay.Halfedge;
import com.nodename.Delaunay.Edge;
import Math.random;
import Math.sqrt;

class com.nodename.Delaunay.EdgeList {
	private var _deltax:Number;
	private var _xmin:Number;
	private var _hashsize:Number;
	private var _hash:Array;
	private var _leftEnd:Halfedge;
	private var _rightEnd:Halfedge;
	
	public function get leftEnd():Halfedge {
		return _leftEnd;
	}
	
	public function get rightEnd():Halfedge {
		return _rightEnd;
	}
	
	public function dispose():Void {
		var halfEdge:Halfedge = _leftEnd;
		var prevHe:Halfedge;
		while (halfEdge != _rightEnd) {
			prevHe = halfEdge;
			halfEdge = halfEdge.edgeListRightNeighbor;
			prevHe.dispose();
		}
		_leftEnd = null;
		_rightEnd.dispose();
		_rightEnd = null;

		var i:Number;
		for (i = 0; i < _hashsize; ++i)	{
			_hash[i] = null;
		}
		_hash = null;
	}
	
	public function EdgeList(xmin:Number, deltax:Number, sqrt_nsites:Number){
		_xmin = xmin;
		_deltax = deltax;
		_hashsize = 2 * sqrt_nsites;

		var i:Number;
		_hash = new Array(_hashsize);
		// two dummy Halfedges:
		_leftEnd = Halfedge.createDummy();
		_rightEnd = Halfedge.createDummy();
		_leftEnd.edgeListLeftNeighbor = null;
		_leftEnd.edgeListRightNeighbor = _rightEnd;
		_rightEnd.edgeListLeftNeighbor = _leftEnd;
		_rightEnd.edgeListRightNeighbor = null;
		_hash[0] = _leftEnd;
		_hash[_hashsize - 1] = _rightEnd;
	}

	/**
	 * Insert newHalfedge to the right of lb 
	 * @param lb
	 * @param newHalfedge
	 * 
	 */
	public function insert(lb:Halfedge, newHalfedge:Halfedge):Void {
		newHalfedge.edgeListLeftNeighbor = lb;
		newHalfedge.edgeListRightNeighbor = lb.edgeListRightNeighbor;
		lb.edgeListRightNeighbor.edgeListLeftNeighbor = newHalfedge;
		lb.edgeListRightNeighbor = newHalfedge;
	}
	
	/**
	 * This function only removes the Halfedge from the left-right list.
	 * We cannot dispose it yet because we are still using it. 
	 * @param halfEdge
	 * 
	 */
	public function remove(halfEdge:Halfedge):Void {
		halfEdge.edgeListLeftNeighbor.edgeListRightNeighbor = halfEdge.edgeListRightNeighbor;
		halfEdge.edgeListRightNeighbor.edgeListLeftNeighbor = halfEdge.edgeListLeftNeighbor;
		halfEdge.edge = Edge.DELETED;
		halfEdge.edgeListLeftNeighbor = halfEdge.edgeListRightNeighbor = null;
	}
	
	/**
	 * Find the rightmost Halfedge that is still left of p 
	 * @param p
	 * @return 
	 * 
	 */
	public function edgeListLeftNeighbor(p:Point):Halfedge {
		var i:Number, bucket:Number;
		var halfEdge:Halfedge;
	
		/* Use hash table to get close to desired halfedge */
		bucket = Math.floor((p.x - _xmin)/_deltax * _hashsize);
		
		if (bucket < 0)	{
			bucket = 0;
		}
		if (bucket >= _hashsize){
			bucket = _hashsize - 1;
		}
		
		halfEdge = getHash(bucket);
		
		if (halfEdge == null) {
			for (i = 1; true ; ++i)	{
				if ((halfEdge = getHash(bucket - i)) != null) {
					break;
				}
				if ((halfEdge = getHash(bucket + i)) != null) {
					break;
				}
			}
		}
		/* Now search linear list of halfedges for the correct one */
		
		if (halfEdge == leftEnd  || (halfEdge != rightEnd && halfEdge.isLeftOf(p)))	{
			do	{
				halfEdge = halfEdge.edgeListRightNeighbor;
			}
			while (halfEdge != rightEnd && halfEdge.isLeftOf(p));
			halfEdge = halfEdge.edgeListLeftNeighbor;
		}
		else {
			do	{
				halfEdge = halfEdge.edgeListLeftNeighbor;
			}
			while (halfEdge != leftEnd && !halfEdge.isLeftOf(p));
		}
	
		/* Update hash table and reference counts */
		if (bucket > 0 && bucket <_hashsize - 1) {
			_hash[bucket] = halfEdge;
		}
		
		return halfEdge;
	}
	
	/* Get entry from hash table, pruning any deleted nodes */
		private function getHash(b:Number):Halfedge	{
			var halfEdge:Halfedge;
			if (b < 0 || b >= _hashsize) {
				return null;
			}
			halfEdge = _hash[b]; 
					
			if (halfEdge != null && halfEdge.edge == Edge.DELETED)	{
				/* Hash table points to deleted halfedge.  Patch as necessary. */
				_hash[b] = null;
				// still can't dispose halfEdge yet!
				return null;
			}
			else {
				return halfEdge;
			}
		}
	
}