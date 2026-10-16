*&---------------------------------------------------------------------*
*& Report z_debugger_data_view_ext_demo
*&---------------------------------------------------------------------*
*& Place a breakpoint at the end of this report, run it and try the
*& "Data for ABAP View" export on the variables below. Each block
*& demonstrates one capability of the Debugger Data View Extension.
*&---------------------------------------------------------------------*
REPORT z_debugger_data_view_ext_demo.

DATA:
  lt_flights TYPE ty_flights,
  ls_flight  TYPE sflight,
  BEGIN OF flights_with_header OCCURS 0,
    carrid TYPE sflights-carrid, " this table contains
    connid TYPE sflights-connid, " the key information
    fldate TYPE sflights-fldate, " of the hit list
  END OF flights_with_header,
  flights_hashed TYPE HASHED TABLE OF sflight WITH UNIQUE KEY mandt carrid connid fldate.

FIELD-SYMBOLS: <table_1>     TYPE STANDARD TABLE,
               <table_2>     TYPE STANDARD TABLE,
               <table_3>     TYPE HASHED TABLE,
               <table_4>     TYPE ANY TABLE,
               <structure_1> TYPE any,
               <structure_2> TYPE any,
               <structure_3> TYPE any,
               <structure_4> TYPE any.

" for obsolete tables with header: the row type is generated AND
" object-bound (\TYPE=%_T...O...), so DDVE rebuilds the structure type
" from its components (component types like S_CARR_ID are named).
" The header line stays initial (only the body [] is filled), so the
" expected export is the one-liner <STRUCTURE_1> = VALUE #( ).

flights_with_header[] = VALUE #( connid = '0017'
                                 ( carrid = 'AA' fldate = '20141217' )
                                 ( carrid = 'AB' fldate = '20150225' )
                                 ( carrid = 'AC' fldate = '20150225' ) ).

ASSIGN flights_with_header[] TO <table_1>.
ASSIGN flights_with_header TO <structure_1>.

" for table enhancement: DDIC table type -> typed export
" DATA(lt_flights) = VALUE ty_flights( ... )
" TIP: switch to the ALV grid view, filter some rows or hide columns -
" the export respects both (issue #16)

lt_flights = VALUE #( mandt      = '100'
                      carrid     = 'AA'
                      connid     = '0017'
                      price      = '422.94 '
                      currency   = 'USD'
                      planetype  = '747-400'
                      seatsmax   = '385 '
                      seatsmax_b = '31 '
                      seatsmax_f = '21 '
                      ( fldate     = '20141217'
                        seatsocc   = '372 '
                        paymentsum = '192437.84 '
                        seatsocc_b = '28 '
                        seatsocc_f = '21 ' )
                      ( fldate     = '20150225'
                        seatsocc   = '369 '
                        paymentsum = '191490.49 '
                        seatsocc_b = '30 '
                        seatsocc_f = '20 ' )
                      ( fldate     = '20150506'
                        seatsocc   = '374 '
                        paymentsum = '192991.93 '
                        seatsocc_b = '30 '
                        seatsocc_f = '19 ' ) ).

ASSIGN lt_flights TO <table_2>.

" for testing filtered view
INSERT LINES OF lt_flights INTO TABLE flights_hashed.

ASSIGN flights_hashed TO <table_3>.

" for testing structure enhancement: DDIC structure -> typed export
" DATA(ls_flight) = VALUE sflight( ... )
ls_flight = VALUE #( mandt      = '100'
                     carrid     = 'AA'
                     connid     = '0017'
                     fldate     = '20141217'
                     price      = '422.94'
                     currency   = 'USD'
                     planetype  = '747-400'
                     seatsmax   = '385'
                     seatsocc   = '372'
                     paymentsum = '192437.84'
                     seatsmax_b = '31'
                     seatsocc_b = '28'
                     seatsmax_f = '21'
                     seatsocc_f = '21' ).

ASSIGN ls_flight TO <structure_2>.

" nested examples: report-local types -> typed export with bare name
" DATA(nested_struc) = VALUE my_nested_struc_type( ... )
TYPES: BEGIN OF t_col2,
         col1 TYPE i,
         col2 TYPE i,
       END OF t_col2.

TYPES: BEGIN OF t_struct,
         col1 TYPE i,
         col2 TYPE t_col2,
       END OF t_struct.

TYPES: my_itab_type         TYPE STANDARD TABLE OF t_struct WITH DEFAULT KEY,
       my_nested_struc_type TYPE t_struct.

TYPES: BEGIN OF nested_type,
         col1 TYPE i,
         col2 TYPE t_col2,
         col3 TYPE my_itab_type,
       END OF nested_type.

TYPES my_nested_itab_type TYPE STANDARD TABLE OF nested_type WITH DEFAULT KEY.

DATA: nested_itab   TYPE my_nested_itab_type,
      nested_struc  TYPE my_nested_struc_type,
      itab_in_struc TYPE nested_type.

" build structures
nested_struc = VALUE my_nested_struc_type( col1 = 1
                                           col2 = VALUE #( col1 = 1
                                                           col2 = 2 ) ).

ASSIGN nested_struc TO <structure_3>.

itab_in_struc = VALUE nested_type( col1 = 1

                                   col2 = VALUE #( col1 = 11
                                                   col2 = 22 )
                                   col3 = VALUE #( ( col1 = 311
                                                     col2 = VALUE #( col1 = 3121
                                                                     col2 = 3122 ) )
                                                   ( col1 = 321
                                                     col2 = VALUE #( col1 = 3221
                                                                     col2 = 3222 ) ) ) ).

ASSIGN itab_in_struc TO <structure_4>.
" build itab
nested_itab = VALUE my_nested_itab_type( ( col1 = 1
                                           col2 = VALUE #( col1 = 1
                                                           col2 = 2 )
                                           col3 = VALUE #( " start here a nested itab
                                                           ( col1 = 1 )  " first row of it
                                                           ( col2-col2 = 2 ) ) ) ).

ASSIGN nested_itab TO <table_4>.

" do something with structure
DATA(ls_col2) = nested_struc-col2.

" do something with itab
DATA(ls_col1) = nested_itab[ 1 ]-col1.

*--------------------------------------------------------------------*
* additional demo cases
*--------------------------------------------------------------------*

" type declared in a global class -> typed export with class prefix
" DATA(dve_customizing) = VALUE zcl_ddve_pp_customizing=>tt_dve_cust( ... )
DATA dve_customizing TYPE zcl_ddve_pp_customizing=>tt_dve_cust.
dve_customizing = VALUE #( ( user_name = 'DEVELOPER'
                             class_name = 'ZCL_DDVE_VALUE_PRETTY_PRINTER' )
                           ( user_name = 'TESTER'
                             class_name = 'ZCL_DDVE_MAX_LINE_LENGTH_PP' ) ).

" local structure with .INCLUDE - the included components are
" flattened into the field catalog
TYPES BEGIN OF t_client_with_extras.
        INCLUDE TYPE t000.
TYPES   dummy_field_1 TYPE i.
TYPES   dummy_field_2 TYPE string.
TYPES END OF t_client_with_extras.

DATA client_with_extras TYPE t_client_with_extras.
client_with_extras = VALUE #( mandt         = '000'
                              mtext         = 'Demo client'
                              logsys        = 'DUMMY_1'
                              dummy_field_1 = 666
                              dummy_field_2 = `Hello` ).

" literals containing apostrophes - modeled on real T100 message texts;
" the escaping ('') must be preserved in the generated statement
TYPES: BEGIN OF t_message_text,
         arbgb TYPE c LENGTH 20,
         msgnr TYPE n LENGTH 3,
         text  TYPE string,
       END OF t_message_text,
       tt_message_texts TYPE STANDARD TABLE OF t_message_text WITH DEFAULT KEY.

DATA message_texts TYPE tt_message_texts.
message_texts = VALUE #( ( arbgb = 'MDM_ID'
                           msgnr = '001'
                           text  = `The SOBJ object &1 &2 is already used with GUID &3. Don't create twice.` )
                         ( arbgb = 'MODEL'
                           msgnr = '001'
                           text  = `Document model area '&1' does not exist` ) ).

" unstructured table (table of an elementary type)
DATA numbers TYPE STANDARD TABLE OF i WITH EMPTY KEY.
numbers = VALUE #( ( 1 ) ( 2 ) ( 3 ) ).

" empty table and empty structure - the export must stay a one-liner
DATA empty_flights TYPE ty_flights.
DATA empty_flight  TYPE sflight.

" structured type from a type pool -> typed export with bare name
" DATA(callstack) = VALUE abap_callstack( ... )
DATA callstack TYPE abap_callstack.
CALL FUNCTION 'SYSTEM_CALLSTACK'
  IMPORTING
    callstack = callstack.

" sorted table: the inline table type is anonymous (%_T...), so the
" export correctly falls back to FLIGHTS_SORTED = VALUE #( ... )
DATA flights_sorted TYPE SORTED TABLE OF sflight
                    WITH UNIQUE KEY mandt carrid connid fldate.
INSERT LINES OF lt_flights INTO TABLE flights_sorted.

" structure with an int8 component - created dynamically so this report
" still compiles on 7.40 (the built-in type int8 needs a newer release).
" The structure type is anonymous (TYPE HANDLE) - DDVE rebuilds it from
" the components and renders int8 via the shim ZCL_DDVE_ABAP_TYPEDESCR:
" <STRUCTURE_INT8> = VALUE #( ID = 1 BIG_VALUE = 9999999999 ).
DATA int8_container TYPE REF TO data.
FIELD-SYMBOLS <structure_int8> TYPE any.

cl_abap_typedescr=>describe_by_name( EXPORTING  p_name         = 'INT8'
                                     RECEIVING  p_descr_ref    = DATA(int8_descr)
                                     EXCEPTIONS type_not_found = 1
                                                OTHERS         = 2 ).
IF sy-subrc = 0.
  DATA(int8_structdescr) = cl_abap_structdescr=>create(
      VALUE #( ( name = 'ID'        type = cl_abap_elemdescr=>get_i( ) )
               ( name = 'BIG_VALUE' type = CAST cl_abap_elemdescr( int8_descr ) ) ) ).
  CREATE DATA int8_container TYPE HANDLE int8_structdescr.
  ASSIGN int8_container->* TO <structure_int8>.
  ASSIGN COMPONENT 'ID' OF STRUCTURE <structure_int8> TO FIELD-SYMBOL(<id>).
  <id> = 1.
  ASSIGN COMPONENT 'BIG_VALUE' OF STRUCTURE <structure_int8> TO FIELD-SYMBOL(<big_value>).
  <big_value> = 9999999999.
ENDIF.

IF 1 = 2.
ENDIF.
