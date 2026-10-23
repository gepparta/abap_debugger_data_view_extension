"! Component representation for ABAP Debugger Enhancement
"! is responsible for representing components/fields
"! within a -component = 'component value' statement
CLASS zcl_ddve_component DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    "! add a single component or already formatted context
    "! @parameter i_current_context | current context as string
    "! @parameter i_component       | current component
    "! @parameter i_component_info  | field catalog info for this component
    "! @parameter r_current_context | changed context with added component data as string
    METHODS add
      IMPORTING i_current_context        TYPE string
                i_component              TYPE any
                i_component_info         TYPE lvc_s_fcat
      RETURNING VALUE(r_current_context) TYPE string.

  PRIVATE SECTION.
    METHODS component_name IMPORTING i_component_name        TYPE string
                           RETURNING VALUE(r_component_name) TYPE string.

    METHODS format_as_integer
      IMPORTING i_component   TYPE any
      RETURNING VALUE(r_text) TYPE string.

    METHODS format_as_string
      IMPORTING i_component   TYPE any
      RETURNING VALUE(r_text) TYPE string.

    METHODS format_as_char
      IMPORTING i_component   TYPE any
      RETURNING VALUE(r_text) TYPE string.

    METHODS format_as_passthrough
      IMPORTING i_component   TYPE any
      RETURNING VALUE(r_text) TYPE string.
ENDCLASS.


CLASS zcl_ddve_component IMPLEMENTATION.
  METHOD add.
    r_current_context = i_current_context.

    CHECK i_component IS NOT INITIAL.

    DATA(assign_component_value) = SWITCH #( i_component_info-inttype
                                             WHEN zcl_ddve_abap_typedescr=>typekind_int1
                                               OR zcl_ddve_abap_typedescr=>typekind_int2
                                               OR zcl_ddve_abap_typedescr=>typekind_int
                                               OR zcl_ddve_abap_typedescr=>typekind_int8 THEN
                                               format_as_integer( i_component )
                                             WHEN zcl_ddve_abap_typedescr=>typekind_struct1
                                               OR zcl_ddve_abap_typedescr=>typekind_struct2
                                               OR zcl_ddve_abap_typedescr=>typekind_table THEN
                                               format_as_passthrough( i_component )
                                             WHEN zcl_ddve_abap_typedescr=>typekind_string THEN
                                               format_as_string( i_component )
                                             ELSE
                                               format_as_char( i_component ) ).

    IF i_component_info-fieldname IS NOT INITIAL.

      DATA(component_name) = COND string( WHEN i_component_info-seltext <> space
                                           AND i_component_info-seltext <> i_component_info-fieldname
                                          THEN i_component_info-seltext
                                          ELSE i_component_info-fieldname ).

      DATA(new_column_value_combi) = | { me->component_name( component_name )
                                       }{ COND #( WHEN i_component_info-datatype <> zcl_ddve_abap_typedescr=>structure_type THEN | = | )
                                       }{ assign_component_value }|.

      r_current_context = |{ i_current_context }{ new_column_value_combi }|.

    ELSE.

      " Line type of table has NO component (like a table of integers: DATA itab TYPE TABLE OF i)
      r_current_context = | { assign_component_value }|.

    ENDIF.
  ENDMETHOD.

  METHOD component_name.
    r_component_name = i_component_name.
    r_component_name = condense( val  = r_component_name
                                 from = ` `
                                 to   = `` ).
  ENDMETHOD.

  METHOD format_as_integer.
    r_text = condense( |{ i_component }| ).
  ENDMETHOD.

  METHOD format_as_string.
    r_text = |`{ replace( val  = i_component
                          sub  = |`|
                          with = |``|
                          occ  = 0 ) }`|.
  ENDMETHOD.

  METHOD format_as_char.
    r_text = |'{ replace( val  = i_component
                          sub  = |'|
                          with = |''|
                          occ  = 0 ) }'|.
  ENDMETHOD.

  METHOD format_as_passthrough.
    r_text = i_component.
  ENDMETHOD.
ENDCLASS.
