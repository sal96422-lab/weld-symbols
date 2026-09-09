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
    label = "Choose weld preset";
    : row {
      : column { : image_button { key = "type_arrow"; width = 24; height = 10; fixed_width = true; fixed_height = true; color = 0; } : text { label = "Arrow"; alignment = centered; } }
      : column { : image_button { key = "type_other"; width = 24; height = 10; fixed_width = true; fixed_height = true; color = 0; } : text { label = "Other"; alignment = centered; } }
      : column { : image_button { key = "type_both"; width = 24; height = 10; fixed_width = true; fixed_height = true; color = 0; } : text { label = "Double"; alignment = centered; } }
    }
    : row {
      : column { : image_button { key = "type_arrow_len"; width = 15; height = 6; fixed_width = true; fixed_height = true; color = 0; } : text { label = "Arrow + L"; alignment = centered; } }
      : column { : image_button { key = "type_other_len"; width = 15; height = 6; fixed_width = true; fixed_height = true; color = 0; } : text { label = "Other + L"; alignment = centered; } }
      : column { : image_button { key = "type_both_len"; width = 15; height = 6; fixed_width = true; fixed_height = true; color = 0; } : text { label = "Double + L"; alignment = centered; } }
    }
    : row {
      : column { : image_button { key = "type_stagger_len"; width = 24; height = 10; fixed_width = true; fixed_height = true; color = 0; } : text { label = "Stag + L"; alignment = centered; } }
      : column { : image_button { key = "type_bevel_arrow"; width = 24; height = 10; fixed_width = true; fixed_height = true; color = 0; } : text { label = "Groove Bevel Arrow"; alignment = centered; } }
      : column { : image_button { key = "type_bevel_other"; width = 24; height = 10; fixed_width = true; fixed_height = true; color = 0; } : text { label = "Groove Bevel Other"; alignment = centered; } }
    }
    : row {
      : column { : image_button { key = "type_bevel_both"; width = 24; height = 10; fixed_width = true; fixed_height = true; color = 0; } : text { label = "Groove Bevel Both"; alignment = centered; } }
      : column { : image_button { key = "type_ugroove_arrow"; width = 24; height = 10; fixed_width = true; fixed_height = true; color = 0; } : text { label = "U-Groove Arrow"; alignment = centered; } }
      : column { : image_button { key = "type_ugroove_other"; width = 24; height = 10; fixed_width = true; fixed_height = true; color = 0; } : text { label = "U-Groove Other"; alignment = centered; } }
    }
    : row {
      : column { : image_button { key = "type_ugroove_both"; width = 24; height = 10; fixed_width = true; fixed_height = true; color = 0; } : text { label = "U-Groove Both"; alignment = centered; } }
      : column { : image_button { key = "type_square_groove_arrow"; width = 24; height = 10; fixed_width = true; fixed_height = true; color = 0; } : text { label = "Square Groove Arrow"; alignment = centered; } }
      : column { : image_button { key = "type_square_groove_other"; width = 24; height = 10; fixed_width = true; fixed_height = true; color = 0; } : text { label = "Square Groove Other"; alignment = centered; } }
    }
    : row {
      : column { : image_button { key = "type_square_groove_both"; width = 24; height = 10; fixed_width = true; fixed_height = true; color = 0; } : text { label = "Square Groove Both"; alignment = centered; } }
      : column { : image_button { key = "type_flare_v_groove_arrow"; width = 24; height = 10; fixed_width = true; fixed_height = true; color = 0; } : text { label = "Flare V Arrow"; alignment = centered; } }
      : column { : image_button { key = "type_flare_v_groove_other"; width = 24; height = 10; fixed_width = true; fixed_height = true; color = 0; } : text { label = "Flare V Other"; alignment = centered; } }
    }
    : row {
      : column { : image_button { key = "type_flare_bevel_groove_arrow"; width = 24; height = 10; fixed_width = true; fixed_height = true; color = 0; } : text { label = "Flare Bevel Arrow"; alignment = centered; } }
      : column { : image_button { key = "type_flare_bevel_groove_other"; width = 24; height = 10; fixed_width = true; fixed_height = true; color = 0; } : text { label = "Flare Bevel Other"; alignment = centered; } }
      : column { : image_button { key = "type_flare_bevel_groove_both"; width = 24; height = 10; fixed_width = true; fixed_height = true; color = 0; } : text { label = "Flare Bevel Both"; alignment = centered; } }
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
        : text { key = "side_label0"; label = "Arrow"; width = 11; alignment = centered; }
        : text { key = "side_label1"; label = "Other"; width = 11; alignment = centered; }
        : text { key = "side_label2"; label = "Both"; width = 11; alignment = centered; }
      }
      : row {
        : edit_box { key = "size"; label = "Arrow size"; edit_width = 8; }
        : edit_box { key = "othersize"; label = "Other size"; edit_width = 8; }
      }
      : row {
        : edit_box { key = "length"; label = "Arrow length"; edit_width = 8; }
        : edit_box { key = "pitch"; label = "Arrow pitch"; edit_width = 8; }
      }
      : row {
        : edit_box { key = "otherlength"; label = "Other length"; edit_width = 8; }
        : edit_box { key = "otherpitch"; label = "Other pitch"; edit_width = 8; }
      }
    }
    : boxed_column {
      label = "Toolbox";
      : row {
        : toggle { key = "field"; label = "Field weld"; }
        : toggle { key = "allaround"; label = "All around"; }
      }
      : toggle { key = "tailon"; label = "Tail"; }
      : edit_box { key = "tailtext"; label = "Tail line 1"; edit_width = 22; }
      : edit_box { key = "tailtext2"; label = "Tail line 2"; edit_width = 22; }
    }
  }
  spacer;
  ok_cancel;
}

weldsym_bevel_opts : dialog {
  label = "Groove Bevel Weld Options";
  : row {
    : boxed_column {
      label = "Arrow side groove bevel";
      : edit_box { key = "beveldepth"; label = "Depth of bevel"; edit_width = 10; }
      : edit_box { key = "bevelsize"; label = "Groove weld size"; edit_width = 10; }
      : edit_box { key = "bevelroot"; label = "Root opening"; edit_width = 10; }
      : edit_box { key = "bevelangle"; label = "Groove angle"; edit_width = 10; }
    }
    : boxed_column {
      label = "Other side groove bevel";
      : edit_box { key = "otherbeveldepth"; label = "Depth of bevel"; edit_width = 10; }
      : edit_box { key = "otherbevelsize"; label = "Groove weld size"; edit_width = 10; }
      : edit_box { key = "otherbevelroot"; label = "Root opening"; edit_width = 10; }
      : edit_box { key = "otherbevelangle"; label = "Groove angle"; edit_width = 10; }
    }
    : boxed_column {
      label = "Toolbox";
      : row {
        : toggle { key = "field"; label = "Field weld"; }
        : toggle { key = "allaround"; label = "All around"; }
      }
      : toggle { key = "tailon"; label = "Tail"; }
      : edit_box { key = "tailtext"; label = "Tail line 1"; edit_width = 22; }
      : edit_box { key = "tailtext2"; label = "Tail line 2"; edit_width = 22; }
    }
  }
  spacer;
  ok_cancel;
}

weldsym_groove_opts : dialog {
  label = "Groove V Weld Options";
  : row {
    : boxed_column {
      label = "Arrow side groove";
      : edit_box { key = "groovedepth"; label = "Depth of bevel S1"; edit_width = 10; }
      : edit_box { key = "groovesize"; label = "Groove V weld size E1"; edit_width = 10; }
      : edit_box { key = "grooveroot"; label = "R1"; edit_width = 10; }
      : edit_box { key = "grooveangle"; label = "A1"; edit_width = 10; }
    }
    : boxed_column {
      label = "Other side groove";
      : edit_box { key = "othergroovedepth"; label = "Depth of bevel S2"; edit_width = 10; }
      : edit_box { key = "othergroovesize"; label = "Groove V weld size E2"; edit_width = 10; }
      : edit_box { key = "othergrooveroot"; label = "R2"; edit_width = 10; }
      : edit_box { key = "othergrooveangle"; label = "A2"; edit_width = 10; }
    }
    : boxed_column {
      label = "Toolbox";
      : row {
        : toggle { key = "field"; label = "Field weld"; }
        : toggle { key = "allaround"; label = "All around"; }
      }
      : toggle { key = "tailon"; label = "Tail"; }
      : edit_box { key = "tailtext"; label = "Tail line 1"; edit_width = 22; }
      : edit_box { key = "tailtext2"; label = "Tail line 2"; edit_width = 22; }
    }
  }
  spacer;
  ok_cancel;
}


