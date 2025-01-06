// Basic case for coffee machine controller board
//
// Thomas Kircher <tkircher@gnu.org>, 2024

// PCB dimensions
board_h = 66;
board_w = 78;

// Mount hole positions
mount_x = 70;
mount_y = 58;

// Cover offsets
cover_h = board_h + 12 - 6;
cover_w = board_w + 12 - 6;
cover_t = 0.6 * 4 + 1.2;

cutout_h = mount_y + 2;
cutout_w = mount_x + 5;

// Middle section offsets
middle_h = board_h - 24;
middle_w = board_w - 20;

// Wall thickness
wall_t = 5 * 0.4;
wall_d1 = 6;
wall_d2 = wall_d1 + 2 * wall_t;

point_d = 3.2 + 2 * 0.4 * 6;

module bottom_outer_ring() {
  outer_d = 10;

  difference() {
    union() {
      // Base
      difference() {
        translate([-cover_w / 2, -cover_h / 2, 0])
          cube([cover_w, cover_h, cover_t]);

        translate([-cutout_w / 2, -cutout_h / 2 - 1 / 2, 1.2])
          cube([cutout_w - 1, cutout_h + 1, cover_t + 1]);
      }

      // Mount points
      for(i = [0 : 1])
      for(j = [0 : 1])
        mirror([i, 0, 0])
        mirror([0, j, 0]) {
        translate([mount_x / 2, mount_y / 2, 0]) {
          cylinder(d = point_d, h = cover_t, $fn = 120);

          translate([-point_d / 2, 0, 0])
            cube([point_d, point_d / 2, cover_t]);

          translate([0, -point_d / 2, 0])
            cube([point_d / 2 + 1, point_d, cover_t]);
        }
      }
    }

    // Mount holes and bottom chamfers
    for(i = [-1 : 2 : 1])
    for(j = [-1 : 2 : 1]) {
      translate([i * mount_x / 2, j * mount_y / 2, -0.1]) {
        cylinder(d = 3.2, h = cover_t + 1, $fn = 120);

        cylinder(d = 5.6, h = 1.2 + 0.1, $fn = 160);

        translate([0, 0, 1.2 + 0.1])
          cylinder(d1 = 5.6, d2 = 3.2, h = 1.8, $fn = 160);
      }
    }

    // Side wall outer fillets
    for(i = [0 : 1])
    for(j = [0 : 1]) {
      mirror([i, 0, 0])
      mirror([0, j, 0])
      translate([-cover_w / 2, -cover_h / 2, -0.1])
      difference() {
        translate([-1, -1, 0])
          cube([outer_d / 2 + 1, outer_d / 2 + 1, cover_t + 1]);

        translate([outer_d / 2, outer_d / 2, -0.1])
          cylinder(d = outer_d, h = cover_t + 2, $fn = outer_d * 24);
      }
    }
  }
}

module bottom_outer_walls(wall_h) {
  difference() {
    union() {
      // Side walls
      for(i = [0 : 1]) {
        mirror([i, 0, 0])
        translate([-cover_w / 2, -cover_h / 2, -wall_h + cover_t])
          cube([wall_t, cover_h, wall_h]);

        mirror([0, i, 0])
        translate([-cover_w / 2, -cover_h / 2, -wall_h + cover_t])
          cube([cover_w, wall_t, wall_h]);
      }

      // Side wall inner fillets
      for(i = [0 : 1])
      for(j = [0 : 1]) {
        mirror([i, 0, 0])
        mirror([0, j, 0]) {
        translate([-cover_w / 2 + wall_t, -cover_h / 2 + wall_t, -wall_h + cover_t])
          difference() {
            cube([wall_d1 / 2, wall_d1 / 2, wall_h]);

            translate([wall_d1 / 2, wall_d1 / 2, -0.1])
              cylinder(d = wall_d1, h = wall_h + 1, $fn = wall_d1 * 24);
          }
        }
      }
    }
    // Side wall outer fillets
    for(i = [0 : 1])
    for(j = [0 : 1]) {
      mirror([i, 0, 0])
      mirror([0, j, 0])
      translate([-cover_w / 2, -cover_h / 2, -0.1 - wall_h + cover_t])
      difference() {
        translate([-1, -1, 0])
          cube([wall_d2 / 2 + 1, wall_d2 / 2 + 1, wall_h + 1]);

        translate([wall_d2 / 2, wall_d2 / 2, -0.1])
          cylinder(d = wall_d2, h = wall_h + 2, $fn = wall_d2 * 24);
      }
    }

    // DC and I2C cutouts
    translate([cover_w / 2 - 45, cover_h / 2 - 10 / 2, cover_t - wall_h])
    difference() {
      cube([23, 10, 10]);

      // Bottom chamfers
      for(i = [0 : 1]) {
        translate([i * (23 + 2.5) - 2.5 / 2, 0, -2.5 / 2])
        rotate([0, 45, 0])
        translate([-5 / 2, 0, -5 / 2])
          cube([5, 5, 5]);
      }
    }

    // Top chamfers
    translate([cover_w / 2 - 45, cover_h / 2 - 10 / 2, cover_t - wall_h])
    for(i = [0 : 1]) {
      translate([i * (23 - 2.5) + 2.5 / 2, 1.5, wall_h + 2.5 / 2])
      rotate([0, 45, 0])
      translate([-5 / 2, 0, -5 / 2])
        cube([5, 5, 5]);
    }
  }
}

module top_outer_ring() {
  //offset = 2 * wall_t + 0.5;
  offset = 0;

  outer_d = 10 + offset;

  cover_h = board_h + 12 - 6 + offset;
  cover_w = board_w + 12 - 6 + offset;

  difference() {
    union() {
      // Base
      difference() {
        translate([-cover_w / 2, -cover_h / 2, 0])
          cube([cover_w, cover_h, cover_t]);

        translate([-cutout_w / 2, -cutout_h / 2 - 1 / 2, 1.2])
          cube([cutout_w - 1, cutout_h + 1, cover_t + 1]);
      }

      // Mount points
      for(i = [0 : 1])
      for(j = [0 : 1])
        mirror([i, 0, 0])
        mirror([0, j, 0]) {
        translate([mount_x / 2, mount_y / 2, 0]) {
          cylinder(d = point_d, h = cover_t, $fn = 120);

          translate([-point_d / 2, 0, 0])
            cube([point_d, point_d / 2, cover_t]);

          translate([0, -point_d / 2, 0])
            cube([point_d / 2 + 1, point_d, cover_t]);
        }
      }
    }

    // Mount holes and bottom chamfers
    for(i = [-1 : 2 : 1])
    for(j = [-1 : 2 : 1]) {
      translate([i * mount_x / 2, j * mount_y / 2, -0.1]) {
        cylinder(d = 3.2, h = cover_t + 1, $fn = 120);

        cylinder(d = 5.6, h = 0.8 + 0.1, $fn = 160);

        translate([0, 0, 0.8 + 0.1])
          cylinder(d1 = 5.6, d2 = 3.2, h = 1.8, $fn = 160);

      }
    }

    // Side wall outer fillets
    for(i = [0 : 1])
    for(j = [0 : 1]) {
      mirror([i, 0, 0])
      mirror([0, j, 0])
      translate([-cover_w / 2, -cover_h / 2, -0.1])
      difference() {
        translate([-1, -1, 0])
          cube([outer_d / 2 + 1, outer_d / 2 + 1, cover_t + 1]);

        translate([outer_d / 2, outer_d / 2, -0.1])
          cylinder(d = outer_d, h = cover_t + 2, $fn = outer_d * 24);
      }
    }
  }
}

module top_inset_walls(wall_h) {
  offset = -4.2;

  wall_d1 = 6 + offset;
  wall_d2 = wall_d1 + 2 * wall_t;

  cover_h = board_h + 12 - 6 + offset;
  cover_w = board_w + 12 - 6 + offset;

  difference() {
    union() {
      // Side walls
      for(i = [0 : 1]) {
        mirror([i, 0, 0])
        translate([-cover_w / 2, -cover_h / 2, -wall_h + cover_t])
          cube([wall_t, cover_h, wall_h]);

        mirror([0, i, 0])
        translate([-cover_w / 2, -cover_h / 2, -wall_h + cover_t])
          cube([cover_w, wall_t, wall_h]);
      }

      // Side wall inner fillets
      for(i = [0 : 1])
      for(j = [0 : 1]) {
        mirror([i, 0, 0])
        mirror([0, j, 0]) {
        translate([-cover_w / 2 + wall_t, -cover_h / 2 + wall_t, -wall_h + cover_t])
          difference() {
            cube([wall_d1 / 2, wall_d1 / 2, wall_h]);

            translate([wall_d1 / 2, wall_d1 / 2, -0.1])
              cylinder(d = wall_d1, h = wall_h + 1, $fn = wall_d1 * 24);
          }
        }
      }
    }

    // Side wall outer fillets
    for(i = [0 : 1])
    for(j = [0 : 1]) {
      mirror([i, 0, 0])
      mirror([0, j, 0])
      translate([-cover_w / 2, -cover_h / 2, -0.1 - wall_h + cover_t])
      difference() {
        translate([-1, -1, 0])
          cube([wall_d2 / 2 + 1, wall_d2 / 2 + 1, wall_h + 1]);

        translate([wall_d2 / 2, wall_d2 / 2, -0.1])
          cylinder(d = wall_d2, h = wall_h + 2, $fn = wall_d2 * 24);
      }
    }
  }
}

module top_outer_walls(wall_h) {
  wall_t = 2.0 + 0.4;
  offset = 0;

  wall_d1 = 6 + offset;
  wall_d2 = wall_d1 + 2 * 2.0;

  cover_h = board_h + 12 - 6 + offset;
  cover_w = board_w + 12 - 6 + offset;

  difference() {
    union() {
      // Side walls
      for(i = [0 : 1]) {
        mirror([i, 0, 0])
        translate([-cover_w / 2, -cover_h / 2, -wall_h + cover_t])
          cube([wall_t, cover_h, wall_h]);

        mirror([0, i, 0])
        translate([-cover_w / 2, -cover_h / 2, -wall_h + cover_t])
          cube([cover_w, wall_t, wall_h]);
      }

      // Side wall inner fillets
      for(i = [0 : 1])
      for(j = [0 : 1]) {
        mirror([i, 0, 0])
        mirror([0, j, 0]) {
        translate([-cover_w / 2 + wall_t, -cover_h / 2 + wall_t, -wall_h + cover_t])
          difference() {
            cube([wall_d1 / 2, wall_d1 / 2, wall_h]);

            translate([wall_d1 / 2, wall_d1 / 2, -0.2])
              cylinder(d = wall_d1, h = wall_h + 0.4, $fn = wall_d1 * 24);
          }
        }
      }

      translate([0, 0, cover_t - wall_h + 19 + 2 - 7])
        top_inset_walls(19 + 2);
    }

    // Side wall outer fillets
    for(i = [0 : 1])
    for(j = [0 : 1]) {
      mirror([i, 0, 0])
      mirror([0, j, 0])
      translate([-cover_w / 2, -cover_h / 2, -0.1 - wall_h + cover_t])
      difference() {
        translate([-1, -1, 0])
          cube([wall_d2 / 2 + 1, wall_d2 / 2 + 1, wall_h + 1]);

        translate([wall_d2 / 2, wall_d2 / 2, -0.1])
          cylinder(d = wall_d2, h = wall_h + 2, $fn = wall_d2 * 24);
      }
    }

    // Front and back cutouts
    for(n = [0 : 1]) {
      rotate([0, 0, n * 180])
      difference() {
        translate([-cover_w / 2 + 25 / 2, cover_h / 2 - 10 / 2, cover_t - wall_h])
          cube([cover_w - 25, 6, wall_h + 4]);

        for(m = [0 : 1]) {
          mirror([m, 0, 0])
          translate([-cover_w / 2 + 25 / 2 - 0.5,
                      cover_h / 2 - 15 / 2, (cover_t - wall_h) - 0.5])
          rotate([0, 45, 0])
          translate([-5 / 2, 0, -5 / 2])
            cube([5, 10, 5]);
        }
      }
    }

    // Side cutouts
    for(n = [0 : 1]) {
      rotate([0, 0, n * 180])
      difference() {
        translate([cover_w / 2 - 10 / 2, -cover_h / 2 + 22 / 2, cover_t - wall_h])
          cube([6, cover_h - 22, wall_h + 4]);


        for(m = [0 : 1]) {
          mirror([0, m, 0])
          translate([ cover_w / 2 - 15 / 2,
                     -cover_h / 2 + 22 / 2 - 0.5, (cover_t - wall_h) - 0.5])
          rotate([45, 0, 0])
          translate([0, -5 / 2, -5 / 2])
            cube([10, 5, 5]);
        }

      }
    }
  }
}

module bottom_piece() {
  bottom_outer_ring();

  translate([0, 0, 6])
    bottom_outer_walls(6);
}

module top_piece() {
  difference() {
    union() {
      top_outer_ring();

      translate([0, 0, 13.8 + 1.8])
        top_outer_walls(13.8 + 1.8);
    }

    translate([-100 / 2, -100 / 2, 26])
      cube([100, 100, 5]);
  }
}

bottom_piece();

translate([0, 0, 6 + 22.5 - 1.2 - 0.1])
rotate([0, 180, 0])
  top_piece();

// EOF