*&---------------------------------------------------------------------*
*& Report z_debugger_data_view_ext_demo
*&---------------------------------------------------------------------*
*&
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

" for obsolete tables with header

flights_with_header[] = VALUE #( connid = '0017'
                                 ( carrid = 'AA' fldate = '20141217' )
                                 ( carrid = 'AB' fldate = '20150225' )
                                 ( carrid = 'AC' fldate = '20150225' ) ).

ASSIGN flights_with_header[] TO <table_1>.
ASSIGN flights_with_header TO <structure_1>.

" for table enhancement

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

" for testing structure enhancement
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

" nested examples
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

ASSIGN nested_struc TO <structure_4>.
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

IF 1 = 2.
ENDIF.
