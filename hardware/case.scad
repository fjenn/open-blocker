// Open Blocker key case
// 25 mm NTAG213 sticker on top, optional 10x2 mm magnet on the bottom.
// Print flat on the bed. No supports.

tag_d = 25.4;
tag_h = 1.2;
magnet_d = 10.2;
magnet_h = 2.1;
wall = 2.2;
floor_gap = 1.2;
$fn = 80;

outer_d = tag_d + wall * 2;
height = magnet_h + floor_gap + tag_h + 0.8;

difference() {
    cylinder(d = outer_d, h = height);
    // Magnet pocket opens on the bed (z=0), no supports
    translate([0, 0, -0.1])
        cylinder(d = magnet_d, h = magnet_h + 0.1);
    // Tag well opens on the top face
    translate([0, 0, height - tag_h])
        cylinder(d = tag_d, h = tag_h + 0.2);
}
