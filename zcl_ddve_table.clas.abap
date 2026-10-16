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
                  i_add_period             TYPE boole_d    DEFAULT abap_true
                  i_type_name              TYPE string     OPTIONAL
        RETURNING VALUE(r_current_context) TYPE string,

      filter_table_from_alv
        IMPORTING i_alv                   TYPE REF TO cl_gui_alv_grid OPTIONAL
                  i_table                 TYPE ANY TABLE
        RETURNING VALUE(r_filtered_table) TYPE REF TO data.

  PRIVATE SECTION.
    TYPES ty_row_indexes TYPE STANDARD TABLE OF i WITH EMPTY KEY.

    DATA renderer TYPE REF TO zcl_ddve_value_renderer.

    METHODS:
      prepare_output
        IMPORTING i_fieldcatalog             TYPE lvc_t_fcat OPTIONAL
                  i_table                    TYPE ANY TABLE
                  i_table_title              TYPE string
                  i_add_period               TYPE boole_d    DEFAULT abap_true
                  i_type_name                TYPE string     OPTIONAL
        RETURNING VALUE(r_content_4_display) TYPE string,

      "! TODO #14: when the toolbar path hands in the debugger ALV clone
      "! (recognizable by its technical INDEX column), re-read the real data
      "! via TPDA and use the clone only as row/column mask. Nested components
      "! are then rendered from the real data instead of the ALV placeholder
      "! texts. Unbound e_table_ref means: keep the given table unchanged.
      replace_clone_by_real_data
        IMPORTING i_table        TYPE ANY TABLE
                  i_fieldcatalog TYPE lvc_t_fcat
                  i_table_title  TYPE string
        EXPORTING e_table_ref    TYPE REF TO data
                  e_fieldcatalog TYPE lvc_t_fcat,

      "! pure operation: does the table's line type contain a component INDEX?
      table_has_index_component
        IMPORTING i_table            TYPE ANY TABLE
        RETURNING VALUE(r_has_index) TYPE abap_bool,

      "! pure operation: INDEX column values of the (already filtered) clone
      "! rows in display order = original row numbers of the debugged table
      extract_row_indexes
        IMPORTING i_clone_table        TYPE ANY TABLE
        RETURNING VALUE(r_row_indexes) TYPE ty_row_indexes,

      "! pure operation: pick the given rows (by primary order position) from
      "! the real table into a standard table container, keeping the order of
      "! i_row_indexes (= ALV display order incl. sorting)
      pick_rows_by_index
        IMPORTING i_table            TYPE ANY TABLE
                  i_row_indexes      TYPE ty_row_indexes
        RETURNING VALUE(r_table_ref) TYPE REF TO data,

      "! pure operation: take the real-type field catalog and carry over the
      "! no_out flags (columns hidden in the ALV) from the frontend catalog
      carry_no_out
        IMPORTING i_real_catalog         TYPE lvc_t_fcat
                  i_alv_catalog          TYPE lvc_t_fcat
        RETURNING VALUE(r_field_catalog) TYPE lvc_t_fcat.
ENDCLASS.


CLASS zcl_ddve_table IMPLEMENTATION.
  METHOD constructor.
    renderer = NEW #( ).
  ENDMETHOD.

  METHOD add_itab.
    r_current_context = renderer->render_itab( i_table_title     = i_table_title
                                               i_current_context = i_current_context
                                               i_table           = i_table
                                               i_component_name  = i_component_name
                                               i_fieldcatalog    = i_fieldcatalog
                                               i_add_period      = i_add_period
                                               i_type_name       = i_type_name ).
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

    r_content_4_display = add_itab( i_table_title = COND #( WHEN type_name IS NOT INITIAL
                                                            THEN variable_name
                                                            ELSE i_table_title )
                                    i_current_context = space
                                    i_table           = i_table
                                    i_fieldcatalog    = i_fieldcatalog
                                    i_add_period      = i_add_period
                                    i_type_name       = type_name ).
  ENDMETHOD.

  METHOD show_popup_w_content.
    FIELD-SYMBOLS <export_table> TYPE ANY TABLE.

    replace_clone_by_real_data( EXPORTING i_table        = i_table
                                          i_fieldcatalog = i_fieldcatalog
                                          i_table_title  = i_table_title
                                IMPORTING e_table_ref    = DATA(real_table_ref)
                                          e_fieldcatalog = DATA(fieldcatalog) ).

    IF real_table_ref IS BOUND.
      ASSIGN real_table_ref->* TO <export_table>.
    ELSE.
      ASSIGN i_table TO <export_table>.
      fieldcatalog = i_fieldcatalog.
    ENDIF.

    DATA(content_4_display) = prepare_output( i_fieldcatalog = fieldcatalog
                                              i_table        = <export_table>
                                              i_table_title  = i_table_title
                                              i_type_name    = NEW zcl_ddve_debugger_integration( )->get_type_expression( i_table_title ) ).

    DATA(formated_content) = zcl_ddve_prettyprinter_factory=>format_with_fallback( content_4_display ).

    NEW zcl_ddve_output_presenter( )->display_text( formated_content ).
  ENDMETHOD.

  METHOD replace_clone_by_real_data.
    FIELD-SYMBOLS <real_table> TYPE ANY TABLE.

    CLEAR: e_table_ref, e_fieldcatalog.

    TRY.
        CHECK table_has_index_component( i_table ) = abap_true.

        DATA(real_table_ref) = NEW zcl_ddve_debugger_integration( )->get_ref_to_any_content( i_table_title ).
        ASSIGN real_table_ref->* TO <real_table>.
        CHECK <real_table> IS ASSIGNED.

        " a genuine INDEX field in the real line type would make the clone
        " column ambiguous - keep today's behavior then
        CHECK table_has_index_component( <real_table> ) = abap_false.

        e_table_ref    = pick_rows_by_index( i_table       = <real_table>
                                             i_row_indexes = extract_row_indexes( i_table ) ).
        e_fieldcatalog = carry_no_out(
            i_real_catalog = NEW zcl_ddve_simple_field_catalog( )->get_by_reference( real_table_ref )
            i_alv_catalog  = i_fieldcatalog ).
      CATCH cx_root.
        " outside the debugger session or any reconstruction problem:
        " unbound result -> caller exports the given table unchanged
        CLEAR: e_table_ref, e_fieldcatalog.
    ENDTRY.
  ENDMETHOD.

  METHOD table_has_index_component.
    DATA(line_descr) = CAST cl_abap_tabledescr( cl_abap_typedescr=>describe_by_data( i_table ) )->get_table_line_type( ).

    CHECK line_descr->kind = cl_abap_typedescr=>kind_struct.

    DATA(structure_descr) = CAST cl_abap_structdescr( line_descr ).
    READ TABLE structure_descr->components WITH KEY name = 'INDEX' TRANSPORTING NO FIELDS.
    r_has_index = xsdbool( sy-subrc = 0 ).
  ENDMETHOD.

  METHOD extract_row_indexes.
    FIELD-SYMBOLS <index_value> TYPE any.

    LOOP AT i_clone_table ASSIGNING FIELD-SYMBOL(<clone_row>).
      ASSIGN COMPONENT 'INDEX' OF STRUCTURE <clone_row> TO <index_value>.
      CHECK <index_value> IS ASSIGNED.
      APPEND <index_value> TO r_row_indexes.
      UNASSIGN <index_value>.
    ENDLOOP.
  ENDMETHOD.

  METHOD pick_rows_by_index.
    DATA line_ref        TYPE REF TO data.
    DATA source_row_ref  TYPE REF TO data.
    DATA source_row_refs TYPE STANDARD TABLE OF REF TO data WITH EMPTY KEY.
    FIELD-SYMBOLS <picked_table> TYPE STANDARD TABLE.

    " a standard table container over the real line type keeps the display order
    CREATE DATA line_ref LIKE LINE OF i_table.
    ASSIGN line_ref->* TO FIELD-SYMBOL(<line>).
    CREATE DATA r_table_ref LIKE STANDARD TABLE OF <line>.
    ASSIGN r_table_ref->* TO <picked_table>.

    " row numbers refer to the primary order of the real table; hashed tables
    " have no index access, so collect row references in loop order first
    LOOP AT i_table ASSIGNING FIELD-SYMBOL(<source_row>).
      GET REFERENCE OF <source_row> INTO source_row_ref.
      APPEND source_row_ref TO source_row_refs.
    ENDLOOP.

    LOOP AT i_row_indexes INTO DATA(row_index).
      READ TABLE source_row_refs INDEX row_index INTO source_row_ref.
      CHECK sy-subrc = 0.
      ASSIGN source_row_ref->* TO FIELD-SYMBOL(<picked_row>).
      APPEND <picked_row> TO <picked_table>.
    ENDLOOP.
  ENDMETHOD.

  METHOD carry_no_out.
    FIELD-SYMBOLS <field> TYPE lvc_s_fcat.

    r_field_catalog = i_real_catalog.

    LOOP AT r_field_catalog ASSIGNING <field>.
      READ TABLE i_alv_catalog INTO DATA(alv_field) WITH KEY fieldname = <field>-fieldname.
      CHECK sy-subrc = 0.
      <field>-no_out = alv_field-no_out.
    ENDLOOP.
  ENDMETHOD.

  METHOD filter_table_from_alv.
    FIELD-SYMBOLS <filtered_table> TYPE table.

    " create local copy of table for filtering
    CREATE DATA r_filtered_table LIKE i_table.
    ASSIGN r_filtered_table->* TO <filtered_table>.
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
