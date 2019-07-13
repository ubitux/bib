// TODO:
// - back holder as male slot for the vertical sides
// - more milling in the angles
// - back holders holes must be more distant to the other holes (too fragile)
// - 2d projection is wrong for the nail (diagonally pierced)

/* [Dimensions] */

// Structure base width, does NOT include the "nailed tongues" (side holders)
base_width = 1300; // [300:2000]

// Maximum depth of the structure
base_depth = 280; // [200:500]

// Thickness of most of the planks
base_thickness = 18; // [10:1:50]

// Thickness of the back holders planks
back_holders_thickness = 9; // [5:1:50]

// Actual free space available at each floor (height)
floor_space = 300; // [100:500]

// Visible extra width of the nailed tongues
hold_extra_width = 70; // [50:100]

/* [Layout] */

// Number of floors, not including the bottom and top one
nb_floors = 2; // [1:5]

// Number of columns, not including the top-left and top-right vertical sides
nb_cols = 2; // [1:5]

/* [Export/Preview] */

piece = "all";

// Show all parts individually
show_parts = false;

// Project parts in 2D (for DXF export typically); needs show_parts to be enabled
project_2d = true;

// Enable animation of the build; needs show_parts to be disabled
animated = false;

/* [Colors] */
// Color for vertical planks
c0 = "#a3917fff";

// Color for horizontal planks
c1 = "#856363ff";

// Color for back holders
c2 = "#8a7875ff";

// Color for nails
c3 = "#564538ff";

extra_w = base_thickness + hold_extra_width;
floor_extra_d = 2 * base_depth / 3;

extra_pad = (base_depth - floor_extra_d) / 2;

cols_height = (nb_floors + 1) * floor_space + (nb_floors + 2) * base_thickness;

full_width  = base_width + 2 * extra_w;
full_height = cols_height;
full_depth  = base_depth;

/* the nail is composed of the 2 extra left-over of each h-plank side cuts stuck together */
nail_width = base_thickness * 2;

/* default size would be too large so we cut them out */
nail_depth = hold_extra_width / 2;
nail_height = extra_w;

mid_plank_depth = 2 * base_depth / 5;

slice_depth = base_depth / 5;

back_holders_height    = 2 * floor_space / 3;
back_holders_length    = base_width + 2 * base_thickness;
back_holders_backpad   = base_thickness;

h_plank_width      = base_width;
h_plank_depth      = base_depth;
h_plank_height     = base_thickness;
h_plank_extra_w    = extra_w;
h_plank_extra_d    = floor_extra_d;

function column_pos(i) = base_width * i / (nb_cols + 1);
function floor_pos(i) = (base_thickness + floor_space) * i;
function back_holder_pos(i) = floor_pos(i) + base_thickness + (floor_space - back_holders_height) / 2;

function segment_size(min_size, length) = length / (2 * min_size) - 1 / 2;

// TODO: dovetail
module milling(w_hint, depth, length, swap=false) {

    // get the number of segments possible with that first approximate
    tot_seg_count_tmp = max(floor(length / w_hint), 3);

    // make sure we have a odd number of segment (so that we can have 2 extremities and 1 space at minimum)
    tot_seg_count = tot_seg_count_tmp - (tot_seg_count_tmp % 2 ? 0 : 1);

    // 1 less female slot that the number of male slots
    fem_seg_count = (tot_seg_count - 1) / 2;
    mal_seg_count = fem_seg_count + 1;
    assert(mal_seg_count == tot_seg_count - fem_seg_count);

    // now compute the adjusted length of the segments
    w_pick = length / tot_seg_count;
    assert(w_pick >= w_hint);

    if (swap)
        for (i = [0:fem_seg_count - 1])
            translate([0, w_pick * (i * 2 + 1)])
                square([depth, w_pick]);
    else
        for (i = [0:mal_seg_count - 1])
            translate([0, w_pick * i * 2])
                square([depth, w_pick]);
}

module h_plank_mid() {
    echo(str("horizontal middle plank: ", h_plank_width + 2 * h_plank_extra_w, "x", h_plank_depth, "x", h_plank_height));

    difference() {

        /* base h-plank*/
        linear_extrude(height=h_plank_height, convexity=2) {
            /* the 2 extra sides */
            translate([-h_plank_extra_w, extra_pad]) square([h_plank_extra_w, h_plank_extra_d]);
            translate([   h_plank_width, extra_pad]) square([h_plank_extra_w, h_plank_extra_d]);

            difference() {
                /* main plank center */
                square([h_plank_width, h_plank_depth]);

                /* mid plank slices */
                for (i = [1:nb_cols]) {
                    translate([column_pos(i), 0])                           square([base_thickness, slice_depth]);
                    translate([column_pos(i), h_plank_depth - slice_depth]) square([base_thickness, slice_depth]);
                }
            }
        }

        /* nail holes */
        translate([0, 0, -(nail_height - base_thickness) / 2]) {
            translate([-base_thickness, (h_plank_depth + nail_width) / 2])
                rotate([0, 0, 180])
                    nail();
            translate([h_plank_width + base_thickness, (h_plank_depth - nail_width) / 2])
                nail();
        }
    }
}

/* top and bottom horizontal planks */
module h_plank_tb() {
    echo(str("horizontal top/bottom plank: ", h_plank_width, "x", h_plank_depth, "x", h_plank_height));

    linear_extrude(height=h_plank_height, convexity=2) {
        difference() {
            /* main plank center */
            square([h_plank_width, h_plank_depth]);

            /* mid plank slices */
            for (i = [1:nb_cols]) {
                translate([column_pos(i), slice_depth])                   square([base_thickness, slice_depth]);
                translate([column_pos(i), h_plank_depth - slice_depth*2]) square([base_thickness, slice_depth]);
            }
        }

        /* joints with vertical sides */
        translate([-v_plank_lr_height, 0])
            milling(v_plank_lr_height, v_plank_lr_height, h_plank_depth);
        translate([h_plank_width, 0])
            milling(v_plank_lr_height, v_plank_lr_height, h_plank_depth);
    }
}

v_plank_mid_front_width = cols_height;
v_plank_mid_front_depth = mid_plank_depth;
v_plank_mid_front_height = base_thickness;

module v_plank_mid_front() {
    echo(str("vertical middle plank (front): ", v_plank_mid_front_width, "x", v_plank_mid_front_depth, "x", v_plank_mid_front_height));

    linear_extrude(height=v_plank_mid_front_height, convexity=2) {
        difference() {
            square([v_plank_mid_front_width, v_plank_mid_front_depth]);

            /* top and bottom extremities */
            translate([0, v_plank_mid_back_depth - slice_depth, 0])
                square([base_thickness, slice_depth]);
            translate([v_plank_mid_back_width - base_thickness, v_plank_mid_back_depth - slice_depth, 0])
                square([base_thickness, slice_depth]);

            /* floor slices */
            for (i = [1:nb_floors])
                translate([floor_pos(i), 0])
                    square([base_thickness, slice_depth]);
        }
    }
}

v_plank_mid_back_width = cols_height;
v_plank_mid_back_depth = mid_plank_depth;
v_plank_mid_back_height = base_thickness;

module v_plank_mid_back() {
    echo(str("vertical middle plank (back): ", v_plank_mid_back_width, "x", v_plank_mid_back_depth, "x", v_plank_mid_back_height));

    linear_extrude(height=v_plank_mid_back_height, convexity=2) {
        difference() {
            square([v_plank_mid_back_width, v_plank_mid_back_depth]);

            /* top and bottom extremities */
            translate([0, v_plank_mid_back_depth - slice_depth, 0])
                square([base_thickness, slice_depth]);
            translate([v_plank_mid_back_width - base_thickness, v_plank_mid_back_depth - slice_depth, 0])
                square([base_thickness, slice_depth]);

            /* floor slices */
            for (i = [1:nb_floors])
                translate([floor_pos(i), 0])
                    square([base_thickness, slice_depth]);

            /* back holder holes */
            for (i = [0:nb_floors])
                translate([back_holder_pos(i), v_plank_mid_back_depth - back_holders_thickness - back_holders_backpad])
                    square([back_holders_height, back_holders_thickness]);
        }
    }
}

v_plank_lr_width = cols_height;
v_plank_lr_depth = base_depth;
v_plank_lr_height = base_thickness;

module v_plank_lr(width=cols_height, depth=base_depth, v_plank_lr_height=base_thickness) {
    echo(str("vertical left/right plank: ", v_plank_lr_width, "x", v_plank_lr_depth, "x", v_plank_lr_height));

    linear_extrude(height=v_plank_lr_height, convexity=2) {
        difference() {
            translate([h_plank_height, 0])
                square([v_plank_lr_width - h_plank_height * 2, v_plank_lr_depth]);

            /* floor holes */
            for (i = [1:nb_floors])
                translate([floor_pos(i), (v_plank_lr_depth - floor_extra_d) / 2])
                    square([base_thickness, floor_extra_d]);

            /* back holder holes */
            for (i = [0:nb_floors])
                translate([back_holder_pos(i) + back_holders_height, base_depth - back_holders_thickness - back_holders_backpad])
                    rotate([0, 0, 90])
                        milling(v_plank_lr_height, back_holders_thickness, back_holders_height, swap=true);
        }

        /* top and bottom millings */
        milling(v_plank_lr_height, v_plank_lr_height, h_plank_depth, swap=true);
        translate([v_plank_lr_width - v_plank_lr_height, 0])
            milling(v_plank_lr_height, v_plank_lr_height, h_plank_depth, swap=true);
    }
}

module nail(width=nail_width, depth=nail_depth, height=nail_height) {
    rotate([0, -90, -90])
    linear_extrude(height=width, convexity=2)
        polygon([[0, 0], [height, 0], [height, depth], [3*height/4, depth], [0, depth/2]]);
}

module back_holder() {
    echo(str("back holder: ", back_holders_length, "x", back_holders_height, "x", back_holders_thickness));
    linear_extrude(height=back_holders_thickness, convexity=2) {
        translate([v_plank_lr_height, 0])
            square([back_holders_length - v_plank_lr_height * 2, back_holders_height]);

        /* extremities */
        milling(v_plank_lr_height, v_plank_lr_height, back_holders_height, swap=true);
        translate([back_holders_length - v_plank_lr_height, 0])
            milling(v_plank_lr_height, v_plank_lr_height, back_holders_height, swap=true);
    }
}

function mix(x, y, a) = x * (1 - a) + y * a;
function linear(x) = x;
function cubic(x) = x*x*x;
function cubic_out(x) = 1-cubic(1-x);
function cubic_in_out(x) = x < 1/2 ? 2*cubic(x)/2 : 1 - cubic(2*(1-x))/2;
function scaled_time(t, start, end) = min(max((t - start) / (end - start), 0), 1);

module animate(time, from, to=[0, 0, 0], start_time=0, end_time=1) {
    if (time >= start_time) {
        translate(mix(from, to, cubic_out(scaled_time(time, start_time, end_time))))
            children();
    }
}

module time_sequence(time, vectors) {
    if (!animated) {
        children();
    } else {
        assert($children == len(vectors));
        for (i = [0:$children-1]) {
            start_time = i / ($children + 1);
            end_time = (i + 1) / ($children + 1);
            animate(time, from=vectors[i], start_time=start_time, end_time=end_time)
                children(i);
        }
    }
}

module main() {

    voff = 400;

    time_sequence(time=$t, vectors=[
       [-voff, 0, 0],   // floors
       [0, voff, 0],    // mid planks (back)
       [0, -voff, 0],   // mid planks (front)
       [0, 0, -voff/2], // bottom
       [0, 0, voff/2],  // top
       [-voff - back_holders_length, 0, 0],
       [-voff, 0, 0],   // left side plank
       [voff, 0, 0],    // right side plank
       [0, 0, 100],     // nails
    ]) {

        /* floors */
        color(c1)
            for (i = [1:nb_floors])
                translate([0, 0, floor_pos(i)])
                    h_plank_mid();

        /* vertical mid planks (back) */
        color(c0)
            for (i = [1:nb_cols])
                rotate([0, -90, 0])
                    translate([0, base_depth - mid_plank_depth, -column_pos(i)-base_thickness])
                        v_plank_mid_back();

        /* vertical mid planks (front) */
        color(c0)
            for (i = [1:nb_cols])
                rotate([0, -90, 180])
                    translate([0, -mid_plank_depth, column_pos(i)])
                        v_plank_mid_front();

        /* bottom */
        color(c1)
            h_plank_tb();

        /* top */
        color(c1)
            translate([0, 0, cols_height - base_thickness])
                h_plank_tb();


        /* back holders */
        color(c2)
            for (i = [0:nb_floors])
                translate([-base_thickness, base_depth - back_holders_backpad, back_holder_pos(i)])
                    rotate([90, 0, 0])
                        back_holder();

        /* vertical side planks (left and right) */
        color(c0)
            rotate([0, -90, 0])
                v_plank_lr();

        color(c0) {
            rotate([0, -90, 0]) {
                translate([0, 0, -base_width - base_thickness])
                    v_plank_lr();
            }
        }

        /* nails */
        color(c3) {
            for (i = [1:nb_floors]) {
                translate([0, 0, floor_pos(i) - (nail_height - base_thickness) / 2]) {
                    translate([-base_thickness, (base_depth+nail_width)/2])
                        rotate([0, 0, 180])
                            nail();
                    translate([base_width + base_thickness, (base_depth-nail_width)/2])
                        nail();
                }
            }
        }
    }
}

module do_show_parts() {
    if      (piece == "h_plank_mid")       h_plank_mid();
    else if (piece == "h_plank_tb")        h_plank_tb();
    else if (piece == "v_plank_lr")        v_plank_lr();
    else if (piece == "v_plank_mid_back")  v_plank_mid_back();
    else if (piece == "v_plank_mid_front") v_plank_mid_front();
    else if (piece == "back_holder")       back_holder();
    else {
        pad = 40;
        h_plank_mid();
        translate([0, pad*1 + h_plank_depth])
            h_plank_tb();
        translate([0, pad*2 + h_plank_depth*2])
            v_plank_lr();
        translate([0, pad*3 + h_plank_depth*2 + v_plank_lr_depth])
            v_plank_mid_back();
        translate([0, pad*4 + h_plank_depth*2 + v_plank_lr_depth + v_plank_mid_back_depth])
            v_plank_mid_front();
        translate([0, pad*5 + h_plank_depth*2 + v_plank_lr_depth + v_plank_mid_back_depth + v_plank_mid_front_depth])
            back_holder();

        //nail();
    }
}

if (show_parts) {
    if (project_2d) {
        projection()
            do_show_parts();
    } else {
        do_show_parts();
    }
} else {
    main();
}

echo(dimensions=[full_width, full_height, full_depth]);
