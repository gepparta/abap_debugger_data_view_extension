CLASS zcl_ddve_prettyprinter_factory DEFINITION
  PUBLIC FINAL
  CREATE PRIVATE
  GLOBAL FRIENDS zcl_ddve_pret_printer_injector.

  PUBLIC SECTION.
    CLASS-METHODS:
      create RETURNING VALUE(r_pretty_printer) TYPE REF TO zif_ddve_value_pretty_printer
             RAISING   cx_class_not_existent,

      "! Format given content with the configured pretty printer.<br/>
      "! Guarantees a usable result: on ANY error during creation or
      "! formatting the unformatted input is returned unchanged.
      "! @parameter i_content | unformatted value #() content
      "! @parameter r_formated_content | formatted content or (on error) the unformatted input
      format_with_fallback IMPORTING i_content                 TYPE string
                           RETURNING VALUE(r_formated_content) TYPE string.

  PRIVATE SECTION.
    CLASS-DATA: pretty_printer TYPE REF TO zif_ddve_value_pretty_printer,
                class_names    TYPE string_table.

    CLASS-METHODS:
      get_activ_implementing_classes RETURNING VALUE(r_class_names) TYPE string_table
                                     RAISING   cx_class_not_existent,

      is_given_class_an_active_impl IMPORTING i_classname_to_use            TYPE seoclsname
                                    RETURNING VALUE(r_class_impl_is_active) TYPE boole_d
                                    RAISING   cx_class_not_existent.
ENDCLASS.


CLASS zcl_ddve_prettyprinter_factory IMPLEMENTATION.
  METHOD create.
    IF pretty_printer IS NOT BOUND.

      DATA(classname_to_use) = zcl_ddve_pp_customizing=>get_class_for_user( sy-uname ).

      DATA(class_to_create) = COND string(
          WHEN is_given_class_an_active_impl( classname_to_use ) = abap_true
          THEN CONV string( classname_to_use )
          ELSE |ZCL_DDVE_VALUE_PRETTY_PRINTER| ).

      CREATE OBJECT pretty_printer TYPE (class_to_create).
    ENDIF.

    r_pretty_printer = pretty_printer.
  ENDMETHOD.

  METHOD format_with_fallback.
    TRY.
        r_formated_content = create( )->format( i_content ).
      CATCH cx_root ##CATCH_ALL.
        " guarantee: any formatting error must fall back to the unformatted content
        r_formated_content = i_content.
    ENDTRY.
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

  METHOD is_given_class_an_active_impl.
    class_names = get_activ_implementing_classes( ).

    r_class_impl_is_active = COND boole_d(
        WHEN line_exists( class_names[ table_line = CONV string( i_classname_to_use ) ] )
        THEN abap_true
        ELSE abap_false ).
  ENDMETHOD.
ENDCLASS.
