weldsym_dir : dialog {
  label = "Weld Direction";
  : boxed_row {
    label = "Callout direction";
    : column { : image_button { key = "dir_pick0"; width = 18; height = 6; fixed_width = true; fixed_height = true; color = 0; } : text { label = "Weld right"; alignment = centered; } }
    : column { : image_button { key = "dir_pick1"; width = 18; height = 6; fixed_width = true; fixed_height = true; color = 0; } : text { label = "Weld left"; alignment = centered; } }
  }
  cancel_button;
}

weldsym_type : dialog {
  label = "Weld Type";
  : boxed_column {
    label = "Pick weld symbol";
    : column {
      : image_button { key = "sym0"; width = 22; height = 9; fixed_width = true; fixed_height = true; color = 0; }
      : text { label = "Fillet"; alignment = centered; }
    }
  }
  cancel_button;
}

weldsym_opts : dialog {
  label = "Weld Options";
  : row {
    : boxed_column {
      label = "Placement";
      : boxed_row {
        label = "Side";
        : image_button { key = "side0"; width = 11; height = 5; fixed_width = true; fixed_height = true; color = 0; }
        : image_button { key = "side1"; width = 11; height = 5; fixed_width = true; fixed_height = true; color = 0; }
        : image_button { key = "side2"; width = 11; height = 5; fixed_width = true; fixed_height = true; color = 0; }
      }
      : row {
        : text { label = "Arrow"; width = 11; alignment = centered; }
        : text { label = "Other"; width = 11; alignment = centered; }
        : text { label = "Both"; width = 11; alignment = centered; }
      }
      : row {
        : edit_box { key = "size"; label = "Arrow size"; edit_width = 8; }
        : edit_box { key = "othersize"; label = "Other size"; edit_width = 8; }
        : edit_box { key = "length"; label = "Length"; edit_width = 8; }
        : edit_box { key = "pitch"; label = "Pitch"; edit_width = 8; }
      }
    }
    : boxed_column {
      label = "Toolbox";
      : row {
        : toggle { key = "field"; label = "Field weld"; }
        : toggle { key = "allaround"; label = "All around"; }
      }
      : toggle { key = "tailon"; label = "Tail"; }
      : boxed_row {
        label = "Contour";
        : image_button { key = "contour0"; width = 9; height = 4; fixed_width = true; fixed_height = true; color = 0; }
        : image_button { key = "contour1"; width = 9; height = 4; fixed_width = true; fixed_height = true; color = 0; }
        : image_button { key = "contour2"; width = 9; height = 4; fixed_width = true; fixed_height = true; color = 0; }
        : image_button { key = "contour3"; width = 9; height = 4; fixed_width = true; fixed_height = true; color = 0; }
      }
      : row {
        : text { label = "None"; width = 9; alignment = centered; }
        : text { label = "Flush"; width = 9; alignment = centered; }
        : text { label = "Convex"; width = 9; alignment = centered; }
        : text { label = "Concave"; width = 9; alignment = centered; }
      }
      : edit_box { key = "process"; label = "Process/spec"; edit_width = 22; }
      : edit_box { key = "tailtext"; label = "Tail line 1"; edit_width = 22; }
      : edit_box { key = "tailtext2"; label = "Tail line 2"; edit_width = 22; }
    }
  }
  spacer;
  ok_cancel;
}


