CLASS zcl_ddve_output_presenter DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS display_text
      IMPORTING i_content TYPE string.

ENDCLASS.


CLASS zcl_ddve_output_presenter IMPLEMENTATION.
  METHOD display_text.
    cl_demo_output=>set_mode( cl_demo_output=>text_mode ).
    cl_demo_output=>write_data( i_content ).
    cl_demo_output=>display( ).
  ENDMETHOD.
ENDCLASS.
