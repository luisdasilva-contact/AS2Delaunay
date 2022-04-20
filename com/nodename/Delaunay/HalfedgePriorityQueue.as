import flash.geom.Point;
import com.nodename.Delaunay.Halfedge;
import Math.floor;

class com.nodename.Delaunay.HalfedgePriorityQueue{
	private var _hash:Array;
	private var _count:Number;
	private var _minBucket:Number;
	private var _hashsize:Number;
	
	private var _ymin:Number;
	private var _deltay:Number;
	
	public function HalfedgePriorityQueue(ymin:Number, deltay:Number, sqrt_nsites:Number) {
		_ymin = ymin;
		_deltay = deltay;
		_hashsize = 4 * sqrt_nsites;
		initialize();
	}
	
	public function toString():String{
		return "in halfEdgePriorityQueue, some values: _hash: " + _hash + ", _count: " + _count
			  + ", _minBucket" + _minBucket + ", _hashSize: " + _hashsize + ", _ymin: " + _ymin + ", _deltay: " + _deltay
	}
	
	public function dispose():Void {
			// get rid of dummies
			for (var i:Number = 0; i < _hashsize; ++i)
			{
				_hash[i].dispose();
				_hash[i] = null;
			}
			_hash = null;
		}

		private function initialize():Void {
			var i:Number;
		
			_count = 0;
			_minBucket = 0;
			_hash = new Array(_hashsize);
			// dummy Halfedge at the top of each hash
			for (i = 0; i < _hashsize; ++i)	{
				_hash[i] = Halfedge.createDummy();
				_hash[i].nextInPriorityQueue = null;
			}
		}
		
		public function insert(halfEdge:Halfedge):Void {
			var previous:Halfedge, next:Halfedge;
			var insertionBucket:Number = bucket(halfEdge);
			if (insertionBucket < _minBucket) {
				_minBucket = insertionBucket;
			}
			previous = _hash[insertionBucket];
			while ((next = previous.nextInPriorityQueue) != null
			&&     (halfEdge.ystar  > next.ystar || (halfEdge.ystar == next.ystar && halfEdge.vertex.x > next.vertex.x)))
			{
				previous = next;
			}
			halfEdge.nextInPriorityQueue = previous.nextInPriorityQueue; 
			previous.nextInPriorityQueue = halfEdge;
			++_count;
		}
		
		public function remove(halfEdge:Halfedge):Void {
			var previous:Halfedge;
			var removalBucket:Number = bucket(halfEdge);
			
			if (halfEdge.vertex != null) {
				previous = _hash[removalBucket];
				while (previous.nextInPriorityQueue != halfEdge) {
					previous = previous.nextInPriorityQueue;
				}
				previous.nextInPriorityQueue = halfEdge.nextInPriorityQueue;
				_count--;
				halfEdge.vertex = null;
				halfEdge.nextInPriorityQueue = null;
				halfEdge.dispose();
			}
		}
		
		private function bucket(halfEdge:Halfedge):Number {
			var theBucket:Number = Math.floor((halfEdge.ystar - _ymin)/_deltay * _hashsize);
			if (theBucket < 0) theBucket = 0;
			if (theBucket >= _hashsize) theBucket = _hashsize - 1;
			return theBucket;
		}
		
		private function isEmpty(bucket:Number):Boolean {
			return (_hash[bucket].nextInPriorityQueue == null);
		}
		
		/**
		 * move _minBucket until it contains an actual Halfedge (not just the dummy at the top); 
		 * 
		 */
		private function adjustMinBucket():Void	{
			while (_minBucket < _hashsize - 1 && isEmpty(_minBucket)) {
				++_minBucket;
			}
		}

		public function empty():Boolean {
			return _count == 0;
		}
		
		/**
		 * @return coordinates of the Halfedge's vertex in V*, the transformed Voronoi diagram
		 * 
		 */
		public function min():Point {
			adjustMinBucket();
			var answer:Halfedge = _hash[_minBucket].nextInPriorityQueue;
			return new Point(answer.vertex.x, answer.ystar);
		}

		/**
		 * remove and return the min Halfedge
		 * @return 
		 * 
		 */
		public function extractMin():Halfedge {
			var answer:Halfedge;
		
			// get the first real Halfedge in _minBucket
			answer = _hash[_minBucket].nextInPriorityQueue;
			
			_hash[_minBucket].nextInPriorityQueue = answer.nextInPriorityQueue;
			_count--;
			answer.nextInPriorityQueue = null;
			return answer;
		}	
}