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
             get_no_comps_from_invalid_xml FOR TESTING RAISING cx_static_check.
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
ENDCLASS.
