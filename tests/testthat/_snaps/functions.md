# read_concentrations() rejects files it can't use

    Code
      read_lines("pac,value", "Pyrene,1")$errors
    Output
      [1] "The file is missing these columns: concentration_ug_L."
    Code
      read_lines("pac,concentration_ug_L", "Pyrene,<0.01", "Anthracene,1")$errors
    Output
      [1] "Concentrations must be numbers: row 2 (<0.01)."
    Code
      read_lines("pac,concentration_ug_L", "Pyrene,-1")$errors
    Output
      [1] "Concentrations can't be negative: row 2 (-1)."
    Code
      read_lines("pac,concentration_ug_L", "c1-anthracenes,1",
        "C1-Phenanthrenes/Anthracenes,2")$errors
    Output
      [1] "Each PAC or homologue group can only be included once: C1-Phenanthrenes/Anthracenes. If its compounds were reported separately, add their concentrations together and enter the total."
    Code
      read_lines("pac,concentration_ug_L", "Pyrene,")$errors
    Output
      [1] "The file has no concentrations."

