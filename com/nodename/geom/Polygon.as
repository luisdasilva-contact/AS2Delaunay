import flash.geom.Point;
import com.nodename.geom.Winding;
import Math.abs;

class com.nodename.geom.Polygon {
	
	private var _vertices:Array;
	
	public function Polygon(vertices:Array) {
			_vertices = vertices;
		}
		
	public function area():Number {
			return Math.abs(signedDoubleArea() * 0.5);
		}
		
	public function winding():Winding {
		var signedDoubleArea:Number = this.signedDoubleArea();
		if (signedDoubleArea < 0) {
			return Winding.CLOCKWISE;
		}
		if (signedDoubleArea > 0) {
			return Winding.COUNTERCLOCKWISE;
		}
		return Winding.NONE;
	}
		
	private function signedDoubleArea():Number {
		var index:Number, nextIndex:Number;
		var n:Number = _vertices.length;
		var point:Point, next:Point;
		var signedDoubleArea:Number = 0;
		for (index = 0; index < n; ++index) {
			nextIndex = (index + 1) % n;
			point = _vertices[index];
			next = _vertices[nextIndex];
			signedDoubleArea += point.x * next.y - next.x * point.y;
		}
		
		return signedDoubleArea;
	}
}