CLASS ltc_table_enh_should DEFINITION DEFERRED.
CLASS zcl_ddve_table   DEFINITION LOCAL FRIENDS ltc_table_enh_should.

CLASS ltc_table_enh_should DEFINITION FOR TESTING
  DURATION SHORT  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA:
      table_view TYPE REF TO zcl_ddve_table.  "class under test

    METHODS:
      setup,
      teardown,
      "!check of
      prepare_output_w_1_line_itab FOR TESTING,
      prepare_typed_output        FOR TESTING,
      handle_structure_in_itab    FOR TESTING,
      handle_itab_in_itab         FOR TESTING,
      st05_main_record_table      FOR TESTING RAISING cx_static_check,
      ris_t_metadata              FOR TESTING RAISING cx_static_check,
      "       |----- max. 30 characters ------|
      detect_clone_by_index_column  FOR TESTING,
      not_mistake_real_for_clone    FOR TESTING,
      extract_indexes_in_alv_order  FOR TESTING,
      pick_rows_in_alv_order        FOR TESTING,
      carry_no_out_from_alv_catalog FOR TESTING,
      keep_real_table_untouched     FOR TESTING.
ENDCLASS.


CLASS ltc_table_enh_should IMPLEMENTATION.

  METHOD setup.
    table_view = NEW zcl_ddve_table( ).
  ENDMETHOD.


  METHOD teardown.
    CLEAR table_view.
  ENDMETHOD.


  METHOD prepare_output_w_1_line_itab.

    TYPES: BEGIN OF ty_sflight_mini,
             carrid TYPE s_carr_id,
             connid TYPE s_conn_id,
             fldate TYPE s_date,
             price  TYPE s_price,
           END OF ty_sflight_mini.
    DATA: output        TYPE                   string,
          output_exp    TYPE                   string,
          sflight_lines TYPE STANDARD TABLE OF ty_sflight_mini.


    sflight_lines = VALUE #(  ( carrid = 'AA'   connid = '0017' fldate = '20170810' price = '422.94 ' ) ).

    output = table_view->prepare_output(  i_table          = sflight_lines
                                          i_table_title    = 'SFLIGHT_LINES' ).

    output_exp = |SFLIGHT_LINES = VALUE #( ( CARRID = 'AA' CONNID = '0017' FLDATE = '20170810' PRICE = '422.94 ' ) ).|.
    cl_abap_unit_assert=>assert_equals( EXPORTING  act = output
                                                   exp = output_exp
                                                   msg = |Character String Different| ).


  ENDMETHOD.

  METHOD prepare_typed_output.
    TYPES: BEGIN OF ty_sflight_mini,
             carrid TYPE s_carr_id,
             connid TYPE s_conn_id,
           END OF ty_sflight_mini.
    DATA sflight_lines TYPE STANDARD TABLE OF ty_sflight_mini.

    sflight_lines = VALUE #( ( carrid = 'AA' connid = '0017' ) ).

    " field-symbol brackets are stripped for the DATA( ) variable name
    DATA(output) = table_view->prepare_output( i_table       = sflight_lines
                                               i_table_title = '<FLIGHTS>'
                                               i_type_name   = 'ZCL_ORDER=>TT_FLIGHTS' ).

    cl_abap_unit_assert=>assert_equals(
        act = output
        exp = |DATA(FLIGHTS) = VALUE ZCL_ORDER=>TT_FLIGHTS( ( CARRID = 'AA' CONNID = '0017' ) ).|
        msg = |Typed table statement was not built correctly| ).
  ENDMETHOD.

  METHOD handle_itab_in_itab.
    TYPES: BEGIN OF ts_flight_data,
             carrid TYPE s_carr_id,
             connid TYPE s_conn_id,
             fldate TYPE s_date,
             price  TYPE s_price,
           END OF ts_flight_data,
           tt_flight_data TYPE STANDARD TABLE OF ts_flight_data WITH EMPTY KEY,
           BEGIN OF ts_flight_data_deep,
             col1 TYPE tt_flight_data,
           END OF ts_flight_data_deep,
           tt_flight_data_deep TYPE STANDARD TABLE OF ts_flight_data_deep WITH EMPTY KEY.

    DATA: output        TYPE string,
          output_exp    TYPE string,
          sflight_lines TYPE tt_flight_data_deep.


    sflight_lines = VALUE #( ( col1 = VALUE #(
                                            ( carrid = 'AA'   connid = '0017' fldate = '20170810' price = '422.94 ' )
                                            ( carrid = 'AA'   connid = '0017' fldate = '20170810' price = '422.94 ' )
                                          )
                          )
                          ( col1 = VALUE #(
                                            ( carrid = 'AA'   connid = '0017' fldate = '20170810' price = '422.94 ' )
                                            ( carrid = 'AA'   connid = '0017' fldate = '20170810' price = '422.94 ' )
                                          )
                          )
                        ).


    output = table_view->prepare_output( i_table          = sflight_lines
                                                       i_table_title    = 'SFLIGHT_LINES' ).

    output_exp = |SFLIGHT_LINES = VALUE #( ( COL1 = VALUE #( ( CARRID = 'AA' CONNID = '0017' FLDATE = '20170810' PRICE = '422.94 ' )| &&
                 | ( CARRID = 'AA' CONNID = '0017' FLDATE = '20170810' PRICE = '422.94 ' ) ) ) ( COL1 = VALUE #( ( CARRID = 'AA' CONNID| &&
                 | = '0017' FLDATE = '20170810' PRICE = '422.94 ' ) ( CARRID = 'AA' CONNID = '0017' FLDATE = '20170810' PRICE = '422.94 ' ) ) ) ).|.

    cl_abap_unit_assert=>assert_equals( EXPORTING act = output
                                                  exp = output_exp
                                                  msg = |Itab in itab formatting is not as expected|
                                                  quit = if_aunit_constants=>method ).

  ENDMETHOD.


  METHOD handle_structure_in_itab.

    TYPES: BEGIN OF ts_flight_data,
             carrid TYPE s_carr_id,
             connid TYPE s_conn_id,
             fldate TYPE s_date,
             price  TYPE s_price,
           END OF ts_flight_data,
           BEGIN OF ts_flight_data_w_structure,
             col1 TYPE ts_flight_data,
           END OF ts_flight_data_w_structure,
           tt_flight_data_w_structure TYPE STANDARD TABLE OF ts_flight_data_w_structure WITH EMPTY KEY.


    DATA: output        TYPE string,
          output_exp    TYPE string,
          sflight_lines TYPE tt_flight_data_w_structure. "ztt_age_col1


    sflight_lines = VALUE #( ( col1 = VALUE #( carrid = 'AA' connid = '0017' fldate = '20170810' price = '422.94 ' )
                          )
                          ( col1 = VALUE #( carrid = 'AA' connid = '0017' fldate = '20170810' price = '422.94 ' )
                          )
                        ).


    output = table_view->prepare_output( i_table = sflight_lines
                                                       i_table_title = 'SFLIGHT_LINES' ).

    output_exp = |SFLIGHT_LINES = VALUE #( ( COL1 = VALUE #( CARRID = 'AA' CONNID = '0017' FLDATE = '20170810' PRICE = '422.94' ) )| &&
                 | ( COL1 = VALUE #( CARRID = 'AA' CONNID = '0017' FLDATE = '20170810' PRICE = '422.94' ) ) ).|.

    cl_abap_unit_assert=>assert_equals( EXPORTING act = output
                                                  exp = output_exp
                                                  msg = |Structure in itab formatting is not as expected|
                                                  quit = if_aunit_constants=>method ).
  ENDMETHOD.

  METHOD st05_main_record_table.
    DATA(lv_date) = sy-datum.
    DATA(lv_time) = sy-uzeit.

    DATA(table) = VALUE st05_main_record_table( ( date                           = lv_date
                                                  time                           = lv_time
                                                  duration                       = 11
                                                  number_of_rows                 = 12
                                                  object                         = 'OBJECT'
                                                  statement_with_values          = `STATEMENT_WITH_VALUES`
                                                  array_size                     = 12
                                                  transaction                    = 'TRANSACTION'
                                                  program                        = 'PROGRAM'
                                                  db_connection_name             = 'DB_CONNECTION_NAME'
                                                  db_connection_id               = 'DB_CON_ID'
                                                  operation                      = 'OPERATI'
                                                  return_code                    = 13
                                                  wp_id                          = '001'
                                                  wp_type                        = 'DIA'
                                                  user_name                      = 'USER_NAME'
                                                  client                         = '100'
                                                  trans_id                       = 'TRANS_ID'
                                                  epp_root_id                    = 'EPP_ROOT_ID'
                                                  epp_connection_id              = 'EPP_CONNECTION_ID'
                                                  epp_connection_counter         = 14
                                                  record_number                  = 15
                                                  record_numbers                 = VALUE #( ( 16 ) ( 17 ) )
                                                  offset                         = 18
                                                  statement_with_names           = `STATEMENT_WITH_NAMES`
                                                  length_of_statement_with_names = 19
                                                  variables                      = `VARIABLES`
                                                  number_of_variables            = 20
                                                  trace_type                     = 'TRAC'
                                                  line_color                     = 'LINE' ) ).

    DATA(output) = table_view->prepare_output( i_table       = table
                                               i_table_title = 'TABLE' ).

    DATA(output_exp) = |TABLE = VALUE #( ( DATE = '{ lv_date }' TIME = '{ lv_time }' DURATION = '11 ' NUMBER_OF_ROWS = 12 |
                        && |OBJECT = `OBJECT` STATEMENT_WITH_VALUES = `STATEMENT_WITH_VALUES` |
                        && |ARRAY_SIZE = 12 TRANSACTION = 'TRANSACTION' PROGRAM = 'PROGRAM' DB_CONNECTION_NAME = |
                        && |'DB_CONNECTION_NAME' DB_CONNECTION_ID = 'DB_CON_ID' OPERATION = 'OPERATI' RETURN_CODE |
                        && |= 13 WP_ID = '001' WP_TYPE = 'DIA' USER_NAME = 'USER_NAME' CLIENT = '100' TRANS_ID = |
                        && |'TRANS_ID' EPP_ROOT_ID = 'EPP_ROOT_ID' EPP_CONNECTION_ID = 'EPP_CONNECTION_ID' |
                        && |EPP_CONNECTION_COUNTER = 14 RECORD_NUMBER = 15 RECORD_NUMBERS = VALUE #( ( 16 ) |
                        && |( 17 ) ) OFFSET = 18 STATEMENT_WITH_NAMES = `STATEMENT_WITH_NAMES` LENGTH_OF_STATEMENT_WITH_NAMES |
                        && |= 19 VARIABLES = `VARIABLES` NUMBER_OF_VARIABLES = 20 TRACE_TYPE = 'TRAC' LINE_COLOR = 'LINE' ) ).|.
    cl_abap_unit_assert=>assert_equals( exp = output_exp
                                        act = output ).
  ENDMETHOD.


  METHOD ris_t_metadata.
    " Keep the legacy metadata shape local: SAP changed RIS_T_METADATA
    " between releases, while this test exercises nested table rendering.
    TYPES: BEGIN OF ty_screen_group,
             name         TYPE c LENGTH 30,
             parent_group TYPE c LENGTH 30,
             text_ref     TYPE string,
           END OF ty_screen_group,
           ty_screen_groups TYPE STANDARD TABLE OF ty_screen_group WITH EMPTY KEY,
           BEGIN OF ty_screen_element,
             index     TYPE i,
             name      TYPE c LENGTH 30,
             type      TYPE c LENGTH 2,
             group     TYPE c LENGTH 30,
             line      TYPE i,
             for       TYPE c LENGTH 30,
             rb_group  TYPE c LENGTH 30,
             label_for TYPE c LENGTH 30,
             label_ref TYPE string,
           END OF ty_screen_element,
           ty_screen_elements TYPE STANDARD TABLE OF ty_screen_element WITH EMPTY KEY,
           BEGIN OF ty_relationship,
             trobjtype   TYPE c LENGTH 4,
             subtype     TYPE c LENGTH 4,
             legacy_type TYPE c LENGTH 3,
             group       TYPE i,
           END OF ty_relationship,
           ty_relationships TYPE STANDARD TABLE OF ty_relationship WITH EMPTY KEY,
           BEGIN OF ty_metadata,
             trobjtype             TYPE c LENGTH 4,
             subtype               TYPE c LENGTH 4,
             legacy_type           TYPE c LENGTH 3,
             search_groups         TYPE ty_screen_groups,
             search_elements       TYPE ty_screen_elements,
             where_used            TYPE ty_relationships,
             environment           TYPE ty_relationships,
             model_implementations TYPE string_table,
           END OF ty_metadata,
           ty_metadata_table TYPE STANDARD TABLE OF ty_metadata WITH EMPTY KEY.

    DATA(table) = VALUE ty_metadata_table(
      ( trobjtype                  = '????'
        subtype                    = ''
        legacy_type                = 'DWY'
        search_groups              = VALUE ty_screen_groups(
                                          ( name         = 'STANDARD'
                                            parent_group = ''
                                            text_ref     = 'TEXT-S01' )
                                          ( name         = 'EINSTELLUNG'
                                            parent_group = ''
                                            text_ref     = '' ) )
        search_elements            = VALUE ty_screen_elements(
                                          ( index     = 1
                                            name      = 'KEY1'
                                            type      = 'SO'
                                            group     = 'STANDARD'
                                            line      = 0
                                            for       = 'SDOKMEP-PROP_NAME'
                                            rb_group  = ''
                                            label_for = ''
                                            label_ref = '' )
                                          ( index     = 2
                                            name      = 'XTEXT'
                                            type      = 'SO'
                                            group     = 'STANDARD'
                                            line      = 0
                                            for       = 'SDOKMET-DESCRIPT'
                                            rb_group  = ''
                                            label_for = ''
                                            label_ref = '' ) )
        where_used                 = VALUE ty_relationships(
                                          ( trobjtype   = 'ECTC'
                                            subtype     = ''
                                            legacy_type = 'GC'
                                            group       = 1 )
                                          ( trobjtype   = 'ECTC'
                                            subtype     = ''
                                            legacy_type = 'GW'
                                            group       = 1 ) )
        environment                = VALUE ty_relationships(
                                          ( trobjtype   = 'FUNC'
                                            subtype     = ''
                                            legacy_type = 'FF'
                                            group       = 1 )
                                          ( trobjtype   = 'DIAL'
                                            subtype     = ''
                                            legacy_type = 'A'
                                            group       = 1 ) )
        model_implementations      = VALUE string_table( )
)
      ( trobjtype                  = '????'
        subtype                    = ''
        legacy_type                = 'GP'
        search_groups              = VALUE ty_screen_groups(
                                          ( name         = 'STANDARD'
                                            parent_group = ''
                                            text_ref     = 'TEXT-S01' )
                                          ( name         = 'EINSTELLUNG'
                                            parent_group = ''
                                            text_ref     = '' ) )
        search_elements            = VALUE ty_screen_elements(
                                          ( index     = 1
                                            name      = 'KEY1'
                                            type      = 'SO'
                                            group     = 'STANDARD'
                                            line      = 0
                                            for       = 'SDOKMEP-PROP_NAME'
                                            rb_group  = ''
                                            label_for = ''
                                            label_ref = '' )
                                          ( index     = 2
                                            name      = 'XTEXT'
                                            type      = 'SO'
                                            group     = 'STANDARD'
                                            line      = 0
                                            for       = 'SDOKMET-DESCRIPT'
                                            rb_group  = ''
                                            label_for = ''
                                            label_ref = '' ) )
        where_used                 = VALUE ty_relationships(
                                          ( trobjtype   = 'ECTC'
                                            subtype     = ''
                                            legacy_type = 'GC'
                                            group       = 1 )
                                          ( trobjtype   = 'ECTC'
                                            subtype     = ''
                                            legacy_type = 'GW'
                                            group       = 1 ) )
        environment                = VALUE ty_relationships(
                                          ( trobjtype   = 'FUNC'
                                            subtype     = ''
                                            legacy_type = 'FF'
                                            group       = 1 )
                                          ( trobjtype   = 'DIAL'
                                            subtype     = ''
                                            legacy_type = 'A'
                                            group       = 1 ) )
        model_implementations      = VALUE string_table( )

) ).

    DATA(output) = table_view->prepare_output( i_table       = table
                                               i_table_title = 'TABLE' ).

    DATA(output_exp) = |TABLE = VALUE #( ( TROBJTYPE = '????' LEGACY_TYPE = 'DWY' SEARCH_GROUPS|
                        && | = VALUE #( ( NAME = 'STANDARD' TEXT_REF = `TEXT-S01` ) ( NAME = 'EINSTELLUNG' ) ) |
                        && |SEARCH_ELEMENTS = VALUE #( ( INDEX = 1 NAME = 'KEY1' TYPE = 'SO' GROUP = 'STANDARD' |
                        && |FOR = 'SDOKMEP-PROP_NAME' ) ( INDEX = 2 NAME = 'XTEXT' TYPE = 'SO' GROUP = 'STANDARD' |
                        && |FOR = 'SDOKMET-DESCRIPT' ) ) WHERE_USED = VALUE #( ( TROBJTYPE = 'ECTC' LEGACY_TYPE = 'GC' GROUP = 1 ) |
                        && |( TROBJTYPE = 'ECTC' LEGACY_TYPE = 'GW' GROUP = 1 ) ) ENVIRONMENT = VALUE #( ( TROBJTYPE = 'FUNC' LEGACY_TYPE = 'FF' GROUP = 1 ) |
                        && |( TROBJTYPE = 'DIAL' LEGACY_TYPE = 'A' GROUP = 1 ) ) ) ( TROBJTYPE = '????' LEGACY_TYPE = 'GP' |
                        && |SEARCH_GROUPS = VALUE #( ( NAME = 'STANDARD' TEXT_REF = `TEXT-S01` ) ( NAME = 'EINSTELLUNG' ) ) |
                        && |SEARCH_ELEMENTS = VALUE #( ( INDEX = 1 NAME = 'KEY1' TYPE = 'SO' GROUP = 'STANDARD' FOR = 'SDOKMEP-PROP_NAME' ) |
                        && |( INDEX = 2 NAME = 'XTEXT' TYPE = 'SO' GROUP = 'STANDARD' FOR = 'SDOKMET-DESCRIPT' ) ) |
                        && |WHERE_USED = VALUE #( ( TROBJTYPE = 'ECTC' LEGACY_TYPE = 'GC' GROUP = 1 ) |
                        && |( TROBJTYPE = 'ECTC' LEGACY_TYPE = 'GW' GROUP = 1 ) ) ENVIRONMENT = VALUE #( |
                        && |( TROBJTYPE = 'FUNC' LEGACY_TYPE = 'FF' GROUP = 1 ) ( TROBJTYPE = 'DIAL' LEGACY_TYPE = 'A' GROUP = 1 ) ) ) ).|.
    cl_abap_unit_assert=>assert_equals( EXPORTING  act = output
                                                   exp = output_exp ).

  ENDMETHOD.


  METHOD detect_clone_by_index_column.
    " given - the debugger ALV clone carries a technical INDEX column
    TYPES: BEGIN OF ty_clone_line,
             index  TYPE char10,
             carrid TYPE s_carr_id,
           END OF ty_clone_line.
    DATA clone_table TYPE STANDARD TABLE OF ty_clone_line WITH EMPTY KEY.

    " when / then
    cl_abap_unit_assert=>assert_equals( act = table_view->table_has_index_component( clone_table )
                                        exp = abap_true
                                        msg = 'Clone with INDEX column must be detected' ).
  ENDMETHOD.

  METHOD not_mistake_real_for_clone.
    " given - a table whose line type has no INDEX component
    TYPES: BEGIN OF ty_real_line,
             carrid TYPE s_carr_id,
             connid TYPE s_conn_id,
           END OF ty_real_line.
    DATA real_table TYPE STANDARD TABLE OF ty_real_line WITH EMPTY KEY.

    " when / then
    cl_abap_unit_assert=>assert_equals( act = table_view->table_has_index_component( real_table )
                                        exp = abap_false
                                        msg = 'Table without INDEX column is no clone' ).
  ENDMETHOD.

  METHOD extract_indexes_in_alv_order.
    " given - clone rows after ALV sorting/filtering: the INDEX column holds
    "         the original row numbers, the display order must be kept
    TYPES: BEGIN OF ty_clone_line,
             index  TYPE char10,
             carrid TYPE s_carr_id,
           END OF ty_clone_line.
    DATA clone_table TYPE STANDARD TABLE OF ty_clone_line WITH EMPTY KEY.
    clone_table = VALUE #( ( index = '3' carrid = 'UA' )
                           ( index = '1' carrid = 'AA' ) ).

    " when / then
    cl_abap_unit_assert=>assert_equals( act = table_view->extract_row_indexes( clone_table )
                                        exp = VALUE zcl_ddve_table=>ty_row_indexes( ( 3 ) ( 1 ) )
                                        msg = 'INDEX values must be extracted in display order' ).
  ENDMETHOD.

  METHOD pick_rows_in_alv_order.
    " given - the real table is sorted (primary order = key order); the
    "         requested order corresponds to the ALV display order
    TYPES: BEGIN OF ty_real_line,
             carrid TYPE s_carr_id,
             price  TYPE s_price,
           END OF ty_real_line,
           tt_real TYPE SORTED TABLE OF ty_real_line WITH UNIQUE KEY carrid.
    DATA(real_table) = VALUE tt_real( ( carrid = 'AA' price = 100 )
                                      ( carrid = 'LH' price = 200 )
                                      ( carrid = 'UA' price = 300 ) ).

    " when
    DATA(picked_ref) = table_view->pick_rows_by_index(
                           i_table       = real_table
                           i_row_indexes = VALUE zcl_ddve_table=>ty_row_indexes( ( 3 ) ( 1 ) ) ).

    " then
    cl_abap_unit_assert=>assert_bound( act = picked_ref
                                       msg = 'Picked table container must be bound' ).

    FIELD-SYMBOLS <picked_table> TYPE STANDARD TABLE.
    ASSIGN picked_ref->* TO <picked_table>.
    cl_abap_unit_assert=>assert_equals( act = lines( <picked_table> )
                                        exp = 2
                                        msg = 'Exactly the requested rows must be picked' ).

    READ TABLE <picked_table> INDEX 1 ASSIGNING FIELD-SYMBOL(<first_row>).
    ASSIGN COMPONENT 'CARRID' OF STRUCTURE <first_row> TO FIELD-SYMBOL(<carrid>).
    cl_abap_unit_assert=>assert_equals( act = <carrid>
                                        exp = 'UA'
                                        msg = 'Row 3 of the source must come first (ALV order)' ).
  ENDMETHOD.

  METHOD carry_no_out_from_alv_catalog.
    " given
    DATA(real_catalog) = VALUE lvc_t_fcat( ( fieldname = 'CARRID' )
                                           ( fieldname = 'CONNID' )
                                           ( fieldname = 'PRICE' ) ).
    DATA(alv_catalog)  = VALUE lvc_t_fcat( ( fieldname = 'CARRID' no_out = abap_true )
                                           ( fieldname = 'CONNID' no_out = abap_false ) ).

    " when
    DATA(result) = table_view->carry_no_out( i_real_catalog = real_catalog
                                             i_alv_catalog  = alv_catalog ).

    " then - CARRID hidden, CONNID visible, PRICE (not in ALV catalog) untouched
    cl_abap_unit_assert=>assert_equals( act = result
                                        exp = VALUE lvc_t_fcat( ( fieldname = 'CARRID' no_out = abap_true )
                                                                ( fieldname = 'CONNID' )
                                                                ( fieldname = 'PRICE' ) )
                                        msg = 'no_out flags must be carried over by fieldname' ).
  ENDMETHOD.

  METHOD keep_real_table_untouched.
    " given - services menu path: the given table IS the real one (no INDEX
    "         column), so no TPDA re-read must happen at all
    TYPES: BEGIN OF ty_real_line,
             carrid TYPE s_carr_id,
           END OF ty_real_line.
    DATA real_table TYPE STANDARD TABLE OF ty_real_line WITH EMPTY KEY.
    real_table = VALUE #( ( carrid = 'AA' ) ).

    " when
    table_view->replace_clone_by_real_data( EXPORTING i_table        = real_table
                                                      i_fieldcatalog = VALUE #( )
                                                      i_table_title  = 'REAL_TABLE'
                                            IMPORTING e_table_ref    = DATA(table_ref)
                                                      e_fieldcatalog = DATA(fieldcatalog) ).

    " then - unbound result: caller keeps table and catalog unchanged
    cl_abap_unit_assert=>assert_not_bound( act = table_ref
                                           msg = 'Real table must be kept unchanged' ).
    cl_abap_unit_assert=>assert_initial( act = fieldcatalog
                                         msg = 'No replacement catalog for a real table' ).
  ENDMETHOD.

ENDCLASS.
