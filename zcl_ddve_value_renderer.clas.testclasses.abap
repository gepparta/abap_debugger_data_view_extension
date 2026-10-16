*"* use this source file for your ABAP unit test classes
CLASS ltc_renderer_should DEFINITION DEFERRED.
CLASS zcl_ddve_value_renderer DEFINITION LOCAL FRIENDS ltc_renderer_should.

CLASS ltc_renderer_should DEFINITION FINAL FOR TESTING
  DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zcl_ddve_value_renderer.

    METHODS: setup,
             "       |----- max. 30 Zeichen ------|
             render_empty_itab_untyped     FOR TESTING RAISING cx_static_check,
             render_empty_itab_typed       FOR TESTING RAISING cx_static_check.
ENDCLASS.


CLASS ltc_renderer_should IMPLEMENTATION.
  METHOD setup.
    cut = NEW #( ).
  ENDMETHOD.

  METHOD render_empty_itab_untyped.
    " given
    DATA empty_flights TYPE STANDARD TABLE OF sflight WITH EMPTY KEY.

    " when
    DATA(output) = cut->render_itab( i_table_title     = 'EMPTY_FLIGHTS'
                                     i_current_context = space
                                     i_table           = empty_flights ).

    " then
    cl_abap_unit_assert=>assert_equals( act = output
                                        exp = |EMPTY_FLIGHTS = VALUE #( ).|
                                        msg = |Empty itab must still render the VALUE prefix| ).
  ENDMETHOD.

  METHOD render_empty_itab_typed.
    " given
    DATA empty_flights TYPE STANDARD TABLE OF sflight WITH EMPTY KEY.

    " when
    DATA(output) = cut->render_itab( i_table_title     = 'EMPTY_FLIGHTS'
                                     i_current_context = space
                                     i_table           = empty_flights
                                     i_type_name       = 'FLIGHTTAB' ).

    " then
    cl_abap_unit_assert=>assert_equals( act = output
                                        exp = |DATA(EMPTY_FLIGHTS) = VALUE FLIGHTTAB( ).|
                                        msg = |Empty typed itab must render DATA(name) = VALUE typ( ).| ).
  ENDMETHOD.
ENDCLASS.
