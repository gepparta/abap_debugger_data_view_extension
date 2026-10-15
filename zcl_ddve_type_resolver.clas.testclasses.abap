*"* use this source file for your ABAP unit test classes
CLASS ltc_type_resolver_should DEFINITION DEFERRED.
CLASS zcl_ddve_type_resolver DEFINITION LOCAL FRIENDS ltc_type_resolver_should.

CLASS ltc_type_resolver_should DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zcl_ddve_type_resolver.

    METHODS setup.

    "       |----- max. 30 Zeichen ------|
    METHODS resolve_ddic_type             FOR TESTING RAISING cx_static_check.
    METHODS resolve_plain_name            FOR TESTING RAISING cx_static_check.
    METHODS resolve_global_class_type     FOR TESTING RAISING cx_static_check.
    METHODS resolve_interface_type        FOR TESTING RAISING cx_static_check.
    METHODS resolve_report_local_type     FOR TESTING RAISING cx_static_check.
    METHODS resolve_class_pool_type       FOR TESTING RAISING cx_static_check.
    METHODS resolve_local_class_type      FOR TESTING RAISING cx_static_check.
    METHODS resolve_type_pool_type        FOR TESTING RAISING cx_static_check.
    METHODS reject_method_local_type      FOR TESTING RAISING cx_static_check.
    METHODS reject_form_local_type        FOR TESTING RAISING cx_static_check.
    METHODS reject_generated_type         FOR TESTING RAISING cx_static_check.
    METHODS reject_empty_input            FOR TESTING RAISING cx_static_check.
    METHODS derive_name_from_field_symbol FOR TESTING RAISING cx_static_check.
    METHODS derive_name_from_header_tab   FOR TESTING RAISING cx_static_check.
    METHODS keep_valid_name_unchanged     FOR TESTING RAISING cx_static_check.
    METHODS reject_component_path_as_name FOR TESTING RAISING cx_static_check.
ENDCLASS.


CLASS ltc_type_resolver_should IMPLEMENTATION.
  METHOD setup.
    cut = NEW #( ).
  ENDMETHOD.

  METHOD resolve_ddic_type.
    cl_abap_unit_assert=>assert_equals( act = cut->resolve( '\TYPE=SFLIGHT' )
                                        exp = `SFLIGHT`
                                        msg = 'DDIC-Typ muss direkt verwendbar sein' ).
  ENDMETHOD.

  METHOD resolve_plain_name.
    cl_abap_unit_assert=>assert_equals( act = cut->resolve( 'SFLIGHT' )
                                        exp = `SFLIGHT`
                                        msg = 'Name ohne Pfad muss direkt verwendbar sein' ).
  ENDMETHOD.

  METHOD resolve_global_class_type.
    cl_abap_unit_assert=>assert_equals( act = cut->resolve( '\CLASS=ZCL_ORDER\TYPE=TY_ITEM' )
                                        exp = `ZCL_ORDER=>TY_ITEM`
                                        msg = 'Klassentyp muss ueber => adressiert werden' ).
  ENDMETHOD.

  METHOD resolve_interface_type.
    cl_abap_unit_assert=>assert_equals( act = cut->resolve( '\INTERFACE=ZIF_ORDER\TYPE=TY_ITEM' )
                                        exp = `ZIF_ORDER=>TY_ITEM`
                                        msg = 'Interfacetyp muss ueber => adressiert werden' ).
  ENDMETHOD.

  METHOD resolve_report_local_type.
    cl_abap_unit_assert=>assert_equals( act = cut->resolve( '\PROGRAM=Z_DEMO\TYPE=MY_ITAB_TYPE' )
                                        exp = `MY_ITAB_TYPE`
                                        msg = 'Reportlokaler Typ muss nackt verwendbar sein' ).
  ENDMETHOD.

  METHOD resolve_class_pool_type.
    cl_abap_unit_assert=>assert_equals( act = cut->resolve( '\CLASS-POOL=ZCL_ORDER\TYPE=TY_LOCAL' )
                                        exp = `TY_LOCAL`
                                        msg = 'Class-Pool-lokaler Typ muss nackt verwendbar sein' ).
  ENDMETHOD.

  METHOD resolve_local_class_type.
    cl_abap_unit_assert=>assert_equals( act = cut->resolve( '\PROGRAM=Z_DEMO\CLASS=LCL_HELPER\TYPE=TY_X' )
                                        exp = `LCL_HELPER=>TY_X`
                                        msg = 'Typ einer lokalen Klasse muss ueber => adressiert werden' ).
  ENDMETHOD.

  METHOD resolve_type_pool_type.
    cl_abap_unit_assert=>assert_equals( act = cut->resolve( '\TYPE-POOL=ABAP\TYPE=ABAP_BOOL' )
                                        exp = `ABAP_BOOL`
                                        msg = 'Type-Pool-Typ muss nackt verwendbar sein' ).
  ENDMETHOD.

  METHOD reject_method_local_type.
    cl_abap_unit_assert=>assert_initial( act = cut->resolve( '\CLASS=ZCL_ORDER\METHOD=PROCESS\TYPE=TY_X' )
                                         msg = 'Methodenlokaler Typ ist nicht adressierbar' ).
  ENDMETHOD.

  METHOD reject_form_local_type.
    cl_abap_unit_assert=>assert_initial( act = cut->resolve( '\PROGRAM=Z_DEMO\FORM=DO_IT\TYPE=TY_X' )
                                         msg = 'FORM-lokaler Typ ist nicht adressierbar' ).
  ENDMETHOD.

  METHOD reject_generated_type.
    cl_abap_unit_assert=>assert_initial( act = cut->resolve( '\TYPE=%_T00004S00000000O0000012345' )
                                         msg = 'Generierter Typname ist im Quelltext nicht gueltig' ).
  ENDMETHOD.

  METHOD reject_empty_input.
    cl_abap_unit_assert=>assert_initial( act = cut->resolve( `` )
                                         msg = 'Leere Eingabe darf keinen Typ liefern' ).
  ENDMETHOD.

  METHOD derive_name_from_field_symbol.
    cl_abap_unit_assert=>assert_equals( act = cut->derive_variable_name( '<TABLE_4>' )
                                        exp = `TABLE_4`
                                        msg = 'Spitzklammern muessen entfernt werden' ).
  ENDMETHOD.

  METHOD derive_name_from_header_tab.
    cl_abap_unit_assert=>assert_equals( act = cut->derive_variable_name( 'FLIGHTS[]' )
                                        exp = `FLIGHTS`
                                        msg = 'Body-Klammern [] muessen entfernt werden' ).
  ENDMETHOD.

  METHOD keep_valid_name_unchanged.
    cl_abap_unit_assert=>assert_equals( act = cut->derive_variable_name( 'LT_FLIGHTS' )
                                        exp = `LT_FLIGHTS`
                                        msg = 'Gueltiger Name muss unveraendert bleiben' ).
  ENDMETHOD.

  METHOD reject_component_path_as_name.
    cl_abap_unit_assert=>assert_initial( act = cut->derive_variable_name( 'LS_FLIGHT-PRICE' )
                                         msg = 'Komponentenpfad ist kein gueltiger Variablenname' ).
  ENDMETHOD.
ENDCLASS.
