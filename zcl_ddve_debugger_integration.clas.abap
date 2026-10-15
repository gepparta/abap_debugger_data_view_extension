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
    METHODS get_ref_to_any_content
      IMPORTING i_variable_name      TYPE string
      RETURNING VALUE(r_content_ref) TYPE REF TO data
      RAISING   cx_tpda_sys_symb
                cx_tpda_varname
                cx_tpda_internel_error.

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
                  cx_tpda_internel_error,

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

    CREATE DATA r_empty_data_structure_ref TYPE (abs_type_name).  " RTTC - dynamic creation of  elementary data object
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

    DATA(empty_data_structure_ref) = create_empty_data_structure( i_variable_name  ).

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
        " we have to rename current node (start element), as its name can lead to unseccessfull transformation
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
