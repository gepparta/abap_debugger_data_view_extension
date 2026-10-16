"Name: \TY:CL_TPDA_TOOL_STRUC_VIEW\IN:IF_TPDA_TOOL\ME:HANDLE_OK_CODE\SE:BEGIN\EI
ENHANCEMENT 0 Z_STRUC_V_BUILD_SERVICES_MENUE.
  IF p_ok_code-ok_code = 'ZDATA_4_ABAP'.
    zcl_ddve_debugger_integration=>debug_debugger_if_needed( ).
    TRY.
        DATA(zz_reference_to_data) = NEW zcl_ddve_debugger_integration( )->get_ref_to_any_content(
                                             i_variable_name = dynp_vars-struc_name ).

        DATA(zz_field_catalog) = NEW zcl_ddve_simple_field_catalog( )->get_by_reference( zz_reference_to_data ).

        FIELD-SYMBOLS <zz_structure> TYPE any.
        ASSIGN zz_reference_to_data->* TO <zz_structure>. " de-referencing

        NEW zcl_ddve_structure( )->show_popup_w_content( i_structure     = <zz_structure>
                                                         i_field_catalog = zz_field_catalog
                                                         i_struc_name    = dynp_vars-struc_name ).
      CATCH cx_root INTO DATA(lx_root).
        " dont want to crash the debugger - but tell the user WHY nothing is shown
        NEW zcl_ddve_output_presenter( )->display_text(
                |DDVE: Anzeige nicht möglich.\n| &&
                |{ cl_abap_typedescr=>describe_by_object_ref( lx_root )->get_relative_name( ) }: | &&
                |{ lx_root->get_text( ) }| ).
    ENDTRY.

    RETURN.
  ENDIF.
ENDENHANCEMENT.
