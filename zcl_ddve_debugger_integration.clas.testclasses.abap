*"* use this source file for your ABAP unit test classes
CLASS ltc_dbg_integration_should DEFINITION DEFERRED.
CLASS zcl_ddve_debugger_integration DEFINITION LOCAL FRIENDS ltc_dbg_integration_should.

CLASS ltc_dbg_integration_should DEFINITION FINAL FOR TESTING
  DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zcl_ddve_debugger_integration.

    METHODS: setup,
             "       |----- max. 30 Zeichen ------|
             get_comps_of_anonymous_type   FOR TESTING RAISING cx_static_check,
             get_comps_only_of_top_level   FOR TESTING RAISING cx_static_check,
             get_no_comps_from_invalid_xml FOR TESTING RAISING cx_static_check,
             create_std_table_for_line     FOR TESTING RAISING cx_static_check,
             fill_handle_table_from_xml    FOR TESTING RAISING cx_static_check.
ENDCLASS.


CLASS ltc_dbg_integration_should IMPLEMENTATION.
  METHOD setup.
    cut = NEW #( ).
  ENDMETHOD.

  METHOD get_comps_of_anonymous_type.
    " given - real asXML of the OCCURS header line <STRUCTURE_1> from the
    "         demo report (anonymous object-bound type as escaped root node)
    DATA(xml) = `<asx:abap version="1.0" xmlns:asx="http://www.sap.com/abapxml"><asx:values>`
             && `<_--5CTYPE_--3D_--25_T00004S00000000O0000032208><CARRID/><CONNID>0000</CONNID>`
             && `<FLDATE>0000-00-00</FLDATE></_--5CTYPE_--3D_--25_T00004S00000000O0000032208>`
             && `</asx:values></asx:abap>`.

    " when
    DATA(component_names) = cut->get_component_names_from_xml( xml ).

    " then
    cl_abap_unit_assert=>assert_equals( act = component_names
                                        exp = VALUE string_table( ( `CARRID` )
                                                                  ( `CONNID` )
                                                                  ( `FLDATE` ) )
                                        msg = 'Component names of anonymous type were not extracted' ).
  ENDMETHOD.

  METHOD get_comps_only_of_top_level.
    " given - nested component COL2: only its name must be returned,
    "         not the names of its sub-components
    DATA(xml) = `<asx:abap version="1.0" xmlns:asx="http://www.sap.com/abapxml"><asx:values>`
             && `<SFLIGHT><MANDT>100</MANDT><COL2><INNER1>1</INNER1><INNER2>2</INNER2></COL2>`
             && `<CARRID>AA</CARRID></SFLIGHT>`
             && `</asx:values></asx:abap>`.

    " when
    DATA(component_names) = cut->get_component_names_from_xml( xml ).

    " then
    cl_abap_unit_assert=>assert_equals( act = component_names
                                        exp = VALUE string_table( ( `MANDT` )
                                                                  ( `COL2` )
                                                                  ( `CARRID` ) )
                                        msg = 'Only top-level component names must be extracted' ).
  ENDMETHOD.

  METHOD get_no_comps_from_invalid_xml.
    " given
    DATA(xml) = `this is no xml at all`.

    " when
    DATA(component_names) = cut->get_component_names_from_xml( xml ).

    " then
    cl_abap_unit_assert=>assert_initial( act = component_names
                                         msg = 'Invalid XML must yield no component names' ).
  ENDMETHOD.

  METHOD create_std_table_for_line.
    " given - a named line type; only the table type itself is anonymous
    "         in the TODO #8 scenario (inline declared sorted/hashed tables)
    DATA(line_descr) = CAST cl_abap_datadescr( cl_abap_typedescr=>describe_by_name( 'SFLIGHT' ) ).

    " when
    DATA(table_ref) = cut->create_table_for_line( line_descr ).

    " then - a standard table over the line type is a sufficient container,
    "        keys are irrelevant for rendering
    DATA(table_descr) = CAST cl_abap_tabledescr( cl_abap_typedescr=>describe_by_data_ref( table_ref ) ).
    cl_abap_unit_assert=>assert_equals( act = table_descr->table_kind
                                        exp = cl_abap_tabledescr=>tablekind_std
                                        msg = 'Container must be a standard table' ).
    cl_abap_unit_assert=>assert_equals( act = table_descr->get_table_line_type( )->absolute_name
                                        exp = '\TYPE=SFLIGHT'
                                        msg = 'Line type of the container is wrong' ).
  ENDMETHOD.

  METHOD fill_handle_table_from_xml.
    " given - asXML of a table variable (TODO #8: anonymous sorted table) and
    "         an empty container built over its line type via TYPE HANDLE
    DATA(xml) = `<asx:abap version="1.0" xmlns:asx="http://www.sap.com/abapxml"><asx:values>`
             && `<FLIGHTS_SORTED><item><CARRID>AA</CARRID><CONNID>0017</CONNID></item>`
             && `<item><CARRID>LH</CARRID><CONNID>0400</CONNID></item></FLIGHTS_SORTED>`
             && `</asx:values></asx:abap>`.

    DATA(line_descr) = cl_abap_structdescr=>create( VALUE #(
        ( name = 'CARRID' type = cl_abap_elemdescr=>get_c( 3 ) )
        ( name = 'CONNID' type = cl_abap_elemdescr=>get_c( 4 ) ) ) ).

    DATA(empty_table_ref) = cut->create_table_for_line( line_descr ).

    " when
    DATA(filled_table_ref) = cut->fill_empty_data_from_xml(
                                 i_xml                      = xml
                                 i_empty_data_structure_ref = empty_table_ref ).

    " then
    FIELD-SYMBOLS <flights> TYPE STANDARD TABLE.
    ASSIGN filled_table_ref->* TO <flights>.
    cl_abap_unit_assert=>assert_equals( act = lines( <flights> )
                                        exp = 2
                                        msg = 'Both rows must be filled from the asXML' ).

    READ TABLE <flights> INDEX 1 ASSIGNING FIELD-SYMBOL(<first_row>).
    ASSIGN COMPONENT 'CARRID' OF STRUCTURE <first_row> TO FIELD-SYMBOL(<carrid>).
    cl_abap_unit_assert=>assert_equals( act = <carrid>
                                        exp = 'AA'
                                        msg = 'First row must contain the first asXML item' ).
  ENDMETHOD.
ENDCLASS.
