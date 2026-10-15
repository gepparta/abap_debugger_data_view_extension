"!This class is offering an API for represent a structure
"!in its ABAP VALUE way: structure_name = VALUE #(...)
CLASS zcl_ddve_structure DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS:
      constructor,

      "! is getting called from enhancement <br/>
      "! will ask for max line length, format content and show it
      "! @parameter i_structure     | given structure
      "! @parameter i_field_catalog | field catalog of structure
      "! @parameter i_struc_name    | structure name for "name" = VALUE #() statement
      show_popup_w_content
        IMPORTING i_structure     TYPE any
                  i_field_catalog TYPE lvc_t_fcat
                  i_struc_name    TYPE string,

      "! add a structure to given formatted context<br/>
      "! kept for compatibility: delegates to ZCL_DDVE_VALUE_RENDERER->RENDER_STRUCTURE_RHS
      "! @parameter i_structure       | given structure
      "! @parameter i_field_catalog   | field catalog of structure
      "! @parameter r_current_context | changed context with added structure data as string
      add_structure
        IMPORTING i_structure              TYPE any
                  i_field_catalog          TYPE lvc_t_fcat
        RETURNING VALUE(r_current_context) TYPE string.

  PRIVATE SECTION.
    DATA renderer TYPE REF TO zcl_ddve_value_renderer.

    METHODS:
      left_hand_side
        IMPORTING i_struc_name                   TYPE string
                  i_type_name                    TYPE string OPTIONAL
        RETURNING VALUE(rv_left_hand_side_value) TYPE string,

      prepare_output
        IMPORTING i_structure                TYPE any
                  i_field_catalog            TYPE lvc_t_fcat
                  i_struc_name               TYPE string
                  i_type_name                TYPE string OPTIONAL
        RETURNING VALUE(r_content_4_display) TYPE string.

ENDCLASS.


CLASS zcl_ddve_structure IMPLEMENTATION.
  METHOD constructor.
    renderer = NEW #( ).
  ENDMETHOD.

  METHOD add_structure.
    r_current_context = renderer->render_structure_rhs( i_structure     = i_structure
                                                        i_field_catalog = i_field_catalog ).
  ENDMETHOD.

  METHOD left_hand_side.
    rv_left_hand_side_value = COND string( WHEN i_type_name IS NOT INITIAL
                                           THEN |DATA({ i_struc_name })|
                                           ELSE i_struc_name ).
  ENDMETHOD.

  METHOD prepare_output.
    CHECK i_structure IS NOT INITIAL.

    " typed form DATA(name) = VALUE typ( ) only when the debugger symbol name
    " can be turned into a valid variable name - otherwise classic name = VALUE #( )
    DATA(variable_name) = NEW zcl_ddve_type_resolver( )->derive_variable_name( i_struc_name ).
    DATA(type_name)     = COND string( WHEN variable_name IS NOT INITIAL THEN i_type_name ).

    r_content_4_display = |{ left_hand_side( i_struc_name = COND #( WHEN type_name IS NOT INITIAL
                                                                    THEN variable_name
                                                                    ELSE i_struc_name )
                                             i_type_name  = type_name ) }{ renderer->render_structure_rhs(
                                                                               i_structure     = i_structure
                                                                               i_field_catalog = i_field_catalog
                                                                               i_type_name     = type_name ) }.|.
  ENDMETHOD.

  METHOD show_popup_w_content.
    DATA(content_4_display) = prepare_output( i_struc_name    = i_struc_name
                                              i_structure     = i_structure
                                              i_field_catalog = i_field_catalog
                                              i_type_name     = NEW zcl_ddve_debugger_integration( )->get_type_expression( i_struc_name ) ).

    DATA(formated_content) = zcl_ddve_prettyprinter_factory=>format_with_fallback( content_4_display ).

    NEW zcl_ddve_output_presenter( )->display_text( formated_content ).
  ENDMETHOD.
ENDCLASS.
