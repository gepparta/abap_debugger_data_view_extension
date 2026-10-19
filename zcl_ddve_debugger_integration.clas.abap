"!This Class is offering an integration for debugger structure view
CLASS zcl_ddve_debugger_integration DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    "! Get reference to structure or table content
    "! we need to do this as the full structure content is hidden here
    "! and need to be retrieved via a kernel call
    "! @parameter i_variable_name | Name of the structure
    "! @parameter r_content_ref   | Reference to structures content
    "! @raising cx_tpda_sys_symb |
    "! @raising cx_tpda_varname |
    "! @raising cx_tpda_internel_error |
    "! @raising cx_sy_create_data_error | variable type cannot be re-created in the
    "!                                    debugger session (e.g. anonymous %_T... types)
    METHODS get_ref_to_any_content
      IMPORTING i_variable_name      TYPE string
      RETURNING VALUE(r_content_ref) TYPE REF TO data
      RAISING   cx_tpda_sys_symb
                cx_tpda_varname
                cx_tpda_internel_error
                cx_sy_create_data_error.

    "! Get the absolute type name of a debugger variable (TPDA varabstypename)
    "! @parameter i_variable_name | Name of the variable in the debugger
    "! @parameter r_abs_type_name | absolute type name, e.g. \CLASS=ZCL_X\TYPE=TY_Y
    "! @raising cx_tpda_sys_symb |
    "! @raising cx_tpda_varname |
    "! @raising cx_tpda_internel_error |
    METHODS get_abs_type_name
      IMPORTING i_variable_name        TYPE string
      RETURNING VALUE(r_abs_type_name) TYPE string
      RAISING   cx_tpda_sys_symb
                cx_tpda_varname
                cx_tpda_internel_error.

    "! Resolve the type of a debugger variable into a source-code type expression
    "! for typed VALUE statements; empty when not resolvable or outside a
    "! debugger session (callers then fall back to VALUE #)
    "! @parameter i_variable_name   | Name of the variable in the debugger
    "! @parameter r_type_expression | type expression, e.g. SFLIGHT or ZCL_X=>TY_Y
    METHODS get_type_expression
      IMPORTING i_variable_name          TYPE string
      RETURNING VALUE(r_type_expression) TYPE string.

    CLASS-METHODS debug_debugger_if_needed.

  PRIVATE SECTION.
    METHODS:

      get_data_as_readable_xml
        IMPORTING i_variable_name            TYPE string
        RETURNING VALUE(r_readable_xml_data) TYPE string
        RAISING   cx_tpda_sys_symb,

      create_empty_data_structure
        IMPORTING i_variable_name                   TYPE string
        RETURNING VALUE(r_empty_data_structure_ref) TYPE REF TO data
        RAISING   cx_tpda_sys_symb
                  cx_tpda_varname
                  cx_tpda_internel_error
                  cx_sy_create_data_error,

      "! extract the top-level component names from the asXML of a structure
      "! (pure operation - no debugger required)
      get_component_names_from_xml
        IMPORTING i_xml                    TYPE string
        RETURNING VALUE(r_component_names) TYPE string_table,

      "! fallback for anonymous/object-bound types (\TYPE=%_T...O...): rebuild the
      "! structure type from its components - their types are usually named and
      "! therefore reconstructable in the debugger session
      create_structure_by_components
        IMPORTING i_variable_name                   TYPE string
                  i_xml                             TYPE string
        RETURNING VALUE(r_empty_data_structure_ref) TYPE REF TO data
        RAISING   cx_tpda_sys_symb
                  cx_tpda_varname
                  cx_tpda_internel_error
                  cx_sy_create_data_error,

      "! fallback for anonymous table types (e.g. inline declared sorted/hashed
      "! tables, TODO #8): the table type is not creatable, but its line type
      "! usually is - build a standard table container over the line type
      create_table_by_line_type
        IMPORTING i_variable_name          TYPE string
        RETURNING VALUE(r_empty_table_ref) TYPE REF TO data
        RAISING   cx_tpda_sys_symb
                  cx_tpda_varname
                  cx_tpda_internel_error
                  cx_sy_create_data_error,

      "! pure operation: create an empty standard table over the given line type
      "! (keys are irrelevant for rendering purposes)
      create_table_for_line
        IMPORTING i_line_descr             TYPE REF TO cl_abap_datadescr
        RETURNING VALUE(r_empty_table_ref) TYPE REF TO data
        RAISING   cx_sy_create_data_error,

      fill_empty_data_from_xml
        IMPORTING i_xml                              TYPE string
                  i_empty_data_structure_ref         TYPE REF TO data
        RETURNING VALUE(r_filled_data_structure_ref) TYPE REF TO data,

      rename_xml_node
        IMPORTING i_new_node_name TYPE string
        CHANGING  c_document      TYPE REF TO if_ixml_document,

      render_new_xml_document
        CHANGING c_xml      TYPE string
                 c_ixml     TYPE REF TO if_ixml
                 c_document TYPE REF TO if_ixml_document.

ENDCLASS.



CLASS zcl_ddve_debugger_integration IMPLEMENTATION.


  METHOD get_abs_type_name.
    cl_tpda_ctrl_handler=>get_quick_var( EXPORTING p_symbname      = i_variable_name     " symbol name
                                         IMPORTING p_symbquick_ref = DATA(symbquick_ref) ).

    cl_tpda_variable_services=>convert_quick_info( EXPORTING p_symbquick      = symbquick_ref    " TPDA: Retrieval Structure for get_Symb_Quick
                                                             p_ref_flag       = space
                                                             p_itab_body_flag = space
                                                   IMPORTING p_var_result     = DATA(var_data)    ).

    r_abs_type_name = var_data-varabstypename.
  ENDMETHOD.


  METHOD get_type_expression.
    TRY.
        r_type_expression = NEW zcl_ddve_type_resolver( )->resolve( get_abs_type_name( i_variable_name ) ).
      CATCH cx_root.
        " not resolvable or not inside a debugger session: fall back to VALUE #
        CLEAR r_type_expression.
    ENDTRY.
  ENDMETHOD.


  METHOD create_empty_data_structure.
    DATA(abs_type_name) = get_abs_type_name( i_variable_name ).

    " fails with CX_SY_CREATE_DATA_ERROR for anonymous/object-bound type names
    " (e.g. \TYPE=%_T...O...) that only exist inside the debugged session
    CREATE DATA r_empty_data_structure_ref TYPE (abs_type_name).  " RTTC - dynamic creation of  elementary data object
  ENDMETHOD.


  METHOD get_component_names_from_xml.
    DATA last_node_name TYPE string.

    DATA(ixml)           = cl_ixml=>create( ).
    DATA(stream_factory) = ixml->create_stream_factory( ).
    DATA(document)       = ixml->create_document( ).

    IF ixml->create_parser( document       = document
                            stream_factory = stream_factory
                            istream        = stream_factory->create_istream_string( i_xml )
                            )->parse( ) <> 0.
      RETURN.
    ENDIF.

    " walk to the data root element: asx:abap / asx:values / <data root>
    DATA(node_element_filter) = document->create_filter_node_type( node_types = if_ixml_node=>co_node_element ).
    DATA(iterator) = document->create_iterator_filtered( filter = node_element_filter ).

    DATA(data_root_node) = iterator->get_next( ).
    WHILE data_root_node IS BOUND.
      IF last_node_name = |values|.
        EXIT. " data_root_node now is the element below asx:values
      ENDIF.
      last_node_name  = data_root_node->get_name( ).
      data_root_node  = iterator->get_next( ).
    ENDWHILE.
    CHECK data_root_node IS BOUND.

    " its direct children are the top-level components of the structure
    DATA(component_node) = data_root_node->get_first_child( ).
    WHILE component_node IS BOUND.
      IF component_node->get_type( ) = if_ixml_node=>co_node_element.
        APPEND component_node->get_name( ) TO r_component_names.
      ENDIF.
      component_node = component_node->get_next( ).
    ENDWHILE.
  ENDMETHOD.


  METHOD create_structure_by_components.
    DATA components TYPE abap_component_tab.

    DATA(component_names) = get_component_names_from_xml( i_xml ).

    LOOP AT component_names INTO DATA(component_name).
      DATA(component_abs_type) = get_abs_type_name( |{ i_variable_name }-{ component_name }| ).

      cl_abap_typedescr=>describe_by_name( EXPORTING  p_name         = component_abs_type
                                           RECEIVING  p_descr_ref    = DATA(component_descr)
                                           EXCEPTIONS type_not_found = 1
                                                      OTHERS         = 2 ).
      IF sy-subrc <> 0.
        " component type itself is not reconstructable - give up like before
        RAISE EXCEPTION TYPE cx_sy_create_data_error.
      ENDIF.

      APPEND VALUE abap_componentdescr( name = component_name
                                        type = CAST cl_abap_datadescr( component_descr ) )
             TO components.
    ENDLOOP.

    IF components IS INITIAL.
      RAISE EXCEPTION TYPE cx_sy_create_data_error.
    ENDIF.

    TRY.
        DATA(struct_descr) = cl_abap_structdescr=>create( components ).
        CREATE DATA r_empty_data_structure_ref TYPE HANDLE struct_descr.
      CATCH cx_sy_struct_creation cx_sy_move_cast_error.
        RAISE EXCEPTION TYPE cx_sy_create_data_error.
    ENDTRY.
  ENDMETHOD.


  METHOD create_table_by_line_type.
    " the line symbol NAME[1] only exists for tables - for structures this
    " raises and the caller falls back to the component based rebuild
    DATA(line_abs_type_name) = get_abs_type_name( |{ i_variable_name }[1]| ).

    cl_abap_typedescr=>describe_by_name( EXPORTING  p_name         = line_abs_type_name
                                         RECEIVING  p_descr_ref    = DATA(line_descr)
                                         EXCEPTIONS type_not_found = 1
                                                    OTHERS         = 2 ).
    IF sy-subrc <> 0.
      " line type itself is anonymous: rebuild the line from its components
      DATA(line_ref) = create_structure_by_components(
                           i_variable_name = |{ i_variable_name }[1]|
                           i_xml           = get_data_as_readable_xml( |{ i_variable_name }[1]| ) ).
      line_descr = cl_abap_typedescr=>describe_by_data_ref( line_ref ).
    ENDIF.

    r_empty_table_ref = create_table_for_line( CAST cl_abap_datadescr( line_descr ) ).
  ENDMETHOD.


  METHOD create_table_for_line.
    TRY.
        DATA(table_descr) = cl_abap_tabledescr=>create( i_line_descr ).
        CREATE DATA r_empty_table_ref TYPE HANDLE table_descr.
      CATCH cx_sy_table_creation.
        RAISE EXCEPTION TYPE cx_sy_create_data_error.
    ENDTRY.
  ENDMETHOD.


  METHOD debug_debugger_if_needed.
    IF sy-datum = '20260603' AND sy-uname = 'DEVELOPER'.
*    BREAK-POINT ##NEEDED.
    ENDIF.
  ENDMETHOD.


  METHOD fill_empty_data_from_xml.
    DATA content_ref TYPE REF TO data.

    content_ref = i_empty_data_structure_ref.

    DATA(xml)            = i_xml. " we need a copy as we will change it locally

    DATA(ixml)           = cl_ixml=>create( ).
    DATA(stream_factory) = ixml->create_stream_factory( ).
    DATA(document)       = ixml->create_document( ).

    CONSTANTS c_new_node_name TYPE string VALUE 'Here_Is_the_Data'.

    IF ixml->create_parser( document       = document
                            stream_factory = stream_factory
                            istream        = stream_factory->create_istream_string( xml )
                            )->parse( ) <> 0.
      RETURN.
    ENDIF.

    rename_xml_node( EXPORTING i_new_node_name = c_new_node_name
                     CHANGING  c_document      = document ).

    render_new_xml_document( CHANGING c_xml      = xml
                                      c_ixml     = ixml
                                      c_document = document ).

    DATA transform_result_binding TYPE abap_trans_resbind_tab.
    FIELD-SYMBOLS <result_binding> LIKE LINE OF transform_result_binding.

    APPEND INITIAL LINE TO transform_result_binding ASSIGNING <result_binding>.
    <result_binding>-name  = c_new_node_name.
    <result_binding>-value = content_ref.

    CALL TRANSFORMATION id
         SOURCE XML  xml
         RESULT (transform_result_binding) ##NO_TEXT.

    r_filled_data_structure_ref = content_ref.
  ENDMETHOD.


  METHOD get_data_as_readable_xml.
    cl_tpda_ctrl_handler=>get_symb_asxml( EXPORTING symbname = |{ i_variable_name }|
                                                    offset   = -1
                                                    len      = -1
                                          IMPORTING xml      = DATA(binary_xml_data) ).
    r_readable_xml_data = cl_abap_codepage=>convert_from( binary_xml_data ).
  ENDMETHOD.


  METHOD get_ref_to_any_content.
    DATA(readable_xml_data) = get_data_as_readable_xml( i_variable_name ).

    TRY.
        DATA(empty_data_structure_ref) = create_empty_data_structure( i_variable_name  ).
      CATCH cx_sy_create_data_error.
        " anonymous/object-bound type: tables are rebuilt over their line type
        " (TODO #8), structures from their components (TODO #7)
        TRY.
            empty_data_structure_ref = create_table_by_line_type( i_variable_name ).
          CATCH cx_tpda_sys_symb cx_tpda_varname cx_tpda_internel_error cx_sy_create_data_error.
            empty_data_structure_ref = create_structure_by_components( i_variable_name = i_variable_name
                                                                       i_xml           = readable_xml_data ).
        ENDTRY.
    ENDTRY.

    r_content_ref = fill_empty_data_from_xml( i_xml                      = readable_xml_data
                                              i_empty_data_structure_ref = empty_data_structure_ref    ).
  ENDMETHOD.


  METHOD rename_xml_node.
    DATA last_node_name TYPE string.

    DATA(node_element_filter) = c_document->create_filter_node_type( node_types = if_ixml_node=>co_node_element ).

    DATA(iterator) = c_document->create_iterator_filtered( filter = node_element_filter ).

    DO.
      DATA(node) = iterator->get_next( ).
      IF node IS INITIAL.
        EXIT.
      ENDIF.
      DATA(current_node_name) = node->get_name( ).
      IF last_node_name = |values|.
        " we have to rename current node (start element), as its name can lead to an unsuccessful transformation
        node->set_name( name = i_new_node_name ).
        EXIT.
      ENDIF.
      last_node_name = current_node_name.
    ENDDO.
  ENDMETHOD.


  METHOD render_new_xml_document.
    CLEAR c_xml. " we will append new content to it now
    c_document->render( ostream = c_ixml->create_stream_factory( )->create_ostream_cstring( string = c_xml ) ).
  ENDMETHOD.
ENDCLASS.
