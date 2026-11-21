# feet

Parametric OpenSCAD models of feet, for teaching and visualization. Each is self-contained: open
the file in [OpenSCAD](https://openscad.org) and set its parameters in the Customizer.

- `human_foot.scad`: a right human foot, with arch, toes, toenails and malleoli.
- `dog_foot.scad`: a dog's foot, with toe pads and a dewclaw.
- `chicken_foot.scad`: a chicken's foot (first pass).

## Checks

`just test` renders each foot and checks it is one solid, standing on z = 0
and cut off flat at the top of its leg. `just fmt` formats the `.scad` files
with topiary 0.8.0, and `just check` fails if one is not formatted.

## Licence

MIT; see [LICENSE](LICENSE).
