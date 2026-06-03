CLASS ltcl_component_should DEFINITION DEFERRED.
CLASS zcl_ddve_component DEFINITION LOCAL FRIENDS ltcl_component_should.

CLASS ltcl_component_should DEFINITION FINAL FOR TESTING
  DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zcl_ddve_component.

    METHODS:
      setup,
      not_change_context_for_initial   FOR TESTING,
      format_integer_without_quotes    FOR TESTING,
      format_string_with_backticks     FOR TESTING,
      format_char_with_single_quotes   FOR TESTING,
      format_value_without_fieldname   FOR TESTING,
      escape_apostrophe_in_char        FOR TESTING.
ENDCLASS.

CLASS ltcl_component_should IMPLEMENTATION.
  METHOD setup.
    cut = NEW zcl_ddve_component( ).
  ENDMETHOD.

  METHOD not_change_context_for_initial.
    " GIVEN
    DATA(context_in) = |PREV = 'VALUE'|.
    DATA(fcat)       = VALUE lvc_s_fcat( fieldname = 'COL1' inttype = 'I' ).
    DATA lv_int      TYPE i.

    " WHEN
    DATA(result) = cut->add( i_current_context = context_in
                             i_component       = lv_int
                             i_component_info  = fcat ).
    " THEN
    cl_abap_unit_assert=>assert_equals(
      exp = context_in
      act = result
      msg = |Initial component must not change context| ).
  ENDMETHOD.

  METHOD format_integer_without_quotes.
    " GIVEN
    DATA lv_int TYPE i VALUE 42.
    DATA(fcat) = VALUE lvc_s_fcat( fieldname = 'COUNT'
                                   inttype   = zcl_ddve_abap_typedescr=>typekind_int ).
    " WHEN
    DATA(result) = cut->add( i_current_context = ||
                             i_component       = lv_int
                             i_component_info  = fcat ).
    " THEN
    cl_abap_unit_assert=>assert_equals(
      exp = | COUNT = 42|
      act = result
      msg = |Integer must be formatted without quotes| ).
  ENDMETHOD.

  METHOD format_string_with_backticks.
    " GIVEN
    DATA lv_str TYPE string VALUE 'hello'.
    DATA(fcat) = VALUE lvc_s_fcat( fieldname = 'TEXT'
                                   inttype   = zcl_ddve_abap_typedescr=>typekind_string ).
    " WHEN
    DATA(result) = cut->add( i_current_context = ||
                             i_component       = lv_str
                             i_component_info  = fcat ).
    " THEN
    cl_abap_unit_assert=>assert_equals(
      exp = | TEXT = `hello`|
      act = result
      msg = |String must use backtick notation| ).
  ENDMETHOD.

  METHOD format_char_with_single_quotes.
    " GIVEN
    DATA lv_char(4) TYPE c VALUE 'AA'.
    DATA(fcat) = VALUE lvc_s_fcat( fieldname = 'CARRID'
                                   inttype   = 'C' ).
    " WHEN
    DATA(result) = cut->add( i_current_context = ||
                             i_component       = lv_char
                             i_component_info  = fcat ).
    " THEN
    cl_abap_unit_assert=>assert_equals(
      exp = | CARRID = 'AA'|
      act = result
      msg = |Char must use single-quote notation| ).
  ENDMETHOD.

  METHOD format_value_without_fieldname.
    " GIVEN - e.g. table of integers: no field name in fcat
    DATA lv_int TYPE i VALUE 5.
    DATA(fcat) = VALUE lvc_s_fcat( inttype = zcl_ddve_abap_typedescr=>typekind_int ).
    " WHEN
    DATA(result) = cut->add( i_current_context = ||
                             i_component       = lv_int
                             i_component_info  = fcat ).
    " THEN
    cl_abap_unit_assert=>assert_equals(
      exp = | 5|
      act = result
      msg = |Component without fieldname must produce direct value| ).
  ENDMETHOD.

  METHOD escape_apostrophe_in_char.
    " GIVEN
    DATA lv_char(10) TYPE c VALUE `it's`.
    DATA(fcat) = VALUE lvc_s_fcat( fieldname = 'TXT'
                                   inttype   = 'C' ).
    " WHEN
    DATA(result) = cut->add( i_current_context = ||
                             i_component       = lv_char
                             i_component_info  = fcat ).
    " THEN
    cl_abap_unit_assert=>assert_equals(
      exp = | TXT = 'it''s'|
      act = result
      msg = |Apostrophe must be escaped as '' in char value| ).
  ENDMETHOD.
ENDCLASS.
