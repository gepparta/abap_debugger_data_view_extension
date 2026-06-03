*"* use this source file for your ABAP unit test classes
CLASS ltcl_pp_factory_should DEFINITION DEFERRED.
CLASS zcl_ddve_prettyprinter_factory DEFINITION LOCAL FRIENDS ltcl_pp_factory_should.
CLASS ltcl_pp_factory_should DEFINITION FINAL
  FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.

  PRIVATE SECTION.
    METHODS: find_standard_pretty_printer   FOR TESTING RAISING cx_static_check,
             create_standard_pretty_printer FOR TESTING RAISING cx_static_check.
ENDCLASS.


CLASS ltcl_pp_factory_should IMPLEMENTATION.
  METHOD find_standard_pretty_printer.
    " GIVEN - ...

    " WHEN
    FINAL(classes) = zcl_ddve_prettyprinter_factory=>get_activ_implementing_classes( ).

    " THEN
    cl_abap_unit_assert=>assert_table_contains(
        line  = |ZCL_DDVE_VALUE_PRETTY_PRINTER|
        table = classes
        msg   = |Main implementation of zif_op_value_pretty_printer was not found|    ).
  ENDMETHOD.

  METHOD create_standard_pretty_printer.
    " GIVEN
    zcl_ddve_prettyprinter_factory=>user_class_customizing = VALUE #(
        ( user_name = |AGEPPART|  class_name = |ZCL_DDVE_VALUE_PRETTY_PRINTER| ) ).

    " WHEN
    FINAL(pretty_printer) = zcl_ddve_prettyprinter_factory=>create( ).

    " THEN
    TRY.
        " TODO: variable is assigned but never used (ABAP cleaner)
        FINAL(must_be_pretty_printer) = CAST zcl_ddve_value_pretty_printer( pretty_printer ).

      CATCH cx_sy_move_cast_error INTO FINAL(error).
        cl_abap_unit_assert=>fail(
            msg = |Standard class ZCL_DDVE_VALUE_PRETTY_PRINTER was not used in factory but should have been. Error is { error->get_longtext( ) }| ).
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
