/**
 * @file human_foot.scad
 * @brief Stylized parametric human foot — teaching / visualization model.
 * @author Cameron K. Brooks
 * @copyright 2026
 *
 * Self-contained: config, parameters, and geometry all live in this file.
 * Built from hulled ellipsoids — a heel + ball body, a flat-topped ankle stump,
 * and five toes. Origin is at the heel centre on the ground plane (z = 0);
 * +x points toward the toes, +z up, +y is medial (the hallux side).
 * Modelled as a right foot.
 */

/* [Render] */
$fn = $preview ? 48 : 96;
zFite = $preview ? 0.1 : 0; // z-fighting avoidance in preview

/* [Foot] */
// Heel-back to ball-front length; toes extend beyond this [mm]
foot_length = 180;

/* [Heel] */
heel_length = 70;
heel_width = 58;
heel_height = 62;

/* [Ball] */
ball_length = 82;
ball_width = 95;
ball_height = 36;

/* [Arch] */
arch_height = 18; // medial arch lift carved into the sole [mm]

/* [Ankle] */
ankle_x = 56; // stump position, measured from the back of the heel
ankle_diameter = 64;
ankle_height = 115; // cut off flat at the top

/* [Malleoli] */
malleolus_diameter = 26; // ankle-bump size
malleolus_elong = 1.25; // vertical stretch — bumps are a bit taller than wide
malleolus_out = 24; // sideways offset of the bump centre from the ankle axis (protrudes ~10% less)
malleolus_med_z = 60; // medial (inner) bump height — sits higher
malleolus_lat_z = 48; // lateral (outer) bump height — sits lower
malleolus_shift = 6; // fore/aft: medial sits forward (+x), lateral back (-x)

/* [Toes] */
hallux_length = 42; // big-toe length; the others taper shorter
toe_diameter = 26;
toe_splay = 14; // total fan of the toe tips, degrees
toe_gap = -3; // adjacent-toe packing: centre spacing = radii sum + this; negative overlaps [mm]

/* [Toenails] */
nail_length = 0.38; // nail length as a fraction of the toe length
nail_width = 0.8; // nail width as a fraction of the toe diameter
nail_raise = 0.9; // height the nail stands proud of the toe [mm]

human_foot();

// --- geometry ----------------------------------------------------------------

module human_foot() {
  //! Draw the human foot from the parameters above
  heel = [heel_length, heel_width, heel_height];
  ball = [ball_length, ball_width, ball_height];

  heel_c = [heel_length / 2, 0, heel_height / 2]; // back of heel at x = 0
  ball_c = [foot_length - ball_length / 2, 0, ball_height / 2];

  // main body: heel blended into the ball, with the medial arch carved out below
  difference() {
    union() {
      hull() {
        translate(heel_c) ellipsoid(heel);
        translate(ball_c) ellipsoid(ball);
      }

      // ankle: an instep blend ellipsoid pulled up into a flat-topped stump
      hull() {
        translate([ankle_x, 0, ball_height * 0.5])
          ellipsoid([ankle_diameter * 1.4, heel_width * 0.95, ball_height]);
        translate([ankle_x, 0, ankle_height - ankle_diameter / 2])
          cylinder(d=ankle_diameter, h=ankle_diameter / 2 + zFite);
      }

      malleoli();
    }
    arch_cutter();
  }
  toes();
}

module malleoli() {
  //! The two ankle bumps. Medial (inner, +y) is higher + forward; lateral
  //! (outer, -y) is lower + further back — the anatomical asymmetry.
  bump = [malleolus_diameter, malleolus_diameter, malleolus_diameter * malleolus_elong];
  translate([ankle_x + malleolus_shift, malleolus_out, malleolus_med_z]) ellipsoid(bump);
  translate([ankle_x - malleolus_shift, -malleolus_out, malleolus_lat_z]) ellipsoid(bump);
}

toe_count = 5; // human foot

function toe_frac(i) = toe_count > 1 ? i / (toe_count - 1) : 0; // 0 = hallux, 1 = little toe
function toe_dia_at(i) = toe_diameter * (1 - toe_frac(i) * 0.42); // size falloff toward the little toe
function toe_len_at(i) = hallux_length * (1 - toe_frac(i) * 0.30); // length falloff
// cumulative centre-to-centre offset from the hallux; spacing tracks each toe's radius
function toe_off(i) = i <= 0 ? 0 : toe_off(i - 1) + (toe_dia_at(i - 1) + toe_dia_at(i)) / 2 + toe_gap;

module toes() {
  //! Five hull-of-two-spheres toes; hallux medial (+y) and largest.
  //! Spacing is diameter-aware (see toe_off) so crowding is uniform fat-to-thin.
  span = toe_off(toe_count - 1);
  y_first = span / 2; // centre the toe fan across the ball
  for (i = [0:toe_count - 1]) {
    f = toe_frac(i);
    d = toe_dia_at(i); // this toe's diameter
    len = toe_len_at(i); // this toe's length
    y = y_first - toe_off(i); // diameter-aware spread from +y (medial) to -y (lateral)
    x0 = foot_length - ball_length * 0.24 - f * 6; // lateral toes set slightly back
    z0 = ball_height * 0.32; // ride up near the ball front, then angle down to the tip
    splay = (0.5 - f) * toe_splay; // fan the tips outward in y

    hull() {
      translate([x0, y, z0]) sphere(d=d * 1.05); // proximal knuckle, merges into the ball
      translate([x0 + len * cos(splay), y + len * sin(splay), d / 2 * 0.85]) sphere(d=d * 0.82);
    }
    toenail(d, len, x0, y, z0, splay);
  }
}

module toenail(d, len, x0, y, z0, splay) {
  //! Oval nail plate centred on the dorsal surface of the distal phalanx
  nl = len * nail_length; // nail length along the toe
  nw = d * nail_width; // nail width across the toe
  nz = nail_raise + 3; // z-thickness; most of it sinks into the toe so it fuses (thin plate)
  t = 1.0; // fraction along the toe (proximal 0 -> tip 1): sits on the distal phalanx, near the tip
  ax = x0 +  len * cos(splay);
  ay = y +  len * sin(splay);
  az = z0 +  (d / 2 * 0.85 - z0); // toe centreline
  r = 0.525 * d + (0.41 * d - 0.525 * d); // toe radius at 
  top = az + r; // actual dorsal surface height
  translate([ax, ay, top + nail_raise - nz / 2])
    rotate([0, 0, splay]) ellipsoid([nl, nw, nz]);
}

module arch_cutter() {
  //! Scoops the underside between heel and ball, biased medial (+y), to form the arch
  x0 = heel_length * 0.6; // start just forward of the heel
  x1 = foot_length - ball_length * 0.6; // stop just behind the ball
  xc = (x0 + x1) / 2;
  len = (x1 - x0) * 1.2; // elongated lengthwise; tapered ends keep heel + ball in contact
  wid = ball_width * 0.65; // narrow trough along the medial border
  yc = ball_width * 0.42; // biased medial; foot centre + lateral sole stay flat
  zext = arch_height + 14; // shallow scoop; its upper dome is the arch surface
  zc = arch_height - zext / 2; // top of the scoop sits at z = arch_height
  translate([xc, yc, zc]) ellipsoid([len, wid, zext]);
}

module ellipsoid(dims) {
  //! Axis-aligned ellipsoid spanning dims = [dx, dy, dz]
  scale(dims) sphere(d=1);
}
