CLASS zcl_ddve_pp_customizing DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC
  GLOBAL FRIENDS zcl_ddve_pret_printer_injector.

  PUBLIC SECTION.
    TYPES tt_dve_cust TYPE STANDARD TABLE OF ztop_dve_cust WITH DEFAULT KEY.
    CLASS-METHODS get_class_for_user
      IMPORTING i_username                  TYPE uname
      RETURNING VALUE(r_printer_class_name) TYPE seoclsname.

  PRIVATE SECTION.
    CLASS-DATA customizing TYPE tt_dve_cust.
    CLASS-METHODS read_customizing.

ENDCLASS.


CLASS zcl_ddve_pp_customizing IMPLEMENTATION.
  METHOD get_class_for_user.
    read_customizing( ).
    CHECK line_exists( customizing[ user_name = i_username ] ).
    r_printer_class_name = customizing[ user_name = i_username ]-class_name.
  ENDMETHOD.

  METHOD read_customizing.
    IF customizing[] IS INITIAL.
      SELECT * FROM ztop_dve_cust INTO TABLE customizing.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
