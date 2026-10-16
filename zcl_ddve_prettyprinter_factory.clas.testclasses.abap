*"* use this source file for your ABAP unit test classes
"! test double: pretty printer that always fails with a dynamic exception
CLASS ltd_throwing_printer DEFINITION FINAL FOR TESTING.
  PUBLIC SECTION.
    INTERFACES zif_ddve_value_pretty_printer.
ENDCLASS.

CLASS ltd_throwing_printer IMPLEMENTATION.
  METHOD zif_ddve_value_pretty_printer~format.
    " simulate an arbitrary runtime error inside a printer implementation
    RAISE EXCEPTION TYPE cx_sy_itab_line_not_found.
  ENDMETHOD.
ENDCLASS.


"! test double: pretty printer returning a recognizable constant
CLASS ltd_fake_printer DEFINITION FINAL FOR TESTING.
  PUBLIC SECTION.
    INTERFACES zif_ddve_value_pretty_printer.
ENDCLASS.

CLASS ltd_fake_printer IMPLEMENTATION.
  METHOD zif_ddve_value_pretty_printer~format.
    r_formatted_content = |FORMATED|.
  ENDMETHOD.
ENDCLASS.


CLASS ltcl_pp_factory_should DEFINITION DEFERRED.
CLASS zcl_ddve_prettyprinter_factory DEFINITION LOCAL FRIENDS ltcl_pp_factory_should.
CLASS ltcl_pp_factory_should DEFINITION FINAL
  FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.

  PRIVATE SECTION.
    METHODS: teardown,
             find_standard_pretty_printer   FOR TESTING RAISING cx_static_check,
             create_standard_pretty_printer FOR TESTING RAISING cx_static_check,
             fall_back_on_printer_error     FOR TESTING RAISING cx_static_check,
             format_via_injected_printer    FOR TESTING RAISING cx_static_check,
             format_real_sflight_statement  FOR TESTING RAISING cx_static_check.
ENDCLASS.


CLASS ltcl_pp_factory_should IMPLEMENTATION.
  METHOD teardown.
    " reset the factory singleton so an injected test double never leaks into other tests
    zcl_ddve_prettyprinter_factory=>pretty_printer = VALUE #( ).
  ENDMETHOD.

  METHOD find_standard_pretty_printer.
    " GIVEN - ...

    " WHEN
    DATA(classes) = zcl_ddve_prettyprinter_factory=>get_active_impl_classes( ).

    " THEN
    cl_abap_unit_assert=>assert_table_contains(
        line  = |ZCL_DDVE_VALUE_PRETTY_PRINTER|
        table = classes
        msg   = |Main implementation of zif_ddve_value_pretty_printer was not found|    ).
  ENDMETHOD.

  METHOD create_standard_pretty_printer.
    " GIVEN - reset singleton and inject customizing for current user
    zcl_ddve_prettyprinter_factory=>pretty_printer = VALUE #( ).
    zcl_ddve_pret_printer_injector=>inject_user_class_customizing( VALUE #(
        ( user_name = sy-uname  class_name = |ZCL_DDVE_VALUE_PRETTY_PRINTER| ) ) ).

    " WHEN
    DATA(pretty_printer) = zcl_ddve_prettyprinter_factory=>create( ).

    " THEN
    TRY.
        DATA(must_be_pretty_printer) = CAST zcl_ddve_value_pretty_printer( pretty_printer ).
      CATCH cx_sy_move_cast_error INTO DATA(error).
        cl_abap_unit_assert=>fail(
            msg = |Standard class ZCL_DDVE_VALUE_PRETTY_PRINTER was not used in factory but should have been. Error is { error->get_longtext( ) }| ).
    ENDTRY.
  ENDMETHOD.

  METHOD fall_back_on_printer_error.
    " GIVEN - a printer that fails with an undeclared dynamic exception
    zcl_ddve_pret_printer_injector=>inject_pretty_printer( NEW ltd_throwing_printer( ) ).
    DATA(unformatted_content) = `X = VALUE #( ( COL1 = 1 ) ).`.

    " WHEN
    DATA(result) = zcl_ddve_prettyprinter_factory=>format_with_fallback( unformatted_content ).

    " THEN
    cl_abap_unit_assert=>assert_equals(
        exp = unformatted_content
        act = result
        msg = |On a formatting error the unformatted content must be returned| ).
  ENDMETHOD.

  METHOD format_via_injected_printer.
    " GIVEN - a working printer
    zcl_ddve_pret_printer_injector=>inject_pretty_printer( NEW ltd_fake_printer( ) ).

    " WHEN
    DATA(result) = zcl_ddve_prettyprinter_factory=>format_with_fallback( `X = VALUE #( ).` ).

    " THEN
    cl_abap_unit_assert=>assert_equals(
        exp = |FORMATED|
        act = result
        msg = |The formatted content of the configured printer must be returned| ).
  ENDMETHOD.

  METHOD format_real_sflight_statement.
    " GIVEN - repro for the debugger report of 16.10.2026: a full typed
    "         SFLIGHT export came back as an unformatted one-liner;
    "         exercise the complete chain create( ) -> format( )
    zcl_ddve_prettyprinter_factory=>pretty_printer = VALUE #( ).
    zcl_ddve_pret_printer_injector=>inject_user_class_customizing( VALUE #(
        ( user_name = sy-uname  class_name = |ZCL_DDVE_VALUE_PRETTY_PRINTER| ) ) ).

    DATA(input) = |DATA(LS_FLIGHT) = VALUE SFLIGHT( MANDT = '100' CARRID = 'AA' CONNID = '0017'|
               && | FLDATE = '20141217' PRICE = '422.94' CURRENCY = 'USD' PLANETYPE = '747-400'|
               && | SEATSMAX = 385 SEATSOCC = 372 PAYMENTSUM = '192437.84' SEATSMAX_B = 31|
               && | SEATSOCC_B = 28 SEATSMAX_F = 21 SEATSOCC_F = 21 ).|.

    " WHEN
    DATA(result) = zcl_ddve_prettyprinter_factory=>format_with_fallback( input ).

    " THEN - the statement must be formatted (multi-line), not the fallback
    cl_abap_unit_assert=>assert_differs(
        act = result
        exp = input
        msg = |Pretty printer fell back to the unformatted one-liner| ).
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( result CS |\n| )
        msg = |Formatted output must contain line breaks| ).
  ENDMETHOD.
ENDCLASS.
