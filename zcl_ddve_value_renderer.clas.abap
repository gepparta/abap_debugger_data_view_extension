"! Renders internal tables and structures as ABAP VALUE #( ... ) expressions.
"! Owns the mutual recursion between table and structure rendering, so that
"! ZCL_DDVE_TABLE and ZCL_DDVE_STRUCTURE do not need to depend on each other.
CLASS zcl_ddve_value_renderer DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS:
      constructor,

      "! render an internal table as [name = ]VALUE #( ( ... ) ... )[.]
      "! @parameter i_table_title      | variable name for "name = VALUE #()" statement
      "! @parameter i_current_context  | already rendered context the table is appended to
      "! @parameter i_table            | any internal table
      "! @parameter i_component_name   | component name when the table is a component of a structure
      "! @parameter i_fieldcatalog     | field catalog; derived from i_table when omitted
      "! @parameter i_dont_add_a_point | suppress the trailing point (for nested rendering)
      "! @parameter i_type_name        | type expression for the outermost VALUE; when supplied
      "!                                 the statement is rendered as DATA(name) = VALUE typ( )
      "! @parameter r_current_context  | changed context with added table data as string
      render_itab
        IMPORTING i_table_title            TYPE string     OPTIONAL
                  i_current_context        TYPE string
                  i_table                  TYPE ANY TABLE
                  i_component_name         TYPE lvc_fname  OPTIONAL
                  i_fieldcatalog           TYPE lvc_t_fcat OPTIONAL
                  i_dont_add_a_point       TYPE boole_d    OPTIONAL
                  i_type_name              TYPE string     OPTIONAL
        RETURNING VALUE(r_current_context) TYPE string,

      "! render a structure as its right hand side " = VALUE #( COMP = ... )"
      "! @parameter i_structure       | given structure
      "! @parameter i_field_catalog   | field catalog of structure
      "! @parameter i_type_name       | type expression for the outermost VALUE; # when empty
      "! @parameter r_current_context | rendered right hand side as string
      render_structure_rhs
        IMPORTING i_structure              TYPE any
                  i_field_catalog          TYPE lvc_t_fcat
                  i_type_name              TYPE string OPTIONAL
        RETURNING VALUE(r_current_context) TYPE string.

  PRIVATE SECTION.
    DATA simple_field_catalog TYPE REF TO zcl_ddve_simple_field_catalog.
    DATA component            TYPE REF TO zcl_ddve_component.

    METHODS:
      " ---- table rendering -------------------------------------------------
      resolve_field_catalog
        IMPORTING i_fieldcatalog         TYPE lvc_t_fcat
                  i_table                TYPE ANY TABLE
        RETURNING VALUE(r_field_catalog) TYPE lvc_t_fcat,

      render_line
        IMPORTING i_table_line          TYPE any
                  i_field_catalog       TYPE lvc_t_fcat
        RETURNING VALUE(r_line_context) TYPE string,

      resolve_cell_value
        IMPORTING i_cell         TYPE any
                  i_field_info   TYPE lvc_s_fcat
        RETURNING VALUE(r_value) TYPE tpda_var_value,

      is_elementary_line_type
        IMPORTING i_field_catalog        TYPE lvc_t_fcat
        RETURNING VALUE(r_is_elementary) TYPE abap_bool,

      add_prefix
        IMPORTING i_tabix                  TYPE i
                  i_current_context        TYPE string
                  i_table_title            TYPE string    OPTIONAL
                  i_component_name         TYPE lvc_fname OPTIONAL
                  i_type_name              TYPE string    OPTIONAL
        RETURNING VALUE(r_current_context) TYPE string,

      append_line_context
        IMPORTING i_current_context        TYPE string
                  i_line_context           TYPE string
        RETURNING VALUE(r_current_context) TYPE string,

      add_closing
        IMPORTING i_current_context        TYPE string
                  i_dont_add_a_point       TYPE boole_d
        RETURNING VALUE(r_current_context) TYPE string,

      add_error_marker
        IMPORTING i_current_context        TYPE string
                  i_error                  TYPE REF TO cx_root
        RETURNING VALUE(r_current_context) TYPE string,

      " ---- structure rendering ---------------------------------------------
      right_hand_side
        IMPORTING i_type_name                    TYPE string OPTIONAL
                  i_structure                    TYPE any
                  i_field_catalog                TYPE lvc_t_fcat
        RETURNING VALUE(r_right_hand_side_value) TYPE string,

      add_rhs_value_prefix
        IMPORTING i_type_name                    TYPE string
        RETURNING VALUE(r_right_hand_side_value) TYPE string,

      add_rhs_postfix
        IMPORTING i_right_hand_side_value        TYPE string
        RETURNING VALUE(r_right_hand_side_value) TYPE string,

      add_rhs_value
        IMPORTING i_right_hand_side_value        TYPE string
                  i_structure                    TYPE any
                  i_field_catalog                TYPE lvc_t_fcat
        RETURNING VALUE(r_right_hand_side_value) TYPE string,

      add_rhs_value_and_postfix
        IMPORTING i_right_hand_side_value        TYPE string
                  i_structure                    TYPE any
                  i_field_catalog                TYPE lvc_t_fcat
        RETURNING VALUE(r_right_hand_side_value) TYPE string,

      handle_nested_structure
        IMPORTING i_current_context        TYPE string
                  i_structure              TYPE any
                  i_component_info         TYPE lvc_s_fcat
        RETURNING VALUE(r_current_context) TYPE string,

      render_itab_component
        IMPORTING i_current_context        TYPE string
                  i_table                  TYPE ANY TABLE
                  i_component_name         TYPE lvc_fname
        RETURNING VALUE(r_current_context) TYPE string,

      component_name
        IMPORTING i_component_name        TYPE lvc_fname
        RETURNING VALUE(r_component_name) TYPE lvc_fname.
ENDCLASS.


CLASS zcl_ddve_value_renderer IMPLEMENTATION.
  METHOD constructor.
    simple_field_catalog = NEW #( ).
    component            = NEW #( ).
  ENDMETHOD.

  METHOD render_itab.
    " integration only: orchestrates the rendering steps, no own logic
    TRY.
        DATA(field_catalog) = resolve_field_catalog( i_fieldcatalog = i_fieldcatalog
                                                     i_table        = i_table ).

        r_current_context = COND string( WHEN i_current_context IS NOT INITIAL THEN i_current_context ELSE || ).

        DATA(line_num) = 0.
        LOOP AT i_table ASSIGNING FIELD-SYMBOL(<table_line>).
          line_num = line_num + 1.

          r_current_context = add_prefix( i_current_context = r_current_context
                                          i_table_title     = i_table_title
                                          i_component_name  = i_component_name
                                          i_type_name       = i_type_name
                                          i_tabix           = line_num ).

          r_current_context = append_line_context(
                                  i_current_context = r_current_context
                                  i_line_context    = render_line( i_table_line    = <table_line>
                                                                   i_field_catalog = field_catalog ) ).
        ENDLOOP.

        r_current_context = add_closing( i_current_context  = r_current_context
                                         i_dont_add_a_point = i_dont_add_a_point ).

      CATCH cx_root INTO DATA(error).
        r_current_context = add_error_marker( i_current_context = r_current_context
                                              i_error           = error ).
    ENDTRY.
  ENDMETHOD.

  METHOD render_structure_rhs.
    r_current_context = right_hand_side( i_field_catalog = i_field_catalog
                                         i_structure     = i_structure
                                         i_type_name     = i_type_name ).
  ENDMETHOD.

  METHOD resolve_field_catalog.
    r_field_catalog = COND lvc_t_fcat( WHEN i_fieldcatalog[] IS NOT INITIAL
                                       THEN i_fieldcatalog
                                       ELSE simple_field_catalog->get_by_data( i_table = i_table ) ).
  ENDMETHOD.

  METHOD render_line.
    FIELD-SYMBOLS <cell> TYPE any.

    DATA(line_type_is_elementary) = is_elementary_line_type( i_field_catalog ).

    LOOP AT i_field_catalog INTO DATA(field_info)
         WHERE no_out = abap_false.
      IF line_type_is_elementary = abap_true.
        ASSIGN i_table_line TO <cell>.
      ELSE.
        ASSIGN COMPONENT field_info-fieldname OF STRUCTURE i_table_line TO <cell>.
      ENDIF.
      CHECK     <cell> IS ASSIGNED
            AND <cell> IS NOT INITIAL.

      r_line_context = component->add( i_current_context = r_line_context
                                       i_component       = resolve_cell_value( i_cell       = <cell>
                                                                               i_field_info = field_info )
                                       i_component_info  = field_info  ).
    ENDLOOP.
  ENDMETHOD.

  METHOD resolve_cell_value.
    r_value = COND tpda_var_value(
                WHEN i_field_info-datatype = zcl_ddve_abap_typedescr=>table_type THEN
                  render_itab( i_current_context  = space
                               i_table            = i_cell
                               i_dont_add_a_point = abap_true )
                WHEN i_field_info-datatype = zcl_ddve_abap_typedescr=>structure_type THEN
                  render_structure_rhs( i_structure     = i_cell
                                        i_field_catalog = simple_field_catalog->get_by_data(
                                                              i_structure = i_cell ) )
                ELSE
                  i_cell ).  " it must be a component
  ENDMETHOD.

  METHOD is_elementary_line_type.
    " a table with elementary line type (e.g. TABLE OF i) has exactly one
    " field catalog entry without a fieldname
    r_is_elementary = xsdbool(     lines( i_field_catalog ) = 1
                               AND i_field_catalog[ 1 ]-fieldname IS INITIAL ).
  ENDMETHOD.

  METHOD add_prefix.
    r_current_context = COND string( WHEN i_current_context IS NOT INITIAL THEN i_current_context ELSE || ).

    IF i_tabix = 1.
      r_current_context = COND #( WHEN i_table_title <> space AND i_type_name IS NOT INITIAL THEN
                                    |{ r_current_context }DATA({ i_table_title }) = VALUE { i_type_name }(|
                                  WHEN i_table_title <> space THEN
                                    |{ r_current_context }{ i_table_title } = VALUE #(|
                                  WHEN i_component_name IS NOT INITIAL THEN
                                    |{ r_current_context  }{ i_component_name } = VALUE #(|
                                  ELSE
                                    |{ r_current_context }VALUE #(| ).
    ENDIF.
  ENDMETHOD.

  METHOD append_line_context.
    r_current_context = COND #( WHEN i_line_context <> space
                                THEN |{ i_current_context } ({ i_line_context } )|
                                ELSE i_current_context ).
  ENDMETHOD.

  METHOD add_closing.
    r_current_context = COND #( WHEN i_dont_add_a_point = abap_true
                                THEN |{ i_current_context } )|
                                ELSE |{ i_current_context } ).| ).
  ENDMETHOD.

  METHOD add_error_marker.
    " degrade gracefully: never dump inside the debugger session, but make the
    " abort visible in the generated output including the raising position
    i_error->get_source_position( IMPORTING program_name = DATA(program_name)
                                            source_line  = DATA(source_line) ).
    r_current_context = |{ i_current_context } " ! DDVE: Aufbereitung unvollständig - { i_error->get_text( ) } ({ program_name } Zeile { source_line })|.
  ENDMETHOD.

  METHOD right_hand_side.
    r_right_hand_side_value = add_rhs_value_prefix( i_type_name ).

    r_right_hand_side_value = add_rhs_value_and_postfix( i_right_hand_side_value = r_right_hand_side_value
                                                         i_structure             = i_structure
                                                         i_field_catalog         = i_field_catalog   ).
  ENDMETHOD.

  METHOD add_rhs_value_prefix.
    " only the outermost VALUE carries the type; nested ones stay # (type inference)
    r_right_hand_side_value = COND string( WHEN i_type_name IS NOT INITIAL
                                           THEN | = VALUE { i_type_name }(|
                                           ELSE | = VALUE #(| ).
  ENDMETHOD.

  METHOD add_rhs_postfix.
    r_right_hand_side_value = |{ i_right_hand_side_value } )|.
  ENDMETHOD.

  METHOD add_rhs_value.
    DATA current_context TYPE string.

    LOOP AT i_field_catalog INTO DATA(field_info).

      ASSIGN COMPONENT field_info-fieldname OF STRUCTURE i_structure TO FIELD-SYMBOL(<field>).
      CHECK     <field> IS ASSIGNED
            AND <field> IS NOT INITIAL.

      current_context = COND #(
          WHEN field_info-datatype = zcl_ddve_abap_typedescr=>table_type THEN
            render_itab_component( i_current_context = current_context
                                   i_table           = <field>
                                   i_component_name  = field_info-fieldname )
          WHEN field_info-datatype = zcl_ddve_abap_typedescr=>structure_type THEN
            handle_nested_structure( i_current_context = current_context
                                     i_structure       = <field>
                                     i_component_info  = field_info   )
          ELSE
            component->add( i_current_context = current_context
                            i_component       = <field>
                            i_component_info  = field_info  ) ).

    ENDLOOP.

    r_right_hand_side_value = |{ i_right_hand_side_value }{ current_context }|.
  ENDMETHOD.

  METHOD add_rhs_value_and_postfix.
    r_right_hand_side_value = add_rhs_value( i_right_hand_side_value = i_right_hand_side_value
                                             i_field_catalog         = i_field_catalog
                                             i_structure             = i_structure ).
    r_right_hand_side_value = add_rhs_postfix( r_right_hand_side_value ).
  ENDMETHOD.

  METHOD handle_nested_structure.
    r_current_context = right_hand_side(
        i_structure     = i_structure
        i_field_catalog = simple_field_catalog->get_by_data( i_structure = i_structure ) ).

    r_current_context = |{ i_current_context } { component_name( i_component_info-fieldname ) }{ r_current_context }|.
  ENDMETHOD.

  METHOD render_itab_component.
    r_current_context = render_itab( i_current_context  = ||
                                     i_table            = i_table
                                     i_component_name   = i_component_name
                                     i_dont_add_a_point = abap_true   ).
    r_current_context = |{ i_current_context } { r_current_context }|.
  ENDMETHOD.

  METHOD component_name.
    r_component_name = i_component_name.
    CONDENSE r_component_name NO-GAPS.
  ENDMETHOD.
ENDCLASS.
