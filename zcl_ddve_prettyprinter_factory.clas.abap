CLASS zcl_ddve_prettyprinter_factory DEFINITION
  PUBLIC FINAL
  CREATE PRIVATE
  GLOBAL FRIENDS zcl_ddve_pret_printer_injector.

  PUBLIC SECTION.
    CLASS-METHODS create RETURNING VALUE(r_pretty_printer) TYPE REF TO zif_ddve_value_pretty_printer
                         RAISING   cx_class_not_existent.

  PRIVATE SECTION.
    TYPES tt_dve_cust TYPE STANDARD TABLE OF ztop_dve_cust WITH DEFAULT KEY.

    CLASS-DATA: pretty_printer         TYPE REF TO zif_ddve_value_pretty_printer,
                class_names            TYPE string_table,
                user_class_customizing TYPE tt_dve_cust.

    CLASS-METHODS:
      "!get active classes implementing zif_op_value_pretty_printer
      "!
      "! @parameter r_class_names |
      "! @raising cx_class_not_existent |
      get_activ_implementing_classes RETURNING VALUE(r_class_names) TYPE string_table
                                     RAISING   cx_class_not_existent,

      get_customizing_for_given_user RETURNING VALUE(r_customizing) TYPE ztop_dve_cust,
      read_customizing,

      "!check if a given class an active implementation
      "!
      "! @parameter i_classname_to_use |
      "! @parameter r_class_impl_is_active |
      "! @raising cx_class_not_existent |
      is_given_class_an_active_impl IMPORTING i_classname_to_use            TYPE ztop_dve_cust
                                    RETURNING VALUE(r_class_impl_is_active) TYPE boole_d
                                    RAISING   cx_class_not_existent.
ENDCLASS.


CLASS zcl_ddve_prettyprinter_factory IMPLEMENTATION.
  METHOD create.
    IF pretty_printer IS NOT BOUND.

      " check which of them is customized for current user
      DATA(classname_to_use) = get_customizing_for_given_user( ).

      classname_to_use = COND #( WHEN is_given_class_an_active_impl( classname_to_use ) = abap_true
                                 THEN classname_to_use
                                 ELSE |ZCL_DDVE_VALUE_PRETTY_PRINTER| ).

      CREATE OBJECT pretty_printer TYPE (classname_to_use).
    ENDIF.

    r_pretty_printer = pretty_printer.
  ENDMETHOD.

  METHOD get_activ_implementing_classes.
    IF class_names[] IS INITIAL.
      DATA(oo_interface) = NEW cl_oo_interface( |ZIF_DDVE_VALUE_PRETTY_PRINTER| ).

      DATA(classes) = oo_interface->get_implementing_classes( ).

      class_names = VALUE #( FOR <line> IN classes
                             ( CONV string( <line>-clsname ) ) ).
    ENDIF.

    r_class_names = class_names.
  ENDMETHOD.

  METHOD get_customizing_for_given_user.
    read_customizing( ).
    CHECK line_exists( user_class_customizing[ user_name = sy-uname ] ).
    r_customizing = user_class_customizing[ user_name = sy-uname ]-class_name.
  ENDMETHOD.

  METHOD is_given_class_an_active_impl.
    " get active classes implementing zif_op_value_pretty_printer
    class_names = get_activ_implementing_classes( ).

    r_class_impl_is_active = COND boole_d( WHEN line_exists( class_names[ table_line = i_classname_to_use ] )
                                           THEN abap_true
                                           ELSE abap_false ).
  ENDMETHOD.

  METHOD read_customizing.
    IF user_class_customizing[] IS INITIAL.
      SELECT * FROM ztop_dve_cust
        INTO TABLE user_class_customizing.

    ENDIF.
  ENDMETHOD.
ENDCLASS.
