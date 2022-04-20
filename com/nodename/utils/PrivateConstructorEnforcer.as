import flash.geom.Point;
import flash.geom.Rectangle;
	
class com.nodename.utils.PrivateConstructorEnforcer {
		public static var TOP:Number = 1;
		public static var BOTTOM:Number = 2;
		public static var LEFT:Number = 4;
		public static var RIGHT:Number = 8;
		
		/**
		 * 
		 * @param point
		 * @param bounds
		 * @return an int with the appropriate bits set if the Point lies on the corresponding bounds lines
		 * 
		 */
		public static function check(point:Point, bounds:Rectangle):Number
		{
			var value:Number = 0;
			if (point.x == bounds.left)
			{
				value |= LEFT;
			}
			if (point.x == bounds.right)
			{
				value |= RIGHT;
			}
			if (point.y == bounds.top)
			{
				value |= TOP;
			}
			if (point.y == bounds.bottom)
			{
				value |= BOTTOM;
			}
			return value;
		}
		
		public function BoundsCheck()
		{
			throw new Error("BoundsCheck constructor unused");
		}

}