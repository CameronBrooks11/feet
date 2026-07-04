/**
 * @file chicken_foot.scad
 * @brief Stylized parametric chicken foot (anisodactyl) — teaching model.
 * @author Cameron K. Brooks
 * @copyright 2026
 *
 * Self-contained: config, parameters, and geometry all live in this file.
 * Anisodactyl: a tall tarsometatarsus (shank) cut off flat at the top, three
 * long thin forward toes splayed on the ground, and one backward hallux — each
 * toe segmented and tipped with a curved claw.
 * Origin at the toe hub on the ground (z = 0); +x forward (middle toe), +z up,
 * +y is one side. Angles are degrees from the ground. Clamped to z >= 0.
 */

/* [Render] */
$fn = $preview ? 40 : 88;
zFite = $preview ? 0.1 : 0; // z-fighting avoidance in preview

/* [Shank] */
shank_length = 96; // tarsometatarsus, cut off flat at the top
shank_dia_bottom = 22;
shank_dia_top = 16;
shank_angle = 82; // near-vertical, slight forward lean (degrees from ground)

/* [Hub] */
hub_size = 20; // the mass where the toes and shank meet
hub_z = 15; // height of the hub above the ground

/* [Front toes] */
toe_length = 68; // middle toe (III); the side toes scale off this
toe_diameter = 12; // thin
toe_spread = 33; // degrees each side toe splays from the middle
toe_segments = 3; // knuckle segments per toe
side_toe_scale = 0.86; // side toes (II, IV) length vs the middle

/* [Hallux] */
hallux_length = 30; // the short backward toe
hallux_diameter = 11;

/* [Claws] */
claw_length = 14;
claw_base = 7;
claw_droop = 34; // downward curl of the claw, degrees

chicken_foot();

// --- geometry ----------------------------------------------------------------

hub = [0, 0, hub_z];
shank_dir = [cos(shank_angle), 0, sin(shank_angle)];
shank_top = hub + shank_length * shank_dir;

module chicken_foot() {
  //! Draw the anisodactyl chicken foot from the parameters above
  intersection() {
    union() {
      translate(hub) ellipsoid([hub_size, hub_size * 0.9, hub_size * 0.8]); // hub
      limb_segment(hub, shank_top, shank_dia_bottom, shank_dia_top); // shank

      toe(0, toe_length, toe_diameter); // III, middle
      toe(toe_spread, toe_length * side_toe_scale, toe_diameter * 0.95); // II, inner
      toe(-toe_spread, toe_length * side_toe_scale, toe_diameter * 0.95); // IV, outer
      toe(180, hallux_length, hallux_diameter); // hallux, backward
    }
    // slab: keep ground (z >= 0) up to a flat cut at the shank top
    translate([shank_top[0], 0, shank_top[2] / 2])
      cube([toe_length * 3, toe_length * 3, shank_top[2]], center=true);
  }
}

module toe(ang, length, base_dia) {
  //! A segmented toe running out from the hub along the ground, tipped with a claw
  hub_r = hub_size * 0.35; // toe starts at the edge of the hub
  ground = base_dia * 0.4; // resting height of the toe centreline near the tip
  nodes = [for (s = [0:toe_segments])
      let(t = s / toe_segments, rad = hub_r + length * t)
        [cos(ang) * rad, sin(ang) * rad, hub_z * (1 - t) + ground * t, base_dia * (1 - 0.4 * t)]];
  for (i = [0:toe_segments - 1])
    hull() {
      translate([nodes[i][0], nodes[i][1], nodes[i][2]]) sphere(d=nodes[i][3]);
      translate([nodes[i + 1][0], nodes[i + 1][1], nodes[i + 1][2]]) sphere(d=nodes[i + 1][3]);
    }
  tip = nodes[toe_segments];
  claw([tip[0], tip[1], tip[2]], ang);
}

module claw(tip, yaw = 0) {
  //! A tapered claw curling down-forward from a toe tip; yaw aims it in-plane
  translate(tip) rotate([0, 0, yaw]) rotate([0, 90 + claw_droop, 0])
    cylinder(d1=claw_base, d2=claw_base * 0.12, h=claw_length);
}

module limb_segment(p0, p1, d0, d1) {
  //! A tapered capsule (hulled spheres) between two points
  hull() {
    translate(p0) sphere(d=d0);
    translate(p1) sphere(d=d1);
  }
}

module ellipsoid(dims) {
  //! Axis-aligned ellipsoid spanning dims = [dx, dy, dz]
  scale(dims) sphere(d=1);
}
