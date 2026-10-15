"!This class is offering an API for representing a table
"!in its ABAP VALUE way: table_name = VALUE #( (...) )
CLASS zcl_ddve_table DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS: constructor,

      handle_toolbar_set
      FOR EVENT toolbar OF cl_gui_alv_grid
      IMPORTING e_object
                e_interactive,

      show_popup_w_content
        IMPORTING i_table        TYPE ANY TABLE
                  i_fieldcatalog TYPE lvc_t_fcat OPTIONAL
                  i_table_title  TYPE string,

      "! kept for compatibility: delegates to ZCL_DDVE_VALUE_RENDERER->RENDER_ITAB
      add_itab
        IMPORTING i_table_title            TYPE string     OPTIONAL
                  i_current_context        TYPE string
                  i_table                  TYPE ANY TABLE
                  i_component_name         TYPE lvc_fname  OPTIONAL
                  i_fieldcatalog           TYPE lvc_t_fcat OPTIONAL
                  i_dont_add_a_point       TYPE boole_d    OPTIONAL
                  i_type_name              TYPE string     OPTIONAL
        RETURNING VALUE(r_current_context) TYPE string,

      filter_table_from_alv
        IMPORTING i_alv         TYPE REF TO cl_gui_alv_grid OPTIONAL
                  i_table       TYPE ANY TABLE
        RETURNING VALUE(result) TYPE REF TO data.

  PRIVATE SECTION.
    DATA renderer TYPE REF TO zcl_ddve_value_renderer.

    METHODS:
      prepare_output
        IMPORTING i_fieldcatalog             TYPE lvc_t_fcat OPTIONAL
                  i_table                    TYPE ANY TABLE
                  i_table_title              TYPE string
                  i_dont_add_a_point         TYPE boole_d    OPTIONAL
                  i_type_name                TYPE string     OPTIONAL
        RETURNING VALUE(r_content_4_display) TYPE string.
ENDCLASS.


CLASS zcl_ddve_table IMPLEMENTATION.
  METHOD constructor.
    renderer = NEW #( ).
  ENDMETHOD.

  METHOD add_itab.
    r_current_context = renderer->render_itab( i_table_title      = i_table_title
                                               i_current_context  = i_current_context
                                               i_table            = i_table
                                               i_component_name   = i_component_name
                                               i_fieldcatalog     = i_fieldcatalog
                                               i_dont_add_a_point = i_dont_add_a_point
                                               i_type_name        = i_type_name ).
  ENDMETHOD.

  METHOD handle_toolbar_set.
    CHECK NOT line_exists( e_object->mt_toolbar[ function = 'ZDATA_4_ABAP_VIEW' ] ).

    APPEND VALUE stb_button( function  = 'ZDATA_4_ABAP_VIEW'
                             butn_type = 0
                             text      = 'Data for ABAP View' ) TO e_object->mt_toolbar.
  ENDMETHOD.

  METHOD prepare_output.
    " typed form DATA(name) = VALUE typ( ) only when the debugger symbol name
    " can be turned into a valid variable name - otherwise classic name = VALUE #( )
    DATA(variable_name) = NEW zcl_ddve_type_resolver( )->derive_variable_name( i_table_title ).
    DATA(type_name)     = COND string( WHEN variable_name IS NOT INITIAL THEN i_type_name ).

    r_content_4_display = add_itab( i_table_title      = COND #( WHEN type_name IS NOT INITIAL
                                                                 THEN variable_name
                                                                 ELSE i_table_title )
                                    i_current_context  = space
                                    i_table            = i_table
                                    i_fieldcatalog     = i_fieldcatalog
                                    i_dont_add_a_point = i_dont_add_a_point
                                    i_type_name        = type_name ).
  ENDMETHOD.

  METHOD show_popup_w_content.
    DATA(content_4_display) = prepare_output( i_fieldcatalog = i_fieldcatalog
                                              i_table        = i_table
                                              i_table_title  = i_table_title
                                              i_type_name    = NEW zcl_ddve_debugger_integration( )->get_type_expression( i_table_title ) ).

    DATA(formated_content) = zcl_ddve_prettyprinter_factory=>format_with_fallback( content_4_display ).

    NEW zcl_ddve_output_presenter( )->display_text( formated_content ).
  ENDMETHOD.

  METHOD filter_table_from_alv.
    FIELD-SYMBOLS <filtered_table> TYPE table.

    " create local copy of table for filtering
    CREATE DATA result LIKE i_table.
    ASSIGN result->* TO <filtered_table>.
    <filtered_table> = i_table.

    IF i_alv IS NOT BOUND.
      RETURN.
    ENDIF.

    i_alv->get_filtered_entries( IMPORTING et_filtered_entries = DATA(filtered_entries) ).
    DATA filtered_entries_std TYPE TABLE OF i.
    filtered_entries_std = filtered_entries.
    " sort descending so deletion of entries doesn't mess up the table indices
    SORT filtered_entries_std BY table_line DESCENDING.
    LOOP AT filtered_entries_std ASSIGNING FIELD-SYMBOL(<i>).
      DELETE <filtered_table> INDEX <i>.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
