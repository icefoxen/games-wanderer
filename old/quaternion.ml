(* QUATERNIONS!
   Because arbitrary-coordinate rotations are yummy and delicious!

   Appropriate documentation, since I still don't actually understand them.
   Yay, voodoo programming!

# OpenGL likes degrees, so everything's given in degrees.
# But we use sin and cos and shit, so we turn it into radians
# internally.
#
# Euler	
# glRotatef( angleX, 1, 0, 0)
# glRotatef( angleY, 0, 1, 0)
# glRotatef( angleZ, 0, 0, 1)
# // translate

# Quaternion	
# // convert Euler to quaternion
# // convert quaternion to axis angle
# glRotate(theta, ax, ay, az)
# // translate

## Q54. How do I convert a quaternion to a rotation matrix?
## --------------------------------------------------------

##   Assuming that a quaternion has been created in the form:

##     Q = |X Y Z W|

##   Then the quaternion can then be converted into a 3x3 rotation
##   matrix using the following expression:


##         |       2     2                                |
##         | 1 - 2Y  - 2Z    2XY - 2ZW      2XZ + 2YW     |
##         |                                              |
##         |                       2     2                |
##     M = | 2XY + 2ZW       1 - 2X  - 2Z   2YZ - 2XW     |
##         |                                              |
##         |                                      2     2 |
##         | 2XZ - 2YW       2YZ + 2XW      1 - 2X  - 2Y  |
##         |                                              |


##   If a 4x4 matrix is required, then the bottom row and right-most column
##   may be added.

##   The matrix may be generated using the following expression:

##     ----------------

##     xx      = X * X;
##     xy      = X * Y;
##     xz      = X * Z;
##     xw      = X * W;

##     yy      = Y * Y;
##     yz      = Y * Z;
##     yw      = Y * W;

##     zz      = Z * Z;
##     zw      = Z * W;

##     mat[0]  = 1 - 2 * ( yy + zz );
##     mat[1]  =     2 * ( xy - zw );
##     mat[2]  =     2 * ( xz + yw );

##     mat[4]  =     2 * ( xy + zw );
##     mat[5]  = 1 - 2 * ( xx + zz );
##     mat[6]  =     2 * ( yz - xw );

##     mat[8]  =     2 * ( xz - yw );
##     mat[9]  =     2 * ( yz + xw );
##     mat[10] = 1 - 2 * ( xx + yy );

##     mat[3]  = mat[7] = mat[11] = mat[12] = mat[13] = mat[14] = 0;
##     mat[15] = 1;

##     ----------------

## Create a quaternion that turns a vector to face the same way as
## another vector.
##         Quaternion getRotationTo(const Vector3& dest) const
##         {
##             // Based on Stan Melax's article in Game Programming Gems
##             Quaternion q;
##             // Copy, since cannot modify local
##             Vector3 v0 = *this;
##             Vector3 v1 = dest;
##             v0.normalise();
##             v1.normalise();
##             Vector3 c = v0.crossProduct(v1);
##             // NB if the crossProduct approaches zero, we get unstable because 
##     ANY axis will do
##             // when v0 == -v1
##             Real d = v0.dotProduct(v1);
##             // If dot == 1, vectors are the same
##             if (d >= 1.0f)
##             {
##                 return Quaternion::IDENTITY;
##             }
##             Real s = Math::Sqrt( (1+d)*2 );
##             assert (s != 0 && "Divide by zero!");
##             Real invs = 1 / s;
##             q.x = c.x * invs;
##             q.y = c.y * invs;
##             q.z = c.z * invs;
##             q.w = s * 0.5;
##             return q;
##         }
*)


open Vector



class quaternion a b c d =
object (self)
  val mutable w = a
  val mutable x = b
  val mutable y = c
  val mutable z = d

  method w = w
  method x = x
  method y = y
  method z = z

  method set a b c d =
    w <- a;
    x <- b;
    y <- c;
    z <- d;

  method setQ (q : quaternion) =
    w <- q#w;
    x <- q#x;
    y <- q#y;
    z <- q#z;

  method magnitude =
    sqrt ((w *. w) +. (x *. x) +. (y *. y) +. (z *. z))

  method normalize =
    let m = self#magnitude in
      w <- w /. m;
      x <- x /. m;
      y <- y /. m;
      z <- z /. m;


  method mul (q : quaternion) =
    let nw = (w *. q#w) -. (x *. q#x) -. (y *. q#y) -. (z *. q#z)
    and nx = (w *. q#x) +. (x *. q#w) +. (y *. q#z) -. (z *. q#y)
    and ny = (w *. q#y) -. (x *. q#z) +. (y *. q#w) +. (z *. q#x)
    and nz = (w *. q#z) +. (x *. q#y) -. (y *. q#x) +. (z *. q#w)
    in
      new quaternion nw nx ny nz

  method fromAxis angle x' y' z' =
    let nx = Util.d2r x'
    and ny = Util.d2r y'
    and nz = Util.d2r z'
    and s = sin (angle /. 2.) 
    in

      w <- cos (angle /. 2.);
      x <- nx *. s;
      y <- ny *. s;
      z <- nz *. s;

  method toAxis =
    let scale = sqrt ((x*.x) +. (y*.y) +. (z*.z)) in
      if scale = 0. then
	(0., (new vector 1. 1. 1.))
      else (
	  let v = new vector (x *. scale) (y *. scale) (z *. scale) in
	    (* w cannot be > 1, but occasionally is due to floating point stuff *)
	    if w > 1.0 then
	      w <- 1.0;
	    let angle = Util.r2d (2. *. (acos w)) in
	      (angle, v)
	)

  method conjugate =
    new quaternion w (-.x) (-.y) (-.z)

  method toMatrix =
    let r1 = new vector 0. 0. 0.
    and r2 = new vector 0. 0. 0.
    and r3 = new vector 0. 0. 0.
    in

    let xx = x *. x
    and xy = x *. y
    and xz = x *. z
    and xw = x *. w

    and yy = y *. y
    and yz = y *. z
    and yw = y *. w

    and zz = z *. z
    and zw = z *. w
    in

      r1#setX (1. -. (2. *. (yy +. zz)));
      r2#setX        (2. *. (xy -. zw));
      r3#setX        (2. *. (xz +. yw));

      r1#setY        (2. *. (xy +. zw));
      r2#setY (1. -. (2. *. (xx +. zz)));
      r3#setY        (2. *. (yz -. xw));

      r1#setZ        (2. *. (xz -. yw));
      r2#setZ        (2. *. (yz +. xw));
      r3#setZ (1. -. (2. *. (xx +. yy)));

      (r1, r2, r3)



  method toString =
    Printf.sprintf "Q<%.1e, (%.1e, %.1e, %.1e)>" w x y z


  method fromEuler x y z = 
    (*
      let x = (Util.d2r x) /. 2.
      and y = (Util.d2r y) /. 2.
      and z = (Util.d2r z) /. 2. in
      let qx = new quaternion (cos x) (sin x) 0. 0.
      and qy = new quaternion (cos y) 0. (sin y) 0.
      and qz = new quaternion (cos z) 0. 0. (sin z)
      in
      self#setQ ((qx#mul qy)#mul qz) *)

    (* Pitch, yaw, roll *)
    let p = (Util.d2r x) /. 2. 
    and y = (Util.d2r y) /. 2.
    and r = (Util.d2r z) /. 2. in

    let sinp = sin p
    and siny = sin y
    and sinr = sin r
    and cosp = cos p
    and cosy = cos y
    and cosr = cos r in
      

    let x = (sinr *. cosp *. cosy) -. (cosr *. sinp *. siny)
    and y = (cosr *. sinp *. cosy) +. (sinr *. cosp *. siny)
    and z = (cosr *. cosp *. siny) -. (sinr *. sinp *. cosy)
    and w = (cosr *. cosp *. cosy) +. (sinr *. sinp *. siny) in

      self#set w x y z;
      self#normalize;
      

end;;
