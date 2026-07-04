/**
 * @file dog_foot.scad
 * @brief Stylized parametric dog foot (digitigrade, front paw) — teaching model.
 * @author Cameron K. Brooks
 * @copyright 2026
 *
 * Self-contained: config, parameters, and geometry all live in this file.
 * Digitigrade posture: a compact paw rests flat on the ground while a short,
 * fairly upright pastern rises to the carpus, with the leg cut off flat above.
 * Signature anatomy: 4 clawed digits, digital pads + a big metacarpal pad on the
 * sole, a small carpal pad, and a raised dewclaw.
 * Origin at the paw's ground contact (z = 0); +x forward (toes), +z up,
 * +y medial. Right foot. Angles are degrees from the ground. Clamped to z >= 0.
 */

/* [Render] */
$fn = $preview ? 48 : 96;
zFite = $preview ? 0.1 : 0; // z-fighting avoidance in preview

/* [Paw] */
paw_length = 62; // fore-aft length of the paw mass
paw_width = 54; // side-to-side width
paw_height = 30; // thickness of the paw mass
paw_lift = 3; // paw mass raised so the pads protrude down to the ground (small = pads sunk in)

/* [Digits] */
digit_count = 4;
digit_length = 18; // middle digits; outer ones taper shorter
digit_diameter = 18;
digit_spread = 0.82; // fraction of paw width the digits fan across
digit_reach = 6; // how much further forward the middle digits sit

/* [Claws] */
claw_length = 12;
claw_base = 8;
claw_droop = 38; // downward tilt of the claw, degrees

/* [Pads] */
show_pads = true;
met_pad = [36, 42, 12]; // metacarpal (main) pad [len, wid, height]
digital_pad = [16, 15, 13]; // one under each digit
carpal_pad = [15, 16, 13]; // small pad on the back of the pastern
show_dewclaw = true;

/* [Pastern] */
pastern_length = 44; // short + fairly upright (digitigrade)
pastern_diameter = 36;
pastern_angle = 74; // steepness from the ground

/* [Carpus] */
joint_diameter = 34; // wrist joint

/* [Leg] */
leg_length = 55; // stump above the carpus (cut off flat)
leg_diameter = 30;
leg_angle = 84; // near-vertical, leaning slightly forward

dog_foot();

// --- geometry ----------------------------------------------------------------

// key points from the paw up to the cut leg top
pastern_base = [-paw_length * 0.18, 0, paw_lift + paw_height * 0.7];
joint_pos = pastern_base + pastern_length * [-cos(pastern_angle), 0, sin(pastern_angle)];
leg_top = joint_pos + leg_length * [cos(leg_angle), 0, sin(leg_angle)];

module dog_foot() {
  //! Draw the digitigrade dog foot from the parameters above
  intersection() {
    union() {
      paw_mass();
      digits();
      if (show_pads) pads();
      if (show_dewclaw) dewclaw();
      limb_segment(pastern_base, joint_pos, pastern_diameter * 1.1, joint_diameter); // pastern
      limb_segment(joint_pos, leg_top, joint_diameter * 0.9, leg_diameter); // lower leg
    }
    // slab: keep ground (z >= 0) up to a flat cut at the leg top
    translate([pastern_base[0], 0, leg_top[2] / 2])
      cube([paw_length * 4, paw_width * 3, leg_top[2]], center=true);
  }
}

module paw_mass() {
  //! The chunky paw block, blended up into the pastern
  hull() {
    translate([0, 0, paw_lift + paw_height / 2]) ellipsoid([paw_length, paw_width, paw_height]);
    translate(pastern_base) sphere(d=pastern_diameter);
  }
}

// digit centreline geometry, shared by the toes and their pads
function digit_arc(i) = 1 - abs(i - (digit_count - 1) / 2) / ((digit_count - 1) / 2); // 0 outer, 1 middle
function digit_y(i) = paw_width * 0.5 * digit_spread * ((digit_count - 1) / 2 - i) / ((digit_count - 1) / 2);
function digit_len(i) = digit_length * (0.8 + 0.2 * digit_arc(i));
function digit_dia(i) = digit_diameter * (0.85 + 0.15 * digit_arc(i));
function digit_x0(i) = paw_length / 2 - digit_diameter * 0.3 + digit_arc(i) * digit_reach;

module digits() {
  //! Forward-pointing clawed digits; middle two longest + furthest forward
  for (i = [0:digit_count - 1]) {
    d = digit_dia(i);
    len = digit_len(i);
    x0 = digit_x0(i);
    y = digit_y(i);
    ztip = d / 2 * 0.9;
    hull() {
      translate([x0, y, paw_lift + paw_height * 0.32]) sphere(d=d * 1.1); // knuckle into the paw
      translate([x0 + len, y, ztip]) sphere(d=d); // toe tip
    }
    claw([x0 + len, y, ztip]);
  }
}

module claw(tip) {
  //! A tapered claw curving down-forward from a digit tip
  translate(tip) rotate([0, 90 + claw_droop, 0])
    cylinder(d1=claw_base, d2=claw_base * 0.12, h=claw_length);
}

module pads() {
  //! Sole pads: one digital pad per digit, the big metacarpal pad, a carpal pad.
  //! Each protrudes down to the ground; the z >= 0 clamp gives it a flat contact.
  for (i = [0:digit_count - 1]) {
    len = digit_len(i);
    translate([digit_x0(i) + len * 0.55, digit_y(i), digital_pad[2] / 2 - 3]) ellipsoid(digital_pad);
  }
  translate([paw_length * 0.04, 0, met_pad[2] / 2 - 3]) ellipsoid(met_pad); // metacarpal pad
  translate(pastern_base + [-pastern_diameter * 0.4, 0, -paw_lift]) // carpal pad, back of pastern
    ellipsoid(carpal_pad);
}

module dewclaw() {
  //! The raised inner digit + claw, up the medial (+y) side of the pastern
  base = [pastern_base[0] + 6, paw_width * 0.32, paw_lift + paw_height * 1.1];
  tip = base + [14, 6, -4];
  hull() {
    translate(base) sphere(d=digit_diameter * 0.7);
    translate(tip) sphere(d=digit_diameter * 0.5);
  }
  claw(tip);
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
